-- Main.server.luau -- the server entry point for Milo's Mole Dig.
--
-- Builds the tower into the MiloTower folder, starts the obstacles, sets up
-- the game rules and the leaderboard, and opens the two remote events the
-- client effects listen to: one for a coin pickup, one for a finished run.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tower = require(script.Tower)
local Obstacles = require(script.Obstacles)
local Game = require(script.Game)
local Board = require(script.Board)

local towerFolder = workspace:FindFirstChild("MiloTower")
if not towerFolder then
	towerFolder = Instance.new("Folder")
	towerFolder.Name = "MiloTower"
	towerFolder.Parent = workspace
end

local eventsFolder = Instance.new("Folder")
eventsFolder.Name = "MiloEvents"
eventsFolder.Parent = ReplicatedStorage

local coinEvent = Instance.new("RemoteEvent")
coinEvent.Name = "CoinCollected"
coinEvent.Parent = eventsFolder

local finishEvent = Instance.new("RemoteEvent")
finishEvent.Name = "RunFinished"
finishEvent.Parent = eventsFolder

local tower = Tower.build(towerFolder)
Obstacles.startMovers(tower.movers)
Obstacles.startSpinners(tower.spinners)
Obstacles.wireCrumblers(tower.crumblers)

local board = Board.create(towerFolder)
board:start()

Game.setup(tower, { coin = coinEvent, finished = finishEvent }, board)
