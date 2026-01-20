-- Status message
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

wait(1)

local screen = Instance.new("ScreenGui")
screen.Parent = playerGui

local message = Instance.new("TextLabel")
message.Size = UDim2.new(0, 600, 0, 200)
message.Position = UDim2.new(0.5, -300, 0.5, -100)
message.BackgroundColor3 = Color3.new(0, 0, 0)
message.BackgroundTransparency = 0.3
message.TextColor3 = Color3.new(1, 1, 1)
message.TextSize = 20
message.Font = Enum.Font.GothamBold
message.Text = [[ZOMBIE SURVIVAL

Controls:
• Left Click = Shoot (25 dmg)
• R = Reload (30 mag / 90 reserve)
• Move with WASD

Features:
• Infinite rounds (harder each round!)
• Yellow ammo boxes spawn around map
• Zombies can jump & climb obstacles
• Gun model shows in first-person

Good luck!]]
message.TextWrapped = true
message.TextYAlignment = Enum.TextYAlignment.Top
message.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = message

-- Fade out after 8 seconds
task.wait(8)
for i = 0, 1, 0.1 do
	message.BackgroundTransparency = 0.3 + (i * 0.7)
	message.TextTransparency = i
	task.wait(0.05)
end
message:Destroy()
