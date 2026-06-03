print("[Movement] MovementController loaded")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")

local GameSettings = require(Modules:WaitForChild("GameSettings"))
print(GameSettings)
print(GameSettings.StaminaDrainRate)
print(GameSettings.MaxStamina)
local InputManager = require(
	script.Parent.Parent.Input:WaitForChild("InputManager")
)

local character
local humanoid

local isSprinting = false
local stamina = GameSettings.MaxStamina

local DEFAULT_FOV = 70
local SPRINT_FOV = 80

local bobTime = 0
local bobSpeed = 8
local bobIntensity = 0.1

local tweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

local function tweenFOV(targetFOV)
	TweenService:Create(camera, tweenInfo, {
		FieldOfView = targetFOV
	}):Play()
end

local function setupCharacter(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = GameSettings.DefaultWalkSpeed
end

local function startSprint()
	if not humanoid then return end
	if stamina <= 0 then return end

	isSprinting = true
	humanoid.WalkSpeed = GameSettings.SprintSpeed
	tweenFOV(SPRINT_FOV)
end

local function stopSprint()
	if not humanoid then return end

	isSprinting = false
	humanoid.WalkSpeed = GameSettings.DefaultWalkSpeed
	tweenFOV(DEFAULT_FOV)
end

local function updateCameraBob(dt)
	dt = tonumber(dt) or 0.016

	if not humanoid or not character then return end

	local moving = humanoid.MoveDirection.Magnitude > 0

	if moving then
		bobTime += dt * bobSpeed

		local intensity = bobIntensity
		if isSprinting then
			intensity = bobIntensity * 1.5
		end

		local x = math.sin(bobTime) * intensity
		local y = math.abs(math.cos(bobTime)) * intensity

		camera.CFrame = camera.CFrame * CFrame.new(x, y, 0)
	else
		bobTime = 0
	end
end

local function updateStamina(dt)
	dt = tonumber(dt) or 0.016

	if isSprinting then
		stamina -= GameSettings.StaminaDrainRate * dt

		if stamina <= 0 then
			stamina = 0
			stopSprint()
		end
	else
		stamina += GameSettings.StaminaRechargeRate * dt

		if stamina > GameSettings.MaxStamina then
			stamina = GameSettings.MaxStamina
		end
	end
end

RunService.RenderStepped:Connect(function(dt)

	dt = tonumber(dt) or 0.016

	if InputManager:IsSprinting() then
		if not isSprinting then
			startSprint()
		end
	else
		if isSprinting then
			stopSprint()
		end
	end

	updateCameraBob(dt)
	updateStamina(dt)
end)

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
	setupCharacter(player.Character)
end
local MovementController = {}

function MovementController:GetStamina()
	return stamina
end

function MovementController:GetMaxStamina()
	return GameSettings.MaxStamina
end

function MovementController:IsSprinting()
	return isSprinting
end

function MovementController:ConsumeStamina(amount)
	-- Consumo locale finche la stamina non viene validata dal server.
	stamina = math.max(0, stamina - amount)

	if stamina <= 0 and isSprinting then
		stopSprint()
	end
end

return MovementController
