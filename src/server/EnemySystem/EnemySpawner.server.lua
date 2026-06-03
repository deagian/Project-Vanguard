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

for _, spawnCFrame in ipairs(ENEMY_SPAWNS) do
	spawnEnemy(spawnCFrame)
end

print("[EnemySpawner] Enemy system loaded")
