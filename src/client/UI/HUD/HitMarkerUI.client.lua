-- HitMarkerUI shows a quick center-screen X when the server confirms a pistol hit.
-- It listens only to the weapon hit confirmation RemoteEvent and does not control crosshair visibility.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local WeaponHitConfirm = Remotes:WaitForChild("WeaponHitConfirm")

local HIT_MARKER_DURATION = 0.12
local BODY_HIT_COLOR = Color3.fromRGB(255, 255, 255)
local HEADSHOT_HIT_COLOR = Color3.fromRGB(255, 55, 55)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HitMarkerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 60
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local markerFrame = Instance.new("Frame")
markerFrame.Name = "HitMarker"
markerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
markerFrame.Position = UDim2.fromScale(0.5, 0.5)
markerFrame.Size = UDim2.fromOffset(34, 34)
markerFrame.BackgroundTransparency = 1
markerFrame.Visible = false
markerFrame.Parent = screenGui

local function createMarkerLine(rotation)
	local line = Instance.new("Frame")
	line.Name = "HitMarkerLine"
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.fromOffset(28, 3)
	line.BackgroundColor3 = BODY_HIT_COLOR
	line.BorderSizePixel = 0
	line.Rotation = rotation
	line.ZIndex = 20
	line.Parent = markerFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = line
end

createMarkerLine(45)
createMarkerLine(-45)

local markerToken = 0

local function setMarkerColor(color)
	for _, child in ipairs(markerFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "HitMarkerLine" then
			child.BackgroundColor3 = color
		end
	end
end

local function showHitMarker(isHeadshot)
	markerToken += 1
	local currentToken = markerToken

	if isHeadshot then
		setMarkerColor(HEADSHOT_HIT_COLOR)
	else
		setMarkerColor(BODY_HIT_COLOR)
	end

	print("[WeaponClient] Hit marker shown")
	markerFrame.Visible = true

	task.delay(HIT_MARKER_DURATION, function()
		if markerToken == currentToken then
			markerFrame.Visible = false
		end
	end)
end

WeaponHitConfirm.OnClientEvent:Connect(showHitMarker)
