local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientFolder = player.PlayerScripts:WaitForChild("Client")
local ControllersFolder = ClientFolder:WaitForChild("Controllers")

local MovementController = require(
	ControllersFolder:WaitForChild("MovementController")
)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local background = Instance.new("Frame")
background.Size = UDim2.new(0, 300, 0, 25)
background.Position = UDim2.new(0.5, -150, 1, -60)
background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
background.BorderSizePixel = 0
background.Parent = screenGui

local staminaBar = Instance.new("Frame")
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = background

RunService.RenderStepped:Connect(function()

	local stamina = MovementController:GetStamina()

	local maxStamina = MovementController:GetMaxStamina()

	local percent = stamina / maxStamina

	staminaBar.Size = UDim2.new(percent, 0, 1, 0)

end)