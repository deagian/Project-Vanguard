-- Bootstrap del game loop: avvia WaveManager dal server.

local WaveManager = require(script.Parent:WaitForChild("WaveManager"))

WaveManager.Start()

print("[EnemySpawner] Enemy system loaded")
