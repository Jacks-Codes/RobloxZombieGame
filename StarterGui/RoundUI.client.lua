-- Round and Zombie Counter UI
print("RoundUI: Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local RoundUpdate = GameEvents:WaitForChild("RoundUpdate")
local ZombieCountUpdate = GameEvents:WaitForChild("ZombieCountUpdate")

-- Create UI
local screen = Instance.new("ScreenGui")
screen.Name = "RoundUI"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Round display (top center)
local roundFrame = Instance.new("Frame")
roundFrame.Size = UDim2.new(0, 250, 0, 80)
roundFrame.Position = UDim2.new(0.5, -125, 0, 100)
roundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
roundFrame.BackgroundTransparency = 0.5
roundFrame.BorderSizePixel = 0
roundFrame.Parent = screen

local roundCorner = Instance.new("UICorner")
roundCorner.CornerRadius = UDim.new(0, 10)
roundCorner.Parent = roundFrame

local roundLabel = Instance.new("TextLabel")
roundLabel.Size = UDim2.new(1, 0, 0.5, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = "ROUND 1"
roundLabel.TextColor3 = Color3.new(1, 1, 1)
roundLabel.TextSize = 32
roundLabel.Font = Enum.Font.GothamBold
roundLabel.Parent = roundFrame

local zombieLabel = Instance.new("TextLabel")
zombieLabel.Size = UDim2.new(1, 0, 0.5, 0)
zombieLabel.Position = UDim2.new(0, 0, 0.5, 0)
zombieLabel.BackgroundTransparency = 1
zombieLabel.Text = "Zombies: 5"
zombieLabel.TextColor3 = Color3.new(0, 1, 0)
zombieLabel.TextSize = 24
zombieLabel.Font = Enum.Font.Gotham
zombieLabel.Parent = roundFrame

-- Intermission display
local intermissionFrame = Instance.new("Frame")
intermissionFrame.Size = UDim2.new(0, 400, 0, 100)
intermissionFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
intermissionFrame.BackgroundColor3 = Color3.new(0, 0.5, 0)
intermissionFrame.BackgroundTransparency = 0.3
intermissionFrame.BorderSizePixel = 0
intermissionFrame.Visible = false
intermissionFrame.Parent = screen

local intermissionCorner = Instance.new("UICorner")
intermissionCorner.CornerRadius = UDim.new(0, 10)
intermissionCorner.Parent = intermissionFrame

local intermissionText = Instance.new("TextLabel")
intermissionText.Size = UDim2.new(1, 0, 1, 0)
intermissionText.BackgroundTransparency = 1
intermissionText.Text = "ROUND COMPLETE!"
intermissionText.TextColor3 = Color3.new(1, 1, 1)
intermissionText.TextSize = 36
intermissionText.Font = Enum.Font.GothamBold
intermissionText.TextWrapped = true
intermissionText.Parent = intermissionFrame

-- Listen for round updates
RoundUpdate.OnClientEvent:Connect(function(data)
	local round = data.Round
	local zombies = data.Zombies
	local status = data.Status

	if status == "Started" then
		roundLabel.Text = "ROUND " .. round
		zombieLabel.Text = "Zombies: " .. zombies
		intermissionFrame.Visible = false
		roundFrame.Visible = true

		print("Round " .. round .. " started!")
	elseif status == "Ended" then
		intermissionFrame.Visible = true
		intermissionText.Text = "ROUND " .. round .. " COMPLETE!\n\nNext round starting soon..."

		print("Round " .. round .. " ended!")
	end
end)

-- Listen for zombie count updates
ZombieCountUpdate.OnClientEvent:Connect(function(count)
	zombieLabel.Text = "Zombies: " .. count

	-- Flash red when zombies are low
	if count <= 3 and count > 0 then
		zombieLabel.TextColor3 = Color3.new(1, 0.5, 0)
	elseif count == 0 then
		zombieLabel.TextColor3 = Color3.new(1, 1, 0)
	else
		zombieLabel.TextColor3 = Color3.new(0, 1, 0)
	end
end)

print("✓ Round UI ready!")
