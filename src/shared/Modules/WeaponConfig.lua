-- WeaponConfig keeps weapon values in one shared table.
-- The server uses these trusted settings for damage, range, and cooldown checks.

local WeaponConfig = {
	Pistol = {
		Damage = 20,
		Range = 300,
		FireCooldown = 0.35,
	},
}

return WeaponConfig
