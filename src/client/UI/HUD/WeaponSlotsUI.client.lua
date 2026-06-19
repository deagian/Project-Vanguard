-- WeaponSlotsUI owns the custom weapon hotbar and local slot equip input.
-- It does not add pickup behavior, call RemoteEvents, or change weapon stats/gameplay.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "WeaponSlotsUI"
local EQUIP_ACTION_NAME = "ProjectVanguardWeaponSlotsEquip"
local EQUIP_ACTION_PRIORITY = Enum.ContextActionPriority.High.Value
local selectedSlot = 1
local slotFrames = {}
local viewportConnection = nil
local keyCodeToSlot = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

ContextActionService:UnbindAction(EQUIP_ACTION_NAME)

local function getBackpack()
	return player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
end

local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
	oldGui:Destroy()
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 54
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "SlotBar"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -26)
container.Size = UDim2.fromOffset(462, 82)
container.BackgroundTransparency = 1
container.Parent = screenGui

local hudScale = Instance.new("UIScale")
hudScale.Parent = container

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = container

local slots = {
	{
		key = "1",
		name = "Pistol",
		icon = "PISTOL",
		toolName = "Pistol",
		selected = true,
	},
	{
		key = "2",
		name = "Assault Rifle",
		icon = "RIFLE",
		toolName = "AssaultRifle",
		selected = false,
	},
	{
		key = "3",
		name = "Empty",
		icon = "-",
		selected = false,
	},
	{
		key = "4",
		name = "Empty",
		icon = "-",
		selected = false,
	},
	{
		key = "5",
		name = "Empty",
		icon = "-",
		selected = false,
	},
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function applySlotStyle(slot, slotInfo, isSelected)
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	local keyBadge = slot:FindFirstChild("Key")
	local accent = slot:FindFirstChild("SelectedAccent")

	slot.BackgroundColor3 = isSelected and Color3.fromRGB(23, 31, 36) or Color3.fromRGB(12, 15, 18)
	slot.BackgroundTransparency = isSelected and 0.04 or 0.16

	if stroke then
		stroke.Color = isSelected and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(82, 92, 98)
		stroke.Transparency = isSelected and 0.08 or 0.45
		stroke.Thickness = isSelected and 2 or 1
	end

	if keyBadge then
		keyBadge.BackgroundColor3 = isSelected and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(32, 38, 43)
		keyBadge.BackgroundTransparency = isSelected and 0 or 0.08
		keyBadge.TextColor3 = isSelected and Color3.fromRGB(8, 13, 16) or Color3.fromRGB(218, 226, 230)
	end

	if accent then
		accent.Visible = isSelected
	end
end

local function createSlot(slotInfo, index)
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. slotInfo.key
	slot.LayoutOrder = index
	slot.Size = UDim2.fromOffset(86, 72)
	slot.BackgroundColor3 = slotInfo.selected and Color3.fromRGB(23, 31, 36) or Color3.fromRGB(12, 15, 18)
	slot.BackgroundTransparency = slotInfo.selected and 0.04 or 0.16
	slot.BorderSizePixel = 0
	slot.Parent = container

	addCorner(slot, 7)
	addStroke(
		slot,
		slotInfo.selected and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(82, 92, 98),
		slotInfo.selected and 0.08 or 0.45,
		slotInfo.selected and 2 or 1
	)

	local keyBadge = Instance.new("TextLabel")
	keyBadge.Name = "Key"
	keyBadge.Position = UDim2.fromOffset(6, 6)
	keyBadge.Size = UDim2.fromOffset(22, 20)
	keyBadge.BackgroundColor3 = slotInfo.selected and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(32, 38, 43)
	keyBadge.BackgroundTransparency = slotInfo.selected and 0 or 0.08
	keyBadge.BorderSizePixel = 0
	keyBadge.Font = Enum.Font.GothamBold
	keyBadge.Text = slotInfo.key
	keyBadge.TextColor3 = slotInfo.selected and Color3.fromRGB(8, 13, 16) or Color3.fromRGB(218, 226, 230)
	keyBadge.TextSize = 14
	keyBadge.TextXAlignment = Enum.TextXAlignment.Center
	keyBadge.TextYAlignment = Enum.TextYAlignment.Center
	keyBadge.Parent = slot

	addCorner(keyBadge, 4)

	local icon = Instance.new("TextLabel")
	icon.Name = "IconPlaceholder"
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 25)
	icon.Size = UDim2.new(1, -16, 0, 19)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = slotInfo.icon
	icon.TextColor3 = slotInfo.name == "Empty" and Color3.fromRGB(88, 96, 101) or Color3.fromRGB(235, 241, 244)
	icon.TextSize = slotInfo.name == "Assault Rifle" and 12 or 13
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.Parent = slot

	local label = Instance.new("TextLabel")
	label.Name = "WeaponLabel"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -7)
	label.Size = UDim2.new(1, -12, 0, 17)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = slotInfo.name
	label.TextColor3 = slotInfo.name == "Empty" and Color3.fromRGB(112, 121, 126) or Color3.fromRGB(210, 219, 224)
	label.TextSize = slotInfo.name == "Assault Rifle" and 10 or 11
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = slot

	local glow = Instance.new("Frame")
	glow.Name = "SelectedAccent"
	glow.AnchorPoint = Vector2.new(0.5, 1)
	glow.Position = UDim2.new(0.5, 0, 1, 0)
	glow.Size = UDim2.new(1, -14, 0, 3)
	glow.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	glow.BorderSizePixel = 0
	glow.Visible = slotInfo.selected
	glow.Parent = slot

	addCorner(glow, 2)

	slotFrames[index] = {
		frame = slot,
		info = slotInfo,
	}
