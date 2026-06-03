-- EnemySpawner crea bot rossi temporanei per testare combattimento e AI.
-- TODO: sostituire il placeholder con un modello nemico professionale.

local Players = game:GetService("Players")

local EnemyConfig = require(script.Parent:WaitForChild("EnemyConfig"))
local EnemyAI = require(script.Parent:WaitForChild("EnemyAI"))

local ENEMY_FOLDER_NAME = "Enemies"
local ENEMY_NAME = "EnemyBot"
local ENEMY_SPAWNS = {
	CFrame.new(-24, 4, -28),
	CFrame.new(24, 4, -30),
	CFrame.new(0, 4, -50),
}

local enemySettings = EnemyConfig.Enemy

local existingFolder = workspace:FindFirstChild(ENEMY_FOLDER_NAME)
if existingFolder then
	existingFolder:Destroy()
end

local enemyFolder = Instance.new("Folder")
enemyFolder.Name = ENEMY_FOLDER_NAME
enemyFolder.Parent = workspace

local function getMapEnemySpawns()
	local map = workspace:WaitForChild("Map", 10)
	if not map then
		return ENEMY_SPAWNS
	end

	local spawnsFolder = map:WaitForChild("Spawns", 5)
	if not spawnsFolder then
		return ENEMY_SPAWNS
	end

	local spawnCFrames = {}
	for index = 1, 3 do
		local spawnPart = spawnsFolder:FindFirstChild("EnemySpawn" .. index)
		if spawnPart and spawnPart:IsA("BasePart") then
			table.insert(spawnCFrames, CFrame.new(spawnPart.Position + Vector3.new(0, 4, 0)))
		end
	end

	if #spawnCFrames == 0 then
		return ENEMY_SPAWNS
	end

	return spawnCFrames
end

local function tintEnemy(model)
	local bodyColors = model:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		local red = BrickColor.new("Really red")
		bodyColors.HeadColor = red
		bodyColors.LeftArmColor = red
		bodyColors.LeftLegColor = red
		bodyColors.RightArmColor = red
		bodyColors.RightLegColor = red
		bodyColors.TorsoColor = red
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Material = Enum.Material.SmoothPlastic
			descendant.Color = Color3.fromRGB(190, 45, 45)
			descendant.CanQuery = true
		end
	end
end

local function attachEnemyRifle(model)
	local hand = model:FindFirstChild("Right Arm")
	local torso = model:FindFirstChild("Torso")
	local attachPart = hand or torso
	if not attachPart or not attachPart:IsA("BasePart") then
		return
	end

	local rifle = Instance.new("Part")
	rifle.Name = "EnemyRifle"
	rifle.Size = Vector3.new(0.22, 0.22, 2.6)
	rifle.Material = Enum.Material.Metal
	rifle.Color = Color3.fromRGB(35, 35, 38)
	rifle.CanCollide = false
	rifle.CanQuery = false
	rifle.CanTouch = false
	rifle.Massless = true
	rifle.CFrame = attachPart.CFrame * CFrame.new(0, -0.9, -0.75) * CFrame.Angles(math.rad(90), 0, 0)
	rifle.Parent = model

	local muzzleAttachment = Instance.new("Attachment")
	muzzleAttachment.Name = "EnemyMuzzleAttachment"
	muzzleAttachment.Position = Vector3.new(0, 0, -rifle.Size.Z * 0.5)
	muzzleAttachment.Parent = rifle

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = attachPart
	weld.Part1 = rifle
	weld.Parent = rifle
end

local function createEnemyRig(spawnCFrame)
	local humanoidDescription = Instance.new("HumanoidDescription")
	local enemy = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R6)
	enemy.Name = ENEMY_NAME
	enemy.Parent = enemyFolder

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = enemySettings.MaxHealth
		humanoid.Health = enemySettings.MaxHealth
		humanoid.WalkSpeed = enemySettings.WalkSpeed
		humanoid.DisplayName = "ENEMY"
	end

	tintEnemy(enemy)
	enemy:PivotTo(spawnCFrame)
	attachEnemyRifle(enemy)

	return enemy
end

local function spawnEnemy(spawnCFrame)
	local enemy = createEnemyRig(spawnCFrame)
	EnemyAI.Start(enemy, enemySettings, spawnCFrame.Position)

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.delay(enemySettings.RespawnTime, function()
				if enemy.Parent then
					enemy:Destroy()
				end

				spawnEnemy(spawnCFrame)
				print("[EnemySpawner] Enemy respawned")
			end)
		end)
	end

	return enemy
end

for _, spawnCFrame in ipairs(getMapEnemySpawns()) do
	spawnEnemy(spawnCFrame)
end

print("[EnemySpawner] Enemy system loaded")
