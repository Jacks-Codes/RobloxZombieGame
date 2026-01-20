-- City Boundary System - Keeps players inside the city
print("CityBoundary: Loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--============================================
-- EDIT THESE VALUES TO SET YOUR BOUNDARIES
--============================================
local USE_MANUAL_BOUNDS = false  -- Set to true to use manual coordinates below

-- Manual boundary coordinates (only used if USE_MANUAL_BOUNDS = true)
-- Stand at each corner of your city in Studio and check the Position in Properties
local MIN_X = -200   -- West edge (negative X)
local MAX_X = 200    -- East edge (positive X)
local MIN_Z = -200   -- North edge (negative Z)
local MAX_Z = 200    -- South edge (positive Z)
local GROUND_Y = 0   -- Ground level

--============================================
local WALL_HEIGHT = 100  -- How tall the invisible walls are
local WALL_THICKNESS = 5  -- Thickness of boundary walls

-- Get city bounds
local function getCityBounds()
	if USE_MANUAL_BOUNDS then
		print("CityBoundary: Using manual bounds")
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + WALL_HEIGHT, MAX_Z)
	end

	-- Auto-detect from city model
	local cityMap = workspace:FindFirstChild("city map modified by RCarCrash")
	if not cityMap then
		warn("CityBoundary: 'city map modified by RCarCrash' not found! Using manual bounds.")
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + WALL_HEIGHT, MAX_Z)
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
		return Vector3.new(MIN_X, GROUND_Y, MIN_Z), Vector3.new(MAX_X, GROUND_Y + WALL_HEIGHT, MAX_Z)
	end

	return Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
end

-- Create invisible boundary walls
local function createBoundaryWalls()
	local minBounds, maxBounds = getCityBounds()

	-- Add some padding so walls are slightly outside the city
	local padding = 5
	minBounds = minBounds - Vector3.new(padding, 0, padding)
	maxBounds = maxBounds + Vector3.new(padding, 0, padding)

	local centerX = (minBounds.X + maxBounds.X) / 2
	local centerZ = (minBounds.Z + maxBounds.Z) / 2
	local centerY = minBounds.Y + WALL_HEIGHT / 2

	local sizeX = maxBounds.X - minBounds.X
	local sizeZ = maxBounds.Z - minBounds.Z

	local boundaryFolder = Instance.new("Folder")
	boundaryFolder.Name = "CityBoundary"
	boundaryFolder.Parent = workspace

	-- North wall (positive Z)
	local northWall = Instance.new("Part")
	northWall.Name = "NorthWall"
	northWall.Size = Vector3.new(sizeX + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS)
	northWall.Position = Vector3.new(centerX, centerY, maxBounds.Z + WALL_THICKNESS / 2)
	northWall.Anchored = true
	northWall.Transparency = 1
	northWall.CanCollide = true
	northWall.Parent = boundaryFolder

	-- South wall (negative Z)
	local southWall = Instance.new("Part")
	southWall.Name = "SouthWall"
	southWall.Size = Vector3.new(sizeX + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS)
	southWall.Position = Vector3.new(centerX, centerY, minBounds.Z - WALL_THICKNESS / 2)
	southWall.Anchored = true
	southWall.Transparency = 1
	southWall.CanCollide = true
	southWall.Parent = boundaryFolder

	-- East wall (positive X)
	local eastWall = Instance.new("Part")
	eastWall.Name = "EastWall"
	eastWall.Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, sizeZ + WALL_THICKNESS * 2)
	eastWall.Position = Vector3.new(maxBounds.X + WALL_THICKNESS / 2, centerY, centerZ)
	eastWall.Anchored = true
	eastWall.Transparency = 1
	eastWall.CanCollide = true
	eastWall.Parent = boundaryFolder

	-- West wall (negative X)
	local westWall = Instance.new("Part")
	westWall.Name = "WestWall"
	westWall.Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, sizeZ + WALL_THICKNESS * 2)
	westWall.Position = Vector3.new(minBounds.X - WALL_THICKNESS / 2, centerY, centerZ)
	westWall.Anchored = true
	westWall.Transparency = 1
	westWall.CanCollide = true
	westWall.Parent = boundaryFolder

	print("CityBoundary: Walls created!")
	print("  Bounds: (" .. math.floor(minBounds.X) .. ", " .. math.floor(minBounds.Z) .. ") to (" .. math.floor(maxBounds.X) .. ", " .. math.floor(maxBounds.Z) .. ")")

	return minBounds, maxBounds, boundaryFolder
end

-- Create the boundary walls (invisible walls keep players in)
local minBounds, maxBounds, boundaryFolder = createBoundaryWalls()

print("CityBoundary: System ready!")
print("CityBoundary: Walls will keep players inside - no teleporting")
