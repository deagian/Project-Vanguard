-- AimCamera gives supported weapons a simple third-person over-the-shoulder feel.
-- It only adjusts local camera/mouse settings while a supported weapon is equipped.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AIM_SENSITIVITY_MULTIPLIER = 0.55
local CAMERA_SMOOTHNESS = 0.15
local SHOULDER_OFFSET = Vector3.new(2.2, 1.4, 0)

local player = Players.LocalPlayer
local SUPPORTED_WEAPONS = {
	Pistol = true,
	AssaultRifle = true,
}

local connectedTools = {}
local watchedContainers = {}
local activeHumanoid = nil
local originalCameraOffset = nil
local originalMouseBehavior = nil
local originalMouseIconEnabled = nil
local originalMouseDeltaSensitivity = nil
local smoothCameraConnection = nil
local aimRotationConnection = nil
local aimDiedConnection = nil
local aimEnabled = false
local disableAimCamera = nil

local function stopSmoothCamera()
	if smoothCameraConnection then
		smoothCameraConnection:Disconnect()
		smoothCameraConnection = nil
	end
end

local function stopAimRotation()
	if aimRotationConnection then
		aimRotationConnection:Disconnect()
		aimRotationConnection = nil
	end
end

local function stopAimDiedConnection()
	if aimDiedConnection then
		aimDiedConnection:Disconnect()
		aimDiedConnection = nil
	end
end

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getHumanoidRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function startSmoothCamera(humanoid, targetOffset)
	stopSmoothCamera()

	smoothCameraConnection = RunService.RenderStepped:Connect(function()
		if not aimEnabled or activeHumanoid ~= humanoid or not humanoid.Parent then
			stopSmoothCamera()
			return
		end

		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(targetOffset, CAMERA_SMOOTHNESS)
	end)
end

local function startAimRotation(humanoid)
	stopAimRotation()

	aimRotationConnection = RunService.RenderStepped:Connect(function()
		if not aimEnabled or activeHumanoid ~= humanoid or not humanoid.Parent or humanoid.Health <= 0 then
			stopAimRotation()
			return
		end

		local camera = workspace.CurrentCamera
		local rootPart = getHumanoidRootPart()
		if not camera or not rootPart then
			return
		end

		local look = camera.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude <= 0.01 then
			return
		end

		local rootPosition = rootPart.Position
		rootPart.CFrame = CFrame.lookAt(rootPosition, rootPosition + flatLook.Unit)
	end)
end

local function enableAimCamera()
	if aimEnabled then
		return
	end

	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	activeHumanoid = humanoid
	originalCameraOffset = humanoid.CameraOffset
	originalMouseBehavior = UserInputService.MouseBehavior
	originalMouseIconEnabled = UserInputService.MouseIconEnabled
	originalMouseDeltaSensitivity = UserInputService.MouseDeltaSensitivity

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseDeltaSensitivity = AIM_SENSITIVITY_MULTIPLIER
	humanoid.AutoRotate = false
	aimEnabled = true

	startSmoothCamera(humanoid, SHOULDER_OFFSET)
	startAimRotation(humanoid)
	aimDiedConnection = humanoid.Died:Connect(function()
		if disableAimCamera then
			disableAimCamera()
		end
	end)
	print("[AimController] Enabled")
	print("[AimCamera] Enabled")
end

function disableAimCamera()
	if not aimEnabled then
		return
	end

	if activeHumanoid then
		activeHumanoid.CameraOffset = originalCameraOffset or Vector3.zero
		activeHumanoid.AutoRotate = true
	end

	stopSmoothCamera()
	stopAimRotation()
	stopAimDiedConnection()

	if originalMouseBehavior then
		UserInputService.MouseBehavior = originalMouseBehavior
	end

	if originalMouseIconEnabled ~= nil then
		UserInputService.MouseIconEnabled = originalMouseIconEnabled
	end

	if originalMouseDeltaSensitivity then
		UserInputService.MouseDeltaSensitivity = originalMouseDeltaSensitivity
	end

	activeHumanoid = nil
	originalCameraOffset = nil
	originalMouseBehavior = nil
	originalMouseIconEnabled = nil
	originalMouseDeltaSensitivity = nil
	aimEnabled = false
	print("[AimController] Disabled")
	print("[AimCamera] Disabled")
end

local function connectWeapon(tool)
	if not tool:IsA("Tool") or not SUPPORTED_WEAPONS[tool.Name] or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true

	tool.Equipped:Connect(enableAimCamera)
	tool.Unequipped:Connect(disableAimCamera)
end

local function watchContainer(container)
	if watchedContainers[container] then
		return
	end

	watchedContainers[container] = true

	for _, child in ipairs(container:GetChildren()) do
		connectWeapon(child)
	end

	container.ChildAdded:Connect(connectWeapon)
end

local function setupCharacter(character)
	disableAimCamera()
	watchContainer(player:WaitForChild("Backpack"))
	watchContainer(character)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)
