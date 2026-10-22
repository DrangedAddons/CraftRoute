-- Mining route from wow-professions.com's Forever Mining guide
-- (https://www.wow-professions.com/forever/mining-leveling-guide). From 125 the guide follows the
-- Classic routes (the beta capped at 30), so those bands may change once it's revised.
-- 1-120 is a choice: smelt bought ore (Copper, Tin, Bronze, Silver - crafts, from MiningRecipes.lua)
-- or mine. Each mining band's zones are a choice too, so you pick the one that suits you; the
-- 1-65 zones only apply when you mine, and the 65-125 zones start at 120 after smelting.
local _, CR = ...

local PICK = 2901

local choices, steps = {}, {}

-- The veins each band is after, with the Mining skill each needs (the guide's values) - the step's
-- card lists them, green when you can mine them and red when you can't yet.
local VEIN = {
  ["Copper Vein"] = 1, ["Tin Vein"] = 65, ["Incendicite Mineral Vein"] = 65, ["Silver Vein"] = 75,
  ["Iron Deposit"] = 125, ["Gold Vein"] = 155, ["Mithril Deposit"] = 175, ["Truesilver Deposit"] = 230,
  ["Small Thorium Vein"] = 245, ["Rich Thorium Vein"] = 275,
}
local function Veins(...)
  local out = {}
  for _, name in ipairs({ ... }) do table.insert(out, { name = name, skill = VEIN[name] }) end
  table.sort(out, function(a, b) return a.skill < b.skill end)
  return { label = "Veins to mine", list = out }
end
local NODES = {
  copper = Veins("Copper Vein"),
  tin = Veins("Copper Vein", "Tin Vein", "Silver Vein"),
  iron = Veins("Tin Vein", "Iron Deposit", "Gold Vein"),
  mithril = Veins("Mithril Deposit", "Truesilver Deposit"),
  thorium = Veins("Mithril Deposit", "Truesilver Deposit", "Small Thorium Vein"),
  richthorium = Veins("Small Thorium Vein", "Rich Thorium Vein"),
}

-- One choice whose options are zones; each option becomes a gathering step over [from, to]. The
-- band's advice, if any, goes in every zone's step - not a step of its own, which would only be a
-- line to read with nothing to do. `also` adds more conditions to every step (the 1-65 zones are
-- only for mining); `starts` gives a different start per method ({ smelt = 120 }: after smelting
-- the 65-125 zones pick up at 120) - one step per method, only the picked one is planned.
local function Zones(key, label, from, to, zones, advice, also, starts)
  local c = { key = key, label = label, options = {} }
  for _, z in ipairs(zones) do
    table.insert(c.options, { key = z[1], label = z[2], faction = z[4] })
    local text = advice and (z[3] .. " " .. advice) or z[3]
    local function Add(f, when)
      table.insert(steps, { kind = "guide", from = f, to = to, when = when, faction = z[4], gather = true,
                            title = "Mine in " .. z[2], nodes = NODES[key], text = text })
    end
    if starts then
      for method, f in pairs(starts) do Add(f, { [key] = z[1], method = method }) end
    else
      local when = { [key] = z[1] }
      for k, v in pairs(also or {}) do when[k] = v end
      Add(from, when)
    end
  end
  table.insert(choices, c)
end

-- 1-120: mine, or smelt bought ore. (Mine first, the default: smelting is only quicker with the
-- gold for the ore.)
table.insert(choices, { key = "method", label = "1-120: mine, or smelt bought ore", options = {
  { key = "mine", label = "Mine" },
  { key = "smelt", label = "Smelt bought ore" },
} })

table.insert(steps, { kind = "guide", from = 1, to = 65, items = { { PICK, 1 } },
  title = "Get a Mining Pick",
  text = "Buy a Mining Pick from the Mining Supplier near your trainer, or from the trainer. It only has to "
    .. "be in your bags, not equipped." })

-- smelting: the guide's counts (Copper Bars kept for the Bronze, all the Tin Bars go into it)
table.insert(steps, { from = 1, to = 65, spell = 2657, crafts = 130, when = { method = "smelt" },
  note = "Keep 70 Copper Bars for the Bronze" })
table.insert(steps, { from = 65, to = 75, spell = 3304, crafts = 70, when = { method = "smelt" },
  note = "Make all 70 - every Tin Bar goes into Bronze" })
table.insert(steps, { from = 75, to = 105, spell = 2659, crafts = 70, when = { method = "smelt" } })
table.insert(steps, { from = 105, to = 120, spell = 2658, crafts = 40, when = { method = "smelt" },
  note = "Check the Silver Ore price first - this part can get expensive" })

Zones("copper", "1-65: Copper - one starting zone", 1, 65, {
  { "durotar", "Durotar", "Mine Copper in Durotar until 65. One or two laps get you there; Razor Hill has a "
    .. "forge for smelting the ore after a lap.", "Horde" },
  { "mulgore", "Mulgore", "Mine Copper in Mulgore until 65. The cave by Bael'dun Digsite has 5 Copper Veins "
    .. "that respawn fast enough to stay inside, with a drop at the end back to the start. The dwarf camp "
    .. "north of it has a forge and an anvil (its dwarves are hostile).", "Horde" },
  { "tirisfal", "Tirisfal Glades", "Mine Copper in Tirisfal Glades until 65. The east side has fewer quest "
    .. "hubs, so fewer people; Brill has a forge for smelting the ore after a lap.", "Horde" },
  { "elwynn", "Elwynn Forest", "Mine Copper in Elwynn Forest until 65, back and forth along the route. The "
    .. "cave respawns fast if you're high enough to clear it; without it, take the small detour north too. "
    .. "Goldshire has a forge for smelting the ore after a lap.", "Alliance" },
  { "dunmorogh", "Dun Morogh", "Mine Copper in Dun Morogh until 65, in loops - the veins outside respawn "
    .. "fast, so the cave is optional. Kharanos has a forge for smelting the ore after a lap.", "Alliance" },
  { "teldrassil", "Teldrassil", "Mine Copper in Teldrassil until 65. Its two caves respawn fast enough to "
    .. "stay inside. Teldrassil has no forge: the nearest is at the Warrior's Terrace in Darnassus.",
    "Alliance" },
  { "zephras", "Zephras Isle", "Mine Copper on Zephras Isle until 65 - the veins around Thendal Village "
    .. "respawn very fast. Shen'dar Village has a forge for smelting the ore after a lap." },
}, nil, { method = "mine" })

Zones("tin", "65-125: Copper, Tin and Silver", 65, 125, {
  { "wetlands", "Wetlands", "Mine in the Wetlands cave until 125 - full of Tin and Incendicite Mineral Veins "
    .. "with a very fast respawn. Its mobs are around level 20 and respawn fast, so outlevel them well.",
    "Alliance" },
  { "silverpine", "Silverpine Forest", "Mine in the Silverpine Forest cave until 125: 3 vein spawns that come "
    .. "back in about 2 minutes. Its mobs are level 21-22 and respawn fast, so outlevel them well.", "Horde" },
  { "westfall", "Westfall", "Mine in the Westfall cave until 125 - Tin Veins that respawn very fast, and more "
    .. "outside. Its mobs are level 13-15 and respawn fast, so outlevel them well.", "Alliance" },
  { "hillsbrad", "Hillsbrad Foothills", "Mine in Hillsbrad Foothills until 125. Busy, but the best open-air "
    .. "route; it circles a Horde town." },
  { "barrens", "The Barrens", "Mine in The Barrens until 125 - fast respawns, but the mobs are level 22-26.",
    "Horde" },
  { "ashenvale", "Ashenvale", "Mine in Ashenvale until 125 - an easy route to follow, often busy." },
  { "stonetalon", "Stonetalon Mountains", "Mine in the Stonetalon Mountains until 125 - quiet, though an Iron "
    .. "Deposit sometimes spawns where a Tin Vein would." },
}, "Tin Veins need 65 and Silver Veins 75. Iron Deposits need 125 - with +5 Mining from a bonus (gloves "
  .. "enchant, Goblin Mining Helmet) you can mine them from 120.", nil, { mine = 65, smelt = 120 })

Zones("iron", "125-175: Iron and Gold", 125, 175, {
  { "arathi", "Arathi Highlands", "Mine in the Arathi Highlands until 175. Go to the back of each of its 4 "
    .. "caves - not every vein shows from the entrance. Low levels: skip the caves, and Alliance go south of "
    .. "Hammerfall." },
  { "needles", "Thousand Needles", "Mine in Thousand Needles until 175 - the safest route around level 30." },
  { "desolace", "Desolace", "Mine in Desolace until 175." },
}, "Iron Deposits need 125 and Gold Veins 155. Smelt Iron gives points to about 135, and Smelt Gold one per "
  .. "bar from 155 to 170 - about 22 Gold Ore takes you to 175.")

Zones("mithril", "175-245: Mithril and Truesilver", 175, 245, {
  { "hinterlands", "The Hinterlands", "Mine in The Hinterlands until 245. Low levels: skip the area with level "
    .. "62 elites, and maybe the cave." },
  { "tanaris", "Tanaris", "Mine in Tanaris until 245 (below level 60: skip the 4 caves)." },
}, "Mithril Deposits need 175 and Truesilver Deposits 230.")

Zones("thorium", "245-275: Mithril, Truesilver and Thorium", 245, 275, {
  { "ungoro", "Un'Goro Crater", "Mine in Un'Goro Crater until 275 - its two caves hold 2-3 veins each "
    .. "(low levels: maybe skip the southern one)." },
  { "blasted", "Blasted Lands", "Mine in the Blasted Lands until 275. Both caves are full of mobs - for "
    .. "well-geared level 60s or stealth. Alliance can't mine in the Garrison Armory." },
  { "felwood", "Felwood", "Mine in Felwood until 275. The small cave usually has 2 veins and few mobs; skip "
    .. "the two caves at Jaedenar, Shadow Hold above all, unless you have stealth." },
}, "Small Thorium Veins need 245.")

Zones("richthorium", "275-300: Thorium and Rich Thorium", 275, 300, {
  { "ungoro2", "Un'Goro Crater", "Mine in Un'Goro Crater until 300." },
  { "epl", "Eastern Plaguelands", "Mine in the Eastern Plaguelands until 300. Part of the route has level "
    .. "57-58 elites - skip it with weak gear unless you have stealth." },
  { "winterspring", "Winterspring", "Mine in Winterspring until 300. The cave is clearable for most classes; "
    .. "the gorge has elite patrols, so it's hard to farm without dying." },
  { "steppes", "Burning Steppes", "Mine in the Burning Steppes until 300. Its two caves have level 50 mobs - "
    .. "low levels may want to skip them." },
}, "Rich Thorium Veins need 275.")

CR.RegisterRoute("Mining", {
  label = "Mining",
  source = "wow-professions.com (Forever guide)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  -- Learn Mining: besides any trainer, Skyborne can take it as a quest reward where they start
  learnAlso = {
    { race = "Skyborne", quest = 93552, questName = "Harvesting Windstones", npc = 251363,
      npcName = "Dalia the Collector",
      text = "Or on Zephras Isle: take Harvesting Windstones from Dalia the Collector in Thendal Village, and "
        .. "pick Mining for Dummies as your reward. Thendal Village has no trainer; the island's are Halavuul "
        .. "Cragwind in Valanaar and Messana Crestwind in Shen'dar Village." },
  },

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Mining at a Mining trainer (skill 50, level 10). The Junior Mining Trainers in "
        .. "the starting areas only teach up to 75." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Mining at a Mining trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Mining at a Mining trainer (skill 200, level 35)." },
  },

  choices = choices,
  steps = steps,
})

CR.extraNames[PICK] = "Mining Pick"
