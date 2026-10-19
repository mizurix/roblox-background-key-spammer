local success, errorMessage = pcall(function()
local LOAD_DELAY = 10

do
	local PlayersSvc = game:GetService("Players")
	local CoreGuiSvc = game:GetService("CoreGui")

	for _, name in ipairs({ "AutoShadowRaidLoader" }) do
		local old = CoreGuiSvc:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local loaderGui = Instance.new("ScreenGui")
	loaderGui.Name = "AutoShadowRaidLoader"
	loaderGui.ResetOnSpawn = false
	loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function()
		loaderGui.Parent = CoreGuiSvc
	end)
	if not loaderGui.Parent then
		repeat
			task.wait()
		until PlayersSvc.LocalPlayer
		loaderGui.Parent = PlayersSvc.LocalPlayer:WaitForChild("PlayerGui")
	end

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(280, 86)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 24)
	box.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	box.BorderSizePixel = 0
	box.Parent = loaderGui
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(48, 53, 66)
	boxStroke.Thickness = 1

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -28, 0, 20)
	title.Position = UDim2.fromOffset(14, 12)
	title.BackgroundTransparency = 1
	title.Text = "Auto Shadow Raid (Undetected)"
	title.TextColor3 = Color3.fromRGB(236, 238, 242)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = box

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -28, 0, 18)
	info.Position = UDim2.fromOffset(14, 34)
	info.BackgroundTransparency = 1
	info.Text = ""
	info.TextColor3 = Color3.fromRGB(137, 145, 161)
	info.Font = Enum.Font.GothamMedium
	info.TextSize = 13
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Parent = box

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -28, 0, 6)
	track.Position = UDim2.fromOffset(14, 62)
	track.BackgroundColor3 = Color3.fromRGB(38, 42, 53)
	track.BorderSizePixel = 0
	track.Parent = box
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

	local startTime = os.clock()
	while true do
		local elapsed = os.clock() - startTime
		if elapsed >= LOAD_DELAY then
			break
		end
		local remaining = math.ceil(LOAD_DELAY - elapsed)
		info.Text = string.format("Loading...  script starts in %ds", remaining)
		fill.Size = UDim2.new(math.clamp(elapsed / LOAD_DELAY, 0, 1), 0, 1, 0)
		task.wait(0.05)
	end

	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(52, 168, 110)
	info.Text = "Loaded!"
	info.TextColor3 = Color3.fromRGB(52, 168, 110)
	task.delay(0.8, function()
		loaderGui:Destroy()
	end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local vim = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local CONFIG_FILE = "AutoShadowRaid_Config.json"

local THEME = {
	Background = Color3.fromRGB(18, 20, 26),
	Panel = Color3.fromRGB(26, 29, 37),
	Key = Color3.fromRGB(38, 42, 53),
	Stroke = Color3.fromRGB(48, 53, 66),
	Text = Color3.fromRGB(236, 238, 242),
	Muted = Color3.fromRGB(137, 145, 161),
	Accent = Color3.fromRGB(88, 101, 242),
	Green = Color3.fromRGB(52, 168, 110),
	Red = Color3.fromRGB(214, 68, 74),
	Amber = Color3.fromRGB(235, 168, 52),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(obj, props)
	TweenService:Create(obj, TWEEN_FAST, props):Play()
end

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	})
end

local baseColors = {}

local function setBase(btn, color)
	baseColors[btn] = color
	tween(btn, { BackgroundColor3 = color })
end

local function makeButton(props)
	local btn = create("TextButton", {
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		BackgroundColor3 = props.Color,
		AutoButtonColor = false,
		Text = props.Text or "",
		TextColor3 = props.TextColor or THEME.Text,
		Font = props.Font or Enum.Font.GothamMedium,
		TextSize = props.TextSize or 14,
		LayoutOrder = props.LayoutOrder or 0,
		BorderSizePixel = 0,
	}, { corner(props.Radius or 8) })

	baseColors[btn] = props.Color

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = baseColors[btn]:Lerp(Color3.new(1, 1, 1), 0.12) })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = baseColors[btn] })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, { BackgroundColor3 = baseColors[btn]:Lerp(Color3.new(0, 0, 0), 0.15) })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, { BackgroundColor3 = baseColors[btn]:Lerp(Color3.new(1, 1, 1), 0.12) })
	end)

	return btn
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local SPAM_KEY = Enum.KeyCode.Q

