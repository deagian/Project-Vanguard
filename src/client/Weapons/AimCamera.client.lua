-- AimCamera gives the pistol a simple third-person over-the-shoulder feel.
-- It only adjusts local camera/mouse settings while the Pistol is equipped.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AIM_SENSITIVITY_MULTIPLIER = 0.55
local CAMERA_SMOOTHNESS = 0.15
local SHOULDER_OFFSET = Vector3.new(2.2, 1.4, 0)

local player = Players.LocalPlayer
local WEAPON_NAME = "Pistol"

local connectedTools = {}
local watchedContainers = {}
local activeHumanoid = nil
local originalCameraOffset = nil
local originalMouseBehavior = nil
local originalMouseIconEnabled = nil
local originalMouseDeltaSensitivity = nil
local smoothCameraConnection = nil
local aimEnabled = false

local function stopSmoothCamera()
	if smoothCameraConnection then
		smoothCameraConnection:Disconnect()
		smoothCameraConnection = nil
	end
end

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
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
	aimEnabled = true

	startSmoothCamera(humanoid, SHOULDER_OFFSET)
	print("[AimCamera] Enabled")
end

local function disableAimCamera()
	if not aimEnabled then
		return
	end

	if activeHumanoid then
		activeHumanoid.CameraOffset = originalCameraOffset or Vector3.zero
	end

	stopSmoothCamera()

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
	print("[AimCamera] Disabled")
end

local function connectPistol(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
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
		connectPistol(child)
	end

	container.ChildAdded:Connect(connectPistol)
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
