-- Server-Side Gun System with Weapon Progression
print("GunSystem: Loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GunDataModule = require(ServerScriptService:WaitForChild("GunDataModule"))

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local ShootGun = GameEvents:WaitForChild("ShootGun")
local AmmoUpdate = GameEvents:WaitForChild("AmmoUpdate")
local ReloadGun = GameEvents:WaitForChild("ReloadGun")
local AddAmmo = GameEvents:WaitForChild("AddAmmo")

-- Create new events for weapon system
local WeaponUpdate = Instance.new("RemoteEvent")
WeaponUpdate.Name = "WeaponUpdate"
WeaponUpdate.Parent = GameEvents

local SwitchWeapon = Instance.new("RemoteEvent")
SwitchWeapon.Name = "SwitchWeapon"
SwitchWeapon.Parent = GameEvents

local MeleeAttack = Instance.new("RemoteEvent")
MeleeAttack.Name = "MeleeAttack"
MeleeAttack.Parent = GameEvents

-- Player gun data (use shared module)
local playerGuns = GunDataModule.PlayerGuns

-- Initialize player with starter weapons
local function initPlayer(player)
	local pistol = GunDataModule.GetWeaponByName("Pistol")
	local knife = GunDataModule.GetWeaponByName("Knife")

	playerGuns[player] = {
		kills = 0,
		currentWeapon = 2,  -- Start with Pistol (index 2, knife is 1)
		weapons = {
			-- Each weapon tracks its own ammo state
			[1] = { ammo = 0, reserve = 0 },  -- Knife (no ammo)
			[2] = { ammo = pistol.magazineSize, reserve = pistol.reserveAmmo },  -- Pistol
			[3] = { ammo = 0, reserve = 0 },  -- SMG (locked)
			[4] = { ammo = 0, reserve = 0 },  -- Shotgun (locked)
			[5] = { ammo = 0, reserve = 0 },  -- Rifle (locked)
			[6] = { ammo = 0, reserve = 0 },  -- LMG (locked)
		},
		lastShot = 0,
		lastMelee = 0,
		reloading = false
	}

	-- Send initial state to client
	local currentWeaponData = GunDataModule.GetWeapon(2)
	local weaponAmmo = playerGuns[player].weapons[2]
	AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)
	WeaponUpdate:FireClient(player, {
		weaponIndex = 2,
		weaponName = currentWeaponData.name,
		kills = 0,
		nextUnlock = GunDataModule.GetNextUnlock(0)
	})

	print("GunSystem: Initialized " .. player.Name .. " with Pistol + Knife")
end

-- Unlock a weapon for a player (give starting ammo)
local function unlockWeapon(player, weaponIndex)
	local gunData = playerGuns[player]
	if not gunData then return end

	local weapon = GunDataModule.GetWeapon(weaponIndex)
	if not weapon then return end

	-- Give starting ammo
	if weapon.type == "gun" then
		gunData.weapons[weaponIndex] = {
			ammo = weapon.magazineSize,
			reserve = weapon.reserveAmmo
		}
	end

	print(player.Name .. " unlocked " .. weapon.name .. "!")
end

-- Check for weapon unlocks after a kill
local function checkUnlocks(player)
	local gunData = playerGuns[player]
	if not gunData then return end

	local kills = gunData.kills

	for i, weapon in ipairs(GunDataModule.Weapons) do
		-- Check if weapon should be unlocked and isn't yet
		if kills >= weapon.killsRequired then
			local weaponAmmo = gunData.weapons[i]
			-- If gun type and has no ammo, it's newly unlocked
			if weapon.type == "gun" and weaponAmmo.ammo == 0 and weaponAmmo.reserve == 0 then
				unlockWeapon(player, i)
				-- Auto-switch to new weapon
				gunData.currentWeapon = i
				local newAmmo = gunData.weapons[i]
				AmmoUpdate:FireClient(player, newAmmo.ammo, newAmmo.reserve)
			end
		end
	end

	-- Update client with kill count and next unlock info
	local currentWeapon = GunDataModule.GetWeapon(gunData.currentWeapon)
	WeaponUpdate:FireClient(player, {
		weaponIndex = gunData.currentWeapon,
		weaponName = currentWeapon.name,
		kills = kills,
		nextUnlock = GunDataModule.GetNextUnlock(kills)
	})
