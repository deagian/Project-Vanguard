-- EnemyConfig centralizza i valori base dei bot nemici.
-- Tutta la logica resta server-side: il client non decide mai il danno nemico.

local EnemyConfig = {
	Enemy = {
		MaxHealth = 100,
		WalkSpeed = 8,
		DetectionRange = 65,
		AttackRange = 35,
		FireCooldown = 2.5,
		Damage = 2,
		RespawnTime = 4,
		PatrolRadius = 10,
		PatrolCooldown = 3,
	},
}

return EnemyConfig
