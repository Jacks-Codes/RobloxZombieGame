-- First-Person Camera System
print("Camera: Loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")

-- Camera settings
local sensitivity = 0.3
local angleX = 0
local angleY = 0

-- Movement offsets (set by Movement script)
_G.SlideCameraOffset = 0
_G.GrappleCameraTilt = 0
_G.IsGrappling = false

-- Smoothed camera position for grapple effect
local smoothedCameraPos = head.Position
local GRAPPLE_CAMERA_LAG = 0.15  -- How much camera lags behind (0-1, lower = more lag)
local GRAPPLE_CAMERA_BACK = 10   -- How far camera pulls back during grapple
local GRAPPLE_CAMERA_UP = 3      -- How much camera rises above player

-- Lock camera
camera.CameraType = Enum.CameraType.Scriptable
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false

-- Make character invisible to player (so it doesn't block view)
local function makeCharacterTransparent(char)
	for _, descendant in pairs(char:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name ~= "HumanoidRootPart" then
				descendant.LocalTransparencyModifier = 1
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.LocalTransparencyModifier = 1
		end
	end

	for _, child in pairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = 1
			end
		end
	end
end

-- Make character visible (for grapple)
local function makeCharacterVisible(char)
	for _, descendant in pairs(char:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 0
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.LocalTransparencyModifier = 0
		end
	end

	for _, child in pairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = 0
			end
		end
	end
end

makeCharacterTransparent(character)

-- Keep updating transparency (unless grappling)
RunService.Heartbeat:Connect(function()
	if character and character.Parent then
		if _G.IsGrappling then
			-- Show character during grapple
			makeCharacterVisible(character)
		else
			-- Hide character normally
			for _, descendant in pairs(character:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
					descendant.LocalTransparencyModifier = 1
				end
			end
		end
	end
end)

-- Mouse movement
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		angleY = angleY - input.Delta.X * sensitivity
		angleX = math.clamp(angleX - input.Delta.Y * sensitivity, -85, 85)
	end
end)

-- Update camera every frame
RunService.RenderStepped:Connect(function(dt)
	if character and character.Parent and head and head.Parent then
		local slideOffset = _G.SlideCameraOffset or 0
		local grappleTilt = _G.GrappleCameraTilt or 0
		local isGrappling = _G.IsGrappling or false

		local targetPos = head.Position + Vector3.new(0, -slideOffset, 0)

		if isGrappling then
			-- Smooth camera lag during grapple (follows player slowly)
			smoothedCameraPos = smoothedCameraPos:Lerp(targetPos, GRAPPLE_CAMERA_LAG)

			-- Third person camera behind and above player
			local camRotation = CFrame.Angles(0, math.rad(angleY), 0)

			-- Position camera behind player, up and back
			local backOffset = camRotation.LookVector * -GRAPPLE_CAMERA_BACK
			local cameraPos = smoothedCameraPos + backOffset + Vector3.new(0, GRAPPLE_CAMERA_UP, 0)

			-- Look at player (slightly above feet for better framing)
			local lookTarget = smoothedCameraPos + Vector3.new(0, -1, 0)
			camera.CFrame = CFrame.new(cameraPos, lookTarget)
		else
			-- Normal first-person camera
			smoothedCameraPos = targetPos
			camera.CFrame = CFrame.new(targetPos)
				* CFrame.Angles(0, math.rad(angleY), 0)
				* CFrame.Angles(math.rad(angleX + grappleTilt), 0, 0)
		end
	end
end)

-- Handle respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	head = character:WaitForChild("Head")
	angleX = 0
	angleY = 0
	_G.SlideCameraOffset = 0
	_G.GrappleCameraTilt = 0
	_G.IsGrappling = false
	smoothedCameraPos = head.Position
	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	task.wait(0.1)
	makeCharacterTransparent(newChar)
end)

print("✓ Camera active!")

-- Export for gun system
_G.GetCameraCFrame = function()
	return camera.CFrame
end