local toggle = false
local loopRunning = false
local flashing = false
local spamEnabled = false
local clickEnabled = false
local clickInterval = 0.1
local clickLoopRunning = false

local isInClickRange = function()
	return true
end

local walkEnabled = false
local nearTarget = false

local WALK = {
	FolderName = "enemies",
	MaxDistance = 1500,
	StopDistance = 4,
	KeyStopDistance = 6,
	KeyResumeDistance = 9,
	RecalculateDelay = 0.3,
	WaypointReach = 3,
	ClickRange = 8,
	FixAnimation = true,
	RunAnimationId = "rbxassetid://129902810960575",
	ImmuneMarker = "OathBeamTo",
}

local function isImmune(enemy)
	return WALK.ImmuneMarker ~= nil and enemy:FindFirstChild(WALK.ImmuneMarker, true) ~= nil
end

local INTERVAL_MIN = 0.01
local INTERVAL_MAX = 2

local function doClick()
	local remote = ReplicatedStorage:FindFirstChild("performM1")
	if not remote then
		error("performM1 remote not found in ReplicatedStorage")
	end
	remote:FireServer()
end

for _, name in ipairs({ "AutoShadowRaidGui", "MultiKeySpammerGui" }) do
	local old = CoreGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local screenGui = create("ScreenGui", {
	Name = "AutoShadowRaidGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function()
	screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local mainFrame = create("Frame", {
	Name = "MainFrame",
	Size = UDim2.fromOffset(280, 300),
	Position = UDim2.new(0, 20, 0, 20),
	BackgroundColor3 = THEME.Background,
	BorderSizePixel = 0,
	Parent = screenGui,
}, { corner(12), stroke(THEME.Stroke, 1) })

local mainHeader = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundTransparency = 1,
	Parent = mainFrame,
}, { padding(0, 14, 0, 14) })

create("Frame", {
	Name = "AccentDot",
	Size = UDim2.fromOffset(8, 8),
	Position = UDim2.new(0, 0, 0.5, -4),
	BackgroundColor3 = THEME.Accent,
	BorderSizePixel = 0,
	Parent = mainHeader,
}, { corner(4) })

create("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1,
	Text = "Auto Shadow Raid (Undetected)",
	TextColor3 = THEME.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = mainHeader,
})

create("Frame", {
	Name = "Divider",
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.fromOffset(12, 38),
	BackgroundColor3 = THEME.Stroke,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

local mainBody = create("Frame", {
	Name = "Body",
	Size = UDim2.new(1, 0, 1, -39),
	Position = UDim2.fromOffset(0, 39),
	BackgroundTransparency = 1,
	Parent = mainFrame,
}, {
	padding(12, 14, 14, 14),
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local statusRow = create("Frame", {
	Name = "StatusRow",
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	LayoutOrder = 1,
	Parent = mainBody,
})

local statusDot = create("Frame", {
	Size = UDim2.fromOffset(8, 8),
	Position = UDim2.new(0, 0, 0.5, -4),
	BackgroundColor3 = THEME.Muted,
	BorderSizePixel = 0,
	Parent = statusRow,
}, { corner(4) })

local statusLabel = create("TextLabel", {
	Size = UDim2.new(1, -90, 1, 0),
	Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1,
	Text = "Idle",
	TextColor3 = THEME.Muted,
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statusRow,
})

create("TextLabel", {
	Name = "Hint",
	Size = UDim2.new(0, 70, 1, 0),
	Position = UDim2.new(1, -70, 0, 0),
	BackgroundTransparency = 1,
	Text = "G to hide",
	TextColor3 = THEME.Muted,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = statusRow,
})

local spam_button = makeButton({
	Size = UDim2.new(1, 0, 0, 34),
	Color = THEME.Panel,
	Text = "Spam Q: OFF",
	TextSize = 13,
	LayoutOrder = 2,
})
spam_button.Parent = mainBody
stroke(THEME.Stroke, 1).Parent = spam_button

local click_button = makeButton({
	Size = UDim2.new(1, 0, 0, 34),
	Color = THEME.Panel,
	Text = "Auto M1: OFF",
	TextSize = 13,
	LayoutOrder = 3,
})
click_button.Parent = mainBody
stroke(THEME.Stroke, 1).Parent = click_button

local intervalRow = create("Frame", {
	Name = "IntervalRow",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	LayoutOrder = 4,
	Parent = mainBody,
})

local intervalLabel = create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.Muted,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = intervalRow,
})

local sliderTrack = create("Frame", {
	Size = UDim2.new(1, -14, 0, 6),
	Position = UDim2.fromOffset(7, 24),
	BackgroundColor3 = THEME.Key,
	BorderSizePixel = 0,
	Parent = intervalRow,
}, { corner(3) })

local sliderFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = THEME.Accent,
	BorderSizePixel = 0,
	Parent = sliderTrack,
}, { corner(3) })

