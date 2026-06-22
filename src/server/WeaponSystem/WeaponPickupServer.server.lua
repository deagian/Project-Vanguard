-- WeaponPickupServer creates pickup prompts and grants trusted weapon tools.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")

local RequestWeaponPickup = Remotes:FindFirstChild("RequestWeaponPickup")
if not RequestWeaponPickup then
	RequestWeaponPickup = Instance.new("RemoteEvent")
	RequestWeaponPickup.Name = "RequestWeaponPickup"
	RequestWeaponPickup.Parent = Remotes
end

local MAX_PICKUP_DISTANCE = 10
local SUPPORTED_WEAPONS = {
	Pistol = "Pistol",
	AssaultRifle = "AssaultRifle",
}

local function isPickupRoot(instance)
	return instance and instance:GetAttribute("WeaponId") ~= nil
end

local function getPromptParent(pickupRoot)
	if pickupRoot:IsA("BasePart") then
		return pickupRoot
	end

	if pickupRoot:IsA("Tool") then
		local handle = pickupRoot:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle
		end
	end

	if pickupRoot:IsA("Model") then
		local primaryPart = pickupRoot.PrimaryPart
		if primaryPart then
			return primaryPart
		end

		local basePart = pickupRoot:FindFirstChildWhichIsA("BasePart", true)
		if basePart then
			return basePart
		end
	end

	return pickupRoot:FindFirstChildWhichIsA("BasePart", true)
end

local function getPickupPosition(pickupRoot)
	if pickupRoot:IsA("BasePart") then
		return pickupRoot.Position
	end

	if pickupRoot:IsA("Model") then
		return pickupRoot:GetPivot().Position
	end

	if pickupRoot:IsA("Tool") then
		local handle = pickupRoot:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle.Position
		end
	end

	local promptParent = getPromptParent(pickupRoot)
	if promptParent then
		return promptParent.Position
	end

	return nil
end

local function playerHasWeapon(player, weaponName)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local backpackTool = backpack:FindFirstChild(weaponName)
		if backpackTool and backpackTool:IsA("Tool") then
			return true
		end
	end

	local character = player.Character
	if character then
		local characterTool = character:FindFirstChild(weaponName)
		if characterTool and characterTool:IsA("Tool") then
			return true
		end
	end

	return false
end

local function isPlayerNearPickup(player, pickupRoot)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local pickupPosition = getPickupPosition(pickupRoot)
	if not pickupPosition then
		return false
	end

	return (rootPart.Position - pickupPosition).Magnitude <= MAX_PICKUP_DISTANCE
end

local function setPickupConsumed(pickupRoot)
	pickupRoot:SetAttribute("PickupConsumed", true)

	for _, descendant in ipairs(pickupRoot:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant:GetAttribute("PVWeaponPickupPrompt") == true then
			descendant.Enabled = false
		elseif descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if pickupRoot:IsA("BasePart") then
		pickupRoot.Transparency = 1
		pickupRoot.CanCollide = false
		pickupRoot.CanTouch = false
		pickupRoot.CanQuery = false
	end

	task.defer(function()
		if pickupRoot.Parent then
			pickupRoot:Destroy()
		end
	end)
end

local function giveWeapon(player, weaponName)
	if playerHasWeapon(player, weaponName) then
		return true
	end

	local template = StarterPack:FindFirstChild(weaponName)
	if not template or not template:IsA("Tool") then
		warn("[WeaponPickupServer] Missing StarterPack tool for " .. weaponName)
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false
	end

	local tool = template:Clone()
	tool.Parent = backpack
	return true
end

local function setupPickup(pickupRoot)
	if not isPickupRoot(pickupRoot) or pickupRoot:GetAttribute("PickupConsumed") == true then
		return
	end

	local weaponId = pickupRoot:GetAttribute("WeaponId")
	if typeof(weaponId) ~= "string" or not SUPPORTED_WEAPONS[weaponId] then
		return
	end

	local promptParent = getPromptParent(pickupRoot)
	if not promptParent then
		warn("[WeaponPickupServer] Pickup has no BasePart for prompt: " .. pickupRoot:GetFullName())
		return
	end

	local prompt = promptParent:FindFirstChild("WeaponPickupPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "WeaponPickupPrompt"
		prompt.Parent = promptParent
	end

	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = MAX_PICKUP_DISTANCE
	prompt.ActionText = "Pick up"
	prompt.ObjectText = ""
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt:SetAttribute("PVWeaponPickupPrompt", true)
end

local function tryPickup(player, pickupRoot)
	if typeof(pickupRoot) ~= "Instance" or not pickupRoot:IsDescendantOf(workspace) then
		return
	end

	if not isPickupRoot(pickupRoot) or pickupRoot:GetAttribute("PickupConsumed") == true then
		return
	end

	local weaponId = pickupRoot:GetAttribute("WeaponId")
	local weaponName = SUPPORTED_WEAPONS[weaponId]
	if not weaponName then
		return
	end

	if not isPlayerNearPickup(player, pickupRoot) then
		return
	end

	if giveWeapon(player, weaponName) then
		setPickupConsumed(pickupRoot)
	end
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	setupPickup(descendant)
end

workspace.DescendantAdded:Connect(function(descendant)
	if isPickupRoot(descendant) then
		setupPickup(descendant)
	end
end)

RequestWeaponPickup.OnServerEvent:Connect(tryPickup)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			for _, descendant in ipairs(workspace:GetDescendants()) do
				setupPickup(descendant)
			end
		end)
	end)
end)
