-- WeaponSlotsUI.client.lua
-- Project Vanguard
-- One-file weapon slot UI.
-- Slot 1 = Pistol
-- Slot 2 = AssaultRifle
-- Press same slot again = unequip weapon
-- Slots 3/4/5 empty
-- Weapon names are intentionally not shown in the HUD.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ACTION_NAME = "PV_WeaponSlots_Input"
local GUI_NAME = "WeaponSlotsUI"

local SLOT_COUNT = 5

local SLOT_WEAPONS = {
	[1] = "Pistol",
	[2] = "AssaultRifle",
	[3] = nil,
	[4] = nil,
	[5] = nil,
}

local slotButtons = {}
local slotStrokes = {}
local slotIcons = {}
local slotScales = {}
local slotTweens = {}
local slotAnimationTokens = {}
local selectedSlot = nil
local slotsRoot = nil
local slotsFadeTween = nil
local fadeToken = 0

local SLOT_BOUNCE_UP = TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLOT_BOUNCE_DOWN = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local SLOT_FADE_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local SLOTS_FADE_DELAY = 3
local SLOTS_FADED_TRANSPARENCY = 0.88
local SLOTS_FADE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Rojo / hot-sync safety
ContextActionService:UnbindAction(ACTION_NAME)

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
	oldGui:Destroy()
end

local function hideDefaultBackpack()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	task.defer(function()
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end)
end

hideDefaultBackpack()

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local character = getCharacter()
	return character:FindFirstChildOfClass("Humanoid")
end

local function findTool(toolName)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	if character then
		local tool = character:FindFirstChild(toolName)
		if tool and tool:IsA("Tool") then
			return tool, "Character"
		end
	end

	if backpack then
		local tool = backpack:FindFirstChild(toolName)
		if tool and tool:IsA("Tool") then
			return tool, "Backpack"
		end
	end

	return nil, nil
end

local function hasTool(toolName)
	return findTool(toolName) ~= nil
end

local function getEquippedTool()
	local character = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end

	return nil
end

local function updateHighlight()
	for slotNumber, button in pairs(slotButtons) do
		local stroke = slotStrokes[slotNumber]
		local icon = slotIcons[slotNumber]
		local weaponName = SLOT_WEAPONS[slotNumber]
		local isAvailable = weaponName ~= nil and hasTool(weaponName)

		if slotNumber == selectedSlot then
			button.BackgroundColor3 = Color3.fromRGB(42, 82, 150)
			if stroke then
				stroke.Color = Color3.fromRGB(115, 170, 255)
				stroke.Thickness = 3
			end
		else
			button.BackgroundColor3 = if isAvailable then Color3.fromRGB(26, 28, 34) else Color3.fromRGB(18, 18, 20)
			if stroke then
				stroke.Color = if isAvailable then Color3.fromRGB(92, 98, 112) else Color3.fromRGB(52, 54, 60)
				stroke.Thickness = 1
			end
		end

		if icon then
			icon.GroupTransparency = if isAvailable then 0 else 0.55
		end
	end
end

local function fadeSlots()
	if not slotsRoot then
		return
	end

	if slotsFadeTween then
		slotsFadeTween:Cancel()
	end

	slotsFadeTween = TweenService:Create(slotsRoot, SLOTS_FADE_INFO, {
		GroupTransparency = SLOTS_FADED_TRANSPARENCY,
	})
	slotsFadeTween:Play()
end

local function scheduleFade()
	fadeToken += 1
	local scheduledToken = fadeToken

	task.delay(SLOTS_FADE_DELAY, function()
		if fadeToken == scheduledToken then
			fadeSlots()
		end
	end)
end

local function showSlots()
	fadeToken += 1

	if slotsFadeTween then
		slotsFadeTween:Cancel()
		slotsFadeTween = nil
	end

	if slotsRoot then
		slotsRoot.GroupTransparency = 0
	end
end

local function noteSlotActivity()
	showSlots()
	scheduleFade()
end

local function cancelSlotTweens(slotNumber)
	local tweens = slotTweens[slotNumber]
	if not tweens then
		return
	end

	for _, tween in ipairs(tweens) do
		tween:Cancel()
	end

	slotTweens[slotNumber] = nil
end

