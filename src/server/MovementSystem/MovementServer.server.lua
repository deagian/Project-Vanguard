local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[MovementServer] Loaded")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local Remotes = Shared:WaitForChild("Remotes")

local MovementConfig = require(Modules:WaitForChild("MovementConfig"))
local MovementAction = Remotes:WaitForChild("MovementAction")
print("[MovementServer] MovementAction RemoteEvent confirmed")

local slideConfig = MovementConfig.Slide
local lastActionTimes = {}
local crouchStates = {}

local function rejectDodge(reason)
	print("[MovementServer] Dodge rejected: " .. reason)
end

local function getCharacterParts(player)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	return character, humanoid, rootPart
end

local function canUseSlide(player)
	local now = os.clock()
	local lastSlideTime = lastActionTimes[player]

	if lastSlideTime and now - lastSlideTime < slideConfig.Cooldown then
		rejectDodge("cooldown")
		return false
	end

	return true
end

local function commitDodgeCooldown(player)
	lastActionTimes[player] = os.clock()
end

local function onMovementAction(player, actionName, dodgeSide)
	if typeof(actionName) ~= "string" then
		rejectDodge("invalid action type")
		return
	end

	if actionName == "CrouchChanged" then
		crouchStates[player] = dodgeSide == true

		local character = player.Character
		if character then
			character:SetAttribute("IsCrouching", crouchStates[player])
			character:SetAttribute("CanSprint", not crouchStates[player])
			character:SetAttribute("CanDodge", not crouchStates[player])
			character:SetAttribute("CanSlide", not crouchStates[player])
		end

		return
	end

	if actionName ~= "Dodge" then
		rejectDodge("invalid action")
		return
	end

	if dodgeSide ~= "Left" and dodgeSide ~= "Right" then
		rejectDodge("invalid direction")
		return
	end

	local _, humanoid, rootPart = getCharacterParts(player)
	if not humanoid or not rootPart then
		rejectDodge("missing character parts")
		return
	end

	if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		rejectDodge("dead humanoid")
		return
	end

	if crouchStates[player] then
		rejectDodge("crouching")
		return
	end

	if not canUseSlide(player) then
		return
	end

	commitDodgeCooldown(player)
	print("[MovementServer] Dodge accepted " .. dodgeSide)
	MovementAction:FireClient(player, "DodgeAccepted", dodgeSide)
end

MovementAction.OnServerEvent:Connect(onMovementAction)

Players.PlayerRemoving:Connect(function(player)
	lastActionTimes[player] = nil
	crouchStates[player] = nil
end)
