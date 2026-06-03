local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ADS_FOV = 55
local FOV_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local player = Players.LocalPlayer

local ADSController = {}

local isEquipped = false
local isADS = false
local normalFOV = nil
local activeFOVTween = nil

local function setADSAttribute()
	player:SetAttribute("ADSActive", isADS)
end

local function tweenCameraFOV(targetFOV)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if activeFOVTween then
		activeFOVTween:Cancel()
		activeFOVTween = nil
	end

	activeFOVTween = TweenService:Create(camera, FOV_TWEEN_INFO, {
		FieldOfView = targetFOV,
	})
	activeFOVTween:Play()
end

local function setADS(enabled)
	if enabled == isADS then
		return
	end

	if enabled and not isEquipped then
		return
	end

	local camera = workspace.CurrentCamera
	if enabled then
		normalFOV = camera and camera.FieldOfView or normalFOV
		isADS = true
		tweenCameraFOV(ADS_FOV)
		print("[ADS] Enabled")
	else
		isADS = false
		if normalFOV then
			tweenCameraFOV(normalFOV)
		end
		normalFOV = nil
		print("[ADS] Disabled")
	end

	setADSAttribute()
end

function ADSController:SetWeaponEquipped(equipped)
	isEquipped = equipped

	if not isEquipped then
		setADS(false)
	end
end

function ADSController:IsADS()
	return isADS
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setADS(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setADS(false)
	end
end)

setADSAttribute()

return ADSController
