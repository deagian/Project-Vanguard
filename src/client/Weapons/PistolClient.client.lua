-- PistolClient listens for the local player's Pistol Tool.
-- It only sends a fire request and aim point; the server decides hits and damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local Remotes = Shared:WaitForChild("Remotes")
local WeaponConfig = require(Modules:WaitForChild("WeaponConfig"))
local WeaponFire = Remotes:WaitForChild("WeaponFire")
local ADSController = require(script.Parent:WaitForChild("ADSController"))
local WeaponEffects = require(script.Parent:WaitForChild("WeaponEffects"))

local WEAPON_NAME = "Pistol"
local PISTOL_CONFIG = WeaponConfig[WEAPON_NAME]
local MUZZLE_FLASH_TIME = 0.05
local RECOIL_KICK = PISTOL_CONFIG.Recoil or 0.9
local ADS_RECOIL_MULTIPLIER = PISTOL_CONFIG.ADSRecoilMultiplier or 0.55
local RECOIL_RETURN_SPEED = 18
local FIRE_SOUND_ID = "rbxassetid://9119561046"
-- TODO: Replace with a Project Vanguard-owned public reload sound ID.
local RELOAD_SOUND_ID = ""
-- TODO: Replace with a Project Vanguard-owned public empty click sound ID if this placeholder causes access errors.
local EMPTY_SOUND_ID = "rbxassetid://9117969717"

local connectedTools = {}
local equippedTool = nil
local currentAmmo = PISTOL_CONFIG.MagazineSize
local isReloading = false
local recoilAmount = 0

print("[WeaponClient] Loaded")

RunService.RenderStepped:Connect(function(deltaTime)
	if recoilAmount <= 0 then
		return
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame *= CFrame.Angles(math.rad(-recoilAmount), 0, 0)
	end

	recoilAmount = math.max(0, recoilAmount - RECOIL_RETURN_SPEED * deltaTime)
end)

local function getSoundParent(tool)
	return tool:FindFirstChild("Handle") or tool
end

local function playTemporarySound(tool, soundId, volume)
	if soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMaxDistance = 80
	sound.Parent = getSoundParent(tool)
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function showMuzzleFlash(tool)
	local barrel = tool:FindFirstChild("Barrel")
	if not barrel or not barrel:IsA("BasePart") then
		return
	end

	local flash = barrel:FindFirstChild("MuzzleFlash")
	if not flash then
		flash = Instance.new("PointLight")
		flash.Name = "MuzzleFlash"
		flash.Brightness = 7
		flash.Range = 8
		flash.Color = Color3.fromRGB(255, 235, 170)
		flash.Enabled = false
		flash.Parent = barrel
	end

	local flashPart = barrel:FindFirstChild("MuzzleFlashPart")
	if not flashPart then
		flashPart = Instance.new("Part")
		flashPart.Name = "MuzzleFlashPart"
		flashPart.Shape = Enum.PartType.Ball
		flashPart.Size = Vector3.new(0.22, 0.22, 0.22)
		flashPart.Material = Enum.Material.Neon
		flashPart.Color = Color3.fromRGB(255, 220, 120)
		flashPart.Transparency = 1
		flashPart.CanCollide = false
		flashPart.CanQuery = false
		flashPart.CanTouch = false
		flashPart.Massless = true
		flashPart.CFrame = barrel.CFrame * CFrame.new(0, 0, -barrel.Size.Z / 2 - 0.08)
		flashPart.Parent = barrel

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = barrel
		weld.Part1 = flashPart
		weld.Parent = flashPart
	end

	print("[WeaponClient] Muzzle flash")
	flash.Enabled = true
	flashPart.Transparency = 0

	task.delay(MUZZLE_FLASH_TIME, function()
		if flash.Parent then
			flash.Enabled = false
		end

		if flashPart.Parent then
			flashPart.Transparency = 1
		end
	end)
end

local function applyRecoil()
	local recoilMultiplier = 1
	if ADSController:IsADS() then
		recoilMultiplier = ADS_RECOIL_MULTIPLIER
	end

	recoilAmount += RECOIL_KICK * recoilMultiplier
	print("[WeaponClient] Recoil applied")
end

