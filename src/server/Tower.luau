-- Tower.luau -- builds the whole climb for Milo's Mole Dig.
--
-- A dark shaft rises from the start platform, and 24 stage pads spiral
-- around it (radius 12, about 55 degrees and 5 studs up per stage) through
-- four color strata. Between the stages sit the obstacles: sliding movers,
-- lava pools, crumbling blocks, jump pads and spinning bars. About sixty
-- gold coins are scattered along the way. Everything is anchored and built
-- into the MiloTower folder, and the module hands back the parts the other
-- systems need to run.

local Tower = {}

local STAGE_COUNT = 24
local SPIRAL_RADIUS = 12
local STAGE_TURN = 55
local STAGE_RISE = 5

local CHECKPOINTS = { [0] = true, [4] = true, [8] = true, [12] = true, [16] = true, [20] = true }
local CRUMBLE_STAGES = { [3] = true, [7] = true, [11] = true, [15] = true, [19] = true, [22] = true }
local JUMP_STAGES = { [1] = true, [5] = true, [9] = true, [13] = true, [17] = true, [21] = true }
local SPINNER_STAGES = { [6] = true, [12] = true, [18] = true }
local MOVER_GAPS = { [2] = true, [6] = true, [10] = true, [14] = true, [18] = true }
local LAVA_GAPS = { [5] = true, [9] = true, [13] = true, [17] = true }
local BIG_LAVA_GAP = 20

-- One color family per stratum of six stages.
local STRATUM_COLORS = { "Bright orange", "Bright green", "Bright blue", "Bright red" }

local function stratumColor(index)
	return STRATUM_COLORS[math.floor(index / 6) + 1]
end

-- The center of a stage pad: stage 0 sits on the start platform, and each
-- stage after it is 5 studs higher and about 55 degrees further around.
local function stageCenter(index)
	local angle = math.rad(index * STAGE_TURN)
	return Vector3.new(
		SPIRAL_RADIUS * math.cos(angle),
		index * STAGE_RISE + 0.5,
		SPIRAL_RADIUS * math.sin(angle)
	)
end

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Parent = parent
	return part
end

-- A wooden board with a text face, standing upright and facing a target at
-- its own height, so the text never leans.
local function makeSign(parent, name, position, size, text, lookTarget)
	local board = makePart(parent, name, size, CFrame.lookAt(position, lookTarget), "Brown", Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 210, 60)
	label.TextStrokeTransparency = 0.5
	label.Parent = gui
	return board
end

local function makeCoin(parent, position)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Ball
	coin.Size = Vector3.new(1.2, 1.2, 1.2)
	coin.CFrame = CFrame.new(position)
	coin.BrickColor = BrickColor.new("Bright yellow")
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.Parent = parent
	return coin
end

