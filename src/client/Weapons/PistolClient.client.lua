-- PistolClient listens for the local player's Pistol Tool.
-- It only sends a fire request and aim point; the server decides hits and damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local WeaponFire = Remotes:WaitForChild("WeaponFire")

local WEAPON_NAME = "Pistol"

local connectedTools = {}
local equippedTool = nil

print("[WeaponClient] Loaded")

local function connectPistol(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true
	print("[WeaponClient] Pistol found")

	tool.Equipped:Connect(function()
		equippedTool = tool
		print("[WeaponClient] Equipped")
	end)

	tool.Unequipped:Connect(function()
		if equippedTool == tool then
			equippedTool = nil
		end
	end)

	tool.Activated:Connect(function()
		print("[WeaponClient] Activated")

		if equippedTool ~= tool or not mouse.Hit then
			return
		end

		-- Send only where the player aimed. The server chooses the ray origin, range, and damage.
		WeaponFire:FireServer(WEAPON_NAME, mouse.Hit.Position)
	end)
end

local function findPistol(backpack, character)
	local backpackTool = backpack:FindFirstChild(WEAPON_NAME)
	if backpackTool then
		connectPistol(backpackTool)
	end

	local characterTool = character:FindFirstChild(WEAPON_NAME)
	if characterTool then
		connectPistol(characterTool)
	end
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		connectPistol(child)
	end

	container.ChildAdded:Connect(connectPistol)
end

local backpack = player:WaitForChild("Backpack")

local function setupCharacter(character)
	equippedTool = nil

	watchContainer(backpack)
	watchContainer(character)
	findPistol(backpack, character)
end

local character = player.Character or player.CharacterAdded:Wait()
setupCharacter(character)

player.CharacterAdded:Connect(setupCharacter)
