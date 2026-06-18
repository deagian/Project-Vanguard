local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local Remotes = Shared:WaitForChild("Remotes")

local GameSettings = require(Modules:WaitForChild("GameSettings"))
local MovementConfig = require(Modules:WaitForChild("MovementConfig"))
local InputManager = require(
	script.Parent.Parent.Input:WaitForChild("InputManager")
)
local MovementAction = Remotes:WaitForChild("MovementAction")

local character
local humanoid

local isSprinting = false
local isCrouching = false
local stamina = GameSettings.MaxStamina
local defaultCameraOffset = Vector3.zero
local currentCameraTween
local crouchIdleTrack
local crouchWalkTrack
local currentCrouchTrack

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

local function setCameraOffset(targetOffset)
	if not humanoid then return end

	if currentCameraTween then
		currentCameraTween:Cancel()
	end

	currentCameraTween = TweenService:Create(humanoid, TweenInfo.new(
		MovementConfig.Crouch.CameraTweenTime,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	), {
		CameraOffset = targetOffset
	})

	currentCameraTween:Play()
end

local function updateMovementState()
	if not humanoid then return end

	if isCrouching then
		humanoid.WalkSpeed = MovementConfig.Crouch.WalkSpeed
	elseif isSprinting then
		humanoid.WalkSpeed = GameSettings.SprintSpeed
	else
		humanoid.WalkSpeed = GameSettings.DefaultWalkSpeed
	end

	if character then
		character:SetAttribute("IsCrouching", isCrouching)
		character:SetAttribute("CanSprint", not isCrouching)
		character:SetAttribute("CanDodge", not isCrouching)
		character:SetAttribute("CanSlide", not isCrouching)
	end
end

local function stopCrouchAnimations()
	if crouchIdleTrack then
		crouchIdleTrack:Stop(0.12)
	end

	if crouchWalkTrack then
		crouchWalkTrack:Stop(0.12)
	end

	currentCrouchTrack = nil
end

local function cleanupCrouchAnimations()
	stopCrouchAnimations()

	if crouchIdleTrack then
		crouchIdleTrack:Destroy()
		crouchIdleTrack = nil
	end

	if crouchWalkTrack then
		crouchWalkTrack:Destroy()
		crouchWalkTrack = nil
	end
end

local function getAnimationAssetId(animationId)
	if typeof(animationId) ~= "string" or string.match(animationId, "^%s*$") then
		return nil
	end

	animationId = string.gsub(animationId, "%s+", "")

	if string.match(animationId, "^rbxassetid://") then
		return animationId
	end

	return "rbxassetid://" .. animationId
end

local function loadCrouchAnimation(animator, animationId)
	local assetId = getAnimationAssetId(animationId)
	if not assetId then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = assetId

	local loaded, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not loaded or not track then
		animation:Destroy()
		warn("[Crouch] failed to load animation " .. assetId)
		return nil
	end

	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true

	animation:Destroy()
	return track
end

local function setupCrouchAnimations()
	cleanupCrouchAnimations()

	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	crouchIdleTrack = loadCrouchAnimation(animator, MovementConfig.Crouch.CrouchIdleAnimationId)
	crouchWalkTrack = loadCrouchAnimation(animator, MovementConfig.Crouch.CrouchWalkAnimationId)
end

local function playCrouchAnimation(nextTrack)
	if currentCrouchTrack == nextTrack then
		return
	end

	if currentCrouchTrack then
		currentCrouchTrack:Stop(0.12)
	end

	currentCrouchTrack = nextTrack

	if currentCrouchTrack then
		currentCrouchTrack:Play(0.12)
	end
end

local function updateCrouchAnimation(isMoving)
	if not isCrouching then
		stopCrouchAnimations()
		return
	end

	if isMoving then
		playCrouchAnimation(crouchWalkTrack or crouchIdleTrack)
	else
		playCrouchAnimation(crouchIdleTrack or crouchWalkTrack)
	end
end

local function setCrouching(nextIsCrouching)
	if isCrouching == nextIsCrouching then return end

	isCrouching = nextIsCrouching
	MovementAction:FireServer("CrouchChanged", isCrouching)

	if isCrouching then
		if isSprinting then
			isSprinting = false
			tweenFOV(DEFAULT_FOV)
		end

		setCameraOffset(defaultCameraOffset + MovementConfig.Crouch.CameraOffset)
		print("[Crouch] enabled")
	else
		setCameraOffset(defaultCameraOffset)
		stopCrouchAnimations()
		print("[Crouch] disabled")
	end

	updateMovementState()
end

local function setupCharacter(newCharacter)
	cleanupCrouchAnimations()

	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	isSprinting = false
	isCrouching = false
	InputManager:SetCrouching(false)
	MovementAction:FireServer("CrouchChanged", false)
	stamina = GameSettings.MaxStamina
	bobTime = 0
	defaultCameraOffset = humanoid.CameraOffset
	humanoid.WalkSpeed = GameSettings.DefaultWalkSpeed
	humanoid.CameraOffset = defaultCameraOffset
	setupCrouchAnimations()
	updateMovementState()
	tweenFOV(DEFAULT_FOV)
end

local function startSprint()
	if not humanoid then return end
	if isCrouching then return end
	if stamina <= 0 then return end
	if humanoid.MoveDirection.Magnitude <= 0 then return end

	isSprinting = true
	updateMovementState()
	tweenFOV(SPRINT_FOV)
end

local function stopSprint()
	if not humanoid then return end

	isSprinting = false
	updateMovementState()
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

	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0

	if isSprinting and moving then
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

	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0
	setCrouching(InputManager:IsCrouching())
	updateCrouchAnimation(moving)

	if InputManager:IsSprinting() and moving and not isCrouching then
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

function MovementController:IsCrouching()
	return isCrouching
end

function MovementController:ConsumeStamina(amount)
	-- Consumo locale finche la stamina non viene validata dal server.
	stamina = math.max(0, stamina - amount)

	if stamina <= 0 and isSprinting then
		stopSprint()
	end
end

return MovementController
