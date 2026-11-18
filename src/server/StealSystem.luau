-- Dugem Brainrot: defence. Slap knocks a nearby rival back (and makes them
-- drop YOUR brainrot if they stole it), and a booth lock keeps thieves out
-- for 30 seconds on a 90 second cooldown.

local Players = game:GetService("Players")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local CarrySystem = require(script.Parent:WaitForChild("CarrySystem"))

local StealSystem = {}

local SLAP_COOLDOWN = 5
local SLAP_RANGE = 7
local LOCK_DURATION = 30
local LOCK_COOLDOWN = 90

local notifyEvent = nil

function StealSystem.setNotifyEvent(event)
	notifyEvent = event
end

local function notify(player, text)
	if notifyEvent and player then
		notifyEvent:FireClient(player, text)
	end
end

local function rootPartOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function onSlap(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local now = os.clock()
	if now < data.slapCooldownUntil then
		return
	end
	data.slapCooldownUntil = now + SLAP_COOLDOWN
	local myRoot = rootPartOf(player)
	if not myRoot then
		return
	end
	local nearest = nil
	local nearestDist = SLAP_RANGE
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = rootPartOf(other)
			if otherRoot then
				local dist = (otherRoot.Position - myRoot.Position).Magnitude
				if dist < nearestDist then
					nearest = other
					nearestDist = dist
				end
			end
		end
	end
	if not nearest then
		notify(player, "Tidak ada pemain di dekatmu untuk ditampar.")
		return
	end
	local otherRoot = rootPartOf(nearest)
	if otherRoot then
		local dir = (otherRoot.Position - myRoot.Position)
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		local power = 30 + 10 * data.upgrades.slap
		otherRoot.AssemblyLinearVelocity = dir * power + Vector3.new(0, 12, 0)
	end
	-- A thief carrying YOUR brainrot drops it when you slap them.
	local victimData = PlayerData.get(nearest)
	if victimData and victimData.carrying then
		local stolen = victimData.carrying
		if (stolen:GetAttribute("OwnerUserId") or 0) == player.UserId then
			CarrySystem.dropCarried(nearest, "Kamu ditampar! Brainrot jatuh!")
			notify(player, "Kamu menampar pencuri itu! " .. stolen.Name .. " kembali.")
		end
	end
end

local function onLock(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local now = os.clock()
	if now < data.lockCooldownUntil then
		notify(player, "Kunci booth masih cooldown (" .. tostring(math.floor(data.lockCooldownUntil - now)) .. " dtk).")
		return
	end
	data.lockUntil = now + LOCK_DURATION
	data.lockCooldownUntil = now + LOCK_COOLDOWN
	for _, model in ipairs(data.owned) do
		local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("InteractPrompt")
		if prompt then
			prompt.Enabled = false
		end
	end
	notify(player, "Booth terkunci 30 detik! Tidak ada yang bisa mencuri.")
	task.delay(LOCK_DURATION, function()
		if not data then
			return
		end
		for _, model in ipairs(data.owned) do
			if model.Parent and model:GetAttribute("State") == "owned" then
				local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("InteractPrompt")
				if prompt then
					prompt.Enabled = true
				end
			end
		end
		notify(player, "Kunci booth habis. Awas pencuri!")
	end)
end

function StealSystem.setup(remotes)
	remotes.SlapPlayer.OnServerEvent:Connect(onSlap)
	remotes.LockBooth.OnServerEvent:Connect(onLock)
end

return StealSystem
