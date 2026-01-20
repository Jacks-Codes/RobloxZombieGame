-- Shooting UI - Crosshair, Ammo, Weapon Display, and Weapon Switching
print("ShootingUI: Loading...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local ShootGun = GameEvents:WaitForChild("ShootGun")
local AmmoUpdate = GameEvents:WaitForChild("AmmoUpdate")
local ReloadGun = GameEvents:WaitForChild("ReloadGun")

-- Wait for new events (created by server)
local WeaponUpdate = GameEvents:WaitForChild("WeaponUpdate", 10)
local SwitchWeapon = GameEvents:WaitForChild("SwitchWeapon", 10)
local MeleeAttack = GameEvents:WaitForChild("MeleeAttack", 10)

-- Current weapon state
local currentWeaponIndex = 2  -- Start with pistol
local currentWeaponName = "Pistol"
local currentWeaponType = "gun"
local playerKills = 0
local nextUnlockInfo = nil

-- Weapon key mappings
local weaponKeys = {
	[Enum.KeyCode.One] = 1,    -- Knife
	[Enum.KeyCode.Two] = 2,    -- Pistol
	[Enum.KeyCode.Three] = 3,  -- SMG
	[Enum.KeyCode.Four] = 4,   -- Shotgun
	[Enum.KeyCode.Five] = 5,   -- Rifle
	[Enum.KeyCode.Six] = 6,    -- LMG
}

local weaponNames = {"Knife", "Pistol", "SMG", "Shotgun", "Rifle", "LMG"}
local weaponUnlocks = {0, 0, 20, 50, 100, 200}

-- Create UI
local screen = Instance.new("ScreenGui")
screen.Name = "GameUI"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Crosshair
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 30, 0, 30)
crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
crosshair.BackgroundTransparency = 1
crosshair.Parent = screen

local crosshairH = Instance.new("Frame")
crosshairH.Size = UDim2.new(0, 20, 0, 2)
crosshairH.Position = UDim2.new(0.5, -10, 0.5, -1)
crosshairH.BackgroundColor3 = Color3.new(1, 1, 1)
crosshairH.BorderSizePixel = 0
crosshairH.Parent = crosshair

local crosshairV = Instance.new("Frame")
crosshairV.Size = UDim2.new(0, 2, 0, 20)
crosshairV.Position = UDim2.new(0.5, -1, 0.5, -10)
crosshairV.BackgroundColor3 = Color3.new(1, 1, 1)
crosshairV.BorderSizePixel = 0
crosshairV.Parent = crosshair

-- Muzzle flash effect
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.new(1, 0.8, 0)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 10
flashFrame.Parent = screen

-- Ammo display (bottom right)
local ammoFrame = Instance.new("Frame")
ammoFrame.Size = UDim2.new(0, 180, 0, 80)
ammoFrame.Position = UDim2.new(1, -200, 1, -100)
ammoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ammoFrame.BackgroundTransparency = 0.5
ammoFrame.BorderSizePixel = 0
ammoFrame.Parent = screen

local ammoCorner = Instance.new("UICorner")
ammoCorner.CornerRadius = UDim.new(0, 8)
ammoCorner.Parent = ammoFrame

-- Weapon name label
local weaponLabel = Instance.new("TextLabel")
weaponLabel.Size = UDim2.new(1, 0, 0, 20)
weaponLabel.Position = UDim2.new(0, 0, 0, 5)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Text = "PISTOL"
weaponLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
weaponLabel.TextSize = 16
weaponLabel.Font = Enum.Font.GothamBold
weaponLabel.Parent = ammoFrame

-- Ammo text (large)
local ammoText = Instance.new("TextLabel")
ammoText.Size = UDim2.new(1, -10, 0, 35)
ammoText.Position = UDim2.new(0, 0, 0, 25)
ammoText.BackgroundTransparency = 1
ammoText.Text = "12"
ammoText.TextColor3 = Color3.new(1, 1, 1)
ammoText.TextSize = 32
ammoText.Font = Enum.Font.GothamBold
ammoText.TextXAlignment = Enum.TextXAlignment.Right
ammoText.Parent = ammoFrame

-- Reserve text
local reserveText = Instance.new("TextLabel")
reserveText.Size = UDim2.new(1, -10, 0, 20)
reserveText.Position = UDim2.new(0, 0, 0, 55)
reserveText.BackgroundTransparency = 1
reserveText.Text = "36"
reserveText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
reserveText.TextSize = 16
reserveText.Font = Enum.Font.Gotham
reserveText.TextXAlignment = Enum.TextXAlignment.Right
reserveText.Parent = ammoFrame

