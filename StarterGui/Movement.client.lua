-- Sprint, Slide, and Grapple Movement System
print("Movement: Loading...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--============================================
-- MOVEMENT SETTINGS
--============================================
local WALK_SPEED = 16
local SPRINT_SPEED = 28
local SLIDE_SPEED = 40
local SLIDE_DURATION = 0.6
local SLIDE_COOLDOWN = 0.3
local SLIDE_CAMERA_DROP = 2

-- Grapple settings
local GRAPPLE_KEY = Enum.KeyCode.E
local GRAPPLE_RANGE = 30        -- Max distance to grapple
local GRAPPLE_MIN_HEIGHT = 2    -- Min height to grapple a ledge
local GRAPPLE_MAX_HEIGHT = 10   -- Max height above player
local GRAPPLE_SPEED = 12        -- How fast you pull (slow, like pulling yourself up)
local GRAPPLE_COOLDOWN = 0.5    -- Seconds between grapples
local GRAPPLE_HANG_OFFSET = 1.5 -- How far below the ledge to hang

-- Slide settings
local SLIDE_SPEED_THRESHOLD = 20  -- Must be moving this fast to slide (requires sprinting)
--============================================

local isSprinting = false
local isSliding = false
local canSlide = true
local isGrappling = false
local canGrapple = true

-- Sprint
local function startSprint()
	if isSliding or isGrappling then return end
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		isSprinting = true
		humanoid.WalkSpeed = SPRINT_SPEED
	end
end

local function stopSprint()
	if isSliding or isGrappling then return end
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		isSprinting = false
		humanoid.WalkSpeed = WALK_SPEED
	end
end

-- Slide
local function doSlide()
	if isSliding or not canSlide or isGrappling then return end

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Must be sprinting (check speed threshold)
	local currentSpeed = rootPart.AssemblyLinearVelocity.Magnitude
	if currentSpeed < SLIDE_SPEED_THRESHOLD then
		print("Must be sprinting to slide! (speed: " .. math.floor(currentSpeed) .. ")")
		return
	end

	print("SLIDING! Speed: " .. math.floor(currentSpeed))
	isSliding = true
	canSlide = false

	humanoid.WalkSpeed = SLIDE_SPEED
	_G.SlideCameraOffset = SLIDE_CAMERA_DROP

	task.delay(SLIDE_DURATION, function()
		isSliding = false
		_G.SlideCameraOffset = 0

		if humanoid then
			if isSprinting then
				humanoid.WalkSpeed = SPRINT_SPEED
			else
				humanoid.WalkSpeed = WALK_SPEED
			end
		end

		task.delay(SLIDE_COOLDOWN, function()
			canSlide = true
		end)
	end)
end

-- Grapple
local function doGrapple()
	if isGrappling or not canGrapple or isSliding then return end

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Raycast in camera direction to find grapple point
	local camCFrame = camera.CFrame
	local rayOrigin = rootPart.Position
	local rayDirection = camCFrame.LookVector * GRAPPLE_RANGE

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	if not result then
		print("No grapple point - jumping!")
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid.Jump = true
		end
		return
	end

	local hitPart = result.Instance
	if not hitPart or not hitPart:IsA("BasePart") then
		return
	end

	-- Check if platform is wide enough to stand on (at least 2 studs)
	local partSize = hitPart.Size
	local minSize = math.min(partSize.X, partSize.Z)
	if minSize < 2 then
		print("Platform too small to grapple to! (size: " .. math.floor(minSize) .. ")")
		return
	end

	-- Find top of the ledge by raycasting down from above the hit point
	local toPlayer = (rootPart.Position - result.Position).Unit
	local ledgeCheckOrigin = result.Position + Vector3.new(0, GRAPPLE_MAX_HEIGHT + 4, 0) + toPlayer * 2
	local ledgeCheckDir = Vector3.new(0, -(GRAPPLE_MAX_HEIGHT + 8), 0)

	local ledgeParams = RaycastParams.new()
	ledgeParams.FilterDescendantsInstances = {char}
	ledgeParams.FilterType = Enum.RaycastFilterType.Exclude

	local ledgeHit = workspace:Raycast(ledgeCheckOrigin, ledgeCheckDir, ledgeParams)
	if not ledgeHit or ledgeHit.Normal.Y < 0.5 then
		print("No valid ledge top found")
		return
	end

	local ledgeTop = ledgeHit.Position
	local heightDiff = ledgeTop.Y - rootPart.Position.Y

	if heightDiff < GRAPPLE_MIN_HEIGHT then
		print("Too low to grapple (" .. math.floor(heightDiff) .. " studs)")
		return
	end

	if heightDiff > GRAPPLE_MAX_HEIGHT then
		print("Too high to grapple! (" .. math.floor(heightDiff) .. " studs up, max is " .. GRAPPLE_MAX_HEIGHT .. ")")
		return
	end

	-- Determine pull direction (onto the platform)
	local wallNormal = result.Normal
	local horizontalForward
	if math.abs(wallNormal.Y) < 0.5 then
		horizontalForward = Vector3.new(-wallNormal.X, 0, -wallNormal.Z).Unit
	else
		local camForward = camera.CFrame.LookVector
		horizontalForward = Vector3.new(camForward.X, 0, camForward.Z).Unit
	end

	-- Positions for hang and pull-up
	local hangPosition = ledgeTop + Vector3.new(0, -GRAPPLE_HANG_OFFSET, 0) - horizontalForward * 0.5
	local standPosition = ledgeTop + Vector3.new(0, 2.5, 0) + horizontalForward * 2

	-- Check for space to stand on top
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {char}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local clearanceBox = workspace:GetPartBoundsInBox(CFrame.new(standPosition), Vector3.new(3, 5, 3), overlapParams)
	if #clearanceBox > 0 then
		print("Not enough clearance to pull up")
		return
	end

	print("GRAPPLING! Height: " .. math.floor(heightDiff))
	isGrappling = true
	canGrapple = false

	-- Disable normal movement during grapple
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

	-- Camera effects - pull back and tilt
	_G.IsGrappling = true
	_G.GrappleCameraTilt = -15

	-- Smooth align for hang + pull-up
	local attachment = Instance.new("Attachment")
	attachment.Name = "GrappleAttachment"
	attachment.Parent = rootPart

	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = "GrappleAlignPosition"
	alignPos.Attachment0 = attachment
	alignPos.Responsiveness = 35
	alignPos.MaxForce = 50000
	alignPos.Position = hangPosition
	alignPos.Parent = rootPart

	local alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "GrappleAlignOrientation"
	alignOri.Attachment0 = attachment
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Responsiveness = 20
	alignOri.MaxTorque = 50000
	alignOri.CFrame = CFrame.lookAt(Vector3.new(), -horizontalForward)
	alignOri.Parent = rootPart

	-- Wait to reach hang position
	local startTime = tick()
	while (rootPart.Position - hangPosition).Magnitude > 1 and tick() - startTime < 0.5 do
		RunService.Heartbeat:Wait()
	end

	-- Pull up to stand position
	alignPos.Position = standPosition
	startTime = tick()
	while (rootPart.Position - standPosition).Magnitude > 1.5 and tick() - startTime < 0.6 do
		RunService.Heartbeat:Wait()
	end

	-- Cleanup
	alignPos:Destroy()
	alignOri:Destroy()
	attachment:Destroy()

	isGrappling = false
	_G.IsGrappling = false
	_G.GrappleCameraTilt = 0
	humanoid.AutoRotate = true
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	if isSprinting then
		humanoid.WalkSpeed = SPRINT_SPEED
	else
		humanoid.WalkSpeed = WALK_SPEED
	end

	task.delay(GRAPPLE_COOLDOWN, function()
		canGrapple = true
	end)
end

-- Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		startSprint()
	elseif input.KeyCode == Enum.KeyCode.C then
		doSlide()
	elseif input.KeyCode == GRAPPLE_KEY then
		doGrapple()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		stopSprint()
	end
end)

-- Reset on respawn
player.CharacterAdded:Connect(function(char)
	isSprinting = false
	isSliding = false
	isGrappling = false
	canSlide = true
	canGrapple = true
	_G.SlideCameraOffset = 0
	_G.GrappleCameraTilt = 0
	_G.IsGrappling = false
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = WALK_SPEED
end)

print("Movement: Ready!")
print("  Sprint: Hold Shift")
print("  Slide: Press C")
print("  Grapple: Press E (aim at surface)")
