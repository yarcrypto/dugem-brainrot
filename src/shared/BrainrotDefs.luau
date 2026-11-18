-- Dugem Brainrot: shared definitions for the brainrot cast, rarities,
-- mutations, booth layout and progression costs. Lives in ReplicatedStorage
-- so both server and client read the same numbers.

local BrainrotDefs = {}

BrainrotDefs.RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

BrainrotDefs.RARITY_COLORS = {
	Common = Color3.fromRGB(170, 180, 200),
	Rare = Color3.fromRGB(60, 140, 255),
	Epic = Color3.fromRGB(170, 60, 235),
	Legendary = Color3.fromRGB(255, 150, 20),
	Mythic = Color3.fromRGB(255, 50, 100),
	["Brainrot God"] = Color3.fromRGB(255, 215, 40),
}

-- Spawn weights per rarity (out of 100).
BrainrotDefs.RARITY_WEIGHTS = {
	Common = 45,
	Rare = 28,
	Epic = 15,
	Legendary = 8,
	Mythic = 3,
	["Brainrot God"] = 1,
}

-- The cast. Original dugem-flavoured characters; cost is cash, income is $/sec.
BrainrotDefs.BRAINROTS = {
	{ name = "Bocil Subwoofer", rarity = "Common", cost = 25, income = 1, color = Color3.fromRGB(120, 130, 150) },
	{ name = "Kuda Karaoke", rarity = "Common", cost = 60, income = 2, color = Color3.fromRGB(150, 120, 90) },
	{ name = "DJ Meong Koplo", rarity = "Rare", cost = 150, income = 6, color = Color3.fromRGB(60, 140, 255) },
	{ name = "Mbak Lampu Disko", rarity = "Rare", cost = 320, income = 12, color = Color3.fromRGB(255, 120, 220) },
	{ name = "Pak Satpam Rave", rarity = "Epic", cost = 800, income = 30, color = Color3.fromRGB(40, 60, 120) },
	{ name = "Nenek Breakbeat", rarity = "Epic", cost = 1600, income = 60, color = Color3.fromRGB(170, 60, 235) },
	{ name = "Tante Dangdut Laser", rarity = "Legendary", cost = 4200, income = 160, color = Color3.fromRGB(255, 150, 20) },
	{ name = "Om Bass Beton", rarity = "Legendary", cost = 8500, income = 320, color = Color3.fromRGB(90, 90, 90) },
	{ name = "Ratu Glowstick", rarity = "Mythic", cost = 21000, income = 800, color = Color3.fromRGB(0, 255, 180) },
	{ name = "Sultan Strobe", rarity = "Mythic", cost = 52000, income = 2000, color = Color3.fromRGB(255, 50, 100) },
	{ name = "Dewa Dugem", rarity = "Brainrot God", cost = 150000, income = 6000, color = Color3.fromRGB(255, 215, 40) },
	{ name = "Raja Koplo Abadi", rarity = "Brainrot God", cost = 500000, income = 20000, color = Color3.fromRGB(255, 240, 120) },
}

-- Mutations: rolled on spawn, multiply income (and price).
BrainrotDefs.MUTATIONS = {
	{ name = "Neon", mult = 2, chance = 0.15, color = Color3.fromRGB(0, 255, 220), material = Enum.Material.Neon },
	{ name = "Gold", mult = 5, chance = 0.08, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Metal },
	{ name = "Rainbow", mult = 10, chance = 0.05, color = Color3.fromRGB(255, 80, 220), material = Enum.Material.Neon },
	{ name = "Disco", mult = 25, chance = 0.02, color = Color3.fromRGB(255, 0, 170), material = Enum.Material.Neon },
}

-- VIP booth centres, matching the pads in default.project.json (west 1-4, east 5-8).
BrainrotDefs.BOOTHS = {
	Vector3.new(-19, 0, -10),
	Vector3.new(-19, 0, -3),
	Vector3.new(-19, 0, 4),
	Vector3.new(-19, 0, 11),
	Vector3.new(19, 0, -10),
	Vector3.new(19, 0, -3),
	Vector3.new(19, 0, 4),
	Vector3.new(19, 0, 11),
}

-- Slot offsets inside a booth pad (up to 8 brainrots per booth).
BrainrotDefs.SLOT_OFFSETS = {
	Vector3.new(-1.3, 0, -1.3),
	Vector3.new(1.3, 0, -1.3),
	Vector3.new(-1.3, 0, 1.3),
	Vector3.new(1.3, 0, 1.3),
	Vector3.new(0, 0, -1.3),
	Vector3.new(0, 0, 1.3),
	Vector3.new(-1.3, 0, 0),
	Vector3.new(1.3, 0, 0),
}

BrainrotDefs.START_CASH = 100
BrainrotDefs.BASE_SLOTS = 4
BrainrotDefs.MAX_UPGRADE_LEVEL = 5
BrainrotDefs.REBIRTH_BASE_COST = 25000

BrainrotDefs.UPGRADE_BASE_COST = { slots = 1000, speed = 500, slap = 750 }
BrainrotDefs.UPGRADE_NAMES = {
	slots = "Slot Booth +2",
	speed = "Lari Lebih Cepat",
	slap = "Tamparan Lebih Kuat",
}

function BrainrotDefs.rollRarity()
	local roll = math.random(1, 100)
	local acc = 0
	for _, rarity in ipairs(BrainrotDefs.RARITIES) do
		acc = acc + BrainrotDefs.RARITY_WEIGHTS[rarity]
		if roll <= acc then
			return rarity
		end
	end
	return "Common"
end

function BrainrotDefs.rollBrainrot()
	local rarity = BrainrotDefs.rollRarity()
	local pool = {}
	for _, def in ipairs(BrainrotDefs.BRAINROTS) do
		if def.rarity == rarity then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

function BrainrotDefs.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, mut in ipairs(BrainrotDefs.MUTATIONS) do
		acc = acc + mut.chance
		if roll <= acc then
			return mut
		end
	end
	return nil
end

function BrainrotDefs.rebirthCost(rebirths)
	return BrainrotDefs.REBIRTH_BASE_COST * (rebirths + 1) * (rebirths + 1)
end

function BrainrotDefs.upgradeCost(kind, level)
	return BrainrotDefs.UPGRADE_BASE_COST[kind] * (level + 1)
end

return BrainrotDefs
