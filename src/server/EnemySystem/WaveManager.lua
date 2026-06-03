-- WaveManager gestisce il primo game loop: wave, kill counter e death counter.
-- I valori sono replicati come attributi Player per una HUD semplice e affidabile.

local Players = game:GetService("Players")

local EnemySpawner = require(script.Parent:WaitForChild("EnemySpawner"))

local WaveManager = {}

local WAVE_DEFINITIONS = {
	[1] = 3,
	[2] = 5,
}

local currentWave = 0
local enemiesRemaining = 0
local isRunning = false

local function setWaveAttributes(waveNumber, message)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CurrentWave", waveNumber)
		player:SetAttribute("WaveMessage", message or "")
	end
end

local function setupDeathCounter(player)
	local function connectCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end

		humanoid.Died:Connect(function()
			local deaths = player:GetAttribute("PlayerDeaths") or 0
			player:SetAttribute("PlayerDeaths", deaths + 1)
		end)
	end

	if player.Character then
		connectCharacter(player.Character)
	end

	player.CharacterAdded:Connect(connectCharacter)
end

local function setupPlayer(player)
	if player:GetAttribute("PlayerKills") == nil then
		player:SetAttribute("PlayerKills", 0)
	end

	if player:GetAttribute("PlayerDeaths") == nil then
		player:SetAttribute("PlayerDeaths", 0)
	end

	player:SetAttribute("CurrentWave", currentWave)
	player:SetAttribute("WaveMessage", "")
	setupDeathCounter(player)
end

local function creditKill(killer)
	if not killer or not killer:IsA("Player") then
		return
	end

	local kills = killer:GetAttribute("PlayerKills") or 0
	killer:SetAttribute("PlayerKills", kills + 1)
end

local function startWave(waveNumber)
	currentWave = waveNumber
	enemiesRemaining = WAVE_DEFINITIONS[waveNumber] or 0
	setWaveAttributes(currentWave, "")

	print("[Wave] Started wave " .. tostring(waveNumber))

	EnemySpawner.SpawnWave(enemiesRemaining, function(_enemy, killer)
		enemiesRemaining -= 1
		creditKill(killer)
		print("[Wave] Enemy eliminated")

		if enemiesRemaining <= 0 then
			print("[Wave] Wave complete")
			setWaveAttributes(currentWave, "WAVE COMPLETE")

			local nextWave = currentWave + 1
			if WAVE_DEFINITIONS[nextWave] then
				task.delay(3, function()
					startWave(nextWave)
				end)
			end
		end
	end)
end

function WaveManager.Start()
	if isRunning then
		return
	end

	isRunning = true

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
		player:SetAttribute("CurrentWave", currentWave)
	end)

	startWave(1)
end

return WaveManager
