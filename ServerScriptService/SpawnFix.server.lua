-- Spawn Fix - Collision and jump height
print("SpawnFix: Loading...")

local Players = game:GetService("Players")

-- Jump settings (default JumpPower is 50 = ~7.2 studs, 35 = ~5 studs)
local JUMP_POWER = 35

-- Enable collision on city parts
local function enableCityCollision()
	local cityMap = workspace:FindFirstChild("city map modified by RCarCrash")
	if cityMap then
		local count = 0
		for _, part in pairs(cityMap:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
				part.Anchored = true
				count = count + 1
			end
		end
		print("SpawnFix: Enabled collision on " .. count .. " city parts")
	else
		warn("SpawnFix: 'city map modified by RCarCrash' not found!")
	end
end

-- Set jump height for players
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.JumpPower = JUMP_POWER
		print("SpawnFix: Set " .. player.Name .. " jump power to " .. JUMP_POWER)
	end)
end

-- Run on startup
enableCityCollision()

-- Setup existing and new players
for _, player in pairs(Players:GetPlayers()) do
	setupPlayer(player)
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.JumpPower = JUMP_POWER
		end
	end
end
Players.PlayerAdded:Connect(setupPlayer)

print("SpawnFix: Ready! Jump power set to " .. JUMP_POWER .. " (~5 studs)")
