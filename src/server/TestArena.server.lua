-- UrbanMap crea un primo blockout urbano giocabile con sole Parts.
-- Il layout e' pensato per testare movimento, coperture, ADS e line of sight nemica.

local MAP_NAME = "Map"

local existingMap = workspace:FindFirstChild(MAP_NAME)
if existingMap then
	existingMap:Destroy()
end

local map = Instance.new("Folder")
map.Name = MAP_NAME
map.Parent = workspace

local streetFolder = Instance.new("Folder")
streetFolder.Name = "Street"
streetFolder.Parent = map

local buildingsFolder = Instance.new("Folder")
buildingsFolder.Name = "Buildings"
buildingsFolder.Parent = map

local coverFolder = Instance.new("Folder")
coverFolder.Name = "Cover"
coverFolder.Parent = map

local spawnsFolder = Instance.new("Folder")
spawnsFolder.Name = "Spawns"
spawnsFolder.Parent = map

local function createPart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createPlayerSpawn(name, cframe, color)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = name
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = cframe
	spawnLocation.Color = color
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.CanQuery = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Transparency = 0.45
	spawnLocation.Parent = spawnsFolder

	return spawnLocation
end

local function createEnemySpawn(name, cframe)
	local spawnMarker = createPart(
		name,
		Vector3.new(5, 0.4, 5),
		cframe,
		Color3.fromRGB(255, 80, 80),
		Enum.Material.Neon,
		spawnsFolder
	)
	spawnMarker.Transparency = 0.55
	spawnMarker.CanCollide = false

	return spawnMarker
end

local function createBuildingA()
	local building = Instance.new("Folder")
	building.Name = "SmallBuildingA"
	building.Parent = buildingsFolder

	createPart("Floor", Vector3.new(24, 1, 28), CFrame.new(-24, 0, -18), Color3.fromRGB(80, 82, 82), Enum.Material.Concrete, building)
	createPart("Roof", Vector3.new(24, 1, 28), CFrame.new(-24, 11, -18), Color3.fromRGB(48, 50, 52), Enum.Material.Concrete, building)

	createPart("BackWall", Vector3.new(24, 10, 1), CFrame.new(-24, 5.5, -31.5), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)
	createPart("LeftWall", Vector3.new(1, 10, 28), CFrame.new(-35.5, 5.5, -18), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)
	createPart("RightWall", Vector3.new(1, 10, 28), CFrame.new(-12.5, 5.5, -18), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)

	-- Parete frontale divisa per lasciare una porta larga verso la strada.
	createPart("FrontWall_Left", Vector3.new(8, 10, 1), CFrame.new(-32, 5.5, -4.5), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)
	createPart("FrontWall_Right", Vector3.new(8, 10, 1), CFrame.new(-16, 5.5, -4.5), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)
	createPart("DoorHeader", Vector3.new(8, 3, 1), CFrame.new(-24, 9, -4.5), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)

	-- Finestra laterale per ADS e line of sight.
	createPart("WindowSill", Vector3.new(1, 2, 8), CFrame.new(-12.5, 2, -22), Color3.fromRGB(70, 70, 70), Enum.Material.Concrete, building)
	createPart("WindowTop", Vector3.new(1, 3, 8), CFrame.new(-12.5, 8.5, -22), Color3.fromRGB(92, 92, 88), Enum.Material.Brick, building)
end

