-- Leveling route transcribed from wow-professions.com's WoW Forever Blacksmithing guide
-- (https://www.wow-professions.com/forever/blacksmithing-leveling-guide, beta data, as of 8 Oct 2026).
-- Reagents per craft come from the recipe database; only skill ranges + craft counts live here.
-- The guide stops at 225 - beyond that CraftRoute fills the gap automatically (see Planner.lua).
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local HAMMER = 5956

CR.RegisterRoute("Blacksmithing", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 225,
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
    { key = "e175", label = "175-185", options = {
      { key = "stones", label = "Solid Grinding Stones" },
      { key = "bracers", label = "Golden Scale Bracers (stopping at 200)" },
    }},
    { key = "e185", label = "185-200", options = {
      { key = "gauntlet", label = "Heavy Mithril Gauntlet (Mageweave)" },
      { key = "shoulder", label = "Heavy Mithril Shoulder (Heavy Leather)" },
    }},
    { key = "e200", label = "200-225", options = {
      { key = "helm", label = "Steel Plate Helm" },
      { key = "spurs", label = "Helm, then Mithril Spurs from 210" },
    }},
  },

  steps = {
    -- Apprentice
    { kind = "guide", from = 1, to = 75, items = { { HAMMER, 1 } }, nearTrainer = { "Blacksmithing" },
      text = "Buy a Blacksmith Hammer from the Blacksmithing Supply vendor next to your trainer - most recipes "
        .. "need it.{H: Undead: nobody near Angus Hammerhand sells one, buy it from Walter Mason in Deathknell "
        .. "or Abigail Shiel in Brill.}{A: Night Elves: the closest trainer is Delfrum Flintbeard in Auberdine, "
        .. "Darkshore.}" },
    { from = 1,   to = 25,  spell = 2660, crafts = 30 },
    { from = 25,  to = 50,  spell = 3320, crafts = 30, note = "Keep 26 - for the gauntlets and Silver Rods" },
    { from = 50,  to = 67,  spell = 3326, crafts = 36, note = "Make all 36 - for the bracers at 95" },
    { from = 67,  to = 75,  spell = 3323, crafts = 8 },

    -- Journeyman
    { from = 75,  to = 80,  spell = 2666, crafts = 5, when = { j75 = "belt" } },
    { from = 75,  to = 80,  spell = 7818, crafts = 5, when = { j75 = "rod" },
      note = "If 1 Silver Bar costs less than 10 Copper Bars" },
    { from = 80,  to = 95,  spell = 2668, crafts = 15 },
    { from = 95,  to = 100, spell = 2672, crafts = 5, note = "Use the Coarse Grinding Stones from 50" },
    { from = 100, to = 112, spell = 3337, crafts = 20, note = "Keep them, you might need them later" },
    { from = 112, to = 125, spell = 2672, crafts = 13 },
    { from = 125, to = 140, spell = 2742, crafts = 24,
      note = "Weak Flux (and Strong Flux for the next step) from the Blacksmithing Supply vendor in any "
        .. "capital" },
    { from = 140, to = 150, spell = 9985, crafts = 10 },

    -- Expert
    { from = 150, to = 175, spell = 3501, crafts = 30,
      note = "Green Dye from {H:Tamar (Orgrimmar), Millie Gregorian (Undercity) or Mahu (Thunder Bluff)}"
        .. "{A:Jillian Tanner (Stormwind) or Bombus Finespindle (Ironforge)} - yellow at 165" },
    { from = 175, to = 185, spell = 9920, crafts = 40, when = { e175 = "stones" },
      note = "Make all 40 - for the helms at 200" },
    { from = 175, to = 185, spell = 7223, crafts = 10, when = { e175 = "bracers" },
      note = "Only if you stop at 200 and Solid Stone is expensive - uses the Heavy Grinding Stones from 100" },
    { from = 185, to = 200, spell = 9928, crafts = 15, when = { e185 = "gauntlet" } },
    { from = 185, to = 200, spell = 9926, crafts = 15, when = { e185 = "shoulder" },
      note = "Use if Mageweave Cloth is hard to get" },
    { from = 200, to = 225, spell = 9935, crafts = 37, when = { e200 = "helm" },
      note = "Yellow from 210, green from 220" },
    { from = 200, to = 210, spell = 9935, crafts = 10, when = { e200 = "spurs" } },
    { from = 210, to = 225, spell = 9964, crafts = 15, when = { e200 = "spurs" },
      note = "Plans: Mithril Spurs is a world drop - check the AH" },
  },
})

CR.extraNames[HAMMER] = "Blacksmith Hammer"
