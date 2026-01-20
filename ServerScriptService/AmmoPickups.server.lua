-- Ammo Pickup System - Drops from zombies
print("AmmoPickups: Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GunDataModule = require(ServerScriptService:WaitForChild("GunDataModule"))

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local AmmoUpdate = GameEvents:WaitForChild("AmmoUpdate")

-- Track player gun data (shared with GunSystem)
local playerGuns = GunDataModule.PlayerGuns

local AMMO_AMOUNT = 30  -- One magazine worth
local DROP_CHANCE = 0.05  -- 5% chance to drop ammo on kill
local PICKUP_LIFETIME = 30  -- Seconds before pickup disappears if not collected

-- Create an ammo pickup box at a position (called when zombie dies)
local function createAmmoPickup(position)
	local pickup = Instance.new("Model")
	pickup.Name = "AmmoPickup"

	-- Create ammo crate model
	local box = Instance.new("Part")
	box.Name = "Box"
	box.Size = Vector3.new(1.5, 1, 1.5)
	box.Position = position + Vector3.new(0, 1, 0)  -- Slightly above ground
	box.Color = Color3.fromRGB(100, 70, 30)
	box.Material = Enum.Material.Wood
	box.Anchored = true
	box.CanCollide = true
	box.Parent = pickup

	-- Ammo symbol (yellow cross)
	local symbol1 = Instance.new("Part")
	symbol1.Size = Vector3.new(0.1, 0.6, 0.2)
	symbol1.Color = Color3.fromRGB(255, 200, 0)
	symbol1.Material = Enum.Material.Neon
	symbol1.Anchored = true
	symbol1.CanCollide = false
	symbol1.CFrame = box.CFrame * CFrame.new(0.76, 0, 0)
	symbol1.Parent = pickup

	local symbol2 = Instance.new("Part")
	symbol2.Size = Vector3.new(0.1, 0.2, 0.6)
	symbol2.Color = Color3.fromRGB(255, 200, 0)
	symbol2.Material = Enum.Material.Neon
	symbol2.Anchored = true
	symbol2.CanCollide = false
	symbol2.CFrame = box.CFrame * CFrame.new(0.76, 0, 0)
	symbol2.Parent = pickup

	-- Metal straps
	local strap1 = Instance.new("Part")
	strap1.Size = Vector3.new(1.6, 0.1, 0.1)
	strap1.Color = Color3.fromRGB(60, 60, 60)
	strap1.Material = Enum.Material.Metal
	strap1.Anchored = true
	strap1.CanCollide = false
	strap1.CFrame = box.CFrame * CFrame.new(0, 0.3, 0)
	strap1.Parent = pickup

	local strap2 = Instance.new("Part")
	strap2.Size = Vector3.new(1.6, 0.1, 0.1)
	strap2.Color = Color3.fromRGB(60, 60, 60)
	strap2.Material = Enum.Material.Metal
	strap2.Anchored = true
	strap2.CanCollide = false
	strap2.CFrame = box.CFrame * CFrame.new(0, -0.3, 0)
	strap2.Parent = pickup

	-- Label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "AMMO\n+30"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard

	-- Spinning animation
	local rotation = 0
	local spawnTime = tick()
	local animConnection
	animConnection = RunService.Heartbeat:Connect(function(dt)
		if not pickup or not pickup.Parent then
			animConnection:Disconnect()
			return
		end

		rotation = rotation + (dt * 50)

		-- Bob up and down
		local bobOffset = math.sin(tick() * 2) * 0.3
		local baseCFrame = CFrame.new(position + Vector3.new(0, 1 + bobOffset, 0)) * CFrame.Angles(0, math.rad(rotation), 0)

		-- Update all parts
		box.CFrame = baseCFrame
		symbol1.CFrame = baseCFrame * CFrame.new(0.76, 0, 0)
		symbol2.CFrame = baseCFrame * CFrame.new(0.76, 0, 0)
		strap1.CFrame = baseCFrame * CFrame.new(0, 0.3, 0)
		strap2.CFrame = baseCFrame * CFrame.new(0, -0.3, 0)
	end)

	pickup.Parent = workspace

	-- Touch detection
	local collected = false
	box.Touched:Connect(function(hit)
		if collected then
			return
		end

		local char = hit.Parent
		if not char or not char:FindFirstChild("Humanoid") then
			return
		end

		local player = Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end

		-- Give ammo to player
		collected = true

		local gunData = playerGuns[player]
		if gunData then
			gunData.reserve = gunData.reserve + AMMO_AMOUNT
			AmmoUpdate:FireClient(player, gunData.ammo, gunData.reserve)
			print(player.Name .. " picked up ammo drop! Reserve: " .. gunData.reserve)
		end

		-- Remove pickup
		animConnection:Disconnect()
		pickup:Destroy()
	end)

	-- Auto-destroy after lifetime expires
	task.spawn(function()
		task.wait(PICKUP_LIFETIME)
		if pickup and pickup.Parent and not collected then
			animConnection:Disconnect()
			pickup:Destroy()
		end
	end)

	return pickup
end

-- Make function available globally for ZombieSpawner to call
_G.SpawnAmmoDrop = function(position)
	-- Random chance to drop
	if math.random() <= DROP_CHANCE then
		createAmmoPickup(position)
		return true
	end
	return false
end

print("AmmoPickups: Ready! Ammo will drop from zombies (5% chance)")
