-- Shared Gun Data Module
-- Weapon definitions and player data

local GunDataModule = {}

-- Player gun data (shared between scripts)
GunDataModule.PlayerGuns = {}

-- Weapon definitions (unlocked by kill count)
-- Unlock order: Knife (0), Pistol (0), SMG (20), Shotgun (50), Rifle (100), LMG (200)
GunDataModule.Weapons = {
	{
		name = "Knife",
		type = "melee",
		damage = 50,
		range = 5,
		attackSpeed = 0.5,  -- Attacks per second
		killsRequired = 0,
		magazineSize = 0,  -- Melee doesn't use ammo
		reserveAmmo = 0,
		reloadTime = 0,
	},
	{
		name = "Pistol",
		type = "gun",
		damage = 25,
		range = 200,
		fireRate = 0.3,  -- Time between shots
		killsRequired = 0,
		magazineSize = 12,
		reserveAmmo = 36,
		reloadTime = 1.5,
	},
	{
		name = "SMG",
		type = "gun",
		damage = 18,
		range = 150,
		fireRate = 0.08,  -- Fast fire rate
		killsRequired = 10,
		magazineSize = 30,
		reserveAmmo = 90,
		reloadTime = 2,
	},
	{
		name = "Shotgun",
		type = "gun",
		damage = 15,  -- Per pellet, shoots 8 pellets
		pellets = 8,
		spread = 5,  -- Degrees of spread
		range = 50,
		fireRate = 0.8,  -- Slow pump action
		killsRequired = 25,
		magazineSize = 6,
		reserveAmmo = 24,
		reloadTime = 0.5,  -- Per shell
		reloadType = "shell",  -- Reload one at a time
	},
	{
		name = "Rifle",
		type = "gun",
		damage = 45,
		range = 500,
		fireRate = 0.15,
		killsRequired = 50,
		magazineSize = 20,
		reserveAmmo = 60,
		reloadTime = 2.5,
	},
	{
		name = "LMG",
		type = "gun",
		damage = 22,
		range = 300,
		fireRate = 0.1,
		killsRequired = 100,
		magazineSize = 100,
		reserveAmmo = 200,
		reloadTime = 4,
	},
}

-- Get weapon by index (1-6)
function GunDataModule.GetWeapon(index)
	return GunDataModule.Weapons[index]
end

-- Get weapon by name
function GunDataModule.GetWeaponByName(name)
	for _, weapon in ipairs(GunDataModule.Weapons) do
		if weapon.name == name then
			return weapon
		end
	end
	return nil
end

-- Get unlocked weapons for a kill count
function GunDataModule.GetUnlockedWeapons(killCount)
	local unlocked = {}
	for i, weapon in ipairs(GunDataModule.Weapons) do
		if killCount >= weapon.killsRequired then
			table.insert(unlocked, {index = i, weapon = weapon})
		end
	end
	return unlocked
end

-- Get next weapon to unlock
function GunDataModule.GetNextUnlock(killCount)
	for i, weapon in ipairs(GunDataModule.Weapons) do
		if killCount < weapon.killsRequired then
			return {
				index = i,
				weapon = weapon,
				killsNeeded = weapon.killsRequired - killCount
			}
		end
	end
	return nil  -- All weapons unlocked
end

return GunDataModule
