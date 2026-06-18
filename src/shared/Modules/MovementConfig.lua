local MovementConfig = {}

MovementConfig.Slide = {
	Duration = 0.25,
	Cooldown = 1.0,
	SpeedBoost = 95,
	StaminaCost = 18,
	MinStaminaRequired = 25,
}

MovementConfig.Crouch = {
	WalkSpeed = 9,
	CameraOffset = Vector3.new(0, -1.4, 0),
	CameraTweenTime = 0.12,
	CrouchIdleAnimationId = "rbxassetid://112933126479531",
	CrouchWalkAnimationId = "rbxassetid://137450686624521",
}

return MovementConfig