end

-- Handle shooting
ShootGun.OnServerEvent:Connect(function(player, cameraCFrame)
	local gunData = playerGuns[player]
	if not gunData then
		initPlayer(player)
		gunData = playerGuns[player]
	end

	local weaponIndex = gunData.currentWeapon
	local weapon = GunDataModule.GetWeapon(weaponIndex)
	local weaponAmmo = gunData.weapons[weaponIndex]

	-- Can't shoot melee weapons
	if weapon.type == "melee" then
		return
	end

	-- Check fire rate
	local now = tick()
	if now - gunData.lastShot < weapon.fireRate then
		return
	end

	-- Check ammo
	if weaponAmmo.ammo <= 0 or gunData.reloading then
		return
	end

	-- Consume ammo
	weaponAmmo.ammo = weaponAmmo.ammo - 1
	gunData.lastShot = now
	AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)

	-- Get character
	local character = player.Character
	if not character then return end

	local rayOrigin = cameraCFrame.Position
	local hitCount = 0

	-- Handle shotgun spread
	local pellets = weapon.pellets or 1
	local spread = weapon.spread or 0

	for p = 1, pellets do
		local rayDirection = cameraCFrame.LookVector * weapon.range

		-- Add spread for shotgun
		if spread > 0 then
			local spreadRad = math.rad(spread)
			local randomX = (math.random() - 0.5) * 2 * spreadRad
			local randomY = (math.random() - 0.5) * 2 * spreadRad
			rayDirection = (cameraCFrame * CFrame.Angles(randomX, randomY, 0)).LookVector * weapon.range
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {character}

		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		if result then
			local hit = result.Instance
			local model = hit:FindFirstAncestorOfClass("Model")

			if model then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					-- Check if it's a zombie (not a player)
					if not Players:GetPlayerFromCharacter(model) then
						local prevHealth = humanoid.Health
						humanoid:TakeDamage(weapon.damage)

						-- Check if this shot killed the zombie
						if prevHealth > 0 and humanoid.Health <= 0 then
							hitCount = hitCount + 1
						end
					end
				end
			end
		end
	end

	-- Track kills
	if hitCount > 0 then
		gunData.kills = gunData.kills + hitCount
		print(player.Name .. " killed " .. hitCount .. " zombie(s)! Total: " .. gunData.kills)
		checkUnlocks(player)
	end
end)

-- Handle melee attack
MeleeAttack.OnServerEvent:Connect(function(player, cameraCFrame)
	local gunData = playerGuns[player]
	if not gunData then
		initPlayer(player)
		gunData = playerGuns[player]
	end

	local weaponIndex = gunData.currentWeapon
	local weapon = GunDataModule.GetWeapon(weaponIndex)

	-- Must be using melee weapon
	if weapon.type ~= "melee" then
		return
	end

	-- Check attack cooldown
	local now = tick()
	if now - gunData.lastMelee < (1 / weapon.attackSpeed) then
		return
	end
	gunData.lastMelee = now

	-- Get character
	local character = player.Character
	if not character then return end

	local rayOrigin = cameraCFrame.Position
	local rayDirection = cameraCFrame.LookVector * weapon.range

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	if result then
		local hit = result.Instance
		local model = hit:FindFirstAncestorOfClass("Model")

		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- Check if it's a zombie (not a player)
				if not Players:GetPlayerFromCharacter(model) then
					local prevHealth = humanoid.Health
					humanoid:TakeDamage(weapon.damage)
					print(player.Name .. " melee hit " .. model.Name .. " for " .. weapon.damage .. " damage")

					-- Check if killed
					if prevHealth > 0 and humanoid.Health <= 0 then
						gunData.kills = gunData.kills + 1
						print(player.Name .. " melee killed a zombie! Total: " .. gunData.kills)
						checkUnlocks(player)
					end
				end
			end
		end
	end
end)