local function animateSlot(slotNumber)
	local button = slotButtons[slotNumber]
	local scale = slotScales[slotNumber]
	local stroke = slotStrokes[slotNumber]
	if not button or not scale then
		return
	end

	cancelSlotTweens(slotNumber)

	scale.Scale = 1
	slotAnimationTokens[slotNumber] = (slotAnimationTokens[slotNumber] or 0) + 1
	local animationToken = slotAnimationTokens[slotNumber]

	local growTween = TweenService:Create(scale, SLOT_BOUNCE_UP, {
		Scale = 1.12,
	})

	local settleTween = TweenService:Create(scale, SLOT_BOUNCE_DOWN, {
		Scale = 1,
	})

	local brightenTween = TweenService:Create(button, SLOT_FADE_TWEEN, {
		BackgroundColor3 = Color3.fromRGB(58, 106, 190),
	})

	local strokeTween = nil
	if stroke then
		strokeTween = TweenService:Create(stroke, SLOT_FADE_TWEEN, {
			Color = Color3.fromRGB(170, 205, 255),
			Thickness = 4,
		})
	end

	slotTweens[slotNumber] = if strokeTween then { growTween, settleTween, brightenTween, strokeTween } else { growTween, settleTween, brightenTween }

	growTween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and slotAnimationTokens[slotNumber] == animationToken then
			settleTween:Play()
			task.delay(0.08, updateHighlight)
		end
	end)

	settleTween.Completed:Connect(function()
		if slotAnimationTokens[slotNumber] == animationToken and slotTweens[slotNumber] then
			slotTweens[slotNumber] = nil
		end
		updateHighlight()
	end)

	growTween:Play()
	brightenTween:Play()
	if strokeTween then
		strokeTween:Play()
	end
end

local function syncSelectedSlotFromCharacter()
	local previousSlot = selectedSlot
	selectedSlot = nil

	local equippedTool = getEquippedTool()
	if equippedTool then
		for slotNumber, weaponName in pairs(SLOT_WEAPONS) do
			if weaponName == equippedTool.Name then
				selectedSlot = slotNumber
				break
			end
		end
	end

	updateHighlight()
	if selectedSlot and selectedSlot ~= previousSlot then
		noteSlotActivity()
		animateSlot(selectedSlot)
	end
end

local function unequipCurrentWeapon()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid:UnequipTools()
	end

	selectedSlot = nil
	updateHighlight()
	noteSlotActivity()
end

local function equipSlot(slotNumber)
	local weaponName = SLOT_WEAPONS[slotNumber]
	if not weaponName then
		return
	end

	local equippedTool = getEquippedTool()

	-- Same slot pressed again: put weapon down
	if equippedTool and equippedTool.Name == weaponName then
		unequipCurrentWeapon()
		return
	end

	local tool = findTool(weaponName)
	if not tool then
		selectedSlot = nil
		updateHighlight()
		return
	end

	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	humanoid:EquipTool(tool)
	selectedSlot = slotNumber
	updateHighlight()
	noteSlotActivity()
	animateSlot(slotNumber)
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createIconPart(parent, name, position, size, rotation, color)
	local part = Instance.new("Frame")
	part.Name = name
	part.AnchorPoint = Vector2.new(0.5, 0.5)
	part.Position = position
	part.Size = size
	part.Rotation = rotation or 0
	part.BackgroundColor3 = color
	part.BorderSizePixel = 0
	part.Parent = parent
	createCorner(part, 2)
	return part
end

