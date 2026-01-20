-- Round-Based Zombie Spawner
print("ZombieSpawner: Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local RoundUpdate = GameEvents:WaitForChild("RoundUpdate")
local ZombieCountUpdate = GameEvents:WaitForChild("ZombieCountUpdate")

--============================================
-- TEST MODE - Set to true to disable zombies
--============================================
local TEST_MODE = false  -- Set to TRUE to disable zombie spawning for testing
--============================================

-- Round configuration
local currentRound = 0
local zombiesRemaining = 0
local spawnedZombies = {}
local isIntermission = false

local BASE_ZOMBIES = 5
local ZOMBIES_PER_ROUND = 3
local INTERMISSION_TIME = 10
local SPAWN_DELAY = 1

-- Zombie stats
local CHASE_RANGE = 100
local ATTACK_RANGE = 5
local ATTACK_DAMAGE = 20
local ATTACK_COOLDOWN = 2

--============================================
-- SPAWN AREA SETTINGS
--============================================
local USE_MANUAL_BOUNDS = false  -- Set to true to use manual coordinates below

-- Manual spawn boundaries (match these to your CityBoundary settings)
local MIN_X = -200
local MAX_X = 200
local MIN_Z = -200
local MAX_Z = 200
local GROUND_Y = 0

-- Spawn distance from players
local SPAWN_NEAR_PLAYER = true  -- If true, spawns within range of players
local SPAWN_MIN_DISTANCE = 20   -- Minimum studs from player
local SPAWN_MAX_DISTANCE = 40   -- Maximum studs from player
local SPAWN_AT_PLAYER_Y = true  -- Spawn at same Y level as player
--============================================

-- Create a zombie
local function createZombie(position, roundNumber)
	-- Try to find zombie template in ReplicatedStorage
	local zombieTemplate = ReplicatedStorage:FindFirstChild("ZombieModel")

	local zombie
	if zombieTemplate and zombieTemplate:IsA("Model") then
		-- Use custom zombie model from Studio
		zombie = zombieTemplate:Clone()
		zombie.Name = "Zombie"

		-- Position zombie
		if zombie.PrimaryPart then
			zombie:SetPrimaryPartCFrame(CFrame.new(position))
		elseif zombie:FindFirstChild("HumanoidRootPart") then
			zombie.HumanoidRootPart.Position = position
		end
	else
		-- Fallback: Create basic zombie if no model found
		zombie = Instance.new("Model")
		zombie.Name = "Zombie"

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = position
		torso.BrickColor = BrickColor.new("Dark green")
		torso.Parent = zombie

		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2, 1, 1)
		head.Position = position + Vector3.new(0, 1.5, 0)
		head.BrickColor = BrickColor.new("Bright green")
		head.Parent = zombie

		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Position = position
		rootPart.Transparency = 1
		rootPart.CanCollide = true
		rootPart.Parent = zombie

		local neckWeld = Instance.new("Weld")
		neckWeld.Part0 = torso
		neckWeld.Part1 = head
		neckWeld.C0 = CFrame.new(0, 1.5, 0)
		neckWeld.Parent = torso

		local rootWeld = Instance.new("Motor6D")
		rootWeld.Name = "Root"
		rootWeld.Part0 = rootPart
		rootWeld.Part1 = torso
		rootWeld.Parent = rootPart

		zombie.PrimaryPart = rootPart

		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = zombie
	end

	zombie.Parent = workspace

	-- Add to spawned list
	table.insert(spawnedZombies, zombie)

	-- Get components needed for AI
	local rootPart = zombie:FindFirstChild("HumanoidRootPart")
	local humanoid = zombie:FindFirstChildOfClass("Humanoid")

	if not rootPart then
		warn("Zombie has no HumanoidRootPart! AI will not work.")
		return zombie
	end

	if not humanoid then
		warn("Zombie has no Humanoid! AI will not work.")
		return zombie
	end

	-- Set health based on round
	local health = 100 * roundNumber
	humanoid.MaxHealth = health
	humanoid.Health = health
	humanoid.WalkSpeed = 8 + (roundNumber * 0.5)

	-- Zombie AI - Enhanced pathfinding
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4,
		Costs = {
			Water = math.huge,  -- Avoid water
			Danger = math.huge  -- Avoid dangerous areas
		}
	})

	local targetPlayer = nil
	local waypoints = {}
	local currentWaypoint = 1
	local lastAttackTime = 0

	-- Find nearest player
	local function findNearestPlayer()
		local nearest = nil
		local nearestDist = CHASE_RANGE

		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local charRoot = char:FindFirstChild("HumanoidRootPart")
				if charRoot then
					local dist = (charRoot.Position - rootPart.Position).Magnitude
					if dist < nearestDist then
						nearest = player
						nearestDist = dist
					end
				end
			end
		end

		return nearest
	end

	-- AI loop
	local aiConnection = RunService.Heartbeat:Connect(function()
		if not zombie.Parent or humanoid.Health <= 0 then
			return
		end

		-- Find target
		if not targetPlayer or not targetPlayer.Character then
			targetPlayer = findNearestPlayer()
		end

		if not targetPlayer or not targetPlayer.Character then
			humanoid:MoveTo(rootPart.Position)
			return
		end

		local targetChar = targetPlayer.Character
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return
		end

		local distance = (targetRoot.Position - rootPart.Position).Magnitude

		-- Attack if in range
		if distance <= ATTACK_RANGE then
			humanoid:MoveTo(rootPart.Position)

			local now = tick()
			if now - lastAttackTime >= ATTACK_COOLDOWN then
				local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
				if targetHumanoid then
					targetHumanoid:TakeDamage(ATTACK_DAMAGE)
					lastAttackTime = now
				end
			end
		else
			-- Chase player
			local success, errorMsg = pcall(function()
				path:ComputeAsync(rootPart.Position, targetRoot.Position)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				waypoints = path:GetWaypoints()
				currentWaypoint = 2

				if waypoints[currentWaypoint] then
					-- Check if need to jump
					if waypoints[currentWaypoint].Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
					humanoid:MoveTo(waypoints[currentWaypoint].Position)
				end
			else
				humanoid:MoveTo(targetRoot.Position)
			end
		end
	end)

	-- Handle waypoint reached
	local moveConnection = humanoid.MoveToFinished:Connect(function(reached)
		if reached and currentWaypoint < #waypoints then
			currentWaypoint = currentWaypoint + 1
			if waypoints[currentWaypoint] then
				-- Check if need to jump at next waypoint
				if waypoints[currentWaypoint].Action == Enum.PathWaypointAction.Jump then
					humanoid.Jump = true
				end
				humanoid:MoveTo(waypoints[currentWaypoint].Position)
			end
		end
	end)

	-- Track if this zombie's death was already counted
	local deathCounted = false

	-- Handle death
	humanoid.Died:Connect(function()
		aiConnection:Disconnect()
		moveConnection:Disconnect()

		-- Prevent double-counting (e.g., from cleanup destroy)
		if deathCounted or isIntermission then
			return
		end
		deathCounted = true

		-- Drop ammo at zombie's position
		if rootPart and _G.SpawnAmmoDrop then
			_G.SpawnAmmoDrop(rootPart.Position)
		end

		-- Remove from list
		for i, z in ipairs(spawnedZombies) do
			if z == zombie then
				table.remove(spawnedZombies, i)
				break
			end
		end

		-- Update count
		zombiesRemaining = zombiesRemaining - 1
		ZombieCountUpdate:FireAllClients(zombiesRemaining)

		print("Zombie killed! Remaining: " .. zombiesRemaining)

		-- Check if round complete
		if zombiesRemaining <= 0 and not isIntermission then
			endRound()
		end

		-- Clean up
		task.wait(3)
		if zombie and zombie.Parent then
			zombie:Destroy()
		end
	end)

	return zombie
end

-- Get city bounds
local function getCityBounds()
	if USE_MANUAL_BOUNDS then
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + 100, MAX_Z)
	end

	local cityMap = workspace:FindFirstChild("city map modified by RCarCrash")
	if not cityMap then
		warn("ZombieSpawner: 'city map modified by RCarCrash' not found! Using manual bounds.")
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + 100, MAX_Z)
	end

	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, part in pairs(cityMap:GetDescendants()) do
		if part:IsA("BasePart") then
			local pos = part.Position
			local size = part.Size / 2

			minX = math.min(minX, pos.X - size.X)
			minY = math.min(minY, pos.Y - size.Y)
			minZ = math.min(minZ, pos.Z - size.Z)
			maxX = math.max(maxX, pos.X + size.X)
			maxY = math.max(maxY, pos.Y + size.Y)
			maxZ = math.max(maxZ, pos.Z + size.Z)
		end
	end

	if minX == math.huge then
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + 100, MAX_Z)
	end

	return Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