local function createBuildingB()
	local building = Instance.new("Folder")
	building.Name = "SmallBuildingB"
	building.Parent = buildingsFolder

	createPart("Floor", Vector3.new(22, 1, 24), CFrame.new(25, 0, -24), Color3.fromRGB(78, 80, 82), Enum.Material.Concrete, building)
	createPart("Roof", Vector3.new(22, 1, 24), CFrame.new(25, 9, -24), Color3.fromRGB(45, 47, 50), Enum.Material.Concrete, building)

	createPart("BackWall", Vector3.new(22, 8, 1), CFrame.new(25, 4.5, -35.5), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
	createPart("RightWall", Vector3.new(1, 8, 24), CFrame.new(35.5, 4.5, -24), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
	createPart("LeftWall_Back", Vector3.new(1, 8, 9), CFrame.new(14.5, 4.5, -30), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
	createPart("LeftWall_Front", Vector3.new(1, 8, 7), CFrame.new(14.5, 4.5, -15), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)

	-- Apertura frontale e finestra verso il centro della strada.
	createPart("FrontWall_Left", Vector3.new(7, 8, 1), CFrame.new(19, 4.5, -12.5), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
	createPart("FrontWall_Right", Vector3.new(7, 8, 1), CFrame.new(31, 4.5, -12.5), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
	createPart("WindowLowCover", Vector3.new(8, 3, 1), CFrame.new(25, 2, -12.5), Color3.fromRGB(65, 68, 72), Enum.Material.Concrete, building)
	createPart("WindowHeader", Vector3.new(8, 2, 1), CFrame.new(25, 7.5, -12.5), Color3.fromRGB(84, 86, 90), Enum.Material.Concrete, building)
end

local function createCar(name, position, color)
	local car = Instance.new("Folder")
	car.Name = name
	car.Parent = coverFolder

	createPart("Body", Vector3.new(8, 2, 4), CFrame.new(position), color, Enum.Material.SmoothPlastic, car)
	createPart("Cabin", Vector3.new(4, 2, 3.5), CFrame.new(position + Vector3.new(0, 2, 0)), Color3.fromRGB(35, 40, 45), Enum.Material.SmoothPlastic, car)
	createPart("FrontBumper", Vector3.new(1, 1, 4.2), CFrame.new(position + Vector3.new(4.5, -0.2, 0)), Color3.fromRGB(28, 28, 28), Enum.Material.Metal, car)
	createPart("RearBumper", Vector3.new(1, 1, 4.2), CFrame.new(position + Vector3.new(-4.5, -0.2, 0)), Color3.fromRGB(28, 28, 28), Enum.Material.Metal, car)
end

-- Player Spawn Area
createPart("PlayerSpawnPad", Vector3.new(22, 1, 18), CFrame.new(0, -0.45, 32), Color3.fromRGB(72, 78, 82), Enum.Material.Concrete, streetFolder)
createPlayerSpawn("PlayerSpawn", CFrame.new(0, 0.25, 34), Color3.fromRGB(60, 160, 255))

-- Main Street
createPart("Road", Vector3.new(34, 1, 110), CFrame.new(0, -0.5, -12), Color3.fromRGB(44, 44, 46), Enum.Material.Asphalt, streetFolder)
createPart("LeftSidewalk", Vector3.new(12, 1, 110), CFrame.new(-23, -0.35, -12), Color3.fromRGB(110, 110, 105), Enum.Material.Concrete, streetFolder)
createPart("RightSidewalk", Vector3.new(12, 1, 110), CFrame.new(23, -0.35, -12), Color3.fromRGB(110, 110, 105), Enum.Material.Concrete, streetFolder)
createPart("BackAlley", Vector3.new(70, 1, 14), CFrame.new(0, -0.4, -48), Color3.fromRGB(58, 58, 60), Enum.Material.Asphalt, streetFolder)

-- Central Cover Area
createPart("CentralLowCover_1", Vector3.new(10, 2.2, 2), CFrame.new(-5, 1.1, -8), Color3.fromRGB(75, 78, 80), Enum.Material.Concrete, coverFolder)
createPart("CentralLowCover_2", Vector3.new(10, 2.2, 2), CFrame.new(7, 1.1, -19), Color3.fromRGB(75, 78, 80), Enum.Material.Concrete, coverFolder)
createPart("ConcreteBlock_A", Vector3.new(5, 4, 3), CFrame.new(-11, 2, -27), Color3.fromRGB(88, 88, 84), Enum.Material.Concrete, coverFolder)
createPart("ConcreteBlock_B", Vector3.new(5, 4, 3), CFrame.new(13, 2, -30), Color3.fromRGB(88, 88, 84), Enum.Material.Concrete, coverFolder)
createPart("Barrier_Left", Vector3.new(2, 5, 12), CFrame.new(-18, 2.5, 5), Color3.fromRGB(62, 66, 70), Enum.Material.Metal, coverFolder)
createPart("Barrier_Right", Vector3.new(2, 5, 12), CFrame.new(18, 2.5, 2), Color3.fromRGB(62, 66, 70), Enum.Material.Metal, coverFolder)
createCar("ParkedCar_Left", Vector3.new(-7, 1, 10), Color3.fromRGB(38, 78, 110))
createCar("ParkedCar_Right", Vector3.new(10, 1, -2), Color3.fromRGB(105, 48, 42))

-- Buildings
createBuildingA()
createBuildingB()

-- Enemy Zone
createPart("EnemyZonePlatform", Vector3.new(46, 1, 16), CFrame.new(0, -0.45, -55), Color3.fromRGB(72, 72, 74), Enum.Material.Concrete, streetFolder)
createPart("EnemyBackWall", Vector3.new(70, 9, 2), CFrame.new(0, 4.5, -64), Color3.fromRGB(50, 52, 55), Enum.Material.Concrete, coverFolder)
createPart("EnemyCover_Left", Vector3.new(8, 3, 2), CFrame.new(-20, 1.5, -50), Color3.fromRGB(82, 84, 86), Enum.Material.Concrete, coverFolder)
createPart("EnemyCover_Right", Vector3.new(8, 3, 2), CFrame.new(20, 1.5, -50), Color3.fromRGB(82, 84, 86), Enum.Material.Concrete, coverFolder)

createEnemySpawn("EnemySpawn1", CFrame.new(-22, 0.2, -52))
createEnemySpawn("EnemySpawn2", CFrame.new(22, 0.2, -52))
createEnemySpawn("EnemySpawn3", CFrame.new(0, 0.2, -58))

print("[Map] Urban test map loaded")
