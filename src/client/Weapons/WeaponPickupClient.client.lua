-- WeaponPickupClient forwards ProximityPrompt pickups to the server.
-- The server owns validation and decides whether a weapon is granted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local RequestWeaponPickup = Remotes:WaitForChild("RequestWeaponPickup")

local function findPickupRoot(instance)
	local current = instance

	while current and current ~= workspace do
		if current:GetAttribute("WeaponId") ~= nil then
			return current
		end

		current = current.Parent
	end

	return nil
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("PVWeaponPickupPrompt") ~= true then
		return
	end

	local pickupRoot = findPickupRoot(prompt.Parent)
	if not pickupRoot then
		return
	end

	RequestWeaponPickup:FireServer(pickupRoot)
end)
