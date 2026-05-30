-- CrosshairUI creates a simple center-screen ScreenGui crosshair for the Pistol.
-- It only handles UI visibility and does not change weapon firing logic.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local WEAPON_NAME = "Pistol"

local crosshairGui = nil
local crosshairFrame = nil
local connectedTools = {}
local watchedContainers = {}

-- GUI creation
local function createLine(parent, name, size, position)
	local outline = Instance.new("Frame")
	outline.Name = name .. "Outline"
	outline.AnchorPoint = Vector2.new(0.5, 0.5)
	outline.Position = position
	outline.Size = size
	outline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	outline.BorderSizePixel = 0
	outline.ZIndex = 10
	outline.Parent = parent

	local line = Instance.new("Frame")
	line.Name = name
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.new(1, -2, 1, -2)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.ZIndex = 11
	line.Parent = outline
end

local function createCrosshairGui()
	local playerGui = player:WaitForChild("PlayerGui")

	crosshairGui = playerGui:FindFirstChild("CrosshairGui")
	if crosshairGui then
		crosshairFrame = crosshairGui:FindFirstChild("Crosshair")
		return
	end

	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "CrosshairGui"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.IgnoreGuiInset = true
	crosshairGui.DisplayOrder = 50
	crosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	crosshairGui.Parent = playerGui

	crosshairFrame = Instance.new("Frame")
	crosshairFrame.Name = "Crosshair"
	crosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshairFrame.Position = UDim2.fromScale(0.5, 0.5)
	crosshairFrame.Size = UDim2.fromOffset(42, 42)
	crosshairFrame.BackgroundTransparency = 1
	crosshairFrame.Visible = false
	crosshairFrame.ZIndex = 10
	crosshairFrame.Parent = crosshairGui

	createLine(crosshairFrame, "Top", UDim2.fromOffset(4, 10), UDim2.new(0.5, 0, 0.5, -12))
	createLine(crosshairFrame, "Bottom", UDim2.fromOffset(4, 10), UDim2.new(0.5, 0, 0.5, 12))
	createLine(crosshairFrame, "Left", UDim2.fromOffset(10, 4), UDim2.new(0.5, -12, 0.5, 0))
	createLine(crosshairFrame, "Right", UDim2.fromOffset(10, 4), UDim2.new(0.5, 12, 0.5, 0))
end

-- Visibility control
local function setCrosshairVisible(isVisible)
	if crosshairFrame then
		crosshairFrame.Visible = isVisible
	end
end

-- Pistol equip tracking
local function connectPistol(tool)
	if not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME or connectedTools[tool] then
		return
	end

	connectedTools[tool] = true

	tool.Equipped:Connect(function()
		setCrosshairVisible(true)
	end)

	tool.Unequipped:Connect(function()
		setCrosshairVisible(false)
	end)
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
	setCrosshairVisible(false)
	watchContainer(player:WaitForChild("Backpack"))
	watchContainer(character)
end

createCrosshairGui()

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)
