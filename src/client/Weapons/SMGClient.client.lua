-- SMGClient handles the placeholder automatic SMG.
-- It mirrors the rifle client pattern while using SMG config values.

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

local WEAPON_NAME = "SMG"
local SMG_CONFIG = WeaponConfig[WEAPON_NAME]
local RECOIL_RETURN_SPEED = 24
local RELOAD_SOUND_ID = ""
local EMPTY_SOUND_ID = "rbxassetid://9117969717"

local connectedTools = {}
local watchedContainers = {}
local equippedTool = nil
local currentAmmo = SMG_CONFIG.MagazineSize
local isReloading = false
local isFiring = false
local recoilAmount = 0
local lastLocalFireTime = -SMG_CONFIG.FireCooldown

print("[SMGClient] Loaded")

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
	if not soundId or soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMaxDistance = 110
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

local function updateAmmoState()
	player:SetAttribute("SMGAmmo", currentAmmo)
	player:SetAttribute("SMGMaxAmmo", SMG_CONFIG.MagazineSize)
	player:SetAttribute("SMGReloading", isReloading)

	if equippedTool then
		player:SetAttribute("EquippedWeaponName", WEAPON_NAME)
		player:SetAttribute("EquippedWeaponAmmo", currentAmmo)
		player:SetAttribute("EquippedWeaponMaxAmmo", SMG_CONFIG.MagazineSize)
		player:SetAttribute("EquippedWeaponReloading", isReloading)
	end

	print("[SMGClient] Ammo", currentAmmo .. " / " .. SMG_CONFIG.MagazineSize)
end

local function applyRecoil()
	local recoilMultiplier = 1
	if ADSController:IsADS() then
		recoilMultiplier = SMG_CONFIG.ADSRecoilMultiplier
	end

	recoilAmount += SMG_CONFIG.Recoil * recoilMultiplier
end

local function getSpreadShot()
	local camera = workspace.CurrentCamera
	if not camera or not mouse.Hit then
		return nil
	end

	local spreadDegrees = SMG_CONFIG.HipFireSpread
	if ADSController:IsADS() then
		spreadDegrees = SMG_CONFIG.ADSSpread
	end

	local yaw = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local pitch = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local aimPoint = mouse.Hit.Position
	print("[SMGClient] aimPoint=", aimPoint)

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

	if os.clock() - lastLocalFireTime < SMG_CONFIG.FireCooldown then
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
	WeaponEffects.PlayBulletTracer(muzzlePosition, tracerDirection, SMG_CONFIG.Range)
	applyRecoil()

	print("[SMGClient] Fire request sent")
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
			task.wait(SMG_CONFIG.FireCooldown)
		end
	end)
end

local function stopAutomaticFire()
	isFiring = false
end

local function reloadSMG()
	if isReloading or currentAmmo == SMG_CONFIG.MagazineSize or not equippedTool then
		return
	end

	stopAutomaticFire()
	isReloading = true
	updateAmmoState()
	print("[SMGClient] Reload started")
	playTemporarySound(equippedTool, RELOAD_SOUND_ID, 0.55)

	task.delay(SMG_CONFIG.ReloadTime, function()
		currentAmmo = SMG_CONFIG.MagazineSize
		isReloading = false
		updateAmmoState()
		print("[SMGClient] Reload complete")
	end)
end

local function connectSMG(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true
	print("[SMGClient] SMG found")

	tool.Equipped:Connect(function()
		equippedTool = tool
		ADSController:SetWeaponEquipped(true)
		updateAmmoState()
		print("[SMGClient] Equipped")
	end)

	tool.Unequipped:Connect(function()
		if equippedTool == tool then
			stopAutomaticFire()
			equippedTool = nil
			isReloading = false
			ADSController:SetWeaponEquipped(false)
			player:SetAttribute("EquippedWeaponReloading", false)
			print("[SMGClient] Unequipped")
		end
	end)
end

local function watchContainer(container)
	if watchedContainers[container] then
		return
	end

	watchedContainers[container] = true

	for _, child in ipairs(container:GetChildren()) do
		connectSMG(child)
	end

	container.ChildAdded:Connect(connectSMG)
end

local backpack = player:WaitForChild("Backpack")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startAutomaticFire()
	elseif input.KeyCode == Enum.KeyCode.R then
		reloadSMG()
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
