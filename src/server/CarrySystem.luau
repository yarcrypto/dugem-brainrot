-- Dugem Brainrot: carrying, stealing delivery and dropping. A stolen
-- brainrot rides above the thief's head until they reach their own VIP booth;
-- a Razia sweep or a slap from the rightful owner makes them drop it, and it
-- walks home to its owner's booth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BrainrotMover = require(script.Parent:WaitForChild("BrainrotMover"))

local CarrySystem = {}

local notifyEvent = nil

function CarrySystem.setNotifyEvent(event)
	notifyEvent = event
end

local function notify(player, text)
	if notifyEvent and player then
		notifyEvent:FireClient(player, text)
	end
end

local function playerByUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end
	return nil
end

local function slotPosition(data, slotIndex)
	local center = PlayerData.boothCenter(data)
	if not center then
		return nil
	end
	local offset = BrainrotDefs.SLOT_OFFSETS[slotIndex] or BrainrotDefs.SLOT_OFFSETS[1]
	return Vector3.new(center.X + offset.X, 1.2, center.Z + offset.Z)
end

-- Sends a brainrot home to its owner's booth and marks it owned there.
function CarrySystem.sendHome(model)
	local ownerId = model:GetAttribute("OwnerUserId") or 0
	local owner = playerByUserId(ownerId)
	local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("InteractPrompt")
	if owner then
		local ownerData = PlayerData.get(owner)
		if ownerData and #ownerData.owned < PlayerData.maxSlots(ownerData) then
			model:SetAttribute("State", "owned")
			model:SetAttribute("CarrierUserId", 0)
			table.insert(ownerData.owned, model)
			if prompt then
				prompt.ActionText = "Curi"
				prompt.ObjectText = model.Name
				prompt.Enabled = not PlayerData.isBoothLocked(ownerData)
			end
			local target = slotPosition(ownerData, #ownerData.owned)
			if target then
				task.spawn(function()
					BrainrotMover.walkTo(model, target, 7)
				end)
			end
			PlayerData.syncLeaderstats(ownerData)
			return true
		end
	end
	model:Destroy()
	return false
end

function CarrySystem.carryBrainrot(player, model)
	local data = PlayerData.get(player)
	if not data or data.carrying then
		return false
	end
	data.carrying = model
	model:SetAttribute("State", "carried")
	model:SetAttribute("CarrierUserId", player.UserId)
	BrainrotMover.stop(model)
	local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("InteractPrompt")
	if prompt then
		prompt.Enabled = false
	end
	notify(player, "Kamu mencuri " .. model.Name .. "! Cepat bawa ke booth kamu!")
	local owner = playerByUserId(model:GetAttribute("OwnerUserId") or 0)
	if owner and owner ~= player then
		notify(owner, player.DisplayName .. " mencuri " .. model.Name .. " kamu! Tampar dia!")
	end
	-- The stolen brainrot rides above the thief's head.
	task.spawn(function()
		while model.Parent and model:GetAttribute("State") == "carried" do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 3.6, 0)))
			end
			task.wait(0.05)
		end
	end)
	return true
end

function CarrySystem.dropCarried(player, reason)
	local data = PlayerData.get(player)
	if not data or not data.carrying then
		return false
	end
	local model = data.carrying
	data.carrying = nil
	model:SetAttribute("CarrierUserId", 0)
	notify(player, reason or "Brainrot jatuh!")
	local ok = CarrySystem.sendHome(model)
	if ok then
		local owner = playerByUserId(model:GetAttribute("OwnerUserId") or 0)
		if owner and owner ~= player then
			notify(owner, model.Name .. " kembali ke booth kamu!")
		end
	end
	return true
end

-- A thief who reaches their own booth keeps the brainrot.
local function tryDeliver(player, data)
	local model = data.carrying
	if not model or not model.Parent then
		data.carrying = nil
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local center = PlayerData.boothCenter(data)
	if not root or not center then
		return
	end
	local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
	if flat.Magnitude > 5 then
		return
	end
	local oldOwner = playerByUserId(model:GetAttribute("OwnerUserId") or 0)
	if oldOwner then
		local oldData = PlayerData.get(oldOwner)
		if oldData then
			for i, owned in ipairs(oldData.owned) do
				if owned == model then
					table.remove(oldData.owned, i)
					break
				end
			end
			PlayerData.syncLeaderstats(oldData)
		end
	end
	data.carrying = nil
	model:SetAttribute("State", "owned")
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("CarrierUserId", 0)
	if #data.owned >= PlayerData.maxSlots(data) then
		notify(player, "Booth penuh! " .. model.Name .. " kabur.")
		model:Destroy()
		return
	end
	table.insert(data.owned, model)
	local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("InteractPrompt")
	if prompt then
		prompt.ActionText = "Curi"
		prompt.ObjectText = model.Name
		prompt.Enabled = true
	end
	local target = slotPosition(data, #data.owned)
	if target then
		task.spawn(function()
			BrainrotMover.walkTo(model, target, 7)
		end)
	end
	PlayerData.syncLeaderstats(data)
	notify(player, model.Name .. " sekarang milikmu! +$" .. tostring(model:GetAttribute("Income") or 0) .. "/dtk")
end

function CarrySystem.start()
	task.spawn(function()
		while true do
			for _, entry in ipairs(PlayerData.allPlayers()) do
				if entry.data.carrying then
					tryDeliver(entry.player, entry.data)
				end
			end
			RunService.Heartbeat:Wait()
			task.wait(0.15)
		end
	end)
end

return CarrySystem