-- Handle weapon switching
SwitchWeapon.OnServerEvent:Connect(function(player, weaponIndex)
	local gunData = playerGuns[player]
	if not gunData then
		initPlayer(player)
		gunData = playerGuns[player]
	end

	-- Validate weapon index
	if weaponIndex < 1 or weaponIndex > #GunDataModule.Weapons then
		return
	end

	local weapon = GunDataModule.GetWeapon(weaponIndex)

	-- Check if player has unlocked this weapon
	if gunData.kills < weapon.killsRequired then
		print(player.Name .. " tried to switch to " .. weapon.name .. " but needs " .. weapon.killsRequired .. " kills")
		return
	end

	-- Switch weapon
	gunData.currentWeapon = weaponIndex
	gunData.reloading = false

	local weaponAmmo = gunData.weapons[weaponIndex]
	AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)
	WeaponUpdate:FireClient(player, {
		weaponIndex = weaponIndex,
		weaponName = weapon.name,
		kills = gunData.kills,
		nextUnlock = GunDataModule.GetNextUnlock(gunData.kills)
	})

	print(player.Name .. " switched to " .. weapon.name)
end)

-- Handle reloading
ReloadGun.OnServerEvent:Connect(function(player)
	local gunData = playerGuns[player]
	if not gunData then
		initPlayer(player)
		gunData = playerGuns[player]
	end

	local weaponIndex = gunData.currentWeapon
	local weapon = GunDataModule.GetWeapon(weaponIndex)
	local weaponAmmo = gunData.weapons[weaponIndex]

	-- Can't reload melee
	if weapon.type == "melee" then
		return
	end

	-- Check if already reloading or magazine is full
	if gunData.reloading or weaponAmmo.ammo >= weapon.magazineSize then
		return
	end

	-- Check if has reserve ammo
	if weaponAmmo.reserve <= 0 then
		return
	end

	gunData.reloading = true

	-- Handle shell-by-shell reloading (shotgun)
	if weapon.reloadType == "shell" then
		task.spawn(function()
			while gunData.reloading and weaponAmmo.ammo < weapon.magazineSize and weaponAmmo.reserve > 0 do
				task.wait(weapon.reloadTime)
				if not gunData.reloading then break end

				weaponAmmo.ammo = weaponAmmo.ammo + 1
				weaponAmmo.reserve = weaponAmmo.reserve - 1
				AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)
			end
			gunData.reloading = false
		end)
	else
		-- Normal magazine reload
		task.wait(weapon.reloadTime)

		local needed = weapon.magazineSize - weaponAmmo.ammo
		local toReload = math.min(needed, weaponAmmo.reserve)

		weaponAmmo.ammo = weaponAmmo.ammo + toReload
		weaponAmmo.reserve = weaponAmmo.reserve - toReload
		gunData.reloading = false

		AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)
		print(player.Name .. " reloaded " .. weapon.name .. ". Ammo: " .. weaponAmmo.ammo .. "/" .. weaponAmmo.reserve)
	end
end)

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		initPlayer(player)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	playerGuns[player] = nil
end)

-- Handle ammo pickups (adds to current weapon)
AddAmmo.OnServerEvent:Connect(function(player, amount)
	local gunData = playerGuns[player]
	if not gunData then
		initPlayer(player)
		gunData = playerGuns[player]
	end

	-- Add ammo to current weapon (if it uses ammo)
	local weaponIndex = gunData.currentWeapon
	local weapon = GunDataModule.GetWeapon(weaponIndex)

	if weapon.type == "gun" then
		local weaponAmmo = gunData.weapons[weaponIndex]
		weaponAmmo.reserve = weaponAmmo.reserve + amount
		AmmoUpdate:FireClient(player, weaponAmmo.ammo, weaponAmmo.reserve)
		print(player.Name .. " picked up " .. amount .. " ammo for " .. weapon.name .. "! Reserve: " .. weaponAmmo.reserve)
	end
end)

print("GunSystem: Ready!")
print("  Weapons: Knife, Pistol (start), SMG (10 kills), Shotgun (25), Rifle (50), LMG (100)")