-- Kill counter and unlock progress (bottom left)
local killFrame = Instance.new("Frame")
killFrame.Size = UDim2.new(0, 200, 0, 60)
killFrame.Position = UDim2.new(0, 20, 1, -80)
killFrame.BackgroundColor3 = Color3.new(0, 0, 0)
killFrame.BackgroundTransparency = 0.5
killFrame.BorderSizePixel = 0
killFrame.Parent = screen

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 8)
killCorner.Parent = killFrame

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(1, 0, 0, 25)
killLabel.Position = UDim2.new(0, 0, 0, 5)
killLabel.BackgroundTransparency = 1
killLabel.Text = "KILLS: 0"
killLabel.TextColor3 = Color3.new(1, 1, 1)
killLabel.TextSize = 20
killLabel.Font = Enum.Font.GothamBold
killLabel.Parent = killFrame

local unlockLabel = Instance.new("TextLabel")
unlockLabel.Size = UDim2.new(1, -10, 0, 25)
unlockLabel.Position = UDim2.new(0, 5, 0, 30)
unlockLabel.BackgroundTransparency = 1
unlockLabel.Text = "Next: SMG (20 kills)"
unlockLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
unlockLabel.TextSize = 14
unlockLabel.Font = Enum.Font.Gotham
unlockLabel.TextXAlignment = Enum.TextXAlignment.Left
unlockLabel.Parent = killFrame

-- Weapon slots (top of screen)
local weaponSlotsFrame = Instance.new("Frame")
weaponSlotsFrame.Size = UDim2.new(0, 360, 0, 50)
weaponSlotsFrame.Position = UDim2.new(0.5, -180, 0, 10)
weaponSlotsFrame.BackgroundTransparency = 1
weaponSlotsFrame.Parent = screen

local weaponSlots = {}
for i = 1, 6 do
	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(0, 55, 0, 45)
	slot.Position = UDim2.new(0, (i-1) * 60, 0, 0)
	slot.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	slot.BackgroundTransparency = 0.5
	slot.BorderSizePixel = 0
	slot.Parent = weaponSlotsFrame

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot

	-- Key number
	local keyNum = Instance.new("TextLabel")
	keyNum.Size = UDim2.new(0, 15, 0, 15)
	keyNum.Position = UDim2.new(0, 3, 0, 2)
	keyNum.BackgroundTransparency = 1
	keyNum.Text = tostring(i)
	keyNum.TextColor3 = Color3.new(0.6, 0.6, 0.6)
	keyNum.TextSize = 12
	keyNum.Font = Enum.Font.GothamBold
	keyNum.Parent = slot

	-- Weapon name
	local slotName = Instance.new("TextLabel")
	slotName.Name = "WeaponName"
	slotName.Size = UDim2.new(1, 0, 0, 20)
	slotName.Position = UDim2.new(0, 0, 0, 15)
	slotName.BackgroundTransparency = 1
	slotName.Text = weaponNames[i]
	slotName.TextColor3 = Color3.new(1, 1, 1)
	slotName.TextSize = 11
	slotName.Font = Enum.Font.GothamBold
	slotName.Parent = slot

	-- Lock indicator
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockLabel"
	lockLabel.Size = UDim2.new(1, 0, 0, 12)
	lockLabel.Position = UDim2.new(0, 0, 1, -14)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Text = weaponUnlocks[i] > 0 and tostring(weaponUnlocks[i]) or ""
	lockLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
	lockLabel.TextSize = 10
	lockLabel.Font = Enum.Font.Gotham
	lockLabel.Parent = slot

	weaponSlots[i] = slot
end

-- Update weapon slots UI
local function updateWeaponSlots()
	for i, slot in ipairs(weaponSlots) do
		local isUnlocked = playerKills >= weaponUnlocks[i]
		local isSelected = i == currentWeaponIndex

		if isSelected then
			slot.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
			slot.BackgroundTransparency = 0.3
		elseif isUnlocked then
			slot.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
			slot.BackgroundTransparency = 0.5
		else
			slot.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
			slot.BackgroundTransparency = 0.7
		end

		local nameLabel = slot:FindFirstChild("WeaponName")
		local lockLabel = slot:FindFirstChild("LockLabel")

		if nameLabel then
			nameLabel.TextColor3 = isUnlocked and Color3.new(1, 1, 1) or Color3.new(0.4, 0.4, 0.4)
		end

		if lockLabel then
			if isUnlocked then
				lockLabel.Text = ""
			else
				lockLabel.Text = weaponUnlocks[i] .. " kills"
				lockLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
			end
		end
	end
