-- Leveling route transcribed from wow-professions.com's WoW Forever Blacksmithing guide
-- (https://www.wow-professions.com/forever/blacksmithing-leveling-guide, beta data, as of 12 Nov 2026).
-- Reagents per craft come from the recipe database; only skill ranges + craft counts live here.
-- 225-300 is the guide's untested draft from the game data: the Imperial Plate plans are quest
-- rewards from Derotain Mudsipper (Tanaris), each quest taking Thorium Bars.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local HAMMER = 5956
local THORIUM = 12359

-- Armorsmith / Weaponsmith (Wowhead Forever, Nov 2026). Tell the Blacksmithing trainer which you want
-- first - without it the spec quest doesn't show - then the quest is from the smith next to them.
local CHOOSE_ARMOR = { talk = "Tell {A:Myolor Sunderfury}{H:Krathok Moltenfist} \"I wish to become an armorsmith\"",
  npc = "{A:Myolor Sunderfury}{H:Krathok Moltenfist}" }
local CHOOSE_WEAPON = { talk = "Tell {A:Myolor Sunderfury}{H:Krathok Moltenfist} \"I wish to become a weaponsmith\"",
  npc = "{A:Myolor Sunderfury}{H:Krathok Moltenfist}" }
local ARMOR_FINAL_TEXT = "Tell {A:Myolor Sunderfury in Ironforge}{H:Krathok Moltenfist in Orgrimmar} you wish to "
  .. "become an armorsmith, then The Art of the Armorsmith is from {A:Grumnus Steelshaper}{H:Okothos Ironrager} "
  .. "next to them."
local WEAPON_FINAL_TEXT = "Tell {A:Myolor Sunderfury in Ironforge}{H:Krathok Moltenfist in Orgrimmar} you wish to "
  .. "become a weaponsmith, then The Way of the Weaponsmith is from {A:Ironus Coldsteel}{H:Borgosh Corebender} "
  .. "next to them. Afterwards you can become a Master Axesmith, Hammersmith or Swordsmith in Everlook, Winterspring."
local ARMOR_ITEMS = { { 7937, 4 }, { 7936, 2 }, { 7935, 1 } }   -- Ornate Mithril Helm, Boots, Breastplate
local function ArmorSpec(path, chain)
  return { spell = 9788, name = "Armorsmith", level = 40, skill = 200, final = "The Art of the Armorsmith",
    finalNpc = "{A:Grumnus Steelshaper}{H:Okothos Ironrager}", path = path,
    giver = "{A:Grumnus Steelshaper}{H:Okothos Ironrager}",
    patterns = {
      { spell = 7223, faction = "Alliance" },   -- Golden Scale Bracers (The Origins of Smithing)
      { spell = 9916, faction = "Horde" },      -- Steel Breastplate (The Old Ways)
      { spell = 9935, faction = "Horde" },      -- Steel Plate Helm
      9961, 9968, 9959,                         -- Mithril Coif, Heavy Mithril Boots / Breastplate (Trenton)
    },
    taught = { 9980, 9979, 9972 },   -- Ornate Mithril Helm / Boots / Breastplate: Trenton Lighthammer's quests
    chain = chain }
end
local ARMOR_CRAFT = ArmorSpec("craft", {
  { quest = "The Origins of Smithing", faction = "Alliance", ids = { A = 2758 }, items = { { 6040, 6 } },
    npc = "Hank the Hammer" },
  { quest = "The Old Ways", faction = "Horde", ids = { H = 2756 }, items = { { 7963, 4 }, { 7922, 4 } },
    npc = "Aturk the Anvil" },
  { quest = "In Search of Galvan", faction = "Alliance", ids = { A = 2759 }, npc = "Hank the Hammer",
    note = "Take it to McGavan in Booty Bay" },
  { quest = "Booty Bay or Bust!", faction = "Horde", ids = { H = 2757 }, npc = "Ox",
    note = "Take it to McGavan in Booty Bay" },
  { quest = "The Mithril Order", ids = { A = 2760, H = 2760 }, npc = "McGavan",
    note = "Take it to Galvan the Ancient in northern Stranglethorn Vale" },
  { accept = { "Smelt On, Smelt Off", "The Art of the Imbue", "The Great Silver Deceiver" }, npc = "Galvan the Ancient" },
  { quest = "Smelt On, Smelt Off", ids = { A = 2761, H = 2761 }, items = { { 3575, 40 }, { 3860, 40 } },
    npc = "Galvan the Ancient" },
  { quest = "The Art of the Imbue", ids = { A = 2763, H = 2763 }, items = { { 3860, 40 }, { 3864, 4 } },
    npc = "Galvan the Ancient" },
  { quest = "The Great Silver Deceiver", ids = { A = 2762, H = 2762 }, items = { { 3860, 40 }, { 6037, 5 } },
    npc = "Galvan the Ancient" },
  { quest = "Galvan's Finest Pupil", ids = { A = 2764, H = 2764 }, npc = "Galvan the Ancient",
    note = "Take it to Trenton Lighthammer in Gadgetzan, Tanaris" },
  { accept = { "A Good Head On Your Shoulders", "The World At Your Feet", "The Mithril Kid" },
    npc = "Trenton Lighthammer" },
  { quest = "A Good Head On Your Shoulders", ids = { A = 2771, H = 2771 }, items = { { 7931, 2 }, { 7928, 1 } },
    npc = "Trenton Lighthammer" },
  { quest = "The World At Your Feet", ids = { A = 2772, H = 2772 }, items = { { 7933, 2 }, { 7926, 1 } },
    npc = "Trenton Lighthammer" },
  { quest = "The Mithril Kid", ids = { A = 2773, H = 2773 }, items = { { 7930, 2 }, { 7927, 1 } },
    npc = "Trenton Lighthammer" },
  CHOOSE_ARMOR,
  { final = true, ids = { A = 5283, H = 5301 }, items = ARMOR_ITEMS },
})
local ARMOR_BUY = ArmorSpec("buy", { CHOOSE_ARMOR, { final = true, ids = { A = 5283, H = 5301 }, items = ARMOR_ITEMS } })

local WEAPON_ITEMS = { { 3853, 4 }, { 3855, 4 }, { 7941, 2 }, { 7945, 2 } }   -- Moonsteel, Massive Iron Axe, HM Axe, BB Mace
local function WeaponSpec(path)
  return { spell = 9787, name = "Weaponsmith", level = 40, skill = 200, final = "The Way of the Weaponsmith",
    finalNpc = "{A:Ironus Coldsteel}{H:Borgosh Corebender}", path = path,
    giver = "{A:Ironus Coldsteel}{H:Borgosh Corebender}",
    patterns = { 3496, 3498, 9993, 10001 },
    patternItems = { [3496] = 12163, [3498] = 12164 },
    patternNpcs = { [3496] = "Zarena Cromwind", [3498] = "Jaquilina Dramet{H:|Vharr}" },
    chain = { CHOOSE_WEAPON, { final = true, ids = { A = 5284, H = 5302 }, items = WEAPON_ITEMS } } }
end
local WEAPON_CRAFT, WEAPON_BUY = WeaponSpec("craft"), WeaponSpec("buy")

CR.RegisterRoute("Blacksmithing", {
  -- Change Specialisation, at the end once you have one
  specChange = { at = 300,
    text = "To switch, unlearn Blacksmithing in the Skills tab of your character window - you lose every "
      .. "recipe and all your skill. Level it back to 200, then do the other specialization's quest (pick it "
      .. "below)." },
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10,
      where = "{H:Snarl (Orgrimmar), James Van Brunt (Undercity), Karn Stonehoof (Thunder Bluff) or Angus "
        .. "Hammerhand (Bandarion Keep, Tirisfal)}{A:Therum Deepforge (Stormwind) or Rotgath Stonebeard "
        .. "(Ironforge)}" },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Saru Steelfury, Orgrimmar}{A:Bengus Deepforge, Ironforge} (50 silver)" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      where = "Brikk Keencraft, Booty Bay (both factions)" },
  },

  -- Bars are smelted with Mining, not made by Blacksmithing - buy or smelt them.
  noExpand = {},

  -- Everyday leveling mats, used only to rank auto-filled recipes before Auctionator has prices.
  commonMats = {
    [2835] = true, [2836] = true, [2838] = true, [7912] = true, [12365] = true,   -- stones
    [2840] = true, [2841] = true, [3576] = true, [3575] = true, [3859] = true,    -- copper, bronze, tin, iron, steel
    [3860] = true, [12359] = true, [2842] = true, [3577] = true, [6037] = true,   -- mithril, thorium, silver, gold, truesilver
    [2880] = true, [3466] = true, [2605] = true, [2604] = true, [4340] = true,    -- fluxes, dyes
    [2318] = true, [2319] = true, [4234] = true, [4304] = true, [8170] = true,    -- leathers
    [2589] = true, [2592] = true, [4306] = true, [4338] = true, [14047] = true,   -- cloth
  },

  choices = {
    { key = "j75", label = "75-80", options = {
      { key = "belt", label = "Runed Copper Belt" },
      { key = "rod", label = "Silver Rod (if Silver Bars are cheap)" },
    }},
    { key = "j125", label = "125-140", options = {
      { key = "sword", label = "Bronze Shortsword" },
      { key = "bracers", label = "Patterned Bronze Bracers (if you disenchant your greens)" },
    }},
    { key = "spec", label = "215 specialization", options = {
      { key = "none", label = "Not now" },
      { key = "armor", label = "Armorsmith" },
      { key = "weapon", label = "Weaponsmith" },
    }},
    { key = "armor", label = "Armorsmith quest items", options = {
      { key = "craft", label = "Craft them (The Mithril Order chain teaches the Ornate Mithril plans)" },
      { key = "buy", label = "Buy the finished items on the AH" },
    }},
    { key = "weapon", label = "Weaponsmith quest items", options = {
      { key = "craft", label = "Craft them (get the plans, buy the materials)" },
      { key = "buy", label = "Buy the finished weapons on the AH" },
    }},
    { key = "e215", label = "215-225", options = {
      { key = "breastplate", label = "Heavy Mithril Breastplate" },
      { key = "spurs", label = "Mithril Spurs (world drop plans)" },
    }},
    { key = "a240", label = "240-270", options = {
      { key = "imperial", label = "Imperial Plate Belt + Bracers (quests at 240)" },
      { key = "ebon", label = "Ebon Shiv + Ornate Thorium Handaxe (if the quests need 265)" },
      { key = "radiant", label = "Radiant Belt + Ornate Thorium Handaxe (world drop plans)" },
      { key = "tbracers", label = "Thorium Bracers + Ornate Thorium Handaxe (world drop plans)" },
    }},
  },

  steps = {
    -- Apprentice
    { kind = "guide", from = 1, to = 75, items = { { HAMMER, 1 } }, nearTrainer = { "Blacksmithing" },
      -- hammer vendors as the guide lists them (Oct 2026); the named ones get map pins
      text = "Buy a Blacksmith Hammer - most recipes need it. Sold by "
        .. "{H:Sumi (Orgrimmar), Samuel Van Brunt (Undercity) and Taur Stonehoof (Thunder Bluff), each right next "
        .. "to the trainer; Flakk in Razor Hill; Walter Mason in Deathknell or Abigail Shiel in Brill (nobody near "
        .. "Angus Hammerhand sells one); on Zephras Isle Halavuul Cragwind in Valanaar or Aedi Thriceforged in "
        .. "Shen'dar Village}"
        .. "{A:Kaita Deepforge (Stormwind City) and Thurgrum Deepforge (Ironforge), each right next to the "
        .. "trainer; Tharynn Bouden in Goldshire; Thrawn Boltar in Kharanos; Elisa Steelhand in Auberdine; on "
        .. "Zephras Isle Halavuul Cragwind in Valanaar or Aedi Thriceforged in Shen'dar Village}." },
    { from = 1,   to = 25,  spell = 2660, crafts = 30 },
    { from = 25,  to = 50,  spell = 3320, crafts = 30, note = "Keep 26 - for the gauntlets and Silver Rods" },
    { from = 50,  to = 67,  spell = 3326, crafts = 36, note = "Make all 36 - for the bracers at 95 and 112" },
    { from = 67,  to = 75,  spell = 3323, crafts = 8 },

    -- Journeyman
    { from = 75,  to = 80,  spell = 2666, crafts = 5, when = { j75 = "belt" } },
    { from = 75,  to = 80,  spell = 7818, crafts = 5, when = { j75 = "rod" },
      note = "If 1 Silver Bar costs less than 10 Copper Bars" },
    { from = 80,  to = 95,  spell = 2666, crafts = 18 },
    { from = 95,  to = 100, spell = 2672, crafts = 5, note = "Use 10 of the Coarse Grinding Stones from 50 - keep the other 26 for 112" },
    { from = 100, to = 112, spell = 3337, crafts = 20, note = "Keep all 20 - for the Golden Scale Bracers at 180" },
    { from = 112, to = 125, spell = 2672, crafts = 13 },
    { from = 125, to = 140, spell = 2672, crafts = 24, when = { j125 = "bracers" } },
    { from = 125, to = 140, spell = 2742, crafts = 24, when = { j125 = "sword" },
      note = "They vendor for over twice what the bracers do, so they end up cheaper. Weak Flux (and Strong "
        .. "Flux for the Bronze Warhammers, 140-170) from the Blacksmithing Supply vendor in any capital" },
    { from = 140, to = 150, spell = 9985, crafts = 10 },

    -- Expert
    { from = 150, to = 170, spell = 9985, crafts = 29 },
    { from = 170, to = 175, spell = 3501, crafts = 9,
      note = "Green Dye from {H:Tamar (Orgrimmar)}{A:Bombus Finespindle (Ironforge)}" },
    { from = 175, to = 180, spell = 9920, crafts = 8, note = "Keep them - 6 go into the Heavy Mithril Axes at 210" },
    { from = 180, to = 195, spell = 7223, crafts = 20,
      note = "Uses the 20 Heavy Grinding Stones from 100 and 20 more (60 Heavy Stone). With Mining 165 you can "
        .. "smelt the Steel Bars from Iron Bar and Coal - Coal is sold by the Blacksmithing Supply vendor in any "
        .. "capital.{A: Keep 6 - you might need them for Armorsmithing.}" },
    { from = 195, to = 210, spell = 9928, crafts = 21 },
    { from = 210, to = 215, spell = 9993, crafts = 6, note = "Keep 2 - you might need them for Weaponsmithing" },

    -- Specialization quests (wow-professions.com's Armorsmith / Weaponsmith guides, Nov 2026)
    { kind = "guide", from = 215, to = 215,
      text = "Blacksmithing specialization: at Blacksmithing 200 and level 40 you can become an Armorsmith or a "
        .. "Weaponsmith. Optional - you don't need one to level, and you can choose later. Pick one under the "
        .. "215 specialization choice for its quest steps." },
    -- Armorsmith / Weaponsmith: a Prerequisites card, then the quest card - crafting the pieces or
    -- buying them. Crafting Armorsmith's goes through The Mithril Order chain (it teaches the plans).
    { kind = "guide", from = 215, to = 215, when = { spec = "armor", armor = "craft" }, specPart = "prep",
      title = "Armorsmith: Prerequisites",
      text = "Get all of this before you start The Mithril Order chain. The chain teaches the Ornate Mithril "
        .. "plans - Galvan the Ancient's quests the Pants, Shoulders and Gloves, Trenton Lighthammer's the Helm, "
        .. "Boots and Breastplate. Mithril Coif, Heavy Mithril Boots and Heavy Mithril Breastplate are also "
        .. "taught by Brikk Keencraft in Booty Bay.",
      spec = ARMOR_CRAFT },
    { kind = "guide", from = 215, to = 215, when = { spec = "armor", armor = "craft" }, specPart = "quests",
      title = "Become an Armorsmith",
      text = "The Mithril Order starts with {A:Hank the Hammer in Stormwind}{H:Aturk the Anvil in Orgrimmar}, "
        .. "then McGavan in Booty Bay, Galvan the Ancient in northern Stranglethorn Vale and Trenton Lighthammer "
        .. "in Gadgetzan. Do all three of Galvan's quests before you leave him. " .. ARMOR_FINAL_TEXT,
      spec = ARMOR_CRAFT },
    { kind = "guide", from = 215, to = 215, when = { spec = "armor", armor = "buy" }, specPart = "prep",
      title = "Armorsmith: Prerequisites",
      text = "Buy all of this before you go to the quest. The pieces only have to be in your bags.",
      spec = ARMOR_BUY },
    { kind = "guide", from = 215, to = 215, when = { spec = "armor", armor = "buy" }, specPart = "quests",
      title = "Become an Armorsmith", text = ARMOR_FINAL_TEXT, spec = ARMOR_BUY },
    { kind = "guide", from = 215, to = 215, when = { spec = "weapon", weapon = "craft" }, specPart = "prep",
      title = "Weaponsmith: Prerequisites",
      text = "Get all of this before you go to the quest. Plans: Moonsteel Broadsword is sold by Zarena Cromwind "
        .. "in Booty Bay, Plans: Massive Iron Axe by Jaquilina Dramet at Nesingwary's Camp{H: or Vharr in "
        .. "Grom'gol}. Brikk Keencraft in Booty Bay teaches Big Black Mace.",
      spec = WEAPON_CRAFT },
    { kind = "guide", from = 215, to = 215, when = { spec = "weapon", weapon = "craft" }, specPart = "quests",
      title = "Become a Weaponsmith", text = WEAPON_FINAL_TEXT, spec = WEAPON_CRAFT },
    { kind = "guide", from = 215, to = 215, when = { spec = "weapon", weapon = "buy" }, specPart = "prep",
      title = "Weaponsmith: Prerequisites",
      text = "Buy all of this before you go to the quest. The weapons only have to be in your bags.",
      spec = WEAPON_BUY },
    { kind = "guide", from = 215, to = 215, when = { spec = "weapon", weapon = "buy" }, specPart = "quests",
      title = "Become a Weaponsmith", text = WEAPON_FINAL_TEXT, spec = WEAPON_BUY },
    { from = 215, to = 225, spell = 9959, crafts = 10, when = { e215 = "breastplate" },
      note = "Keep 2 - you might need them for Armorsmithing" },
    { from = 215, to = 225, spell = 9964, crafts = 10, when = { e215 = "spurs" },
      note = "Plans: Mithril Spurs is a world drop - check the AH" },

    -- Artisan (the guide's untested draft). The Imperial Plate plans are quest rewards from
    -- Derotain Mudsipper in Tanaris (level 50); each quest takes Thorium Bars. In Classic they needed
    -- 265 - Forever lowered the recipes to 240, so the quests probably moved too (else: Ebon Shiv).
    { from = 225, to = 230, spell = 16641, crafts = 5 },
    { from = 230, to = 240, spell = 9968, crafts = 16, note = "Keep 2 - you might need them for Armorsmithing" },
    { kind = "guide", from = 240, to = 245, when = { a240 = "imperial" }, recipes = { 16647 },
      items = { { THORIUM, 20 } }, title = "Learn Imperial Plate Belt",
      text = "Do the Imperial Plate Belt quest from Derotain Mudsipper in Tanaris (level 50, 20 Thorium Bars). "
        .. "Bring at least 250 Thorium Bars: the belts, and the next three plans come from him too. If the "
        .. "quest still needs Blacksmithing 265, pick the Ebon Shiv path for 240-270 instead." },
    { from = 240, to = 245, spell = 16647, crafts = 5, when = { a240 = "imperial" } },
    { kind = "guide", from = 245, to = 270, when = { a240 = "imperial" }, recipes = { 16649 },
      items = { { THORIUM, 20 } }, title = "Learn Imperial Plate Bracers",
      text = "Do the Imperial Plate Bracer quest from Derotain Mudsipper in Tanaris (20 Thorium Bars)." },
    { from = 245, to = 270, spell = 16649, crafts = 27, when = { a240 = "imperial" } },
    { from = 240, to = 255, spell = 10013, crafts = 15, when = { a240 = "ebon" },
      note = "Plans from Magnus Frostwake, Western Plaguelands" },
    { from = 240, to = 255, spell = 16645, crafts = 15, when = { a240 = "radiant" },
      note = "Plans: Radiant Belt is a world drop" },
    { from = 240, to = 255, spell = 16644, crafts = 17, when = { a240 = "tbracers" },
      note = "Plans: Thorium Bracers is a world drop" },
    { from = 255, to = 270, spell = 16969, crafts = 15, when = { a240 = { "ebon", "radiant", "tbracers" } },
      note = "Plans from Magnus Frostwake, Western Plaguelands" },
    { kind = "guide", from = 270, to = 290, recipes = { 16657 }, items = { { THORIUM, 40 } },
      title = "Learn Imperial Plate Boots",
      text = "Do the Imperial Plate Boots quest from Derotain Mudsipper in Tanaris (40 Thorium Bars)." },
    { from = 270, to = 290, spell = 16657, crafts = 20 },
    { kind = "guide", from = 290, to = 300, recipes = { 16730 }, items = { { THORIUM, 60 } },
      title = "Learn Imperial Plate Leggings",
      text = "Do the Imperial Plate Leggings quest from Derotain Mudsipper in Tanaris (60 Thorium Bars)." },
    { from = 290, to = 300, spell = 16730, crafts = 10 },
  },
})

CR.extraNames[HAMMER] = "Blacksmith Hammer"
