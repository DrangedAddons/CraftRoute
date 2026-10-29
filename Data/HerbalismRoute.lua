-- Herbalism route from wow-professions.com's Forever Herbalism guide
-- (https://www.wow-professions.com/forever/herbalism-leveling-guide). From 170 the guide follows the
-- Classic routes (the beta capped at 30), so those bands may change once it's revised.
-- Every step is an instruction ("guide" step); each band's zones are a choice, so you pick the one
-- that suits you.
local _, CR = ...

local choices, steps = {}, {}

-- The herbs each band is after, with the Herbalism skill each needs to pick (the guide's values) -
-- the step's card lists them, green when you can pick them and red when you can't yet.
local HERB = {
  ["Peacebloom"] = 1, ["Silverleaf"] = 1, ["Earthroot"] = 15, ["Mageroyal"] = 50, ["Briarthorn"] = 70,
  ["Stranglekelp"] = 85, ["Bruiseweed"] = 100, ["Wild Steelbloom"] = 115, ["Kingsblood"] = 125,
  ["Liferoot"] = 150, ["Fadeleaf"] = 160, ["Goldthorn"] = 170, ["Khadgar's Whisker"] = 185,
  ["Firebloom"] = 205, ["Purple Lotus"] = 210, ["Sungrass"] = 230, ["Ghost Mushroom"] = 245,
  ["Gromsblood"] = 250, ["Golden Sansam"] = 260, ["Dreamfoil"] = 270, ["Mountain Silversage"] = 280,
  ["Plaguebloom"] = 285,
}
local function Herbs(...)
  local out = {}
  for _, name in ipairs({ ... }) do table.insert(out, { name = name, skill = HERB[name] }) end
  table.sort(out, function(a, b) return a.skill < b.skill end)
  return { label = "Herbs to pick", list = out }
end
local NODES = {
  start = Herbs("Peacebloom", "Silverleaf", "Earthroot"),
  mid = Herbs("Mageroyal", "Briarthorn", "Stranglekelp"),
  expert = Herbs("Bruiseweed", "Wild Steelbloom", "Stranglekelp", "Kingsblood", "Liferoot"),
  upper = Herbs("Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn", "Khadgar's Whisker"),
  artisan = Herbs("Firebloom", "Purple Lotus"),
}
-- One choice whose options are zones; each option becomes a gathering step over [from, to]. The
-- band's advice (which herbs to look for), if any, goes in every zone's step - not a step of its
-- own, which would only be a line to read with nothing to do.
local function Zones(key, label, from, to, zones, advice)
  local c = { key = key, label = label, options = {} }
  for _, z in ipairs(zones) do
    table.insert(c.options, { key = z[1], label = z[2], faction = z[4] })
    table.insert(steps, { kind = "guide", from = from, to = to, when = { [key] = z[1] }, faction = z[4],
                          gather = true, title = "Pick herbs in " .. z[2], nodes = NODES[key],
                          text = advice and (z[3] .. " " .. advice) or z[3] })
  end
  table.insert(choices, c)
end

Zones("start", "1-70: one starting zone", 1, 70, {
  { "durotar", "Durotar", "Pick herbs in Durotar until 70.", "Horde" },
  { "mulgore", "Mulgore", "Pick herbs in Mulgore until 70.", "Horde" },
  { "tirisfal", "Tirisfal Glades", "Pick herbs in Tirisfal Glades until 70.", "Horde" },
  { "elwynn", "Elwynn Forest", "Pick herbs in Elwynn Forest until 70.", "Alliance" },
  { "dunmorogh", "Dun Morogh", "Pick herbs in Dun Morogh until 70.", "Alliance" },
  { "teldrassil", "Teldrassil", "Pick herbs in Teldrassil until 70.", "Alliance" },
  { "zephras", "Zephras Isle", "Pick herbs on Zephras Isle until 70." },
}, "Every starting zone is full of Peacebloom, Silverleaf and Earthroot, and they respawn so fast you "
  .. "can just circle and pick them as you see them.")

Zones("mid", "70-115: one of these", 70, 115, {
  { "silverpine", "Silverpine Forest", "Pick herbs in Silverpine Forest until 115. In its lower part they "
    .. "respawn fast enough to run small circles; with a mount, run the main road up and down to the loop.",
    "Horde" },
  { "lochmodan", "Loch Modan", "Pick herbs in Loch Modan until 115 - an easy route, with a few fewer herbs "
    .. "than Darkshore.", "Alliance" },
  { "darkshore", "Darkshore", "Pick herbs in Darkshore until 115. It has herbs everywhere and a fast "
    .. "respawn, so small circles in different areas work too.", "Alliance" },
}, "Mageroyal and Briarthorn now; Stranglekelp (in water) once you have 85.")

Zones("expert", "115-170: one of these", 115, 170, {
  { "hillsbrad", "Hillsbrad Foothills", "Pick herbs in Hillsbrad Foothills until 170 - one loop gives the "
    .. "herbs time to respawn." },
  { "stonetalon", "Stonetalon Mountains", "Pick herbs in the Stonetalon Mountains until 170. The safest area "
    .. "has level 14-15 mobs; another has level 25 mobs; the busiest one, full of mobs, has more Kingsblood - "
    .. "worth it from 125." },
}, "Bruiseweed, Wild Steelbloom and Stranglekelp; Kingsblood from 125 and Liferoot from 150 - keep to the "
  .. "easier parts of the zone until 150. With +5 Herbalism (gloves enchant, Herbalist's Gloves) you can "
  .. "pick Kingsblood from 120.")

Zones("upper", "170-205: one of these", 170, 205, {
  { "stv", "Stranglethorn Vale", "Pick herbs in Stranglethorn Vale until 205." },
  { "arathi", "Arathi Highlands", "Pick herbs in the Arathi Highlands until 205." },
}, "Kingsblood, Liferoot, Fadeleaf and Goldthorn; Khadgar's Whisker from 185.")

Zones("artisan", "205-230: one of these", 205, 230, {
  { "tanaris", "Tanaris", "Pick herbs in Tanaris until 230." },
  { "searing", "Searing Gorge", "Pick herbs in the Searing Gorge until 230." },
}, "Purple Lotus and Firebloom.")

table.insert(steps, { kind = "guide", from = 230, to = 270, gather = true,
  title = "Pick herbs in The Hinterlands",
  nodes = Herbs("Sungrass", "Purple Lotus", "Ghost Mushroom", "Golden Sansam"),
  text = "Pick Sungrass, Purple Lotus, Ghost Mushroom and Golden Sansam in The Hinterlands until 270. Its cave "
    .. "is full of Ghost Mushrooms once you have 245." })

table.insert(steps, { kind = "guide", from = 270, to = 300, gather = true,
  title = "Pick herbs in Felwood",
  nodes = Herbs("Sungrass", "Gromsblood", "Golden Sansam", "Dreamfoil", "Mountain Silversage", "Plaguebloom"),
  text = "Pick Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage and Plaguebloom in Felwood "
    .. "until 300." })

CR.RegisterRoute("Herbalism", {
  label = "Herbalism",
  source = "wow-professions.com (Forever guide)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  -- Learn Herbalism: besides any trainer, Skyborne can take it as a quest reward where they start
  learnAlso = {
    { race = "Skyborne", quest = 93552, questName = "Harvesting Windstones", npc = 251363,
      npcName = "Dalia the Collector",
      text = "Or on Zephras Isle: take Harvesting Windstones from Dalia the Collector in Thendal Village, and "
        .. "pick Wild Harvest as your reward. Thendal Village has no trainer; the island's are Syriel "
        .. "Nightrain in Valanaar and Halassa Fernbreeze in Shen'dar Village." },
  },

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Herbalism at a Herbalism trainer (skill 50, level 10). The Junior Herbalism "
        .. "Trainers in the starting areas only teach up to 75." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Herbalism at a Herbalism trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Herbalism at a Herbalism trainer (skill 200, level 35), before you leave for "
        .. "Tanaris or the Searing Gorge - neither has a trainer." },
  },

  choices = choices,
  steps = steps,
})
