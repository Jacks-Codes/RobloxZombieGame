-- Create a better procedural gun model
print("GunModelSpawner: Creating improved gun model...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a more detailed gun model using only code
local function createGunModel()
	local gun = Instance.new("Model")
	gun.Name = "AssaultRifle"

	-- Main handle/grip
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 0.7, 0.25)
	handle.Color = Color3.fromRGB(40, 30, 20)
	handle.Material = Enum.Material.Wood
	handle.Parent = gun

	-- Trigger guard
	local trigger = Instance.new("Part")
	trigger.Name = "Trigger"
	trigger.Size = Vector3.new(0.15, 0.3, 0.15)
	trigger.Color = Color3.fromRGB(30, 30, 30)
	trigger.Material = Enum.Material.Metal
	trigger.Parent = gun

	-- Magazine
	local mag = Instance.new("Part")
	mag.Name = "Magazine"
	mag.Size = Vector3.new(0.25, 0.5, 0.2)
	mag.Color = Color3.fromRGB(30, 30, 30)
	mag.Material = Enum.Material.Metal
	mag.Parent = gun

	-- Lower receiver
	local lowerReceiver = Instance.new("Part")
	lowerReceiver.Name = "LowerReceiver"
	lowerReceiver.Size = Vector3.new(0.3, 0.4, 0.6)
	lowerReceiver.Color = Color3.fromRGB(40, 40, 40)
	lowerReceiver.Material = Enum.Material.Metal
	lowerReceiver.Parent = gun

	-- Upper receiver
	local upperReceiver = Instance.new("Part")
	upperReceiver.Name = "UpperReceiver"
	upperReceiver.Size = Vector3.new(0.3, 0.25, 0.8)
	upperReceiver.Color = Color3.fromRGB(35, 35, 35)
	upperReceiver.Material = Enum.Material.Metal
	upperReceiver.Parent = gun

	-- Barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.15, 0.15, 1.5)
	barrel.Color = Color3.fromRGB(20, 20, 20)
	barrel.Material = Enum.Material.Metal
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Parent = gun

	-- Stock
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Size = Vector3.new(0.3, 0.3, 0.6)
	stock.Color = Color3.fromRGB(40, 30, 20)
	stock.Material = Enum.Material.Wood
	stock.Parent = gun

	-- Sight front
	local sightFront = Instance.new("Part")
	sightFront.Name = "SightFront"
	sightFront.Size = Vector3.new(0.1, 0.2, 0.1)
	sightFront.Color = Color3.fromRGB(20, 20, 20)
	sightFront.Material = Enum.Material.Metal
	sightFront.Parent = gun

	-- Sight rear
	local sightRear = Instance.new("Part")
	sightRear.Name = "SightRear"
	sightRear.Size = Vector3.new(0.1, 0.15, 0.1)
	sightRear.Color = Color3.fromRGB(20, 20, 20)
	sightRear.Material = Enum.Material.Metal
	sightRear.Parent = gun

	-- Make all parts non-anchored (required for welds to work)
	handle.Anchored = false
	trigger.Anchored = false
	mag.Anchored = false
	lowerReceiver.Anchored = false
	upperReceiver.Anchored = false
	barrel.Anchored = false
	stock.Anchored = false
	sightFront.Anchored = false
	sightRear.Anchored = false

	-- Position all parts relative to handle (origin)
	local origin = CFrame.new(0, 0, 0)
	handle.CFrame = origin

	-- Position other parts
	trigger.CFrame = origin * CFrame.new(0, 0.3, -0.1)
	mag.CFrame = origin * CFrame.new(0, -0.1, -0.1)
	lowerReceiver.CFrame = origin * CFrame.new(0, 0.5, -0.2)
	upperReceiver.CFrame = origin * CFrame.new(0, 0.75, -0.3)
	barrel.CFrame = origin * CFrame.new(0, 0.8, -0.9) * CFrame.Angles(0, 0, math.rad(90))
	stock.CFrame = origin * CFrame.new(0, 0.4, 0.4)
	sightFront.CFrame = origin * CFrame.new(0, 1.0, -1.4)
	sightRear.CFrame = origin * CFrame.new(0, 0.95, -0.5)

	-- Weld everything to handle using proper Welds (not WeldConstraints)
	for _, part in pairs(gun:GetChildren()) do
		if part:IsA("BasePart") and part ~= handle then
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = part
			weld.C0 = CFrame.new(0, 0, 0)
			weld.C1 = handle.CFrame:ToObjectSpace(part.CFrame)
			weld.Parent = handle
		end
	end

	gun.PrimaryPart = handle
	gun.Parent = ReplicatedStorage

	print("✓ Improved gun model created!")
	return gun
end

-- Check if gun already exists
local existing = ReplicatedStorage:FindFirstChild("AssaultRifle")
if existing then
	existing:Destroy()
end

createGunModel()
