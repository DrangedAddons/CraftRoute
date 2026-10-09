-- First Aid route transcribed from wow-professions.com's WoW Forever First Aid guide
-- (https://www.wow-professions.com/forever/first-aid-leveling-guide, beta data, Oct 2026).
-- In Forever, First Aid also makes the healing potions that used to be Alchemy recipes.
-- 225-300 is the untested Classic route (beta was capped at level 30).
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

CR.RegisterRoute("First Aid", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 0,
      text = "Train Journeyman First Aid at any First Aid trainer (skill 50). Learn Wool Bandage at 80, Heavy "
        .. "Wool Bandage at 115 and Silk Bandage before you leave - it's the last recipe trainers teach." },
    { name = "Expert",     cap = 225, skill = 125, level = 0, book = 16084,
      text = "Buy and read 'Expert First Aid - Under Wraps' (skill 125, no level needed) from "
        .. "{H:Balai Lok'Wein, Dustwallow Marsh}{A:Deneb Walker, Arathi Highlands}. Buy Manual: Heavy Silk "
        .. "Bandage and Manual: Mageweave Bandage there too (or on the AH)." },
    { name = "Artisan",    cap = 300, skill = 225, level = 35, quest = true,
      text = "Complete the Triage quest (level 35, skill 225) from {H:Doctor Gregory Victor at Hammerfall, "
        .. "Arathi Highlands}{A:Doctor Gustaf VanHowzen at Theramore, Dustwallow Marsh}. Use the doctor's "
        .. "Triage Bandages, heal the critical patients first, and turn in as soon as 15 are saved." },
  },

  commonMats = {
    [2589] = true, [2592] = true, [4306] = true, [4338] = true, [14047] = true,   -- cloth
    [2447] = true, [3371] = true, [2678] = true, [3713] = true, [8838] = true, [8925] = true,
  },

  choices = {
    { key = "start", label = "1-75", options = {
      { key = "bandages", label = "Bandages (Linen Cloth)" },
      { key = "potions", label = "Minor Healing Potions (Peacebloom)" },
    }},
    { key = "e210", label = "210-225", options = {
      { key = "mageweave", label = "Mageweave Bandage" },
      { key = "silk", label = "Heavy Silk Bandage (no Mageweave)" },
    }},
  },

  steps = {
    { kind = "guide", from = 1, to = 75, when = { start = "potions" },
      text = "Mild Spices come from Cooking supply vendors and Empty Vials from Alchemy supply vendors - "
        .. "most trainers have both nearby." },
    { from = 1,   to = 40,  spell = 3275,    crafts = 50, when = { start = "bandages" } },
    { from = 40,  to = 75,  spell = 3276,    crafts = 40, when = { start = "bandages" }, note = "Yellow from 50" },
    { from = 1,   to = 75,  spell = 1244431, crafts = 81, when = { start = "potions" }, note = "Yellow from 55" },
    { from = 75,  to = 80,  spell = 3276,    crafts = 12, note = "Green - about every second craft gives a point" },
    { from = 80,  to = 115, spell = 3277,    crafts = 50, note = "Learn at 80 - yellow the whole way" },
    { from = 115, to = 150, spell = 3278,    crafts = 50, note = "Learn at 115 - yellow the whole way" },
    { from = 150, to = 180, spell = 7928,    crafts = 42, note = "Yellow the whole way" },
    { from = 180, to = 210, spell = 7929,    crafts = 46, note = "Use Manual: Heavy Silk Bandage first" },
    { from = 210, to = 225, spell = 10840,   crafts = 17, when = { e210 = "mageweave" },
      note = "Use Manual: Mageweave Bandage first" },
    { from = 210, to = 225, spell = 7929,    crafts = 42, when = { e210 = "silk" } },
    { from = 225, to = 240, spell = 1244435, crafts = 16,
      note = "Manual: Superior Healing Potion drops from higher level mobs - untested" },
    { from = 240, to = 260, spell = 10841,   crafts = 30, note = "The Triage doctor teaches it at 240" },
    { from = 260, to = 275, spell = 18629,   crafts = 20, note = "The Triage doctor teaches it at 260" },
    { from = 275, to = 300, spell = 1244436, crafts = 30,
      note = "Manual: Major Healing Potion is a drop" },
  },
})
