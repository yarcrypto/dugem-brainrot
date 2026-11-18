-- Dugem Brainrot: the single place player state lives. Every server module
-- reads and writes player data through this module only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local PlayerData = {}

local dataByPlayer = {}
local boothTaken = {}

-- Set by BrainrotSpawner at load: runs before the data row is deleted so
-- owned/carried brainrot models can be returned or despawned.
PlayerData.onPlayerRemoving = nil

function PlayerData.newPlayer(player)
	local booth = 0
	for i = 1, #BrainrotDefs.BOOTHS do
		if not boothTaken[i] then
			booth = i
			boothTaken[i] = player
			break
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = BrainrotDefs.START_CASH
	cashValue.Parent = leaderstats
	local brainrotValue = Instance.new("IntValue")
	brainrotValue.Name = "Brainrot"
	brainrotValue.Value = 0
	brainrotValue.Parent = leaderstats
	leaderstats.Parent = player

	dataByPlayer[player] = {
		cash = BrainrotDefs.START_CASH,
		rebirths = 0,
		multiplier = 1,
		booth = booth,
		owned = {},
		carrying = nil,
		upgrades = { slots = 0, speed = 0, slap = 0 },
		slapCooldownUntil = 0,
		lockUntil = 0,
		lockCooldownUntil = 0,
		leaderCash = cashValue,
		leaderBrainrots = brainrotValue,
	}
	return dataByPlayer[player]
end

function PlayerData.get(player)
	return dataByPlayer[player]
end

function PlayerData.remove(player)
	local data = dataByPlayer[player]
	if data then
		if PlayerData.onPlayerRemoving then
			PlayerData.onPlayerRemoving(player, data)
		end
		if data.booth > 0 then
			boothTaken[data.booth] = nil
		end
		dataByPlayer[player] = nil
	end
	return data
end

function PlayerData.allPlayers()
	local list = {}
	for player, data in pairs(dataByPlayer) do
		table.insert(list, { player = player, data = data })
	end
	return list
end

function PlayerData.boothOwner(index)
	return boothTaken[index]
end

function PlayerData.maxSlots(data)
	return BrainrotDefs.BASE_SLOTS + 2 * data.upgrades.slots
end

function PlayerData.computeIncome(data)
	local perSecond = 0
	for _, model in ipairs(data.owned) do
		perSecond = perSecond + (model:GetAttribute("Income") or 0)
	end
	return perSecond * data.multiplier
end

function PlayerData.boothCenter(data)
	if data.booth > 0 then
		return BrainrotDefs.BOOTHS[data.booth]
	end
	return nil
end

function PlayerData.isBoothLocked(data)
	return os.clock() < data.lockUntil
end

function PlayerData.syncLeaderstats(data)
	data.leaderCash.Value = math.floor(data.cash)
	data.leaderBrainrots.Value = #data.owned
end

function PlayerData.applyWalkSpeed(player, data)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 + 2 * data.upgrades.speed
	end
end

Players.PlayerAdded:Connect(function(player)
	PlayerData.newPlayer(player)
	player.CharacterAdded:Connect(function()
		local data = PlayerData.get(player)
		if data then
			PlayerData.applyWalkSpeed(player, data)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.remove(player)
end)

return PlayerData
