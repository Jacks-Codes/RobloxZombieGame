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
local GRAPPLE_MIN_HEIGHT = 6    -- Min height to grapple (below this, just jump)
local GRAPPLE_MAX_HEIGHT = 10   -- Max height above player
local GRAPPLE_SPEED = 12        -- How fast you pull (slow, like pulling yourself up)
local GRAPPLE_COOLDOWN = 0.5    -- Seconds between grapples

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

	if result then
		-- Found a grapple point!
		local grapplePoint = result.Position
		local distance = (grapplePoint - rootPart.Position).Magnitude
		local heightDiff = grapplePoint.Y - rootPart.Position.Y

		-- Check if target is too low (just jump instead)
		if heightDiff < GRAPPLE_MIN_HEIGHT then
			print("Too low to grapple (" .. math.floor(heightDiff) .. " studs) - jumping!")
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid.Jump = true
			end
			return
		end

		-- Check if target is too high
		if heightDiff > GRAPPLE_MAX_HEIGHT then
			print("Too high to grapple! (" .. math.floor(heightDiff) .. " studs up, max is " .. GRAPPLE_MAX_HEIGHT .. ")")
			-- Just jump instead
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid.Jump = true
			end
			return
		end

		-- Check if platform is wide enough to stand on (at least 2 studs)
		local hitPart = result.Instance
		if hitPart and hitPart:IsA("BasePart") then
			local partSize = hitPart.Size
			local minSize = math.min(partSize.X, partSize.Z)
			if minSize < 2 then
				print("Platform too small to grapple to! (size: " .. math.floor(minSize) .. ")")
				if humanoid.FloorMaterial ~= Enum.Material.Air then
					humanoid.Jump = true
				end
				return
			end
		end

		-- Calculate landing point ABOVE the ledge (so we land on top)
		local landingPoint = grapplePoint + Vector3.new(0, 3, 0)  -- 3 studs above hit point

		-- Also move slightly forward onto the platform
		local forwardDir = (grapplePoint - rootPart.Position)
		forwardDir = Vector3.new(forwardDir.X, 0, forwardDir.Z).Unit
		landingPoint = landingPoint + forwardDir * 2  -- 2 studs forward onto platform

		print("GRAPPLING! Distance: " .. math.floor(distance) .. ", Height: " .. math.floor(heightDiff))
		isGrappling = true
		canGrapple = false

		-- Disable normal movement during grapple
		humanoid.WalkSpeed = 0

		-- Camera effects - pull back and tilt
		_G.IsGrappling = true
		_G.GrappleCameraTilt = -15

		-- Create pull force
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "GrappleForce"
		bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		bodyVelocity.Parent = rootPart

		-- Pull toward landing point (above the ledge)
		local startTime = tick()
		local totalDistance = (landingPoint - rootPart.Position).Magnitude
		local maxGrappleTime = totalDistance / GRAPPLE_SPEED + 1

		local grappleConnection
		grappleConnection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			local currentPos = rootPart.Position
			local toTarget = landingPoint - currentPos
			local currentDistance = toTarget.Magnitude

			-- Check if reached landing point or timed out
			if currentDistance < 2 or elapsed > maxGrappleTime then
				-- End grapple
				grappleConnection:Disconnect()
				bodyVelocity:Destroy()

				isGrappling = false
				_G.IsGrappling = false
				_G.GrappleCameraTilt = 0

				-- Final boost forward and up to land on platform
				rootPart.AssemblyLinearVelocity = Vector3.new(
					forwardDir.X * 10,
					5,
					forwardDir.Z * 10
				)

				-- Restore speed
				if isSprinting then
					humanoid.WalkSpeed = SPRINT_SPEED
				else
					humanoid.WalkSpeed = WALK_SPEED
				end

				-- Cooldown
				task.delay(GRAPPLE_COOLDOWN, function()
					canGrapple = true
				end)
				return
			end

			-- Pull toward landing point
			local direction = toTarget.Unit
			bodyVelocity.Velocity = direction * GRAPPLE_SPEED

			-- Camera tilt based on progress
			local progress = 1 - (currentDistance / totalDistance)
			_G.GrappleCameraTilt = -15 + (progress * 20)
		end)
	else
		-- No grapple point found - just jump
		print("No grapple point - jumping!")
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid.Jump = true
		end
	end
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
