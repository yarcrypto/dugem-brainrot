-- Dugem Brainrot: the conveyor. Brainrots spawn on the DJ stage, walk down
-- the glowing conveyor across the dance floor and leave at the south end.
-- A player buys one with the E prompt; a player who is not the owner can
-- steal an owned one the same way when its booth is unlocked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local BrainrotMover = require(script.Parent:WaitForChild("BrainrotMover"))
local CarrySystem = require(script.Parent:WaitForChild("CarrySystem"))

local BrainrotSpawner = {}

local SPAWN_INTERVAL = 5
local MAX_WALKING = 12
local WALK_SPEED = 6
local CONVEYOR_PATH = {
	Vector3.new(0, 2, -18),
	Vector3.new(0, 2, -15),
	Vector3.new(0, 1.2, -13),
	Vector3.new(0, 1.2, 16),
}

local folder = nil
local notifyEvent = nil
local walkingCount = 0

function BrainrotSpawner.setNotifyEvent(event)
	notifyEvent = event
end

local function notify(player, text)
	if notifyEvent and player then
		notifyEvent:FireClient(player, text)
	end
end

local function slotPosition(data, slotIndex)
	local center = PlayerData.boothCenter(data)
	if not center then
		return nil
	end
	local offset = BrainrotDefs.SLOT_OFFSETS[slotIndex] or BrainrotDefs.SLOT_OFFSETS[1]
	return Vector3.new(center.X + offset.X, 1.2, center.Z + offset.Z)
end

local function onPrompt(player, model)
	local state = model:GetAttribute("State")
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if state == "walking" then
		-- Buying from the conveyor.
		local cost = model:GetAttribute("Cost") or 0
		if data.booth == 0 then
			notify(player, "Semua booth penuh, tunggu pemain keluar dulu.")
			return
		end
		if #data.owned >= PlayerData.maxSlots(data) then
			notify(player, "Booth penuh! Upgrade slot dulu.")
			return
		end
		if data.cash < cost then
			notify(player, "Uang kurang! Butuh $" .. tostring(cost) .. ".")
			return
		end
		data.cash = data.cash - cost
		model:SetAttribute("State", "owned")
		model:SetAttribute("OwnerUserId", player.UserId)
		BrainrotMover.stop(model)
		table.insert(data.owned, model)
		local prompt = model.Body:FindFirstChild("InteractPrompt")
		if prompt then
			prompt.ActionText = "Curi"
			prompt.ObjectText = model.Name
		end
		local target = slotPosition(data, #data.owned)
		if target then
			task.spawn(function()
				BrainrotMover.walkTo(model, target, 8)
			end)
		end
		PlayerData.syncLeaderstats(data)
		notify(player, "Dapat " .. model.Name .. "! +$" .. tostring(model:GetAttribute("Income") or 0) .. "/dtk")
	elseif state == "owned" then
		-- Stealing from another player's booth.
		local ownerId = model:GetAttribute("OwnerUserId") or 0
		if ownerId == player.UserId then
			notify(player, "Itu brainrot kamu sendiri!")
			return
		end
		if data.carrying then
			notify(player, "Kamu sudah membawa satu brainrot!")
			return
		end
		if data.booth == 0 then
			notify(player, "Kamu belum punya booth.")
			return
		end
		if #data.owned >= PlayerData.maxSlots(data) then
			notify(player, "Booth penuh! Upgrade slot dulu.")
			return
		end
		local ownerData = nil
		for _, entry in ipairs(PlayerData.allPlayers()) do
			if entry.player.UserId == ownerId then
				ownerData = entry.data
				break
			end
		end
		if ownerData and PlayerData.isBoothLocked(ownerData) then
			notify(player, "Booth itu terkunci! Tunggu sampai kunci habis.")
			return
		end
		if ownerData then
			for i, owned in ipairs(ownerData.owned) do
				if owned == model then
					table.remove(ownerData.owned, i)
					break
				end
			end
			PlayerData.syncLeaderstats(ownerData)
		end
		CarrySystem.carryBrainrot(player, model)
	end
end

local function spawnBrainrot()
	local def = BrainrotDefs.rollBrainrot()
	local mutation = BrainrotDefs.rollMutation()
	local model = BrainrotFactory.build(def, mutation)
	model.Parent = folder
	walkingCount = walkingCount + 1
	local prompt = model.Body:FindFirstChild("InteractPrompt")
	prompt.Triggered:Connect(function(player)
		onPrompt(player, model)
	end)
	task.spawn(function()
		local arrived = BrainrotMover.walkWaypoints(model, CONVEYOR_PATH, WALK_SPEED)
		if arrived and model.Parent and model:GetAttribute("State") == "walking" then
			model:Destroy()
		end
		walkingCount = walkingCount - 1
	end)
end

function BrainrotSpawner.start()
	folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	folder.Parent = Workspace
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL)
			if walkingCount < MAX_WALKING then
				spawnBrainrot()
			end
		end
	end)
end

-- Called by PlayerData before a leaving player's data row is deleted.
function BrainrotSpawner.cleanupPlayer(player, data)
	if data.carrying then
		CarrySystem.dropCarried(player, "Kamu keluar, brainrot kembali.")
	end
	for _, model in ipairs(data.owned) do
		if model.Parent then
			model:Destroy()
		end
	end
end

PlayerData.onPlayerRemoving = BrainrotSpawner.cleanupPlayer

return BrainrotSpawner
