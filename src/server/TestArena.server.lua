-- TestArena creates a small temporary weapon testing space.
-- It is only for local testing and does not change weapon, HUD, or stamina logic.

local ARENA_NAME = "TestArena"
local TARGET_SPAWN_CFRAME = CFrame.new(0, 3, -35)
local TARGET_HEAD_CFRAME = CFrame.new(0, 5, -35)
local TARGET_RESPAWN_TIME = 3

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

	createPart(
		"Head",
		Vector3.new(1.25, 1.25, 1.25),
		TARGET_HEAD_CFRAME,
		Color3.fromRGB(190, 190, 185),
		dummy
	)

	dummy.PrimaryPart = root

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
