-- TestArena creates a small temporary weapon testing space.
-- It is only for local testing and does not change weapon, HUD, or stamina logic.

local TweenService = game:GetService("TweenService")

local ARENA_NAME = "TestArena"
local TARGET_SPAWN_CFRAME = CFrame.new(0, 3, -35)
local TARGET_HEAD_CFRAME = CFrame.new(0, 5, -35)
local TARGET_RESPAWN_TIME = 3
local DAMAGE_NUMBER_TIME = 0.5

local function createPart(name, size, cframe, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function showFloatingDamage(head, damageAmount)
	local isHeadshotDamage = damageAmount >= 40
	local textColor = if isHeadshotDamage then Color3.fromRGB(255, 55, 55) else Color3.fromRGB(255, 255, 255)

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DamageNumber"
	billboardGui.Adornee = head
	billboardGui.AlwaysOnTop = true
	billboardGui.Size = UDim2.fromOffset(100, 40)
	billboardGui.StudsOffset = Vector3.new(0, 1.45, 0)
	billboardGui.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = tostring(damageAmount)
	label.TextColor3 = textColor
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.25
	label.TextSize = 28
	label.Parent = billboardGui

	local tweenInfo = TweenInfo.new(DAMAGE_NUMBER_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboardGui, tweenInfo, { StudsOffset = Vector3.new(0, 2.35, 0) }):Play()
	TweenService:Create(label, tweenInfo, {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(DAMAGE_NUMBER_TIME, function()
		if billboardGui.Parent then
			billboardGui:Destroy()
		end
	end)
end

local function createTargetDummy(parent)
	local dummy = Instance.new("Model")
	dummy.Name = "DamageTestDummy"
	dummy.Parent = parent

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.DisplayName = "TARGET"
	humanoid.Parent = dummy

	local bodyColor = Color3.fromRGB(120, 125, 130)
	local hitColor = Color3.fromRGB(170, 60, 60)

	local root = createPart(
		"HumanoidRootPart",
		Vector3.new(2, 2, 1),
		TARGET_SPAWN_CFRAME,
		bodyColor,
		dummy
	)
	root.Transparency = 1

	createPart(
		"Torso",
		Vector3.new(2, 2.5, 1),
		TARGET_SPAWN_CFRAME,
		hitColor,
		dummy
	)

	local head = createPart(
		"Head",
		Vector3.new(1.25, 1.25, 1.25),
		TARGET_HEAD_CFRAME,
		Color3.fromRGB(190, 190, 185),
		dummy
	)

	dummy.PrimaryPart = root
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			local damageAmount = math.round(lastHealth - newHealth)
			showFloatingDamage(head, damageAmount)
		end

		lastHealth = newHealth
	end)

	-- Reset the target after it is defeated so damage can be tested repeatedly.
	humanoid.Died:Connect(function()
		print("[Target] Eliminated")
		task.wait(TARGET_RESPAWN_TIME)

		if dummy.Parent then
			print("[Target] Respawning")
			dummy:Destroy()
			createTargetDummy(parent)
			print("[Target] Respawn complete")
		end
	end)

	return dummy
end

local existingArena = workspace:FindFirstChild(ARENA_NAME)
if existingArena then
	existingArena:Destroy()
end

local arena = Instance.new("Folder")
arena.Name = ARENA_NAME
arena.Parent = workspace

-- Flat grey test floor
createPart(
	"TestFloor",
	Vector3.new(120, 1, 120),
	CFrame.new(0, -0.5, 0),
	Color3.fromRGB(95, 95, 95),
	arena
)

-- Simple cover blocks
createPart(
	"CoverBlock_Left",
	Vector3.new(5, 5, 2),
	CFrame.new(-12, 2.5, -16),
	Color3.fromRGB(55, 58, 62),
	arena
)

createPart(
	"CoverBlock_Right",
	Vector3.new(5, 5, 2),
	CFrame.new(12, 2.5, -16),
	Color3.fromRGB(55, 58, 62),
	arena
)

createPart(
	"CoverBlock_CenterLow",
	Vector3.new(8, 3, 2),
	CFrame.new(0, 1.5, -20),
	Color3.fromRGB(65, 68, 72),
	arena
)

createTargetDummy(arena)

print("[TestArena] Temporary weapon test arena created")