local sliderKnob = create("Frame", {
	Size = UDim2.fromOffset(14, 14),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = sliderTrack,
}, { corner(7) })

local sliderHit = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.fromOffset(0, 16),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Parent = intervalRow,
})

local function updateIntervalUI()

	local alpha = math.sqrt(math.clamp((clickInterval - INTERVAL_MIN) / (INTERVAL_MAX - INTERVAL_MIN), 0, 1))
	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	intervalLabel.Text = string.format("Click interval  ·  %.2fs", clickInterval)
end
updateIntervalUI()

local walk_button = makeButton({
	Size = UDim2.new(1, 0, 0, 34),
	Color = THEME.Panel,
	Text = "Walk to Bots: OFF",
	LayoutOrder = 5,
})
walk_button.Parent = mainBody
stroke(THEME.Stroke, 1).Parent = walk_button

local toggle_button = makeButton({
	Size = UDim2.new(1, 0, 0, 36),
	Color = THEME.Green,
	Text = "Enable",
	Font = Enum.Font.GothamBold,
	LayoutOrder = 6,
})
toggle_button.Parent = mainBody

makeDraggable(mainHeader, mainFrame)

local function refreshStatus()
	spam_button.Text = spamEnabled and "Spam Q: ON" or "Spam Q: OFF"
	setBase(spam_button, spamEnabled and THEME.Accent or THEME.Panel)

	click_button.Text = clickEnabled and "Auto M1: ON" or "Auto M1: OFF"
	setBase(click_button, clickEnabled and THEME.Accent or THEME.Panel)

	walk_button.Text = walkEnabled and "Walk to Bots: ON" or "Walk to Bots: OFF"
	setBase(walk_button, walkEnabled and THEME.Accent or THEME.Panel)

	if flashing then
		return
	end

	if toggle then
		toggle_button.Text = "Disable"
		setBase(toggle_button, THEME.Red)
		tween(statusDot, { BackgroundColor3 = THEME.Green })
		local parts = {}
		if spamEnabled then
			table.insert(parts, "Q")
		end
		if clickEnabled then
			table.insert(parts, "M1")
		end
		if walkEnabled then
			table.insert(parts, "walk")
		end
		statusLabel.Text = "Running  ·  " .. table.concat(parts, " + ")
		tween(statusLabel, { TextColor3 = THEME.Green })
	else
		toggle_button.Text = "Enable"
		setBase(toggle_button, THEME.Green)
		tween(statusDot, { BackgroundColor3 = THEME.Muted })
		statusLabel.Text = "Idle"
		tween(statusLabel, { TextColor3 = THEME.Muted })
	end
end

local function runClickLoop()
	if clickLoopRunning then
		return
	end
	clickLoopRunning = true

	task.spawn(function()
		while toggle do
			if clickEnabled and isInClickRange() then
				local ok, err = pcall(doClick)
				if not ok then
					warn("[Auto Shadow Raid] Click failed: " .. tostring(err))
					task.wait(1)
				end
				task.wait(clickInterval)
			else
				task.wait(0.05)
			end
		end
		clickLoopRunning = false
	end)
end

local function runSpamLoop()
	runClickLoop()
	if loopRunning then
		return
	end
	loopRunning = true

	task.spawn(function()
		while toggle do
			if not spamEnabled or (walkEnabled and nearTarget) then

				task.wait(0.05)
			else
				pcall(function()
					vim:SendKeyEvent(true, SPAM_KEY, false, game)
					task.wait()
					vim:SendKeyEvent(false, SPAM_KEY, false, game)
				end)
				task.wait(0.05)
			end
		end
		loopRunning = false
	end)
end

pcall(function()
	if getgenv().MizWalkerLoop then
		getgenv().MizWalkerLoop:Disconnect()
		getgenv().MizWalkerLoop = nil
	end
end)

