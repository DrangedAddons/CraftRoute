-- Herbalism route from wow-professions.com's Classic Herbalism guide
-- (https://www.wow-professions.com/classic/herbalism-leveling-guide-classic-wow) - a stand-in until
-- there's a Forever one; gathering changes little between the two. Every step is an instruction
-- ("guide" step); each band's zones are a choice, so you pick the one that suits you.
local _, CR = ...

local choices, steps = {}, {}
-- One choice whose options are zones; each option becomes a gathering step over [from, to]. The
-- band's advice (which herbs to look for), if any, goes in every zone's step - not a step of its
-- own, which would only be a line to read with nothing to do.
local function Zones(key, label, from, to, zones, advice)
  local c = { key = key, label = label, options = {} }
  for _, z in ipairs(zones) do
    table.insert(c.options, { key = z[1], label = z[2], faction = z[4] })
    table.insert(steps, { kind = "guide", from = from, to = to, when = { [key] = z[1] }, faction = z[4],
                          gather = true, title = "Pick herbs in " .. z[2],
                          text = advice and (z[3] .. " " .. advice) or z[3] })
  end
  table.insert(choices, c)
end

Zones("start", "1-70: one starting zone", 1, 70, {
  { "durotar", "Durotar", "Pick herbs in Durotar until 70.", "Horde" },
  { "mulgore", "Mulgore", "Pick herbs in Mulgore until 70.", "Horde" },
  { "tirisfal", "Tirisfal Glades", "Pick herbs in Tirisfal Glades until 70.", "Horde" },
  { "elwynn", "Elwynn Forest", "Pick herbs in Elwynn Forest until 70.", "Alliance" },
  { "teldrassil", "Teldrassil", "Pick herbs in Teldrassil until 70.", "Alliance" },
  { "dunmorogh", "Dun Morogh", "Pick herbs in Dun Morogh until 70.", "Alliance" },
}, "Peacebloom, Silverleaf and Earthroot - any starting zone has them.")

Zones("mid", "70-115: one of these", 70, 115, {
  { "barrens", "The Barrens", "Pick herbs in The Barrens until 115 - it's big enough for more than one loop.",
    "Horde" },
  { "silverpine", "Silverpine Forest", "Pick herbs in Silverpine Forest until 115.", "Horde" },
  { "lochmodan", "Loch Modan", "Pick herbs in Loch Modan until 115.", "Alliance" },
  { "darkshore", "Darkshore", "Pick herbs in Darkshore until 115.", "Alliance" },
}, "Mageroyal and Briarthorn now; Stranglekelp (in water) once you have 85.")

Zones("expert", "115-170: one of these", 115, 170, {
  { "hillsbrad", "Hillsbrad Foothills", "Pick herbs in Hillsbrad Foothills until 170." },
  { "wetlands", "Wetlands", "Pick herbs in the Wetlands until 170.", "Alliance" },
  { "stonetalon", "Stonetalon Mountains", "Pick herbs in the Stonetalon Mountains until 170." },
}, "Bruiseweed, Wild Steelbloom and Stranglekelp; Kingsblood from 125 and Liferoot from 150 - keep to the "
  .. "easier parts of the zone until 150.")

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
  text = "Pick Sungrass, Purple Lotus, Ghost Mushroom and Golden Sansam in The Hinterlands until 270. Its cave "
    .. "is full of Ghost Mushrooms once you have 245." })

table.insert(steps, { kind = "guide", from = 270, to = 300, gather = true,
  title = "Pick herbs in Felwood",
  text = "Pick Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage and Plaguebloom in Felwood "
    .. "until 300." })

CR.RegisterRoute("Herbalism", {
  label = "Herbalism",
  source = "wow-professions.com (Classic guide - stand-in)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Herbalism at any Herbalism trainer (skill 50, level 10)." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Herbalism at any Herbalism trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Herbalism at a Herbalism trainer (skill 200, level 35)." },
  },

  choices = choices,
  steps = steps,
})
