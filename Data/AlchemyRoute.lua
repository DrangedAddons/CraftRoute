-- Leveling route transcribed from wow-professions.com's WoW Forever Alchemy guide
-- (https://www.wow-professions.com/forever/alchemy-leveling-guide, beta data, Oct 2026).
-- 225-300 is the guide's untested Classic route with the healing potions removed (they moved
-- to First Aid in Forever).
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

CR.RegisterRoute("Alchemy", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10,
      where = "{H:Yelmak (Orgrimmar), Doctor Marsh (Undercity) or Bena Winterhoof (Thunder Bluff)}"
        .. "{A:Lilyssia Nightbreeze (Stormwind), Tally Berryfizz (Ironforge) or Sylvanna Forestmoon (Darnassus)}" },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Doctor Herbert Halsey, Undercity}{A:Ainethil, Darnassus} (50 silver)" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      where = "{H:Rogvar, Stonard, Swamp of Sorrows}{A:Kylanna Windwhisper, Feathermoon Stronghold, Feralas}" },
  },

  commonMats = {
    [2447] = true, [765] = true, [785] = true, [2449] = true, [2450] = true, [3820] = true, [3355] = true,
    [3356] = true, [3357] = true, [3818] = true, [3821] = true, [3358] = true, [8836] = true, [8838] = true,
    [8839] = true, [8845] = true, [3371] = true, [3372] = true, [8925] = true,
  },

  choices = {
    { key = "a1", label = "1-10", options = {
      { key = "arcane", label = "Minor Arcane Elixir (Peacebloom)" },
      { key = "force", label = "Elixir of Minor Force (Silverleaf)" },
    }},
    { key = "a130", label = "130-165", options = {
      { key = "fireoil", label = "Fire Oil, then Elixir of Fire Power" },
      { key = "mana", label = "Lesser Mana Potions (if Firefin Snapper is scarce)" },
    }},
    { key = "a195", label = "195-215", options = {
      { key = "defense", label = "Elixir of Defense" },
      { key = "nature", label = "Nature Protection Potion (no Goldthorn)" },
    }},
    { key = "a275", label = "275-290", options = {
      { key = "supmana", label = "Superior Mana Potion" },
      { key = "grdefense", label = "Elixir of Greater Defense" },
      { key = "shadow", label = "Elixir of Shadow Power" },
    }},
  },

  steps = {
    { kind = "guide", from = 1, to = 10,
      text = "Empty Vials are sold by Alchemy Supply and Trade Supply vendors near most trainers"
        .. "{H: - in Undercity the closest is Algernon}{A: - in Dolanaar it's Narret Shadowgrove}." },
    { from = 1,   to = 10,  spell = 1245246, crafts = 9,  when = { a1 = "arcane" } },
    { from = 1,   to = 10,  spell = 1245250, crafts = 9,  when = { a1 = "force" } },
    { from = 10,  to = 55,  spell = 7183,    crafts = 45 },
    { from = 55,  to = 65,  spell = 2331,    crafts = 10 },
    { from = 65,  to = 90,  spell = 2334,    crafts = 27, note = "Yellow from 80" },
    { from = 90,  to = 120, spell = 3171,    crafts = 30, note = "Keep them if you level Tailoring" },
    { from = 120, to = 130, spell = 3173,    crafts = 10 },
    { from = 130, to = 150, spell = 7837,    crafts = 20, when = { a130 = "fireoil" },
      note = "Makes 2 each - keep 30 for Fire Power" },
    { from = 150, to = 165, spell = 7845,    crafts = 15, when = { a130 = "fireoil" } },
    { from = 130, to = 150, spell = 3173,    crafts = 20, when = { a130 = "mana" } },
    { from = 150, to = 165, spell = 3173,    crafts = 22, when = { a130 = "mana" } },
    { from = 165, to = 180, spell = 3452,    crafts = 15 },
    { from = 180, to = 195, spell = 3450,    crafts = 15 },
    { from = 195, to = 215, spell = 11450,   crafts = 20, when = { a195 = "defense" } },
    { from = 195, to = 215, spell = 7259,    crafts = 20, when = { a195 = "nature" },
      note = "Recipe (bind on pickup): Bronk / Logannas (Feralas), Glyx Brewright (Stranglethorn), Alchemist "
        .. "Pestlezugg (Tanaris) - yellow from 210" },
    { from = 215, to = 225, spell = 11448,   crafts = 11, note = "Yellow for the last 5 points" },
    { from = 225, to = 230, spell = 11448,   crafts = 6,  note = "Untested in Forever (Classic route)" },
    { from = 230, to = 265, spell = 11460,   crafts = 45, note = "Yellow from 245" },
    { from = 265, to = 275, spell = 17553,   crafts = 10,
      note = "Recipe from {H:Algernon, Undercity}{A:Ulthir, Darnassus}" },
    { from = 275, to = 290, spell = 17553,   crafts = 20, when = { a275 = "supmana" } },
    { from = 275, to = 290, spell = 17554,   crafts = 17, when = { a275 = "grdefense" },
      note = "Recipe from {H:Kor'geld, Orgrimmar}{A:Soolie Berryfizz, Ironforge}" },
    { from = 275, to = 290, spell = 11476,   crafts = 27, when = { a275 = "shadow" },
      note = "Recipe from {H:Algernon, Undercity}{A:Maria Lumere, Stormwind}" },
    { from = 290, to = 300, spell = 1251740, crafts = 17,
      note = "Merchant's Favor recipe from {H:Apothecary Durelle, outside the Crossroads}{A:Nina Surefire, "
        .. "Three Corners, Redridge} - the guide's 290-300 route isn't final yet" },
  },
})