end

-- Check if position is within bounds
local function isWithinBounds(x, z)
	local minBounds, maxBounds = getCityBounds()
	return x >= minBounds.X and x <= maxBounds.X and z >= minBounds.Z and z <= maxBounds.Z
end

-- Find valid ground position using raycast
local function findGroundPosition(x, z)
	local minBounds, maxBounds = getCityBounds()

	local rayOrigin = Vector3.new(x, maxBounds.Y + 50, z)
	local rayDirection = Vector3.new(0, -500, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = spawnedZombies

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result then
		return result.Position + Vector3.new(0, 3, 0)
	end
	return nil
end

-- Get random spawn position near a player (within SPAWN_DISTANCE studs)
local function getRandomSpawnPosition()
	local minBounds, maxBounds = getCityBounds()

	-- Try to spawn near a player
	if SPAWN_NEAR_PLAYER then
		local players = Players:GetPlayers()
		if #players > 0 then
			-- Pick a random player
			local player = players[math.random(1, #players)]
			local char = player.Character
			if char then
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					-- Spawn between min and max distance from player
					local angle = math.random() * math.pi * 2
					local distance = math.random(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE)
					local x = rootPart.Position.X + math.cos(angle) * distance
					local z = rootPart.Position.Z + math.sin(angle) * distance

					-- Use player's Y level if enabled
					if SPAWN_AT_PLAYER_Y then
						return Vector3.new(x, rootPart.Position.Y, z)
					else
						local groundPos = findGroundPosition(x, z)
						if groundPos then
							return groundPos
						end
					end
				end
			end
		end
	end

	-- Fallback: random position in map bounds
	for attempt = 1, 10 do
		local x = math.random(math.floor(minBounds.X), math.floor(maxBounds.X))
		local z = math.random(math.floor(minBounds.Z), math.floor(maxBounds.Z))

		local groundPos = findGroundPosition(x, z)
		if groundPos then
			return groundPos
		end
	end

	-- Final fallback
	local centerX = (minBounds.X + maxBounds.X) / 2
	local centerZ = (minBounds.Z + maxBounds.Z) / 2
	return Vector3.new(centerX, GROUND_Y + 5, centerZ)
end

-- Spawn zombies for a round
local function spawnZombies(count, round)
	print("Spawning " .. count .. " zombies for round " .. round)

	for i = 1, count do
		local pos = getRandomSpawnPosition()
		createZombie(pos, round)

		if i < count then
			task.wait(SPAWN_DELAY)
		end
	end

	print("Spawned " .. count .. " zombies!")
end

-- Start a new round
function startRound()
	if isIntermission then
		return
	end

	-- Check TEST_MODE to disable zombie spawning
	if TEST_MODE then
		print("=== TEST MODE ENABLED - NO ZOMBIES ===")
		print("Set TEST_MODE = false in ZombieSpawner.server.lua to enable zombies")
		return
	end

	currentRound = currentRound + 1
	local zombieCount = BASE_ZOMBIES + (currentRound - 1) * ZOMBIES_PER_ROUND
	zombiesRemaining = zombieCount

	RoundUpdate:FireAllClients({
		Round = currentRound,
		Zombies = zombieCount,
		Status = "Started"
	})

	ZombieCountUpdate:FireAllClients(zombiesRemaining)

	print("=== ROUND " .. currentRound .. " STARTED ===")
	print("Zombies: " .. zombieCount)

	spawnZombies(zombieCount, currentRound)
end

-- End current round
function endRound()
	if isIntermission then
		return
	end

	isIntermission = true

	RoundUpdate:FireAllClients({
		Round = currentRound,
		Zombies = 0,
		Status = "Ended"
	})

	print("=== ROUND " .. currentRound .. " COMPLETE ===")
	print("Intermission: " .. INTERMISSION_TIME .. " seconds")

	-- Clear any remaining zombies
	for _, zombie in ipairs(spawnedZombies) do
		if zombie and zombie.Parent then
			zombie:Destroy()
		end
	end
	spawnedZombies = {}

	task.wait(INTERMISSION_TIME)

	isIntermission = false
	startRound()
end

-- Start game
task.wait(3)
print("=== ZOMBIE GAME STARTING ===")
startRound()
