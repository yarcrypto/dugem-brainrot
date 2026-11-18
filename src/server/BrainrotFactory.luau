-- Dugem Brainrot: builds the visible brainrot model from a definition and an
-- optional mutation: a coloured body, a head, a neon topper and a BillboardGui
-- showing name, rarity and $/sec. No meshes, decals or unions.

local BrainrotFactory = {}

local function makeLabel(name, text, size, color, y)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, size)
	label.Position = UDim2.new(0, 0, 0, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.2
	return label
end

function BrainrotFactory.build(def, mutation)
	local mult = 1
	local bodyColor = def.color
	local bodyMaterial = Enum.Material.SmoothPlastic
	if mutation then
		mult = mutation.mult
		bodyColor = mutation.color
		bodyMaterial = mutation.material
	end
	local cost = def.cost * mult
	local income = def.income * mult

	local model = Instance.new("Model")
	model.Name = def.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 2, 2)
	body.Color = bodyColor
	body.Material = bodyMaterial
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.2, 0)
	body.Parent = model
	model.PrimaryPart = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.Color = def.color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.85, 0)
	head.Parent = model

	local topper = Instance.new("Part")
	topper.Name = "Topper"
	topper.Size = Vector3.new(1.6, 0.4, 1.6)
	topper.Color = Color3.fromRGB(255, 255, 255)
	topper.Material = Enum.Material.Neon
	topper.Anchored = true
	topper.CanCollide = false
	topper.Position = Vector3.new(0, 3.7, 0)
	topper.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 150, 0, 78)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = model
	makeLabel("NameLabel", def.name, 16, Color3.fromRGB(255, 255, 255), 0).Parent = gui
	local rarityText = def.rarity
	if mutation then
		rarityText = mutation.name .. " " .. def.rarity
	end
	makeLabel("RarityLabel", rarityText, 13, Color3.fromRGB(255, 220, 80), 20).Parent = gui
	makeLabel("IncomeLabel", "$" .. tostring(income) .. "/dtk", 15, Color3.fromRGB(120, 255, 140), 40).Parent = gui
	makeLabel("CostLabel", "Harga: $" .. tostring(cost), 13, Color3.fromRGB(200, 220, 255), 58).Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = def.name .. " - $" .. tostring(cost)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	model:SetAttribute("Cost", cost)
	model:SetAttribute("Income", income)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", mutation and mutation.name or "")
	model:SetAttribute("State", "walking")
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("CarrierUserId", 0)
	model:SetAttribute("WalkToken", 0)

	return model
end

return BrainrotFactory
