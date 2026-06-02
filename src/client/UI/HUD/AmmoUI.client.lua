-- AmmoUI displays the local pistol ammo count near the bottom right.
-- It reads client-side player attributes updated by PistolClient and does not affect weapon damage.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AmmoGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 55
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -34, 1, -34)
ammoLabel.Size = UDim2.fromOffset(150, 42)
ammoLabel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
ammoLabel.BackgroundTransparency = 0.22
ammoLabel.BorderSizePixel = 0
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.TextSize = 24
ammoLabel.TextXAlignment = Enum.TextXAlignment.Center
ammoLabel.TextYAlignment = Enum.TextYAlignment.Center
ammoLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = ammoLabel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.78
stroke.Thickness = 1
stroke.Parent = ammoLabel

local function updateAmmoText()
	local currentAmmo = player:GetAttribute("PistolAmmo") or 0
	local maxAmmo = player:GetAttribute("PistolMaxAmmo") or 12
	local isReloading = player:GetAttribute("PistolReloading")

	if isReloading then
		ammoLabel.Text = "RELOAD"
	else
		ammoLabel.Text = currentAmmo .. " / " .. maxAmmo
	end
end

player:GetAttributeChangedSignal("PistolAmmo"):Connect(updateAmmoText)
player:GetAttributeChangedSignal("PistolMaxAmmo"):Connect(updateAmmoText)
player:GetAttributeChangedSignal("PistolReloading"):Connect(updateAmmoText)

updateAmmoText()
