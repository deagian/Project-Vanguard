-- EnemyConfig centralizza i valori base dei bot nemici.
-- Tutta la logica resta server-side: il client non decide mai il danno nemico.

local EnemyConfig = {
	Enemy = {
		MaxHealth = 100,
		WalkSpeed = 10,
		DetectionRange = 80,
		AttackRange = 55,
		FireCooldown = 1.2,
		Damage = 8,
		RespawnTime = 4,
		PatrolRadius = 10,
		PatrolCooldown = 3,
	},
}

return EnemyConfig