function Tower.build(folder)
	local movers = {}
	local spinners = {}
	local crumblers = {}
	local coins = {}
	local lavaPools = {}
	local jumpPads = {}
	local stages = {}
	local checkpoints = {}
	local winPad = nil

	-- The ground the tower stands on.
	makePart(folder, "Baseplate", Vector3.new(512, 20, 512), CFrame.new(0, -10, 0), "Reddish brown", Enum.Material.Slate)
	makePart(folder, "StartPlatform", Vector3.new(26, 2, 26), CFrame.new(12, 0, 0), "Bright green", Enum.Material.Grass)
	-- The dark shaft the stages wind around.
	makePart(folder, "Shaft", Vector3.new(8, 118, 8), CFrame.new(0, 59, 0), "Really black", Enum.Material.Slate)

	-- Milo the mole, keeping watch beside the spawn.
	local statue = Instance.new("Folder")
	statue.Name = "MiloStatue"
	statue.Parent = folder
	local body = makePart(statue, "Body", Vector3.new(2.5, 2, 2), CFrame.new(4, 2.25, -8) * CFrame.Angles(0, 0, math.rad(90)), "Brown")
	body.Shape = Enum.PartType.Cylinder
	local head = makePart(statue, "Head", Vector3.new(1.6, 1.6, 1.6), CFrame.new(4, 4, -8), "Brown")
	head.Shape = Enum.PartType.Ball
	local nose = makePart(statue, "Nose", Vector3.new(0.5, 0.5, 0.5), CFrame.new(4, 3.9, -7.1), "Pink")
	nose.Shape = Enum.PartType.Ball
	local hat = makePart(statue, "HardHat", Vector3.new(1.8, 0.9, 1.8), CFrame.new(4, 4.8, -8), "Bright yellow")
	hat.Shape = Enum.PartType.Ball
	local eyeLeft = makePart(statue, "EyeLeft", Vector3.new(0.25, 0.25, 0.25), CFrame.new(3.7, 4.1, -7.3), "Really black")
	eyeLeft.Shape = Enum.PartType.Ball
	local eyeRight = makePart(statue, "EyeRight", Vector3.new(0.25, 0.25, 0.25), CFrame.new(4.3, 4.1, -7.3), "Really black")
	eyeRight.Shape = Enum.PartType.Ball

	-- Torches flanking the start.
	local function makeTorch(x, z)
		local torch = Instance.new("Folder")
		torch.Name = "Torch"
		torch.Parent = folder
		makePart(torch, "Pole", Vector3.new(0.4, 3, 0.4), CFrame.new(x, 2.5, z), "Brown")
		local flame = makePart(torch, "Flame", Vector3.new(0.9, 0.9, 0.9), CFrame.new(x, 4.4, z), "Bright orange", Enum.Material.Neon)
		flame.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 40)
		light.Range = 12
		light.Brightness = 2
		light.Parent = flame
	end
	makeTorch(22, -10)
	makeTorch(2, 10)

	-- The title sign, facing the spawn.
	makeSign(folder, "TitleSign", Vector3.new(20, 4, 10), Vector3.new(10, 4, 0.5), "MILO'S MOLE DIG", Vector3.new(12, 4, 0))

	-- The 24 stage pads.
	for index = 0, STAGE_COUNT - 1 do
		local center = stageCenter(index)
		local pad
		if index == STAGE_COUNT - 1 then
			-- The last stage is the win pad.
			pad = makePart(folder, "WinPad", Vector3.new(8, 1, 8), CFrame.new(center), "Bright yellow", Enum.Material.Neon)
			winPad = pad
		elseif CHECKPOINTS[index] then
			pad = Instance.new("SpawnLocation")
			pad.Name = "Checkpoint"
			pad.Size = Vector3.new(8, 1, 8)
			pad.CFrame = CFrame.new(center)
			pad.BrickColor = BrickColor.new(stratumColor(index))
			pad.Material = Enum.Material.SmoothPlastic
			pad.Anchored = true
			pad.Neutral = true
			pad.Parent = folder
			checkpoints[index] = pad
		elseif CRUMBLE_STAGES[index] then
			pad = makePart(folder, "CrumblePad", Vector3.new(8, 1, 8), CFrame.new(center), "Brown", Enum.Material.Slate)
			table.insert(crumblers, pad)
		else
			pad = makePart(folder, "StagePad", Vector3.new(8, 1, 8), CFrame.new(center), stratumColor(index))
		end
		stages[index + 1] = { index = index, center = center, pad = pad }

		-- A jump pad on this stage, off to the outer edge so it never
		-- blocks the landing spot.
		if JUMP_STAGES[index] then
			local outward = Vector3.new(center.X, 0, center.Z).Unit
			local jumpPad = makePart(folder, "JumpPad", Vector3.new(3, 1, 3), CFrame.new(center + outward * 2 + Vector3.new(0, 1, 0)), "Cyan", Enum.Material.Neon)
			table.insert(jumpPads, jumpPad)
		end

		-- A spinning bar above this stage, turning around its post.
		if SPINNER_STAGES[index] then
			makePart(folder, "SpinnerPost", Vector3.new(0.6, 4, 0.6), CFrame.new(center + Vector3.new(0, 2, 0)), "Medium stone grey", Enum.Material.Metal)
			local bar = makePart(folder, "SpinnerBar", Vector3.new(8, 0.8, 0.8), CFrame.new(center + Vector3.new(0, 3.5, 0)), "Bright red", Enum.Material.SmoothPlastic)
			table.insert(spinners, { bar = bar, pivot = center + Vector3.new(0, 3.5, 0), angle = 0, speed = 1.5 })
		end

		-- Two coins on every stage, one each side of the pad.
		local radial = Vector3.new(center.X, 0, center.Z).Unit
		local tangent = Vector3.new(-radial.Z, 0, radial.X)
		table.insert(coins, makeCoin(folder, center + tangent * 2 + Vector3.new(0, 1.5, 0)))
		table.insert(coins, makeCoin(folder, center - tangent * 2 + Vector3.new(0, 1.5, 0)))
	end

	-- The sign over the win pad, facing the way the player arrives.
	local winCenter = stageCenter(STAGE_COUNT - 1)
	makeSign(folder, "WinSign", winCenter + Vector3.new(0, 6, 0), Vector3.new(8, 4, 0.5), "ESCAPE!", stageCenter(STAGE_COUNT - 2))

	-- The gaps between the stages: a stepping platform halfway up, or an
	-- obstacle in its place.
	for gap = 0, STAGE_COUNT - 2 do
		local from = stageCenter(gap)
		local to = stageCenter(gap + 1)
		local mid = (from + to) / 2
		local direction = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Unit
		local tangent = Vector3.new(-direction.Z, 0, direction.X)
		if MOVER_GAPS[gap] then
			local moverPart = makePart(folder, "Mover", Vector3.new(6, 1, 6), CFrame.new(mid), "Medium stone grey", Enum.Material.Metal)
			table.insert(movers, {
				part = moverPart,
				base = moverPart.CFrame,
				axis = tangent,
				range = 3,
				speed = 1.2,
				phase = gap * 1.3,
			})
		elseif LAVA_GAPS[gap] then
			local pool = makePart(folder, "LavaPool", Vector3.new(4, 1, 4), CFrame.new(mid), "Really red", Enum.Material.Neon)
			table.insert(lavaPools, pool)
			-- A safe stone beside the pool, so the crossing stays fair.
			makePart(folder, "SafeStone", Vector3.new(2, 1, 2), CFrame.new(mid + tangent * 3), "Bright green")
		elseif gap == BIG_LAVA_GAP then
			-- The big pool by stage 21: shifted toward stage 22 and well
			-- to the side, so it never hangs over the checkpoint-20 pad.
			local pool = makePart(folder, "BigLavaPool", Vector3.new(10, 0.5, 10), CFrame.new(mid + direction * 3 + tangent * 11), "Really red", Enum.Material.Neon)
			table.insert(lavaPools, pool)
			makePart(folder, "SafePad", Vector3.new(3, 1, 3), CFrame.new(mid - direction * 3), "Bright green")
			makePart(folder, "StepStone", Vector3.new(2, 1, 2), CFrame.new(mid), "Bright green")
			makePart(folder, "SafePad", Vector3.new(3, 1, 3), CFrame.new(mid + direction * 3), "Bright green")
		else
			makePart(folder, "MidPad", Vector3.new(4, 1, 4), CFrame.new(mid), stratumColor(gap))
		end
		-- A coin over every other gap.
		if gap % 2 == 0 then
			table.insert(coins, makeCoin(folder, mid + Vector3.new(0, 2, 0)))
		end
	end

	return {
		movers = movers,
		spinners = spinners,
		crumblers = crumblers,
		coins = coins,
		lavaPools = lavaPools,
		jumpPads = jumpPads,
		stages = stages,
		checkpoints = checkpoints,
		winPad = winPad,
	}
end

return Tower
