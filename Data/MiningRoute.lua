-- Mining route from wow-professions.com's Classic Mining guide
-- (https://www.wow-professions.com/classic/mining-leveling-guide-classic-wow) - a stand-in until
-- there's a Forever one; gathering changes little between the two. Every step is an instruction
-- ("guide" step); each band's zones are a choice, so you pick the one that suits you.
-- Smelting (Mining's crafting window) is in MiningRecipes.lua; the route doesn't craft.
local _, CR = ...

local PICK = 2901

local choices, steps = {}, {}
-- One choice whose options are zones; each option becomes a gathering step over [from, to].
local function Zones(key, label, from, to, zones)
  local c = { key = key, label = label, options = {} }
  for _, z in ipairs(zones) do
    table.insert(c.options, { key = z[1], label = z[2], faction = z[4] })
    table.insert(steps, { kind = "guide", from = from, to = to, when = { [key] = z[1] }, faction = z[4],
                          gather = true, title = "Mine in " .. z[2], text = z[3] })
  end
  table.insert(choices, c)
end

table.insert(steps, { kind = "guide", from = 1, to = 65, items = { { PICK, 1 } },
  title = "Get a Mining Pick, mine Copper",
  text = "Buy a Mining Pick from the Mining Supply vendor by your trainer - it only has to be in your bags, "
    .. "not equipped. Then mine Copper Veins in a starting zone; they respawn quickly, so stay in one area "
    .. "rather than circling the whole zone." })
Zones("copper", "1-65: Copper - one starting zone", 1, 65, {
  { "durotar", "Durotar", "Mine Copper in Durotar until 65. At a high level, clear the Venture Co. mine and the "
    .. "ledge behind it for about 8 more veins.", "Horde" },
  { "mulgore", "Mulgore", "Mine Copper in Mulgore until 65 (low levels: skip the caves).", "Horde" },
  { "tirisfal", "Tirisfal Glades", "Mine Copper in Tirisfal Glades until 65.", "Horde" },
  { "elwynn", "Elwynn Forest", "Mine Copper in Elwynn Forest until 65 (low levels: skip the caves).", "Alliance" },
  { "dunmorogh", "Dun Morogh", "Mine Copper in Dun Morogh until 65.", "Alliance" },
  { "darkshore", "Darkshore", "Mine Copper in Darkshore until 65 - night elves: Teldrassil has no Copper, so "
    .. "start here.", "Alliance" },
})

table.insert(steps, { kind = "guide", from = 65, to = 125,
  title = "Tin and Silver; smelt Silver at 75",
  text = "Copper, Tin and Silver from here. Smelt Silver from 75 to help reach 125 - buy Silver Ore, smelt it "
    .. "and sell the bars; they sell for about what the ore costs." })
Zones("tin", "65-125: Copper and Tin", 65, 125, {
  { "hillsbrad", "Hillsbrad Foothills", "Mine in Hillsbrad Foothills until 125 (low levels: skip the caves)." },
  { "redridge", "Redridge Mountains", "Mine in Redridge Mountains until 125 - low levels keep to the east side.",
    "Alliance" },
  { "ashenvale", "Ashenvale", "Mine in Ashenvale until 125. With high levels the cave always has two Tin "
    .. "Veins." },
  { "barrens", "The Barrens", "Mine in The Barrens until 125 - the southern part has more Copper and Tin.",
    "Horde" },
})

table.insert(steps, { kind = "guide", from = 125, to = 175,
  title = "Iron and Gold; smelt Gold at 155",
  text = "Iron, Tin and Gold from here. Smelt Gold from 155: about 30 Gold Ore smelted takes you to around "
    .. "175 - buy the ore and sell the bars." })
Zones("iron", "125-175: Iron and Tin", 125, 175, {
  { "arathi", "Arathi Highlands", "Mine in Arathi Highlands until 175. Go to the back of each cave - the veins "
    .. "aren't all in sight from the entrance (low levels: skip the caves)." },
  { "desolace", "Desolace", "Mine in Desolace until 175." },
  { "needles", "Thousand Needles", "Mine in Thousand Needles until 175." },
})

table.insert(steps, { kind = "guide", from = 175, to = 245,
  title = "Mithril, then Truesilver at 230",
  text = "Mithril from here, and Truesilver Deposits from 230." })
Zones("mithril", "175-245: Mithril and Truesilver", 175, 245, {
  { "hinterlands", "The Hinterlands", "Mine Mithril in The Hinterlands until 245. Low levels: avoid the area "
    .. "with level 62 elites, and maybe the cave." },
  { "tanaris", "Tanaris", "Mine Mithril in Tanaris until 245 (below level 60: skip the caves)." },
})

table.insert(steps, { kind = "guide", from = 245, to = 275,
  title = "Small Thorium Veins from 245",
  text = "Mithril, Truesilver and now Small Thorium Veins." })
Zones("thorium", "245-275: Mithril and Thorium", 245, 275, {
  { "ungoro", "Un'Goro Crater", "Mine in Un'Goro Crater until 275 - the caves hold 2-3 veins each." },
  { "blasted", "Blasted Lands", "Mine in the Blasted Lands until 275 (low levels: maybe skip the southern "
    .. "cave)." },
  { "felwood", "Felwood", "Mine in Felwood until 275. Its caves are full of mobs - for well-geared level 60s, "
    .. "or stealth. Alliance can't mine in the Garrison Armory." },
})

table.insert(steps, { kind = "guide", from = 275, to = 300,
  title = "Rich Thorium Veins from 275",
  text = "Thorium and Mithril - and from 275 you can mine Rich Thorium Veins too." })
Zones("richthorium", "275-300: Thorium and Rich Thorium", 275, 300, {
  { "ungoro2", "Un'Goro Crater", "Mine in Un'Goro Crater until 300, Rich Thorium Veins included." },
  { "epl", "Eastern Plaguelands", "Mine in the Eastern Plaguelands until 300 (low levels: its caves have "
    .. "level 50 mobs)." },
  { "winterspring", "Winterspring", "Mine in Winterspring until 300." },
  { "steppes", "Burning Steppes", "Mine in the Burning Steppes until 300 - mind the elite patrols." },
})

CR.RegisterRoute("Mining", {
  label = "Mining",
  source = "wow-professions.com (Classic guide - stand-in)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Mining at any Mining trainer (skill 50, level 10)." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Mining at any Mining trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Mining at a Mining trainer (skill 200, level 35)." },
  },

  choices = choices,
  steps = steps,
})

CR.extraNames[PICK] = "Mining Pick"
