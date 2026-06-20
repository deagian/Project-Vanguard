-- WeaponSlotsUI.client.lua
-- Project Vanguard
-- One-file weapon slot UI.
-- Slot 1 = Pistol
-- Slot 2 = AssaultRifle
-- Press same slot again = unequip weapon
-- Slots 3/4/5 empty

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

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
local selectedSlot = nil

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
		if slotNumber == selectedSlot then
			button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
			button.BorderSizePixel = 3
		else
			button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			button.BorderSizePixel = 1
		end
	end
end

local function syncSelectedSlotFromCharacter()
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
end

local function unequipCurrentWeapon()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid:UnequipTools()
	end

	selectedSlot = nil
	updateHighlight()
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
end

local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -35)
	root.Size = UDim2.new(0, 360, 0, 70)
	root.BackgroundTransparency = 1
	root.Parent = screenGui

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
		button.BorderColor3 = Color3.fromRGB(255, 255, 255)
		button.BorderSizePixel = 1
		button.AutoButtonColor = true
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = root

		local weaponName = SLOT_WEAPONS[i]
		if weaponName then
			button.Text = tostring(i) .. "\n" .. weaponName
		else
			button.Text = tostring(i) .. "\nEmpty"
			button.TextColor3 = Color3.fromRGB(140, 140, 140)
		end

		slotButtons[i] = button

		button.MouseButton1Click:Connect(function()
			equipSlot(i)
		end)
	end

	updateHighlight()
end

local function onInput(actionName, inputState, inputObject)
	if actionName ~= ACTION_NAME then
		return Enum.ContextActionResult.Pass
	end

	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	local keyCode = inputObject.KeyCode

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