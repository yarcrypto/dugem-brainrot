-- Dugem Brainrot: the player HUD. Cash, income, owned brainrots, the rarity
-- ladder, the Razia timer and the action buttons (slap, booth lock, rebirth,
-- upgrades). All panels stay clear of the top-left corner, where Roblox puts
-- its own menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hudUpdate = ReplicatedStorage:WaitForChild("HudUpdate")
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")
local slapRemote = ReplicatedStorage:WaitForChild("SlapPlayer")
local lockRemote = ReplicatedStorage:WaitForChild("LockBooth")
local rebirthRemote = ReplicatedStorage:WaitForChild("Rebirth")
local upgradeRemote = ReplicatedStorage:WaitForChild("BuyUpgrade")

local gui = Instance.new("ScreenGui")
gui.Name = "DugemHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function panel(name, anchor, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(16, 10, 28)
	frame.BackgroundTransparency = 0.25
	frame.BorderColor3 = Color3.fromRGB(255, 0, 170)
	frame.BorderSizePixel = 2
	frame.Parent = gui
	return frame
end

local function label(parent, name, position, size, text, textSize, color)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.Text = text
	item.TextSize = textSize
	item.Font = Enum.Font.GothamBold
	item.TextColor3 = color
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.Parent = parent
	return item
end

local function button(parent, name, position, size, text)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = Color3.fromRGB(255, 0, 170)
	item.BorderColor3 = Color3.fromRGB(255, 255, 255)
	item.BorderSizePixel = 1
	item.Text = text
	item.TextSize = 16
	item.Font = Enum.Font.GothamBold
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.Parent = parent
	return item
end

-- Cash panel, top right.
local cashPanel = panel("CashPanel", Vector2.new(1, 0), UDim2.new(1, -16, 0, 16), UDim2.fromOffset(280, 116))
local cashLabel = label(cashPanel, "Cash", UDim2.fromOffset(12, 8), UDim2.fromOffset(256, 28), "Uang: $0", 22, Color3.fromRGB(120, 255, 140))
local incomeLabel = label(cashPanel, "Income", UDim2.fromOffset(12, 38), UDim2.fromOffset(256, 22), "+$0/dtk", 16, Color3.fromRGB(200, 220, 255))
local ownedLabel = label(cashPanel, "Owned", UDim2.fromOffset(12, 62), UDim2.fromOffset(256, 22), "Brainrot: 0/4", 16, Color3.fromRGB(255, 220, 80))
local rebirthLabel = label(cashPanel, "Rebirth", UDim2.fromOffset(12, 86), UDim2.fromOffset(256, 22), "Rebirth: 0 (x1)", 16, Color3.fromRGB(255, 150, 220))

-- Razia timer, top centre.
local eventPanel = panel("EventPanel", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 16), UDim2.fromOffset(340, 40))
local eventLabel = label(eventPanel, "Event", UDim2.fromOffset(10, 0), UDim2.fromOffset(320, 40), "Razia Satpam: 90 dtk", 16, Color3.fromRGB(255, 255, 255))
eventLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Rarity ladder, right side under the cash panel.
local ladderPanel = panel("LadderPanel", Vector2.new(1, 0), UDim2.new(1, -16, 0, 148), UDim2.fromOffset(240, 196))
label(ladderPanel, "Title", UDim2.fromOffset(12, 6), UDim2.fromOffset(216, 22), "RARITY LADDER", 16, Color3.fromRGB(255, 255, 255))
local ladderRows = {
	{ "Common", Color3.fromRGB(170, 180, 200) },
	{ "Rare", Color3.fromRGB(60, 140, 255) },
	{ "Epic", Color3.fromRGB(170, 60, 235) },
	{ "Legendary", Color3.fromRGB(255, 150, 20) },
	{ "Mythic", Color3.fromRGB(255, 50, 100) },
	{ "Brainrot God", Color3.fromRGB(255, 215, 40) },
}
for i, row in ipairs(ladderRows) do
	label(ladderPanel, "Row" .. tostring(i), UDim2.fromOffset(12, 30 + (i - 1) * 26), UDim2.fromOffset(216, 22), row[1], 15, row[2])
end

-- Action buttons, bottom centre.
local buttonRow = Instance.new("Frame")
buttonRow.Name = "ButtonRow"
buttonRow.AnchorPoint = Vector2.new(0.5, 1)
buttonRow.Position = UDim2.new(0.5, 0, 1, -16)
buttonRow.Size = UDim2.fromOffset(560, 52)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = gui
local slapButton = button(buttonRow, "Slap", UDim2.fromOffset(0, 0), UDim2.fromOffset(132, 52), "Tampar")
local lockButton = button(buttonRow, "Lock", UDim2.fromOffset(142, 0), UDim2.fromOffset(132, 52), "Kunci Booth")
local rebirthButton = button(buttonRow, "Rebirth", UDim2.fromOffset(284, 0), UDim2.fromOffset(132, 52), "Rebirth")
local upgradeButton = button(buttonRow, "Upgrade", UDim2.fromOffset(426, 0), UDim2.fromOffset(132, 52), "Upgrade")
upgradeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 220)

