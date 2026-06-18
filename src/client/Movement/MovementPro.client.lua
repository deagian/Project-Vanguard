local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

print("[MovementPro] Loaded")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local Remotes = Shared:WaitForChild("Remotes")
local Client = script.Parent.Parent
local Controllers = Client:WaitForChild("Controllers")

local MovementConfig = require(Modules:WaitForChild("MovementConfig"))
local MovementController = require(Controllers:WaitForChild("MovementController"))
local MovementAction = Remotes:WaitForChild("MovementAction")
print("[MovementPro] MovementAction RemoteEvent confirmed")

local slideConfig = MovementConfig.Slide
local lastSlideTime = -slideConfig.Cooldown
local isSliding = false
local sideInput = {
	Left = false,
	Right = false,
}

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getDodgeSide()
	if sideInput.Left == sideInput.Right then
		return nil
	end

	if sideInput.Left then
		return "Left"
	end

	return "Right"
end

local function canStartSlide()
	if isSliding then
		return false
	end

	if os.clock() - lastSlideTime < slideConfig.Cooldown then
		return false
	end

	if not MovementController:IsSprinting() then
		return false
	end

	if MovementController:IsCrouching() then
		return false
	end

	if MovementController:GetStamina() < slideConfig.MinStaminaRequired then
		return false
	end

	if not getDodgeSide() then
		return false
	end

	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true
end

local function startSlide()
	if not canStartSlide() then
		return
	end

	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	local dodgeSide = getDodgeSide()
	if not dodgeSide then
		return
	end

	isSliding = true
	lastSlideTime = os.clock()

	print("[MovementPro] Dodge requested", dodgeSide)
	MovementAction:FireServer("Dodge", dodgeSide)

	task.delay(slideConfig.Duration, function()
		isSliding = false
	end)
end

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function applyLocalDodge(dodgeSide)
	local humanoid = getHumanoid()
	local rootPart = getRootPart()
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	if dodgeSide ~= "Left" and dodgeSide ~= "Right" then
		return
	end

	local right = rootPart.CFrame.RightVector
	local direction = if dodgeSide == "Left" then -right else right
	direction = Vector3.new(direction.X, 0, direction.Z)

	if direction.Magnitude < 0.1 then
		return
	end

	direction = direction.Unit
	local attachment = Instance.new("Attachment")
	local linearVelocity = Instance.new("LinearVelocity")

	attachment.Name = "TacticalDodgeSlideAttachment"
	attachment.Parent = rootPart

	linearVelocity.Name = "TacticalDodgeSlideVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * slideConfig.SpeedBoost
	linearVelocity.Parent = rootPart

	print("[MovementPro] Dodge accepted " .. dodgeSide)
	-- TODO: futuro passaggio a stamina e validazione movimento server-authoritative.
	MovementController:ConsumeStamina(slideConfig.StaminaCost)

	task.delay(slideConfig.Duration, function()
		if linearVelocity.Parent then
			linearVelocity:Destroy()
		end

		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

MovementAction.OnClientEvent:Connect(function(actionName, dodgeSide)
	if actionName == "DodgeAccepted" then
		applyLocalDodge(dodgeSide)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.A then
		sideInput.Left = true
	elseif input.KeyCode == Enum.KeyCode.D then
		sideInput.Right = true
	end

	if input.KeyCode == Enum.KeyCode.LeftControl then
		startSlide()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.A then
		sideInput.Left = false
	elseif input.KeyCode == Enum.KeyCode.D then
		sideInput.Right = false
	end
end)
