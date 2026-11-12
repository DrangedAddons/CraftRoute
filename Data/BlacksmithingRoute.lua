-- Leveling route transcribed from wow-professions.com's WoW Forever Blacksmithing guide
-- (https://www.wow-professions.com/forever/blacksmithing-leveling-guide, beta data, as of 12 Nov 2026).
-- Reagents per craft come from the recipe database; only skill ranges + craft counts live here.
-- 225-300 is the guide's untested draft from the game data: the Imperial Plate plans are quest
-- rewards from Derotain Mudsipper (Tanaris), each quest taking Thorium Bars.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local HAMMER = 5956
local THORIUM = 12359

CR.RegisterRoute("Blacksmithing", {
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
    { kind = "guide", from = 215, to = 215, when = { spec = "armor" }, title = "Become an Armorsmith",
      spec = { spell = 9788, name = "Armorsmith", level = 40 },
      text = "Talk to {H:Krathok Moltenfist in Orgrimmar}{A:Myolor Sunderfury in Ironforge} and pick \"I wish "
        .. "to become an armorsmith\". Then take The Art of the Armorsmith from the Armorsmith trainer next to "
        .. "them, {H:Okothos Ironrager}{A:Grumnus Steelshaper}."
        .. "\n\nIt needs 4 Ornate Mithril Helm, 2 Ornate Mithril Boots and 1 Ornate Mithril Breastplate in your "
        .. "bags - you can buy them or have someone craft them."
        .. "\n\nTo make them yourself, the plans come from The Mithril Order quest chain (Blacksmithing 210): "
        .. "{A:The Origins of Smithing from Hank the Hammer in Stormwind (6 Golden Scale Bracers - the ones you "
        .. "kept at 180)}{H:The Old Ways from Aturk the Anvil in Orgrimmar (4 Steel Breastplate, 4 Steel Plate "
        .. "Helm)}, then McGavan in Booty Bay, Galvan the Ancient in northern Stranglethorn Vale and Trenton "
        .. "Lighthammer in Gadgetzan (Blacksmithing 235, with the Heavy Mithril Boots and Breastplates you kept)." },
    { kind = "guide", from = 215, to = 215, when = { spec = "weapon" }, title = "Become a Weaponsmith",
      spec = { spell = 9787, name = "Weaponsmith", level = 40 },
      text = "Talk to {H:Krathok Moltenfist in Orgrimmar}{A:Myolor Sunderfury in Ironforge} and pick \"I wish "
        .. "to become a weaponsmith\" - without that the quest doesn't show. Then take The Way of the "
        .. "Weaponsmith from the Weaponsmith trainer next to them, {H:Borgosh Corebender}{A:Ironus Coldsteel}."
        .. "\n\nIt needs 4 Moonsteel Broadsword, 4 Massive Iron Axe, 2 Heavy Mithril Axe (the ones you kept at "
        .. "210) and 2 Big Black Mace in your bags - bought or crafted. Plans: Moonsteel Broadsword is sold by "
        .. "Zarena Cromwind in Booty Bay, Plans: Massive Iron Axe by Jaquilina Dramet at Nesingwary's Camp"
        .. "{H: or Vharr in Grom'gol}. Brikk Keencraft in Booty Bay teaches Big Black Mace at 205."
        .. "\n\nAfterwards you can become a Master Axesmith, Hammersmith or Swordsmith in Everlook, "
        .. "Winterspring (the three trainers stand together in one house), each with a dungeon quest." },
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
