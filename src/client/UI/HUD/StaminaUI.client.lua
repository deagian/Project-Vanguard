local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientFolder = player.PlayerScripts:WaitForChild("Client")
local ControllersFolder = ClientFolder:WaitForChild("Controllers")

local MovementController = require(
	ControllersFolder:WaitForChild("MovementController")
)

local HUD_NAME = "HUD"
local LEGACY_HUD_NAMES = {
	"StaminaGui",
	"ProjectVanguardStaminaGui",
}

local oldGui = playerGui:FindFirstChild(HUD_NAME)
if oldGui then
	oldGui:Destroy()
end

for _, guiName in LEGACY_HUD_NAMES do
	local legacyGui = playerGui:FindFirstChild(guiName)
	if legacyGui then
		legacyGui:Destroy()
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = HUD_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
print("[HUD] Tactical StaminaUI loaded")

local background = Instance.new("Frame")
background.AnchorPoint = Vector2.new(0, 1)
background.Size = UDim2.new(0, 178, 0, 30)
background.Position = UDim2.new(0.018, 0, 0.94, 0)
background.BackgroundColor3 = Color3.fromRGB(12, 16, 18)
background.BackgroundTransparency = 0.3
background.BorderSizePixel = 0
background.Parent = screenGui

local backgroundCorner = Instance.new("UICorner")
backgroundCorner.CornerRadius = UDim.new(0, 5)
backgroundCorner.Parent = background

local backgroundStroke = Instance.new("UIStroke")
backgroundStroke.Color = Color3.fromRGB(76, 88, 90)
backgroundStroke.Transparency = 0.25
backgroundStroke.Thickness = 1
backgroundStroke.Parent = background

local hudScale = Instance.new("UIScale")
hudScale.Scale = 1
hudScale.Parent = background

local label = Instance.new("TextLabel")
label.Name = "StaminaLabel"
label.BackgroundTransparency = 1
label.Position = UDim2.new(0, 8, 0, 2)
label.Size = UDim2.new(0, 34, 0, 12)
label.Font = Enum.Font.GothamBold
label.Text = "STM"
label.TextColor3 = Color3.fromRGB(176, 188, 186)
label.TextSize = 10
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = background

local barBackground = Instance.new("Frame")
barBackground.Name = "StaminaBarBackground"
barBackground.Size = UDim2.new(0, 160, 0, 8)
barBackground.Position = UDim2.new(0, 8, 0, 17)
barBackground.BackgroundColor3 = Color3.fromRGB(30, 36, 37)
barBackground.BackgroundTransparency = 0.1
barBackground.BorderSizePixel = 0
barBackground.Parent = background

local barBackgroundCorner = Instance.new("UICorner")
barBackgroundCorner.CornerRadius = UDim.new(0, 4)
barBackgroundCorner.Parent = barBackground

local staminaBar = Instance.new("Frame")
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = barBackground

local staminaBarCorner = Instance.new("UICorner")
staminaBarCorner.CornerRadius = UDim.new(0, 4)
staminaBarCorner.Parent = staminaBar

local currentTween = nil
local lastPercent = nil

local function updateHudScale()
	if not workspace.CurrentCamera then
		return
	end

	local viewportSize = workspace.CurrentCamera.ViewportSize
	hudScale.Scale = math.clamp(viewportSize.X / 1280, 0.82, 1)
end

local function getStaminaColor(percent)
	if percent <= 0.3 then
		return Color3.fromRGB(255, 60, 60)
	elseif percent <= 0.5 then
		return Color3.fromRGB(255, 210, 0)
	end

	return Color3.fromRGB(0, 170, 255)
end

updateHudScale()

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudScale)
end

RunService.RenderStepped:Connect(function()

	local stamina = MovementController:GetStamina()

	local maxStamina = MovementController:GetMaxStamina()

	local percent = stamina / maxStamina

	if not lastPercent or math.abs(percent - lastPercent) >= 0.01 or percent == 0 or percent == 1 then
		lastPercent = percent

		if currentTween then
			currentTween:Cancel()
		end

		currentTween = TweenService:Create(
			staminaBar,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(percent, 0, 1, 0) }
		)
		currentTween:Play()
	end

	staminaBar.BackgroundColor3 = getStaminaColor(percent)

end)
