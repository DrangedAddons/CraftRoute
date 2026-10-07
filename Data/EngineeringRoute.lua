-- Leveling route transcribed from wow-professions.com's WoW Forever Engineering guide
-- (https://www.wow-professions.com/forever/engineering-leveling-guide, beta data, Oct 2026).
-- 200-300 is the guide's untested Classic route (Engineering ranges are unchanged in Forever).
-- Powders, bolts, tubes and frames are Engineering recipes, so shortfalls become extra crafts.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local HAMMER = 5956

CR.RegisterRoute("Engineering", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10,
      where = "{H:Nogg (Orgrimmar) or Franklin Lloyd (Undercity)}{A:Lilliam Sparkspindle (Stormwind), Trixie "
        .. "Quikswitch (Ironforge) or Finbus Geargrind (Duskwood)}" },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Roxxik, Orgrimmar}{A:Springspindle Fizzlegear, Ironforge} (50 silver)" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      where = "Buzzek Bracketswing, outside the inn in Gadgetzan - he also teaches the 200+ recipes, so go at 200" },
  },

  commonMats = {
    [2835] = true, [2836] = true, [2838] = true, [7912] = true, [12365] = true,
    [2840] = true, [2841] = true, [3575] = true, [3859] = true, [3860] = true, [12359] = true, [2842] = true,
    [2589] = true, [2592] = true, [4306] = true, [4338] = true, [14047] = true,
    [2880] = true, [2318] = true, [2319] = true, [1206] = true,
  },

  choices = {
    { key = "g100", label = "100-105", options = {
      { key = "contact", label = "Silver Contact" },
      { key = "goggles", label = "Flying Tiger Goggles (if Silver is expensive)" },
    }},
    { key = "g125", label = "125-135", options = {
      { key = "scope", label = "Standard Scope (Moss Agate)" },
      { key = "powder", label = "Heavy Blasting Powder early (no Moss Agate)" },
    }},
    { key = "g175", label = "175-194", options = {
      { key = "powder", label = "60 Solid Blasting Powder" },
      { key = "grenade", label = "10 powder + Iron Grenades (Solid Stone is pricey)" },
    }},
  },

  steps = {
    { kind = "guide", from = 1, to = 30, items = { { HAMMER, 1 } },
      text = "Buy a Blacksmith Hammer - most recipes need it. Most trainers have a Blacksmithing or Engineering "
        .. "Supply vendor nearby{A:; in Dun Morogh buy it from Thrawn Boltar in Kharanos}; on Zephras Isle buy "
        .. "it from Aedi Thriceforged in Shen'dar Village." },
    { from = 1,   to = 30,  spell = 3918,  crafts = 60, note = "Keep all 60 for the bombs" },
    { from = 30,  to = 50,  spell = 3922,  crafts = 30, note = "Keep these for the bombs too" },
    { from = 50,  to = 51,  spell = 7430,  crafts = 1,  note = "Keep the spanner - recipes need it" },
    { from = 51,  to = 75,  spell = 3923,  crafts = 30,
      note = "Can pass 75 - learn Journeyman first or don't AFK craft. Yellow from 60" },
    { from = 75,  to = 90,  spell = 3929,  crafts = 60, note = "Keep all 60 for the dynamite" },
    { from = 90,  to = 100, spell = 3931,  crafts = 20 },
    { from = 100, to = 105, spell = 3973,  crafts = 5,  when = { g100 = "contact" } },
    { from = 100, to = 105, spell = 3934,  crafts = 5,  when = { g100 = "goggles" } },
    { from = 105, to = 125, spell = 3938,  crafts = 25,
      note = "Weak Flux from the Engineering Supply vendor - yellow the whole way" },
    { from = 125, to = 135, spell = 3978,  crafts = 10, when = { g125 = "scope" }, note = "Uses 10 of the tubes" },
    { from = 125, to = 135, spell = 3945,  crafts = 10, when = { g125 = "powder" } },
    { from = 135, to = 143, spell = 3945,  crafts = 30, note = "Make these first - for the sheep at 160" },
    { from = 143, to = 150, spell = 3942,  crafts = 15, note = "Then these - also for the sheep" },
    { from = 150, to = 160, spell = 3953,  crafts = 15, note = "Keep all 15 for the sheep" },
    { from = 160, to = 175, spell = 3955,  crafts = 15, note = "Keep 5 if you might pick Goblin Engineering" },
    { from = 175, to = 194, spell = 12585, crafts = 60, when = { g175 = "powder" }, note = "Save them for later" },
    { from = 175, to = 180, spell = 12585, crafts = 10, when = { g175 = "grenade" } },
    { from = 180, to = 194, spell = 3962,  crafts = 20, when = { g175 = "grenade" } },
    { from = 194, to = 195, spell = 12590, crafts = 1,  note = "Keep it - recipes need it" },
    { from = 195, to = 200, spell = 12589, crafts = 6 },

    -- Artisan (untested Classic route)
    { from = 200, to = 215, spell = 12591, crafts = 20, note = "Untested in Forever - keep all 20 for the bombs" },
    { from = 215, to = 238, spell = 12599, crafts = 40, note = "Keep 40 for the bombs" },
    { from = 238, to = 250, spell = 12619, crafts = 20 },
    { from = 250, to = 260, spell = 19788, crafts = 30, note = "Yellow from 250" },
    { from = 260, to = 285, spell = 19791, crafts = 35,
      note = "Schematic from {H:Sovik, Orgrimmar}{A:Gearcutter Cogspinner, Ironforge}" },
    { from = 285, to = 300, spell = 19795, crafts = 20,
      note = "Schematic (bind on pickup) from Xizzer Fizzbolt, Everlook, Winterspring" },
  },
})

CR.extraNames[HAMMER] = "Blacksmith Hammer"