local waypoints = {}
local currentWaypointIndex = 1
local lastPathTick = 0
local computingPath = false
local wasWalking = false

local DEFAULT_RUN_IDS = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://913376220",
	[Enum.HumanoidRigType.R6] = "rbxassetid://180426354",
}

local runTrack = nil
local runTrackAnimator = nil

local function stopRunTrack()
	if runTrack then
		pcall(function()
			if runTrack.IsPlaying then
				runTrack:Stop(0.2)
			end
		end)
	end
end

local function getRunAnimationId(char, humanoid)

	if WALK.RunAnimationId and WALK.RunAnimationId ~= "" then
		return WALK.RunAnimationId
	end

	local animate = char:FindFirstChild("Animate")
	if animate then
		local run = animate:FindFirstChild("run")
		local runAnim = run and (run:FindFirstChild("RunAnim") or run:FindFirstChildOfClass("Animation"))
		if runAnim and runAnim.AnimationId ~= "" then
			return runAnim.AnimationId
		end
		local walk = animate:FindFirstChild("walk")
		local walkAnim = walk and (walk:FindFirstChild("WalkAnim") or walk:FindFirstChildOfClass("Animation"))
		if walkAnim and walkAnim.AnimationId ~= "" then
			return walkAnim.AnimationId
		end
	end
	return DEFAULT_RUN_IDS[humanoid.RigType]
end

local function updateRunAnimation(char, humanoid, root)
	if not WALK.FixAnimation then
		stopRunTrack()
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local vel = root.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = speed > 1.5 and onGround

	if not moving then
		stopRunTrack()
		return
	end

	local natural = false
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= runTrack and track.WeightCurrent > 0.1 then
			local name = string.lower(track.Name)
			local animName = track.Animation and string.lower(track.Animation.Name) or ""
			if string.find(name, "run") or string.find(name, "walk")
				or string.find(animName, "run") or string.find(animName, "walk") then
				natural = true
				break
			end
		end
	end

	if natural then
		stopRunTrack()
		return
	end

	if not runTrack or runTrackAnimator ~= animator then
		local id = getRunAnimationId(char, humanoid)
		if not id then
			return
		end
		local anim = Instance.new("Animation")
		anim.Name = "MizRunAnim"
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not ok or not track then
			return
		end
		track.Priority = Enum.AnimationPriority.Movement
		track.Looped = true
		runTrack = track
		runTrackAnimator = animator
	end

	if not runTrack.IsPlaying then
		runTrack:Play(0.15)
	end

	runTrack:AdjustSpeed(math.clamp(speed / 16, 0.4, 2.5))
end

