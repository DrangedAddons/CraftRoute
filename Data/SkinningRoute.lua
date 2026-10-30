-- Skinning route from wow-professions.com's Forever Skinning guide
-- (https://www.wow-professions.com/forever/skinning-leveling-guide, beta data, as of 30 Oct 2026).
-- Every step is an instruction ("guide" step): the knife, then skinning by zone. 1-75 and 75-150 are
-- one place per faction; 150-225 is a pick-one choice. Training comes from the tiers.
-- What you can skin: up to level 10 anything, levels 11-19 need (level - 10) * 10, from 20 level * 5.
local _, CR = ...

local KNIFE = 7005
local H, A = "Horde", "Alliance"

local choices, steps = {}, {}

-- The Skinning a mob of this level needs (the guide's rule).
local function Need(level)
  if level <= 10 then return 1 end
  if level < 20 then return (level - 10) * 10 end
  return level * 5
end
-- The mobs a step is after, each with the skill its lowest level needs - the step's card lists them,
-- green when you can skin them and red when you can't yet.
local function Mobs(...)
  local out = {}
  for _, m in ipairs({ ... }) do table.insert(out, { name = m[1], skill = Need(m[2]) }) end
  table.sort(out, function(a, b) return a.skill < b.skill end)
  return { label = "Mobs to skin", list = out }
end

local function Zone(from, to, title, text, nodes, faction, when)
  table.insert(steps, { kind = "guide", from = from, to = to, faction = faction, when = when, gather = true,
                        title = title, nodes = nodes, text = text })
end

-- the knife (learning Skinning itself is CraftRoute's own first step while it isn't learned)
table.insert(steps, { kind = "guide", from = 1, to = 75, items = { { KNIFE, 1 } }, nearTrainer = { "Skinning" },
  title = "Buy a Skinning Knife",
  text = "Buy a Skinning Knife from the Leatherworking Supply vendor near your trainer or most General Goods "
    .. "vendors. It only has to be in your bags, not equipped." })

-- 1-75: starting-area mobs give points all the way to 75
Zone(1, 75, "Skin in the Valley of Trials",
  "Skin the Mottled Boars in the Valley of Trials, Durotar, until 75 (mob level 1-2). Any starting zone works "
    .. "- on a new character, skin whatever you kill there.",
  Mobs({ "Mottled Boar", 1 }), H)
Zone(1, 75, "Skin in Northshire Valley",
  "Skin the Young Wolves and Timber Wolves in Northshire Valley, Elwynn Forest, until 75 (mob level 1-2). Any "
    .. "starting zone works - on a new character, skin whatever you kill there.",
  Mobs({ "Young Wolf", 1 }, { "Timber Wolf", 1 }), A)

-- 75-150
Zone(75, 150, "Skin in The Barrens",
  "Skin at the small raptor camp just west of Northwatch Hold in The Barrens until 150 (mob level 16-18). "
    .. "Skin the level 16-17 ones until 80, then the level 18 ones too. The last 10 points are green, but the "
    .. "respawn is fast.",
  Mobs({ "Sunscale Scytheclaw", 16 }, { "Zhevra Charger", 16 }, { "Ornery Plainstrider", 16 }), H)
Zone(75, 125, "Skin in Loch Modan",
  "Skin in Loch Modan until about 125 (mob level 16-17) - pull the Loch Crocolisks on the shore too. Then "
    .. "head north to the Wetlands, on the way to Hillsbrad.",
  Mobs({ "Elder Mountain Boar", 16 }, { "Black Bear Patriarch", 16 }, { "Loch Crocolisk", 16 }), A)
Zone(125, 150, "Skin in the Wetlands",
  "Skin the raptors at Whelgar's Excavation Site in the Wetlands until 150 (mob level 25-27) - there are "
    .. "always a few there.",
  Mobs({ "Mottled Scytheclaw", 25 }, { "Mottled Razormaw", 25 }), A)

-- 150-225: one of these
table.insert(choices, { key = "expert", label = "150-225: one of these", options = {
  { key = "hillsbrad", label = "Hillsbrad Foothills" },
  { key = "duskwood", label = "Duskwood" },
} })
Zone(150, 225, "Skin in the Foothill Caverns",
  "Skin the yetis in the Foothill Caverns, Hillsbrad Foothills, on the border of Alterac Mountains, until 225 "
    .. "(mob level 30-32). They respawn so fast you can stay inside the cave. Horde get there from Tarren "
    .. "Mill, Alliance from Southshore.",
  Mobs({ "Cave Yeti", 30 }, { "Ferocious Yeti", 30 }), nil, { expert = "hillsbrad" })
Zone(150, 225, "Skin at the Rotting Orchard",
  "Skin the worgen in Duskwood until 225 (mob level 26-29): clear Roland's Doom, outside and in the cave, then "
    .. "go to the Rotting Orchard while they respawn. Horde can get there from Grom'gol.",
  Mobs({ "Nightbane Worgen", 26 }, { "Nightbane Shadow Weaver", 26 }, { "Nightbane Dark Runner", 26 }), nil,
  { expert = "duskwood" })

-- 225-300
Zone(225, 280, "Skin in Feralas",
  "Skin the yetis in the cave at Feral Scar Vale, south Feralas, until 280 (mob level 43-46). Horde get there "
    .. "from Camp Mojache, Alliance from Feathermoon Stronghold.",
  Mobs({ "Feral Scar Yeti", 43 }, { "Enraged Feral Scar", 43 }, { "Hulking Feral Scar", 43 }))
Zone(280, 300, "Skin in Un'Goro Crater",
  "Fly to Marshal's Refuge and skin the dinosaurs in the west of Un'Goro Crater until 300 (mob level 50-55).",
  Mobs({ "Diemetradon", 50 }, { "Pterrordax", 50 }, { "Elder Diemetradon", 50 }, { "Frenzied Pterrordax", 50 }))

CR.RegisterRoute("Skinning", {
  label = "Skinning",
  source = "wow-professions.com (Forever guide)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  -- Learn Skinning: besides any trainer, Skyborne can take it as a quest reward where they start
  learnAlso = {
    { race = "Skyborne", quest = 93552, questName = "Harvesting Windstones", npc = 251363,
      npcName = "Dalia the Collector",
      text = "Or on Zephras Isle: take Harvesting Windstones from Dalia the Collector in Thendal Village, and "
        .. "pick Pelt Collecting for Beginners as your reward. Thendal Village has no trainer; the island's are "
        .. "Ishlee Breezewhisper in Valanaar and Mendalass Tattermend in Shen'dar Village." },
  },

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Skinning at a Skinning trainer (skill 50, level 10). The Junior Skinning "
        .. "Trainers in the starting areas only teach up to 75." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Skinning at a Skinning trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Skinning at a Skinning trainer (skill 200, level 35)." },
  },

  choices = choices,
  steps = steps,
})

CR.extraNames[KNIFE] = "Skinning Knife"
