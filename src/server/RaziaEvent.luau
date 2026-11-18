-- Dugem Brainrot: "Razia Satpam". Every 90 seconds a security sweep crosses
-- the dance floor. A player caught outside their own VIP booth while
-- carrying a stolen brainrot drops it on the spot.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BrainrotMover = require(script.Parent:WaitForChild("BrainrotMover"))
local CarrySystem = require(script.Parent:WaitForChild("CarrySystem"))

local RaziaEvent = {}

local CYCLE_SECONDS = 90
local WARNING_SECONDS = 5
local SWEEP_SECONDS = 12
local BOOTH_SAFE_RADIUS = 7

local secondsUntil = CYCLE_SECONDS
local phase = "tenang" -- tenang | peringatan | razia
local notifyEvent = nil

function RaziaEvent.setNotifyEvent(event)
	notifyEvent = event
end

function RaziaEvent.getStatus()
	return { secondsUntil = secondsUntil, phase = phase }
end

local function notifyAll(text)
	if notifyEvent then
		for _, player in ipairs(Players:GetPlayers()) do
			notifyEvent:FireClient(player, text)
		end
	end
end

local function buildSatpam()
	local model = Instance.new("Model")
	model.Name = "SatpamRazia"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 4, 2)
	body.Color = Color3.fromRGB(20, 40, 90)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(-23, 2, 0)
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Color = Color3.fromRGB(230, 190, 150)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(-23, 4.9, 0)
	head.Parent = model
	local gui = Instance.new("BillboardGui")
	gui.Name = "SatpamLabel"
	gui.Size = UDim2.new(0, 160, 0, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = model
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "SATPAM RAZIA!"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	model:SetAttribute("WalkToken", 0)
	return model
end

local function runSweep()
	phase = "razia"
	secondsUntil = 0
	notifyAll("RAZIA SATPAM! Yang bawa brainrot curian cepat balik ke booth!")
	local satpam = buildSatpam()
	satpam.Parent = Workspace
	task.spawn(function()
		BrainrotMover.walkTo(satpam, Vector3.new(23, 2, 0), 46 / SWEEP_SECONDS)
		if satpam.Parent then
			satpam:Destroy()
		end
	end)
	local checks = SWEEP_SECONDS * 2
	for _ = 1, checks do
		task.wait(0.5)
		for _, entry in ipairs(PlayerData.allPlayers()) do
			local data = entry.data
			if data.carrying then
				local character = entry.player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local center = PlayerData.boothCenter(data)
				if root and center then
					local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
					if flat.Magnitude > BOOTH_SAFE_RADIUS then
						CarrySystem.dropCarried(entry.player, "Kena razia! Brainrot curian jatuh!")
					end
				end
			end
		end
	end
	phase = "tenang"
	secondsUntil = CYCLE_SECONDS
end

function RaziaEvent.start()
	task.spawn(function()
		while true do
			for remaining = CYCLE_SECONDS, 1, -1 do
				secondsUntil = remaining
				if remaining <= WARNING_SECONDS then
					phase = "peringatan"
				else
					phase = "tenang"
				end
				task.wait(1)
			end
			runSweep()
		end
	end)
end

return RaziaEvent