local function getClosestEnemy(root)
	local folder = workspace:FindFirstChild(WALK.FolderName)
	if not folder then
		return nil
	end

	local closest = nil
	local shortest = WALK.MaxDistance

	for _, enemy in ipairs(folder:GetChildren()) do
		if enemy:IsA("Model") then
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			local targetRoot = enemy:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and targetRoot and not isImmune(enemy) then
				local dist = (targetRoot.Position - root.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = enemy
				end
			end
		end
	end
	return closest
end

isInClickRange = function()
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local enemy = getClosestEnemy(root)
	if not enemy then
		return false
	end
	local targetRoot = enemy:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return false
	end
	local dist = (targetRoot.Position - root.Position).Magnitude
	local size = enemy:GetExtentsSize()
	local edgeDist = math.max(dist - math.max(size.X, size.Z) / 2, 0)
	return edgeDist <= WALK.ClickRange
end

local function computePath(root, targetPosition)
	if computingPath then
		return
	end
	computingPath = true

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4,
	})

	local ok = pcall(function()
		path:ComputeAsync(root.Position, targetPosition)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
		currentWaypointIndex = 2
	else
		waypoints = {}
	end
	computingPath = false
end

local stoppedMoving = false
local function stopMoving(humanoid)

	if humanoid and not stoppedMoving then
		stoppedMoving = true
		humanoid:Move(Vector3.zero)
	end
end

getgenv().MizWalkerLoop = RunService.Heartbeat:Connect(function()
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")

	if not (toggle and walkEnabled) then
		nearTarget = false
		if wasWalking then
			wasWalking = false
			stopMoving(humanoid)
			stopRunTrack()
		end
		return
	end
	wasWalking = true

	if not root or not humanoid or humanoid.Health <= 0 then
		nearTarget = false
		stopRunTrack()
		return
	end

	updateRunAnimation(char, humanoid, root)

	local enemy = getClosestEnemy(root)
	if not enemy then
		nearTarget = false
		stopMoving(humanoid)
		return
	end

	local targetRoot = enemy:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		nearTarget = false
		return
	end

	local dist = (targetRoot.Position - root.Position).Magnitude

	local size = enemy:GetExtentsSize()
	local bodyRadius = math.max(size.X, size.Z) / 2
	local edgeDist = math.max(dist - bodyRadius, 0)

	if edgeDist <= WALK.KeyStopDistance then
		nearTarget = true
	elseif edgeDist >= WALK.KeyResumeDistance then
		nearTarget = false
	end

	if dist <= WALK.StopDistance then
		stopMoving(humanoid)
		return
	end

	local now = tick()
	if now - lastPathTick >= WALK.RecalculateDelay then
		lastPathTick = now
		task.spawn(computePath, root, targetRoot.Position)
	end

	local moveTarget = targetRoot.Position

	if #waypoints > 0 then

		local rootFlat = Vector3.new(root.Position.X, 0, root.Position.Z)
		while currentWaypointIndex < #waypoints do
			local wp = waypoints[currentWaypointIndex]
			local wpFlat = Vector3.new(wp.Position.X, 0, wp.Position.Z)
			if (wpFlat - rootFlat).Magnitude < WALK.WaypointReach then
				currentWaypointIndex += 1
			else
				break
			end
		end

		local waypoint = waypoints[math.min(currentWaypointIndex, #waypoints)]
		moveTarget = waypoint.Position

		if waypoint.Action == Enum.PathWaypointAction.Jump
			and humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid.Jump = true
		end
	end

	stoppedMoving = false
	humanoid:MoveTo(moveTarget)
end)

local function saveSettings()
	pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode({
			spam = spamEnabled,
			click = clickEnabled,
			interval = clickInterval,
			walk = walkEnabled,
		}))
	end)
end

local function loadSettings()
	local ok, raw = pcall(function()
		return readfile(CONFIG_FILE)
	end)
	if not ok then
		return
	end

	local success, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not (success and type(decoded) == "table") then
		return
	end

	if decoded.spam == true then
		spamEnabled = true
	end
	if decoded.click == true then
		clickEnabled = true
	end
	if decoded.walk == true then
		walkEnabled = true
	end
	if type(decoded.interval) == "number" then
		clickInterval = math.clamp(decoded.interval, INTERVAL_MIN, INTERVAL_MAX)
		updateIntervalUI()
	end

	if spamEnabled or clickEnabled or walkEnabled then
		toggle = true
		runSpamLoop()
	end
end

loadSettings()
refreshStatus()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		walkEnabled = not walkEnabled
		refreshStatus()
		saveSettings()
		return
	end

	if input.KeyCode == Enum.KeyCode.G then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

spam_button.MouseButton1Click:Connect(function()
	spamEnabled = not spamEnabled
	refreshStatus()
	saveSettings()
end)

click_button.MouseButton1Click:Connect(function()
	clickEnabled = not clickEnabled
	refreshStatus()
	saveSettings()
end)

walk_button.MouseButton1Click:Connect(function()
	walkEnabled = not walkEnabled
	refreshStatus()
	saveSettings()
end)

do
	local draggingSlider = false

	local function setFromX(x)
		local alpha = math.clamp((x - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
		local value = INTERVAL_MIN + (INTERVAL_MAX - INTERVAL_MIN) * alpha * alpha
		clickInterval = math.clamp(math.floor(value * 100 + 0.5) / 100, INTERVAL_MIN, INTERVAL_MAX)
		updateIntervalUI()
	end

	sliderHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			draggingSlider = false
			saveSettings()
		end
	end)
end

toggle_button.MouseButton1Click:Connect(function()
	if not spamEnabled and not clickEnabled and not walkEnabled then
		if flashing then
			return
		end
		flashing = true
		toggle_button.Text = "Turn something on first!"
		setBase(toggle_button, THEME.Amber)
		task.delay(1.2, function()
			flashing = false
			refreshStatus()
		end)
		return
	end

	toggle = not toggle
	if toggle then
		runSpamLoop()
	end
	refreshStatus()
end)
print("Auto Shadow Raid initialized!")
end)

if not success then
	warn("[Auto Shadow Raid Error]: " .. tostring(errorMessage))
end
