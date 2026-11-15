-- Obstacles.luau -- the moving parts of the climb.
--
-- Slides each mover platform back and forth along its axis, spins each
-- spinner bar around its post, and wires each crumbling block to vanish a
-- moment after a player stands on it and come back a few seconds later.
-- One Heartbeat connection drives all the movers and one drives all the
-- spinners, so nothing here busy-loops.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Obstacles = {}

function Obstacles.startMovers(movers)
	if #movers == 0 then
		return
	end
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, mover in ipairs(movers) do
			local offset = math.sin(now * mover.speed + mover.phase) * mover.range
			mover.part.CFrame = mover.base * CFrame.new(mover.axis * offset)
		end
	end)
end

function Obstacles.startSpinners(spinners)
	if #spinners == 0 then
		return
	end
	RunService.Heartbeat:Connect(function(deltaTime)
		for _, spinner in ipairs(spinners) do
			spinner.angle = spinner.angle + spinner.speed * deltaTime
			spinner.bar.CFrame = CFrame.new(spinner.pivot) * CFrame.Angles(0, spinner.angle, 0)
		end
	end)
end

function Obstacles.wireCrumblers(crumblers)
	for _, block in ipairs(crumblers) do
		local cooling = false
		block.Touched:Connect(function(hit)
			if cooling then
				return
			end
			local character = hit.Parent
			if not character then
				return
			end
			if not character:FindFirstChildOfClass("Humanoid") then
				return
			end
			if not Players:GetPlayerFromCharacter(character) then
				return
			end
			cooling = true
			-- A beat to jump clear, then the block is gone for a few seconds.
			task.delay(0.7, function()
				block.Transparency = 1
				block.CanCollide = false
				task.delay(3, function()
					block.Transparency = 0
					block.CanCollide = true
					cooling = false
				end)
			end)
		end)
	end
end

return Obstacles