end

for index, slotInfo in slots do
	createSlot(slotInfo, index)
end

local function findToolByName(toolName)
	local character = player.Character
	if character then
		local characterTool = character:FindFirstChild(toolName)
		if characterTool and characterTool:IsA("Tool") then
			print("[WeaponSlotsUI] Found tool:", toolName, "in Character")
			return characterTool
		end
	end

	local backpack = getBackpack()
	local backpackTool = backpack:FindFirstChild(toolName) or backpack:WaitForChild(toolName, 0.25)
	if backpackTool and backpackTool:IsA("Tool") then
		print("[WeaponSlotsUI] Found tool:", toolName, "in Backpack")
		return backpackTool
	end

	print("[WeaponSlotsUI] Tool not found:", toolName)
	return nil
end

local function updateSelectedSlot(slotNumber)
	selectedSlot = slotNumber

	for index, slotData in slotFrames do
		applySlotStyle(slotData.frame, slotData.info, index == selectedSlot)
	end
end

local function equipSlot(slotNumber)
	local slotInfo = slots[slotNumber]
	if not slotInfo or not slotInfo.toolName then
		return
	end

	print("[WeaponSlotsUI] Slot pressed:", slotNumber)

	local tool = findToolByName(slotInfo.toolName)
	if not tool then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	if tool.Parent == character then
		updateSelectedSlot(slotNumber)
		print("[WeaponSlotsUI] Equipped tool:", tool.Name)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid:EquipTool(tool)

	if tool.Parent == character then
		updateSelectedSlot(slotNumber)
		print("[WeaponSlotsUI] Equipped tool:", tool.Name)
	end
end

local function handleEquipAction(_, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local slotNumber = keyCodeToSlot[inputObject.KeyCode]
	if slotNumber then
		equipSlot(slotNumber)
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

local function updateHudScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local viewportSize = camera.ViewportSize
	local widthScale = viewportSize.X / 1280
	local heightScale = viewportSize.Y / 720
	hudScale.Scale = math.clamp(math.min(widthScale, heightScale), 0.72, 1.08)
end

updateHudScale()

if workspace.CurrentCamera then
	viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudScale)
end

updateSelectedSlot(selectedSlot)

ContextActionService:BindActionAtPriority(
	EQUIP_ACTION_NAME,
	handleEquipAction,
	false,
	EQUIP_ACTION_PRIORITY,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five
)

screenGui.Destroying:Connect(function()
	ContextActionService:UnbindAction(EQUIP_ACTION_NAME)

	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
end)