-- Upgrade panel, hidden until the Upgrade button is pressed.
local upgradePanel = panel("UpgradePanel", Vector2.new(1, 0.5), UDim2.new(1, -16, 0.5, 0), UDim2.fromOffset(300, 190))
upgradePanel.Visible = false
label(upgradePanel, "Title", UDim2.fromOffset(12, 8), UDim2.fromOffset(276, 24), "UPGRADE", 18, Color3.fromRGB(255, 255, 255))
local upgradeRows = {}
local upgradeKinds = { "slots", "speed", "slap" }
local upgradeNames = { slots = "Slot Booth +2", speed = "Lari Lebih Cepat", slap = "Tamparan Lebih Kuat" }
for i, kind in ipairs(upgradeKinds) do
	local y = 40 + (i - 1) * 48
	label(upgradePanel, kind .. "Name", UDim2.fromOffset(12, y), UDim2.fromOffset(170, 22), upgradeNames[kind], 14, Color3.fromRGB(255, 255, 255))
	local levelLabel = label(upgradePanel, kind .. "Level", UDim2.fromOffset(12, y + 20), UDim2.fromOffset(170, 20), "Level 0", 13, Color3.fromRGB(200, 220, 255))
	local buyButton = button(upgradePanel, kind .. "Buy", UDim2.fromOffset(190, y), UDim2.fromOffset(96, 40), "Beli $0")
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
	buyButton.TextSize = 14
	buyButton.MouseButton1Click:Connect(function()
		upgradeRemote:FireServer(kind)
	end)
	upgradeRows[kind] = { level = levelLabel, buy = buyButton }
end
local closeButton = button(upgradePanel, "Close", UDim2.fromOffset(190, 184 - 28), UDim2.fromOffset(96, 28), "Tutup")
closeButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
closeButton.TextSize = 14
closeButton.MouseButton1Click:Connect(function()
	upgradePanel.Visible = false
end)

slapButton.MouseButton1Click:Connect(function()
	slapRemote:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)
upgradeButton.MouseButton1Click:Connect(function()
	upgradePanel.Visible = not upgradePanel.Visible
end)

-- Centre notification line.
local notifyLabel = Instance.new("TextLabel")
notifyLabel.Name = "Notify"
notifyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
notifyLabel.Position = UDim2.new(0.5, 0, 0.32, 0)
notifyLabel.Size = UDim2.fromOffset(560, 40)
notifyLabel.BackgroundTransparency = 1
notifyLabel.Text = ""
notifyLabel.TextSize = 20
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifyLabel.TextStrokeTransparency = 0.1
notifyLabel.Parent = gui

local notifyToken = 0
notifyEvent.OnClientEvent:Connect(function(text)
	notifyToken = notifyToken + 1
	local token = notifyToken
	notifyLabel.Text = text
	task.delay(3, function()
		if token == notifyToken then
			notifyLabel.Text = ""
		end
	end)
end)

hudUpdate.OnClientEvent:Connect(function(state)
	cashLabel.Text = "Uang: $" .. tostring(state.cash)
	incomeLabel.Text = "+$" .. tostring(state.income) .. "/dtk"
	ownedLabel.Text = "Brainrot: " .. tostring(state.owned) .. "/" .. tostring(state.slots)
	rebirthLabel.Text = "Rebirth: " .. tostring(state.rebirths) .. " (x" .. tostring(state.multiplier) .. ")"
	if state.slapReadyIn > 0 then
		slapButton.Text = "Tampar (" .. tostring(state.slapReadyIn) .. ")"
	else
		slapButton.Text = "Tampar"
	end
	if state.lockActiveIn > 0 then
		lockButton.Text = "Terkunci (" .. tostring(state.lockActiveIn) .. ")"
	elseif state.lockCooldownIn > 0 then
		lockButton.Text = "Kunci (" .. tostring(state.lockCooldownIn) .. ")"
	else
		lockButton.Text = "Kunci Booth"
	end
	if state.eventPhase == "razia" then
		eventLabel.Text = "RAZIA SATPAM! BALIK KE BOOTH!"
		eventPanel.BorderColor3 = Color3.fromRGB(255, 0, 0)
	elseif state.eventPhase == "peringatan" then
		eventLabel.Text = "Razia Satpam dalam " .. tostring(state.eventIn) .. " dtk - SIAP-SIAP!"
		eventPanel.BorderColor3 = Color3.fromRGB(255, 200, 0)
	else
		eventLabel.Text = "Razia Satpam: " .. tostring(state.eventIn) .. " dtk"
		eventPanel.BorderColor3 = Color3.fromRGB(255, 0, 170)
	end
	for kind, row in pairs(upgradeRows) do
		local level = state.upgrades[kind]
		local cost = state.upgradeCosts[kind]
		row.level.Text = "Level " .. tostring(level) .. " / 5"
		if level >= 5 then
			row.buy.Text = "MAX"
		else
			row.buy.Text = "Beli $" .. tostring(cost)
		end
	end
end)