local function createWeaponIcon(parent, weaponName)
	local icon = Instance.new("CanvasGroup")
	icon.Name = "WeaponIcon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.55)
	icon.Size = UDim2.fromOffset(42, 30)
	icon.BackgroundTransparency = 1
	icon.Parent = parent

	local color = Color3.fromRGB(232, 236, 244)
	local accent = Color3.fromRGB(158, 174, 202)

	if weaponName == "Pistol" then
		createIconPart(icon, "Slide", UDim2.fromScale(0.48, 0.33), UDim2.fromOffset(28, 7), 0, color)
		createIconPart(icon, "Barrel", UDim2.fromScale(0.76, 0.31), UDim2.fromOffset(12, 4), 0, color)
		createIconPart(icon, "Body", UDim2.fromScale(0.43, 0.52), UDim2.fromOffset(21, 8), 0, color)
		createIconPart(icon, "Grip", UDim2.fromScale(0.34, 0.73), UDim2.fromOffset(9, 18), -18, accent)
		createIconPart(icon, "TriggerGuard", UDim2.fromScale(0.52, 0.68), UDim2.fromOffset(8, 4), 0, accent)
	elseif weaponName == "AssaultRifle" then
		createIconPart(icon, "Receiver", UDim2.fromScale(0.48, 0.42), UDim2.fromOffset(28, 8), 0, color)
		createIconPart(icon, "Barrel", UDim2.fromScale(0.79, 0.39), UDim2.fromOffset(21, 4), 0, color)
		createIconPart(icon, "Stock", UDim2.fromScale(0.14, 0.47), UDim2.fromOffset(16, 8), -18, accent)
		createIconPart(icon, "Grip", UDim2.fromScale(0.43, 0.69), UDim2.fromOffset(7, 16), 16, accent)
		createIconPart(icon, "Magazine", UDim2.fromScale(0.58, 0.72), UDim2.fromOffset(8, 17), -9, accent)
	else
		createIconPart(icon, "EmptyLine", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(24, 3), 0, Color3.fromRGB(98, 102, 112))
	end

	return icon
end

local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local root = Instance.new("CanvasGroup")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -35)
	root.Size = UDim2.new(0, 360, 0, 70)
	root.BackgroundTransparency = 1
	root.GroupTransparency = 0
	root.Parent = screenGui
	slotsRoot = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = root

	for i = 1, SLOT_COUNT do
		local button = Instance.new("TextButton")
		button.Name = "Slot" .. i
		button.Size = UDim2.new(0, 62, 0, 62)
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Text = ""
		button.Parent = root
		createCorner(button, 6)

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = button
		slotScales[i] = scale

		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Color3.fromRGB(92, 98, 112)
		stroke.Thickness = 1
		stroke.Parent = button
		slotStrokes[i] = stroke

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyNumber"
		keyLabel.BackgroundTransparency = 1
		keyLabel.Position = UDim2.fromOffset(6, 4)
		keyLabel.Size = UDim2.fromOffset(16, 16)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.Text = tostring(i)
		keyLabel.TextColor3 = Color3.fromRGB(235, 238, 246)
		keyLabel.TextSize = 13
		keyLabel.TextXAlignment = Enum.TextXAlignment.Left
		keyLabel.TextYAlignment = Enum.TextYAlignment.Top
		keyLabel.Parent = button

		local weaponName = SLOT_WEAPONS[i]
		slotIcons[i] = createWeaponIcon(button, weaponName)

		slotButtons[i] = button

		button.MouseButton1Click:Connect(function()
			noteSlotActivity()
			equipSlot(i)
		end)
	end

	updateHighlight()
	noteSlotActivity()
end

local function onInput(actionName, inputState, inputObject)
	if actionName ~= ACTION_NAME then
		return Enum.ContextActionResult.Pass
	end

	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	local keyCode = inputObject.KeyCode
	noteSlotActivity()

	if keyCode == Enum.KeyCode.One then
		equipSlot(1)
	elseif keyCode == Enum.KeyCode.Two then
		equipSlot(2)
	elseif keyCode == Enum.KeyCode.Three then
		equipSlot(3)
	elseif keyCode == Enum.KeyCode.Four then
		equipSlot(4)
	elseif keyCode == Enum.KeyCode.Five then
		equipSlot(5)
	end

	return Enum.ContextActionResult.Sink
end

createUI()

ContextActionService:BindAction(
	ACTION_NAME,
	onInput,
	false,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five
)

player.CharacterAdded:Connect(function(character)
	hideDefaultBackpack()
	noteSlotActivity()

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(syncSelectedSlotFromCharacter)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(syncSelectedSlotFromCharacter)
		end
	end)

	task.defer(syncSelectedSlotFromCharacter)
end)

local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		task.defer(updateHighlight)
	end
end)

backpack.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		task.defer(updateHighlight)
	end
end)

if player.Character then
	player.Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(syncSelectedSlotFromCharacter)
		end
	end)

	player.Character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(syncSelectedSlotFromCharacter)
		end
	end)

	task.defer(syncSelectedSlotFromCharacter)
end
