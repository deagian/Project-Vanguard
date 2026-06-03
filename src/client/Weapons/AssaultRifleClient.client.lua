-- AssaultRifleClient gestisce fuoco automatico, munizioni, reload e feedback locale.
-- Il client invia solo richiesta e punto mirato: danno e hit detection restano server-side.

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

local WEAPON_NAME = "AssaultRifle"
local RIFLE_CONFIG = WeaponConfig[WEAPON_NAME]
local MUZZLE_FLASH_TIME = 0.035
local RECOIL_RETURN_SPEED = 22
local FIRE_SOUND_ID = "rbxassetid://9119561046"
-- TODO: sostituire con suoni proprietari Project Vanguard.
local RELOAD_SOUND_ID = ""
local EMPTY_SOUND_ID = "rbxassetid://9117969717"

local connectedTools = {}
local equippedTool = nil
local currentAmmo = RIFLE_CONFIG.MagazineSize
local isReloading = false
local isFiring = false
local recoilAmount = 0
local lastLocalFireTime = -RIFLE_CONFIG.FireCooldown

print("[AssaultRifleClient] Loaded")

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
	sound.RollOffMaxDistance = 120
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
		flash.Brightness = 8
		flash.Range = 10
		flash.Color = Color3.fromRGB(255, 232, 160)
		flash.Enabled = false
		flash.Parent = barrel
	end

	local flashPart = barrel:FindFirstChild("MuzzleFlashPart")
	if not flashPart then
		flashPart = Instance.new("Part")
		flashPart.Name = "MuzzleFlashPart"
		flashPart.Shape = Enum.PartType.Ball
		flashPart.Size = Vector3.new(0.2, 0.2, 0.2)
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

local function updateAmmoState()
	player:SetAttribute("AssaultRifleAmmo", currentAmmo)
	player:SetAttribute("AssaultRifleMaxAmmo", RIFLE_CONFIG.MagazineSize)
	player:SetAttribute("AssaultRifleReloading", isReloading)

	if equippedTool then
		player:SetAttribute("EquippedWeaponName", WEAPON_NAME)
		player:SetAttribute("EquippedWeaponAmmo", currentAmmo)
		player:SetAttribute("EquippedWeaponMaxAmmo", RIFLE_CONFIG.MagazineSize)
		player:SetAttribute("EquippedWeaponReloading", isReloading)
	end

	print("[AssaultRifleClient] Ammo", currentAmmo .. " / " .. RIFLE_CONFIG.MagazineSize)
end

local function applyRecoil()
	local recoilMultiplier = 1
	if ADSController:IsADS() then
		recoilMultiplier = RIFLE_CONFIG.ADSRecoilMultiplier
	end

	recoilAmount += RIFLE_CONFIG.Recoil * recoilMultiplier
end

local function getSpreadShot()
	local camera = workspace.CurrentCamera
	if not camera or not mouse.Hit then
		return nil
	end

	local spreadDegrees = RIFLE_CONFIG.HipFireSpread
	if ADSController:IsADS() then
		spreadDegrees = RIFLE_CONFIG.ADSSpread
	end

	local yaw = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local pitch = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local aimPoint = mouse.Hit.Position
	print("[AssaultRifleClient] aimPoint=", aimPoint)

	local shotOrigin = camera.CFrame.Position
	local shotDirection = aimPoint - shotOrigin
	if shotDirection.Magnitude <= 0 then
		return nil
	end

	local spreadCFrame = CFrame.lookAt(shotOrigin, aimPoint) * CFrame.Angles(pitch, yaw, 0)

	return shotOrigin, spreadCFrame.LookVector.Unit, aimPoint
end

local function canFire()
	if not equippedTool or isReloading or currentAmmo <= 0 then
		return false
	end

	if os.clock() - lastLocalFireTime < RIFLE_CONFIG.FireCooldown then
		return false
	end

	return true
end

local function fireOnce()
	if not canFire() then
		if equippedTool and currentAmmo <= 0 then
			playTemporarySound(equippedTool, EMPTY_SOUND_ID, 0.4)
		end

		return
	end

	local shotOrigin, shotDirection, aimPoint = getSpreadShot()
	if not shotOrigin or not shotDirection then
		return
	end

	lastLocalFireTime = os.clock()
	currentAmmo -= 1
	updateAmmoState()
	WeaponEffects.PlayMuzzleFlash(equippedTool)
	WeaponEffects.PlayFireSound(equippedTool, WEAPON_NAME)
	local muzzlePosition = WeaponEffects.GetMuzzleWorldPosition(equippedTool) or shotOrigin
	local tracerDirection = aimPoint - muzzlePosition
	WeaponEffects.PlayBulletTracer(muzzlePosition, tracerDirection, RIFLE_CONFIG.Range)
	applyRecoil()

	print("[AssaultRifleClient] Fire request sent")
	print("[ARClient] FireServer weapon=AssaultRifle origin=", shotOrigin, " direction=", shotDirection, " ammo=", currentAmmo)
	WeaponFire:FireServer(WEAPON_NAME, shotOrigin, shotDirection, aimPoint)
end

local function startAutomaticFire()
	if isFiring then
		return
	end

	isFiring = true

	task.spawn(function()
		while isFiring and equippedTool do
			fireOnce()
			task.wait(RIFLE_CONFIG.FireCooldown)
		end
	end)
end

local function stopAutomaticFire()
	isFiring = false
end

local function reloadRifle()
	if isReloading or currentAmmo == RIFLE_CONFIG.MagazineSize or not equippedTool then
		return
	end

	stopAutomaticFire()
	isReloading = true
	updateAmmoState()
	print("[AssaultRifleClient] Reload started")
	playTemporarySound(equippedTool, RELOAD_SOUND_ID, 0.55)

	task.delay(RIFLE_CONFIG.ReloadTime, function()
		currentAmmo = RIFLE_CONFIG.MagazineSize
		isReloading = false
		updateAmmoState()
		print("[AssaultRifleClient] Reload complete")
	end)
end

local function connectRifle(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true
	print("[AssaultRifleClient] AssaultRifle found")

	tool.Equipped:Connect(function()
		equippedTool = tool
		ADSController:SetWeaponEquipped(true)
		updateAmmoState()
		print("[AssaultRifleClient] Equipped")
	end)

	tool.Unequipped:Connect(function()
		if equippedTool == tool then
			stopAutomaticFire()
			equippedTool = nil
			isReloading = false
			ADSController:SetWeaponEquipped(false)
			player:SetAttribute("EquippedWeaponReloading", false)
			print("[AssaultRifleClient] Unequipped")
		end
	end)
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		connectRifle(child)
	end

	container.ChildAdded:Connect(connectRifle)
end

local backpack = player:WaitForChild("Backpack")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startAutomaticFire()
	elseif input.KeyCode == Enum.KeyCode.R then
		reloadRifle()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopAutomaticFire()
	end
end)

local function setupCharacter(character)
	stopAutomaticFire()
	equippedTool = nil
	isReloading = false
	ADSController:SetWeaponEquipped(false)

	watchContainer(backpack)
	watchContainer(character)
end

local character = player.Character or player.CharacterAdded:Wait()
setupCharacter(character)
updateAmmoState()

player.CharacterAdded:Connect(setupCharacter)
