-- Board.luau -- the top-times leaderboard.
--
-- A best-times OrderedDataStore holds each player's fastest run, stored
-- negated so the fastest sorts first. The board is a big part standing on
-- the start platform, facing the spawn; its screen lists the ten fastest
-- times and refreshes every minute, on a win and when a player joins. Every
-- DataStore call is wrapped, so a failure shows an "unavailable" note
-- instead of an error.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Board = {}

local TOP_STORE_NAME = "MiloTowerTop10"
local BOARD_POSITION = Vector3.new(12, 5, -9)
local BOARD_LOOK = Vector3.new(12, 5, 0)
local REFRESH_SECONDS = 60

local topStore
do
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(TOP_STORE_NAME)
	end)
	if ok then
		topStore = store
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

function Board.create(folder)
	local part = Instance.new("Part")
	part.Name = "TopTimesBoard"
	part.Size = Vector3.new(12, 8, 0.6)
	part.CFrame = CFrame.lookAt(BOARD_POSITION, BOARD_LOOK)
	part.BrickColor = BrickColor.new("Brown")
	part.Material = Enum.Material.Wood
	part.Anchored = true
	part.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = part

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 64)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 44
	title.TextColor3 = Color3.fromRGB(255, 210, 60)
	title.Text = "TOP TIMES"
	title.Parent = gui

	local list = Instance.new("TextLabel")
	list.Name = "List"
	list.Size = UDim2.new(1, -24, 1, -72)
	list.Position = UDim2.new(0, 12, 0, 68)
	list.BackgroundTransparency = 1
	list.Font = Enum.Font.GothamBold
	list.TextSize = 26
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.TextColor3 = Color3.fromRGB(255, 240, 200)
	list.Text = "Loading..."
	list.Parent = gui

	local board = {}

	function board.recordBest(player, time)
		if not topStore then
			return
		end
		pcall(function()
			topStore:SetAsync(tostring(player.UserId), -time)
		end)
	end

	function board.refresh()
		if not topStore then
			list.Text = "Leaderboard unavailable\n(DataStores are off)"
			return
		end
		local ok, pages = pcall(function()
			return topStore:GetSortedAsync(false, 10)
		end)
		if not ok or not pages then
			list.Text = "Leaderboard unavailable\n(DataStores are off)"
			return
		end
		local entries = pages:GetCurrentPage()
		if #entries == 0 then
			list.Text = "No times yet —\nbe the first!"
			return
		end
		local lines = {}
		for i, entry in ipairs(entries) do
			local name = "Player"
			local nameOk, found = pcall(function()
				return Players:GetNameFromUserIdAsync(tonumber(entry.key))
			end)
			if nameOk and found then
				name = found
			end
			lines[i] = string.format("%d. %s — %s", i, name, formatTime(-entry.value))
		end
		list.Text = table.concat(lines, "\n")
	end

	function board.start()
		Players.PlayerAdded:Connect(function()
			board.refresh()
		end)
		task.spawn(function()
			while true do
				task.wait(REFRESH_SECONDS)
				board.refresh()
			end
		end)
		board.refresh()
	end

	return board
end

return Board