end

-- Visual feedback function
local function showShootEffect()
	flashFrame.BackgroundTransparency = 0.9
	TweenService:Create(flashFrame, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()

	crosshairH.BackgroundColor3 = Color3.new(1, 1, 0)
	crosshairV.BackgroundColor3 = Color3.new(1, 1, 0)
	task.wait(0.05)
	crosshairH.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshairV.BackgroundColor3 = Color3.new(1, 1, 1)
end

-- Melee visual feedback
local function showMeleeEffect()
	crosshairH.BackgroundColor3 = Color3.new(1, 0.5, 0)
	crosshairV.BackgroundColor3 = Color3.new(1, 0.5, 0)

	-- Quick swipe effect
	local originalSize = crosshairH.Size
	crosshairH.Size = UDim2.new(0, 40, 0, 3)
	task.wait(0.1)
	crosshairH.Size = originalSize
	crosshairH.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshairV.BackgroundColor3 = Color3.new(1, 1, 1)
end

-- Shooting / Melee
local canShoot = true
local shootCooldown = 0.1
local meleeCooldown = 0.5

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Shooting / Melee attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 and canShoot then
		canShoot = false

		local cameraCFrame = _G.GetCameraCFrame and _G.GetCameraCFrame() or workspace.CurrentCamera.CFrame

		if currentWeaponType == "melee" then
			-- Melee attack
			if MeleeAttack then
				MeleeAttack:FireServer(cameraCFrame)
			end
			showMeleeEffect()
			task.wait(meleeCooldown)
		else
			-- Gun shot
			ShootGun:FireServer(cameraCFrame)
			showShootEffect()
			task.wait(shootCooldown)
		end

		canShoot = true
	end

	-- Reload
	if input.KeyCode == Enum.KeyCode.R then
		if currentWeaponType == "gun" then
			ReloadGun:FireServer()
			print("Reloading...")
		end
	end

	-- Weapon switching (number keys 1-6)
	local weaponIndex = weaponKeys[input.KeyCode]
	if weaponIndex and SwitchWeapon then
		-- Check if unlocked locally first (for responsiveness)
		if playerKills >= weaponUnlocks[weaponIndex] then
			SwitchWeapon:FireServer(weaponIndex)
		else
			print("Need " .. weaponUnlocks[weaponIndex] .. " kills to unlock " .. weaponNames[weaponIndex])
		end
	end
end)

-- Update ammo display
AmmoUpdate.OnClientEvent:Connect(function(current, reserve)
	if currentWeaponType == "melee" then
		ammoText.Text = "--"
		reserveText.Text = "melee"
	else
		ammoText.Text = tostring(current)
		reserveText.Text = tostring(reserve)

		if current <= 5 then
			ammoText.TextColor3 = Color3.new(1, 0.3, 0.3)
		else
			ammoText.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end)

-- Update weapon info
if WeaponUpdate then
	WeaponUpdate.OnClientEvent:Connect(function(data)
		currentWeaponIndex = data.weaponIndex
		currentWeaponName = data.weaponName
		playerKills = data.kills
		nextUnlockInfo = data.nextUnlock

		-- Determine weapon type
		currentWeaponType = (currentWeaponIndex == 1) and "melee" or "gun"

		-- Update UI
		weaponLabel.Text = string.upper(currentWeaponName)
		killLabel.Text = "KILLS: " .. playerKills

		if nextUnlockInfo then
			unlockLabel.Text = "Next: " .. nextUnlockInfo.weapon.name .. " (" .. nextUnlockInfo.weapon.killsRequired .. " kills)"
			unlockLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
		else
			unlockLabel.Text = "All weapons unlocked!"
			unlockLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		end

		-- Update ammo display for melee
		if currentWeaponType == "melee" then
			ammoText.Text = "--"
			reserveText.Text = "melee"
		end

		updateWeaponSlots()
	end)
end

-- Initialize weapon slots
updateWeaponSlots()

print("ShootingUI: Ready!")
print("  LMB: Shoot/Attack")
print("  R: Reload")
print("  1-6: Switch weapons")
