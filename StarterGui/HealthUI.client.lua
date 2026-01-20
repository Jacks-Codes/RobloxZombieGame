-- Player Health UI
print("HealthUI: Loading...")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create UI
local screen = Instance.new("ScreenGui")
screen.Name = "HealthUI"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Health bar background
local healthBg = Instance.new("Frame")
healthBg.Size = UDim2.new(0, 300, 0, 30)
healthBg.Position = UDim2.new(0, 20, 1, -50)
healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
healthBg.BorderSizePixel = 0
healthBg.Parent = screen

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 8)
bgCorner.Parent = healthBg

-- Health bar fill
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = healthFill

-- Health text
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100 HP"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.TextSize = 18
healthText.Font = Enum.Font.GothamBold
healthText.TextStrokeTransparency = 0.5
healthText.Parent = healthBg

-- Current connection (to disconnect on respawn)
local healthConnection = nil

-- Update health display
local function updateHealth(humanoid)
	if not humanoid then return end

	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth
	local percent = math.clamp(health / maxHealth, 0, 1)

	healthFill.Size = UDim2.new(percent, 0, 1, 0)
	healthText.Text = math.ceil(health) .. " HP"

	-- Change color based on health
	if percent > 0.6 then
		healthFill.BackgroundColor3 = Color3.new(0, 1, 0)  -- Green
	elseif percent > 0.3 then
		healthFill.BackgroundColor3 = Color3.new(1, 1, 0)  -- Yellow
	else
		healthFill.BackgroundColor3 = Color3.new(1, 0, 0)  -- Red
	end
end

-- Setup health tracking for a character
local function setupCharacter(character)
	if not character then return end

	-- Disconnect old connection
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Connect to health changes
	healthConnection = humanoid.HealthChanged:Connect(function()
		updateHealth(humanoid)
	end)

	-- Initial update
	updateHealth(humanoid)
end

-- Handle current character
if player.Character then
	setupCharacter(player.Character)
end

-- Handle respawn
player.CharacterAdded:Connect(function(character)
	-- Small delay to ensure character is fully loaded
	task.wait(0.1)
	setupCharacter(character)
end)

print("HealthUI: Ready!")
