-- WaveHUD mostra il primo loop giocabile: wave, kill e deaths.
-- Legge solo attributi replicati dal server, senza influenzare gameplay o danno.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 60
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "StatsPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -28, 0, 28)
panel.Size = UDim2.fromOffset(170, 94)
panel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.8
stroke.Thickness = 1
stroke.Parent = panel

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.BackgroundTransparency = 1
statsLabel.Position = UDim2.fromOffset(12, 10)
statsLabel.Size = UDim2.new(1, -24, 1, -20)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextColor3 = Color3.fromRGB(245, 248, 250)
statsLabel.TextSize = 18
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = panel

local waveMessage = Instance.new("TextLabel")
waveMessage.Name = "WaveMessage"
waveMessage.AnchorPoint = Vector2.new(0.5, 0)
waveMessage.Position = UDim2.new(0.5, 0, 0, 132)
waveMessage.Size = UDim2.fromOffset(360, 44)
waveMessage.BackgroundTransparency = 1
waveMessage.Font = Enum.Font.GothamBlack
waveMessage.TextColor3 = Color3.fromRGB(255, 230, 90)
waveMessage.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
waveMessage.TextStrokeTransparency = 0.25
waveMessage.TextSize = 32
waveMessage.Text = ""
waveMessage.Parent = screenGui

local function updateHUD()
	local wave = player:GetAttribute("CurrentWave") or 0
	local kills = player:GetAttribute("PlayerKills") or 0
	local deaths = player:GetAttribute("PlayerDeaths") or 0
	local message = player:GetAttribute("WaveMessage") or ""

	statsLabel.Text = "WAVE: " .. wave .. "\nKILLS: " .. kills .. "\nDEATHS: " .. deaths
	waveMessage.Text = message
end

player:GetAttributeChangedSignal("CurrentWave"):Connect(updateHUD)
player:GetAttributeChangedSignal("PlayerKills"):Connect(updateHUD)
player:GetAttributeChangedSignal("PlayerDeaths"):Connect(updateHUD)
player:GetAttributeChangedSignal("WaveMessage"):Connect(updateHUD)

updateHUD()
