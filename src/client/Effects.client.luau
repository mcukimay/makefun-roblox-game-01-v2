-- Effects.client.luau -- the client-side feedback for Milo's Mole Dig.
--
-- Listens to the two game events: a gold burst where a coin was picked up,
-- and a shower of colored light where the player wins. Everything here is
-- cosmetic; the server owns the game state.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local events = ReplicatedStorage:WaitForChild("MiloEvents")
local coinEvent = events:WaitForChild("CoinCollected")
local finishEvent = events:WaitForChild("RunFinished")

local BURST_COLORS = {
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(255, 120, 60),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(180, 255, 120),
	Color3.fromRGB(255, 120, 220),
}

local function burstAt(position, colors, count, lifetime)
	local anchor = Instance.new("Part")
	anchor.Name = "MiloBurst"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace
	for _, color in ipairs(colors) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new(0.6)
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(8, 16)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = anchor
		emitter:Emit(count)
	end
	Debris:AddItem(anchor, lifetime)
end

coinEvent.OnClientEvent:Connect(function(position)
	burstAt(position, { BURST_COLORS[1] }, 24, 1.5)
end)

finishEvent.OnClientEvent:Connect(function(_runTime, _coins)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local center = root and (root.Position + Vector3.new(0, 3, 0)) or Vector3.new(12, 10, 0)
	burstAt(center, BURST_COLORS, 40, 3)
end)
