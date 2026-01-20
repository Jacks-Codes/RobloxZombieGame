-- Round and Zombie Counter UI
print("RoundUI: Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local RoundUpdate = GameEvents:WaitForChild("RoundUpdate")
local ZombieCountUpdate = GameEvents:WaitForChild("ZombieCountUpdate")

-- Position/size constants
local CENTER_POS = UDim2.new(0.5, -200, 0.3, 0)
local CENTER_SIZE = UDim2.new(0, 400, 0, 120)
local CENTER_TEXT_SIZE = 48
local CENTER_ZOMBIE_SIZE = 28

local CORNER_POS = UDim2.new(1, -170, 0, 10)
local CORNER_SIZE = UDim2.new(0, 150, 0, 50)
local CORNER_TEXT_SIZE = 18
local CORNER_ZOMBIE_SIZE = 14

local DISPLAY_TIME = 7  -- Seconds to show big center display

-- Create UI
local screen = Instance.new("ScreenGui")
screen.Name = "RoundUI"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Round display frame (start in corner position but hidden)
local roundFrame = Instance.new("Frame")
roundFrame.Size = CORNER_SIZE
roundFrame.Position = CORNER_POS
roundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
roundFrame.BackgroundTransparency = 0.5
roundFrame.BorderSizePixel = 0
roundFrame.Visible = false
roundFrame.Parent = screen

local roundCorner = Instance.new("UICorner")
roundCorner.CornerRadius = UDim.new(0, 10)
roundCorner.Parent = roundFrame

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.Size = UDim2.new(1, 0, 0.55, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = "ROUND 1"
roundLabel.TextColor3 = Color3.new(1, 1, 1)
roundLabel.TextSize = CORNER_TEXT_SIZE
roundLabel.Font = Enum.Font.GothamBold
roundLabel.Parent = roundFrame

local zombieLabel = Instance.new("TextLabel")
zombieLabel.Name = "ZombieLabel"
zombieLabel.Size = UDim2.new(1, 0, 0.45, 0)
zombieLabel.Position = UDim2.new(0, 0, 0.55, 0)
zombieLabel.BackgroundTransparency = 1
zombieLabel.Text = "Zombies: 5"
zombieLabel.TextColor3 = Color3.new(0, 1, 0)
zombieLabel.TextSize = CORNER_ZOMBIE_SIZE
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

-- Track state
local moveToCornerThread = nil

-- Forward declare
local showCorner

-- Animate to center (big)
local function showCenter()
	print("RoundUI: Showing center")

	-- Cancel any pending corner animation
	if moveToCornerThread then
		task.cancel(moveToCornerThread)
		moveToCornerThread = nil
	end

	-- Reset to center position/size immediately (no tween in)
	roundFrame.Size = CENTER_SIZE
	roundFrame.Position = CENTER_POS
	roundLabel.TextSize = CENTER_TEXT_SIZE
	zombieLabel.TextSize = CENTER_ZOMBIE_SIZE
	roundFrame.Visible = true

	-- Schedule move to corner after DISPLAY_TIME seconds
	moveToCornerThread = task.delay(DISPLAY_TIME, function()
		print("RoundUI: Moving to corner")
		showCorner()
	end)
end

-- Animate to corner (small)
showCorner = function()
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	TweenService:Create(roundFrame, tweenInfo, {
		Size = CORNER_SIZE,
		Position = CORNER_POS
	}):Play()

	TweenService:Create(roundLabel, TweenInfo.new(0.8), {
		TextSize = CORNER_TEXT_SIZE
	}):Play()

	TweenService:Create(zombieLabel, TweenInfo.new(0.8), {
		TextSize = CORNER_ZOMBIE_SIZE
	}):Play()
end

-- Listen for round updates
RoundUpdate.OnClientEvent:Connect(function(data)
	local round = data.Round
	local zombies = data.Zombies
	local status = data.Status

	print("RoundUI: Received update - Round", round, "Status", status)

	if status == "Started" then
		roundLabel.Text = "ROUND " .. round
		zombieLabel.Text = "Zombies: " .. zombies
		intermissionFrame.Visible = false

		-- Show big center display
		showCenter()

	elseif status == "Ended" then
		-- Cancel corner animation if pending
		if moveToCornerThread then
			task.cancel(moveToCornerThread)
			moveToCornerThread = nil
		end

		-- Hide round frame during intermission
		roundFrame.Visible = false

		-- Show intermission
		intermissionFrame.Visible = true
		intermissionText.Text = "ROUND " .. round .. " COMPLETE!\n\nNext round starting soon..."
	end
end)

-- Listen for zombie count updates
ZombieCountUpdate.OnClientEvent:Connect(function(count)
	zombieLabel.Text = "Zombies: " .. count

	-- Change color when zombies are low
	if count <= 3 and count > 0 then
		zombieLabel.TextColor3 = Color3.new(1, 0.5, 0)
	elseif count == 0 then
		zombieLabel.TextColor3 = Color3.new(1, 1, 0)
	else
		zombieLabel.TextColor3 = Color3.new(0, 1, 0)
	end
end)

print("RoundUI: Ready!")
