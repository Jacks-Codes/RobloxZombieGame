-- Grapple Practice Platforms
print("GrapplePlatforms: Creating platforms...")

-- Find spawn location to place platforms nearby
local function findSpawnPosition()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("SpawnLocation") then
			return obj.Position
		end
	end
	return Vector3.new(0, 5, 0)  -- Default fallback
end

local spawnPos = findSpawnPosition()

-- Platform settings (grapple works 6-10 studs, jump is ~5 studs)
local platforms = {
	{
		name = "GrapplePlatform_JumpOnly",
		height = 4,      -- Below grapple range - must jump
		offset = Vector3.new(10, 0, -10),
		color = Color3.fromRGB(100, 100, 255),  -- Blue
		size = Vector3.new(6, 1, 6)
	},
	{
		name = "GrapplePlatform_Low",
		height = 6,      -- Min grapple height
		offset = Vector3.new(10, 0, 0),
		color = Color3.fromRGB(0, 255, 100),  -- Green
		size = Vector3.new(6, 1, 6)
	},
	{
		name = "GrapplePlatform_Mid",
		height = 8,      -- Middle grapple height
		offset = Vector3.new(10, 0, 10),
		color = Color3.fromRGB(255, 255, 0),  -- Yellow
		size = Vector3.new(6, 1, 6)
	},
	{
		name = "GrapplePlatform_High",
		height = 10,     -- Max grapple height
		offset = Vector3.new(10, 0, 20),
		color = Color3.fromRGB(255, 100, 0),  -- Orange
		size = Vector3.new(6, 1, 6)
	}
}

-- Create folder for platforms
local folder = Instance.new("Folder")
folder.Name = "GrapplePlatforms"
folder.Parent = workspace

-- Create each platform
for _, config in ipairs(platforms) do
	local platform = Instance.new("Part")
	platform.Name = config.name
	platform.Size = config.size
	platform.Position = spawnPos + config.offset + Vector3.new(0, config.height, 0)
	platform.Color = config.color
	platform.Material = Enum.Material.Neon
	platform.Anchored = true
	platform.CanCollide = true
	platform.Parent = folder

	-- Add label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = platform

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = config.height .. " studs"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard

	print("  Created: " .. config.name .. " at height " .. config.height)
end

print("GrapplePlatforms: Ready! 4 platforms created near spawn.")
print("  Blue (4 studs) - Jump only, too low for grapple")
print("  Green (6 studs) - Min grapple height")
print("  Yellow (8 studs) - Mid grapple height")
print("  Orange (10 studs) - Max grapple height")
