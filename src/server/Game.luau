-- Game.luau -- the rules of Milo's Mole Dig, kept in one place.
--
-- Owns every player's run: checkpoint, timer, coins, deaths and best time;
-- the HUD that shows them; respawns at the latest checkpoint; coin pickups;
-- lava and falls; and the win at stage 23. Best times are saved to a
-- DataStore, every call wrapped so a failure stays silent.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Game = {}

local BEST_STORE_NAME = "MiloTowerBest"
local FALL_MARGIN = 20
local RESPAWN_LIFT = 4
local JUMP_POWER = 75

local bestStore
do
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(BEST_STORE_NAME)
	end)
	if ok then
		bestStore = store
	end
end

local function formatTime(seconds)
	if seconds == nil then
		return "--"
	end
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	return string.format("%d:%05.2f", minutes, rest)
end

-- The HUD in the top-right corner, clear of Roblox's own top-left buttons.
local function makeHud(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MiloHud"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -12, 0, 12)
	frame.Size = UDim2.new(0, 250, 0, 150)
	frame.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local labels = {}
	local rows = { "Stage", "Coins", "Time", "Best", "Deaths" }
	for i, key in ipairs(rows) do
		local label = Instance.new("TextLabel")
		label.Name = key
		label.Size = UDim2.new(1, -16, 0, 26)
		label.Position = UDim2.new(0, 8, 0, 6 + (i - 1) * 28)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(255, 240, 200)
		label.Parent = frame
		labels[key] = label
	end
	return labels
end

-- The win screen, with a PLAY AGAIN button that respawns the player; the
-- respawn handler sees the finished run and restarts it from stage 0.
local function showWinGui(player, runTime, coins)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end
	local old = playerGui:FindFirstChild("WinGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "WinGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.42)
	frame.Size = UDim2.new(0, 420, 0, 220)
	frame.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
	frame.BackgroundTransparency = 0.2
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 80)
	title.Position = UDim2.new(0, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 48
	title.TextColor3 = Color3.fromRGB(255, 210, 60)
	title.Text = "YOU ESCAPED!"
	title.Parent = frame

	local detail = Instance.new("TextLabel")
	detail.Name = "Detail"
	detail.Size = UDim2.new(1, 0, 0, 36)
	detail.Position = UDim2.new(0, 0, 0, 96)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.GothamBold
	detail.TextSize = 24
	detail.TextColor3 = Color3.fromRGB(255, 240, 200)
	detail.Text = string.format("TIME %s  •  COINS %d", formatTime(runTime), coins)
	detail.Parent = frame

	local button = Instance.new("TextButton")
	button.Name = "PlayAgain"
	button.Size = UDim2.new(0, 220, 0, 56)
	button.Position = UDim2.new(0.5, -110, 0, 148)
	button.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 26
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = "PLAY AGAIN"
	button.Parent = frame

	local handler = Instance.new("Script")
	handler.Name = "PlayAgainHandler"
	handler.Source = [[
		local button = script.Parent.PlayAgain
		local gui = script.Parent.Parent
		local player = gui.Parent.Parent
		button.MouseButton1Click:Connect(function()
			gui:Destroy()
			player:LoadCharacter()
		end)
	]]
	handler.Parent = frame
end

function Game.setup(tower, events, board)
	local states = {}

	local function newRunState()
		return {
			checkpoint = 0,
			stage = 0,
			coins = 0,
			deaths = 0,
			startedAt = os.clock(),
			finishTime = nil,
			finished = false,
			best = nil,
			hud = nil,
		}
	end

	local function refreshHud(state)
		local labels = state.hud
		if not labels then
			return
		end
		labels.Stage.Text = string.format("STAGE %d / 23", state.stage)
		labels.Coins.Text = string.format("COINS %d", state.coins)
		if state.finished then
			labels.Time.Text = string.format("TIME %s", formatTime(state.finishTime))
		else
			labels.Time.Text = string.format("TIME %s", formatTime(os.clock() - state.startedAt))
		end
		labels.Best.Text = string.format("BEST %s", formatTime(state.best))
		labels.Deaths.Text = string.format("DEATHS %d", state.deaths)
	end

	local function teleportToCheckpoint(player, state)
		local pad = tower.checkpoints[state.checkpoint]
		if not pad then
			return
		end
		player.RespawnLocation = pad
		local character = player.Character
		if not character then
			return
		end
		task.spawn(function()
			local root = character:WaitForChild("HumanoidRootPart")
			task.wait(0.15)
			if root.Parent == nil then
				return
			end
			root.CFrame = pad.CFrame + Vector3.new(0, RESPAWN_LIFT, 0)
		end)
	end

	local function onCharacterAdded(player, character)
		local state = states[player]
		if not state then
			return
		end
		if state.finished then
			-- A finished run restarts from the beginning.
			state.checkpoint = 0
			state.stage = 0
			state.coins = 0
			state.deaths = 0
			state.startedAt = os.clock()
			state.finishTime = nil
			state.finished = false
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local coinsValue = leaderstats:FindFirstChild("Coins")
				if coinsValue then
					coinsValue.Value = 0
				end
				local stageValue = leaderstats:FindFirstChild("Stage")
				if stageValue then
					stageValue.Value = 0
				end
			end
			local playerGui = player:FindFirstChild("PlayerGui")
			local winGui = playerGui and playerGui:FindFirstChild("WinGui")
			if winGui then
				winGui:Destroy()
			end
		end
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			state.deaths += 1
		end)
		teleportToCheckpoint(player, state)
	end

	local function addPlayer(player)
		local state = newRunState()
		states[player] = state

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		local coinsValue = Instance.new("IntValue")
		coinsValue.Name = "Coins"
		coinsValue.Value = 0
		coinsValue.Parent = leaderstats
		local stageValue = Instance.new("IntValue")
		stageValue.Name = "Stage"
		stageValue.Value = 0
		stageValue.Parent = leaderstats

		state.hud = makeHud(player)

		-- Best time, loaded quietly; a failure just leaves it blank.
		if bestStore then
			task.spawn(function()
				local ok, value = pcall(function()
					return bestStore:GetAsync("best_" .. player.UserId)
				end)
				if ok and type(value) == "number" then
					state.best = value
				end
			end)
		end

		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end

	local function removePlayer(player)
		states[player] = nil
	end

	-- Coins: one touch collects them, tells every client where the burst
	-- goes, and takes the coin out of the world.
	local takenCoins = {}
	for _, coin in ipairs(tower.coins) do
		coin.Touched:Connect(function(hit)
			if takenCoins[coin] then
				return
			end
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local state = states[player]
			if not state then
				return
			end
			takenCoins[coin] = true
			state.coins += 1
			local leaderstats = player:FindFirstChild("leaderstats")
			local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
			if coinsValue then
				coinsValue.Value = state.coins
			end
			events.coin:FireAllClients(coin.Position)
			coin:Destroy()
		end)
	end

	-- Lava kills on touch, at most once a second per player.
	local lastLavaKill = {}
	for _, pool in ipairs(tower.lavaPools) do
		pool.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local now = os.clock()
			if lastLavaKill[player] and now - lastLavaKill[player] < 1 then
				return
			end
			lastLavaKill[player] = now
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end

	-- Jump pads launch the player straight up, keeping their sideways speed.
	local lastJump = {}
	for _, pad in ipairs(tower.jumpPads) do
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local now = os.clock()
			if lastJump[player] and now - lastJump[player] < 0.5 then
				return
			end
			lastJump[player] = now
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, JUMP_POWER, velocity.Z)
		end)
	end

	-- Stage pads track the highest stage reached and set checkpoints.
	for _, stage in ipairs(tower.stages) do
		stage.pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local state = states[player]
			if not state then
				return
			end
			if stage.index > state.stage then
				state.stage = stage.index
				local leaderstats = player:FindFirstChild("leaderstats")
				local stageValue = leaderstats and leaderstats:FindFirstChild("Stage")
				if stageValue then
					stageValue.Value = state.stage
				end
			end
			if tower.checkpoints[stage.index] and stage.index > state.checkpoint then
				state.checkpoint = stage.index
				player.RespawnLocation = stage.pad
			end
		end)
	end

	-- The win pad ends the run: best time, the win screen, the board.
	if tower.winPad then
		tower.winPad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local state = states[player]
			if not state or state.finished then
				return
			end
			state.finished = true
			state.finishTime = os.clock() - state.startedAt
			if state.best == nil or state.finishTime < state.best then
				state.best = state.finishTime
				if bestStore then
					pcall(function()
						bestStore:SetAsync("best_" .. player.UserId, state.finishTime)
					end)
				end
				board.recordBest(player, state.finishTime)
			end
			events.finished:FireClient(player, state.finishTime, state.coins)
			showWinGui(player, state.finishTime, state.coins)
			board.refresh()
			refreshHud(state)
		end)
	end

	-- A fall far below the latest checkpoint counts as a death.
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, state in pairs(states) do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if humanoid and root and humanoid.Health > 0 then
					local pad = tower.checkpoints[state.checkpoint]
					if pad and root.Position.Y < pad.Position.Y - FALL_MARGIN then
						humanoid.Health = 0
					end
				end
			end
		end
	end)

	-- The HUD clock ticks while the run is live.
	task.spawn(function()
		while true do
			task.wait(0.1)
			for _, state in pairs(states) do
				refreshHud(state)
			end
		end
	end)

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		addPlayer(player)
	end
end

return Game