local function getSpreadShot()
	local camera = workspace.CurrentCamera
	if not camera or not mouse.Hit then
		return nil, nil
	end

	local spreadDegrees = PISTOL_CONFIG.HipFireSpread or 0
	if ADSController:IsADS() then
		spreadDegrees = PISTOL_CONFIG.ADSSpread or spreadDegrees
	end

	local aimPoint = mouse.Hit.Position
	print("[PistolClient] aimPoint=", aimPoint)

	local origin = camera.CFrame.Position
	local aimDirection = aimPoint - origin
	if aimDirection.Magnitude <= 0 then
		return nil, nil
	end

	if spreadDegrees <= 0 then
		return origin, aimDirection.Unit
	end

	local yaw = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local pitch = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local spreadCFrame = CFrame.lookAt(origin, aimPoint) * CFrame.Angles(pitch, yaw, 0)
	local spreadDirection = spreadCFrame.LookVector

	return origin, spreadDirection.Unit, aimPoint
end

local function updateAmmoState()
	player:SetAttribute("PistolAmmo", currentAmmo)
	player:SetAttribute("PistolMaxAmmo", PISTOL_CONFIG.MagazineSize)
	player:SetAttribute("PistolReloading", isReloading)

	if equippedTool then
		player:SetAttribute("EquippedWeaponName", WEAPON_NAME)
		player:SetAttribute("EquippedWeaponAmmo", currentAmmo)
		player:SetAttribute("EquippedWeaponMaxAmmo", PISTOL_CONFIG.MagazineSize)
		player:SetAttribute("EquippedWeaponReloading", isReloading)
	end

	print("[WeaponClient] Ammo", currentAmmo .. " / " .. PISTOL_CONFIG.MagazineSize)
end

local function reloadPistol()
	if isReloading or currentAmmo == PISTOL_CONFIG.MagazineSize then
		return
	end

	isReloading = true
	updateAmmoState()
	print("[WeaponClient] Reload started")
	playTemporarySound(equippedTool, RELOAD_SOUND_ID, 0.55)

	task.delay(PISTOL_CONFIG.ReloadTime, function()
		currentAmmo = PISTOL_CONFIG.MagazineSize
		isReloading = false
		updateAmmoState()
		print("[WeaponClient] Reload complete")
	end)
end

local function connectPistol(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true
	print("[WeaponClient] Pistol found")

	tool.Equipped:Connect(function()
		equippedTool = tool
		ADSController:SetWeaponEquipped(true)
		updateAmmoState()
		print("[WeaponClient] Equipped")
	end)

	tool.Unequipped:Connect(function()
		if equippedTool == tool then
			equippedTool = nil
			ADSController:SetWeaponEquipped(false)
			player:SetAttribute("EquippedWeaponReloading", false)
		end
	end)

	tool.Activated:Connect(function()
		print("[WeaponClient] Activated")

		if equippedTool ~= tool or isReloading then
			return
		end

		if currentAmmo <= 0 then
			print("[WeaponClient] Empty magazine")
			playTemporarySound(tool, EMPTY_SOUND_ID, 0.45)
			return
		end

		currentAmmo -= 1
		updateAmmoState()
		WeaponEffects.PlayMuzzleFlash(tool)
		WeaponEffects.PlayFireSound(tool, WEAPON_NAME)
		print("[WeaponClient] Fire sound")
		applyRecoil()

		-- Send only the aimed position. The server chooses the origin, range, hit, and damage.
		print("[WeaponClient] Fire request sent")
		local shotOrigin, shotDirection, aimPoint = getSpreadShot()
		if shotOrigin and shotDirection then
			local muzzlePosition = WeaponEffects.GetMuzzleWorldPosition(tool) or shotOrigin
			local tracerDirection = aimPoint - muzzlePosition
			WeaponEffects.PlayBulletTracer(muzzlePosition, tracerDirection, PISTOL_CONFIG.Range)
			WeaponFire:FireServer(WEAPON_NAME, shotOrigin, shotDirection, aimPoint)
		end
	end)
end

local function findPistol(backpack, character)
	local backpackTool = backpack:FindFirstChild(WEAPON_NAME)
	if backpackTool then
		connectPistol(backpackTool)
	end

	local characterTool = character:FindFirstChild(WEAPON_NAME)
	if characterTool then
		connectPistol(characterTool)
	end
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		connectPistol(child)
	end

	container.ChildAdded:Connect(connectPistol)
end

local backpack = player:WaitForChild("Backpack")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.R or not equippedTool then
		return
	end

	reloadPistol()
end)

local function setupCharacter(character)
	equippedTool = nil
	ADSController:SetWeaponEquipped(false)

	watchContainer(backpack)
	watchContainer(character)
	findPistol(backpack, character)
end

local character = player.Character or player.CharacterAdded:Wait()
setupCharacter(character)
updateAmmoState()

player.CharacterAdded:Connect(setupCharacter)
