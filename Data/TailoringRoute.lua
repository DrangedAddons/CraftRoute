-- Leveling route transcribed from wow-professions.com's WoW Forever Tailoring guide
-- (https://www.wow-professions.com/forever/tailoring-leveling-guide, beta data, as of 6 Oct 2026).
-- The guide stops at 225 - beyond that CraftRoute fills the gap automatically (see Planner.lua).
-- Bolts are Tailoring recipes, so any bolts you're short of are added as extra crafts.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

CR.RegisterRoute("Tailoring", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 225,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10,
      where = "{H:Magar (Orgrimmar), Rhiannon Davis (Undercity) or Tepa (Thunder Bluff)}"
        .. "{A:Sellandus (Stormwind), Jormund Stonebrow (Ironforge) or Me'lynn (Darnassus)}" },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Josef Gregorian, Undercity}{A:Georgio Bolero, Stormwind City} (50 silver)" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      where = "{H:Daryl Stack, Tarren Mill, Hillsbrad Foothills}{A:Timothy Worthington, Theramore Isle, "
        .. "Dustwallow Marsh}" },
  },

  commonMats = {
    [2589] = true, [2592] = true, [4306] = true, [4338] = true, [14047] = true, [14256] = true,  -- cloth
    [2996] = true, [2997] = true, [4305] = true, [4339] = true, [14048] = true,                -- bolts
    [2320] = true, [2321] = true, [4291] = true, [8343] = true, [14341] = true,                -- thread
    [2324] = true, [2604] = true, [2605] = true, [4340] = true, [4341] = true, [4342] = true,  -- dyes
    [6260] = true, [6261] = true, [10290] = true, [2325] = true,
  },

  choices = {
    { key = "j100", label = "100-125", options = {
      { key = "silk", label = "Bolts of Silk, then shoulders" },
      { key = "shoulders", label = "Shoulders only (stopping at 150)" },
    }},
    { key = "e140", label = "140-150", options = {
      { key = "mageweave", label = "Bolts of Mageweave" },
      { key = "gloves", label = "Gloves of Meditation (no Mageweave)" },
    }},
  },

  steps = {
    { from = 1,   to = 30,  spell = 2963,  crafts = 30, note = "Keep the bolts for the belts" },
    { from = 30,  to = 55,  spell = 8776,  crafts = 28, note = "Yellow from 50" },
    { from = 55,  to = 80,  spell = 2964,  crafts = 45,
      note = "Learn Journeyman first - you can pass 75. Make all 45, you need them" },
    { from = 80,  to = 95,  spell = 2402,  crafts = 22,
      note = "Yellow the whole way. If the bolts already took you past 80, make capes until 95" },
    { from = 95,  to = 100, spell = 3848,  crafts = 5 },
    { from = 100, to = 120, spell = 3839,  crafts = 40, when = { j100 = "silk" },
      note = "Keep the bolts - you need 176 by 190" },
    { from = 120, to = 125, spell = 3848,  crafts = 8,  when = { j100 = "silk" } },
    { from = 100, to = 125, spell = 3848,  crafts = 29, when = { j100 = "shoulders" } },
    { from = 125, to = 140, spell = 3852,  crafts = 20,
      note = "Elixir of Wisdom from the AH or an Alchemist" },
    { from = 140, to = 150, spell = 3865,  crafts = 17, when = { e140 = "mageweave" },
      note = "Keep the bolts - you need 180 by 225" },
    { from = 140, to = 150, spell = 3852,  crafts = 31, when = { e140 = "gloves" }, note = "Green from 140" },
    { from = 150, to = 170, spell = 8791,  crafts = 20 },
    { from = 170, to = 190, spell = 8799,  crafts = 24, note = "Yellow from 180" },
    { from = 190, to = 215, spell = 12053, crafts = 38, note = "Yellow from 195, green from 210" },
    { from = 215, to = 225, spell = 12065, crafts = 26, note = "Green from 220" },
  },
})
