-- Dugem Brainrot: server bootstrap. Creates the RemoteEvents, starts the
-- conveyor, the carry system, the Razia sweep and the defence system, then
-- ticks income every second and pushes the HUD state to every player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local CarrySystem = require(script.Parent:WaitForChild("CarrySystem"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))
local RaziaEvent = require(script.Parent:WaitForChild("RaziaEvent"))

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local remotes = {
	HudUpdate = makeRemote("HudUpdate"),
	Notify = makeRemote("Notify"),
	SlapPlayer = makeRemote("SlapPlayer"),
	LockBooth = makeRemote("LockBooth"),
	Rebirth = makeRemote("Rebirth"),
	BuyUpgrade = makeRemote("BuyUpgrade"),
}

BrainrotSpawner.setNotifyEvent(remotes.Notify)
CarrySystem.setNotifyEvent(remotes.Notify)
StealSystem.setNotifyEvent(remotes.Notify)
RaziaEvent.setNotifyEvent(remotes.Notify)

StealSystem.setup(remotes)
CarrySystem.start()
RaziaEvent.start()
BrainrotSpawner.start()

local function hudPayload(data)
	local now = os.clock()
	local status = RaziaEvent.getStatus()
	return {
		cash = math.floor(data.cash),
		income = PlayerData.computeIncome(data),
		owned = #data.owned,
		slots = PlayerData.maxSlots(data),
		rebirths = data.rebirths,
		multiplier = data.multiplier,
		slapReadyIn = math.max(0, math.floor(data.slapCooldownUntil - now)),
		lockActiveIn = math.max(0, math.floor(data.lockUntil - now)),
		lockCooldownIn = math.max(0, math.floor(data.lockCooldownUntil - now)),
		eventIn = status.secondsUntil,
		eventPhase = status.phase,
		upgrades = { slots = data.upgrades.slots, speed = data.upgrades.speed, slap = data.upgrades.slap },
		upgradeCosts = {
			slots = BrainrotDefs.upgradeCost("slots", data.upgrades.slots),
			speed = BrainrotDefs.upgradeCost("speed", data.upgrades.speed),
			slap = BrainrotDefs.upgradeCost("slap", data.upgrades.slap),
		},
	}
end

remotes.Rebirth.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local cost = BrainrotDefs.rebirthCost(data.rebirths)
	if data.cash < cost then
		remotes.Notify:FireClient(player, "Rebirth butuh $" .. tostring(cost) .. ". Kamu punya $" .. tostring(math.floor(data.cash)) .. ".")
		return
	end
	data.cash = 0
	data.rebirths = data.rebirths + 1
	data.multiplier = 2 ^ data.rebirths
	PlayerData.syncLeaderstats(data)
	remotes.Notify:FireClient(player, "REBIRTH! Penghasilan sekarang x" .. tostring(data.multiplier) .. "!")
end)

remotes.BuyUpgrade.OnServerEvent:Connect(function(player, kind)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if kind ~= "slots" and kind ~= "speed" and kind ~= "slap" then
		return
	end
	local level = data.upgrades[kind]
	if level >= BrainrotDefs.MAX_UPGRADE_LEVEL then
		remotes.Notify:FireClient(player, "Upgrade sudah maksimal!")
		return
	end
	local cost = BrainrotDefs.upgradeCost(kind, level)
	if data.cash < cost then
		remotes.Notify:FireClient(player, "Uang kurang! Upgrade butuh $" .. tostring(cost) .. ".")
		return
	end
	data.cash = data.cash - cost
	data.upgrades[kind] = level + 1
	if kind == "speed" then
		PlayerData.applyWalkSpeed(player, data)
	end
	remotes.Notify:FireClient(player, BrainrotDefs.UPGRADE_NAMES[kind] .. " naik ke level " .. tostring(level + 1) .. "!")
end)

-- Income tick: every brainrot pays every second, HUD refreshes with it.
task.spawn(function()
	while true do
		task.wait(1)
		for _, entry in ipairs(PlayerData.allPlayers()) do
			local data = entry.data
			data.cash = data.cash + PlayerData.computeIncome(data)
			PlayerData.syncLeaderstats(data)
			remotes.HudUpdate:FireClient(entry.player, hudPayload(data))
		end
	end
end)

-- Players who join after the server started still get their data row here;
-- PlayerData also hooks PlayerAdded itself, this is only a safety net.
Players.PlayerAdded:Connect(function(player)
	if not PlayerData.get(player) then
		PlayerData.newPlayer(player)
	end
end)

print("Dugem Brainrot server ready: conveyor, booths, razia and slap live.")
