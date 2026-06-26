-- WeaponConfig keeps weapon values in one shared table.
-- The server uses these trusted settings for damage, range, and cooldown checks.

local WeaponConfig = {
	Pistol = {
		Damage = 20,
		Range = 300,
		FireCooldown = 0.35,
		MagazineSize = 12,
		ReloadTime = 1.5,
		HipFireSpread = 1.5,
		ADSSpread = 0.5,
		Recoil = 0.9,
		ADSRecoilMultiplier = 0.55,
	},

	AssaultRifle = {
		Damage = 16,
		HeadshotMultiplier = 1.8,
		Range = 450,
		FireCooldown = 0.09,
		MagazineSize = 30,
		ReloadTime = 1.8,
		HipFireSpread = 2.2,
		ADSSpread = 0.9,
		Recoil = 0.65,
		ADSRecoilMultiplier = 0.55,
		Automatic = true,
	},

	SMG = {
		Damage = 12,
		HeadshotMultiplier = 1.6,
		Range = 330,
		FireCooldown = 0.065,
		MagazineSize = 25,
		ReloadTime = 1.8,
		HipFireSpread = 3.0,
		ADSSpread = 1.25,
		Recoil = 0.48,
		ADSRecoilMultiplier = 0.6,
		Automatic = true,
	},
}

return WeaponConfig
