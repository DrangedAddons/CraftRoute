-- Leveling route transcribed from wow-professions.com's WoW Forever Leatherworking guide
-- (https://www.wow-professions.com/forever/leatherworking-leveling-guide, beta data, as of 8 Nov 2026).
-- Reagents per craft come from the recipe database; only skill ranges + craft counts live here.
-- Steps, counts and choices follow the guide exactly - re-check it when the guide is updated.
-- 225-300 is the guide's untested draft from the game data.
local _, CR = ...

CR.RegisterRoute("Leatherworking", {
  id = "Leatherworking",   -- keeps choices saved before routes had ids
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10 },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Una, Thunder Bluff}{A:Telonis, Darnassus}" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      where = "{H:Hahrana Ironhide, Camp Mojache, Feralas}{A:Drakk Stonehand, Aerie Peak, The Hinterlands}" },
  },

  -- Bulk leather is never auto-crafted from the tier below when short; buy/farm it instead.
  noExpand = { [2318] = true, [2319] = true, [4234] = true, [4304] = true, [8170] = true },

  -- Everyday leveling mats (leathers, hides, threads, dyes, salt). Only used to rank auto-filled
  -- recipes when Auctionator has no price yet - anything not listed is treated as expensive.
  commonMats = {
    [2318] = true, [2319] = true, [4234] = true, [4304] = true, [8170] = true,     -- leathers
    [783] = true, [4232] = true, [4235] = true, [8169] = true, [8171] = true,      -- hides
    [4231] = true, [4233] = true, [4236] = true, [8172] = true, [15407] = true,    -- cured hides
    [2320] = true, [2321] = true, [4291] = true, [8343] = true, [14341] = true,    -- threads
    [4289] = true, [8150] = true, [15409] = true,                                  -- salt
    [2324] = true, [2325] = true, [2604] = true, [2605] = true, [4340] = true,     -- dyes
    [4341] = true, [4342] = true, [6260] = true, [6261] = true, [10290] = true,
  },

  choices = {
    { key = "apprentice", label = "1-30", options = {
      { key = "scraps",  label = "Ruined Leather Scraps" },
      { key = "leather", label = "Bought Light Leather" },
    }},
    { key = "a30", label = "30-55", options = {
      { key = "kits", label = "Light Armor Kit + Embossed Leather Gloves" },
      { key = "hides", label = "Cured Light Hide (bought Light Hides)" },
    }},
    { key = "medium", label = "80-90 and 115-125", options = {
      { key = "hides", label = "Cured Medium Hide + Dark Leather Belt" },
      { key = "leather", label = "Bought Medium Leather instead of Medium Hides" },
    }},
    { key = "j100", label = "100-115", options = {
      { key = "cloak", label = "Dark Leather Cloak" },
      { key = "pants", label = "Light Leather Pants (with Cured Light Hides)" },
    }},
    { key = "expert", label = "130-175", options = {
      { key = "hide",    label = "Cured Heavy Hide" },
      { key = "nohide",  label = "Leveling without Heavy Hide" },
    }},
    { key = "a285", label = "285-300", options = {
      { key = "headband", label = "Runic Leather Headband" },
      { key = "scorpid", label = "Heavy Scorpid Shoulders (pattern drop)" },
      { key = "wicked", label = "Wicked Leather Armor (pattern drop)" },
      { key = "tooled", label = "Tooled Leather Pants (pattern)" },
    }},
  },

  steps = {
    -- Apprentice (1-55)
    { from = 1,   to = 30,  spell = 2881,  crafts = 33, when = { apprentice = "scraps" },
      note = "100 Ruined Leather Scraps - yellow at 20" },
    { from = 1,   to = 30,  spell = 2152,  when = { apprentice = "leather" },
      note = "Light Armor Kit until 30, 1 Light Leather each" },
    { from = 30,  to = 45,  spell = 2152,  crafts = 24, when = { a30 = "kits" } },
    { from = 45,  to = 55,  spell = 3756,  crafts = 10, when = { a30 = "kits" } },
    { from = 30,  to = 55,  spell = 3816,  crafts = 27, when = { a30 = "hides" },
      note = "Keep 24 for the Light Leather Pants at 100" },

    -- Journeyman (55-130)
    { from = 55,  to = 75,  spell = 3756,  crafts = 21 },
    { from = 75,  to = 80,  spell = 20648, crafts = 8 },
    { from = 80,  to = 90,  spell = 3817,  crafts = 10, when = { medium = "hides" },
      note = "Keep them for the Dark Leather Belts at 115" },
    { from = 80,  to = 90,  spell = 3763,  crafts = 11, when = { medium = "leather" } },
    { from = 90,  to = 100, spell = 3763,  crafts = 19,
      note = "Keep 10 for the Dark Leather Belts at 115" },
    { from = 100, to = 115, spell = 2168,  crafts = 16, when = { j100 = "cloak" } },
    { from = 100, to = 115, spell = 9068,  crafts = 24, when = { j100 = "pants" },
      note = "Uses the Cured Light Hides from 30" },
    { from = 115, to = 125, spell = 3766,  crafts = 10, when = { medium = "hides" } },
    { from = 115, to = 120, spell = 7135,  crafts = 6,  when = { medium = "leather" } },
    { from = 120, to = 125, spell = 3764,  crafts = 5,  when = { medium = "leather" } },
    { from = 125, to = 130, spell = 20649, crafts = 7 },

    -- Expert (130-210): Cured Heavy Hide path
    { from = 130, to = 140, spell = 3818,  crafts = 20, when = { expert = "hide" },
      note = "You will need the Cured Heavy Hides later" },
    { from = 140, to = 155, spell = 3764,  crafts = 20, when = { expert = "hide" } },
    { from = 155, to = 165, spell = 7151,  crafts = 10, when = { expert = "hide" } },
    { from = 165, to = 175, spell = 7156,  crafts = 10, when = { expert = "hide" } },
    -- Expert (130-210): without Heavy Hide
    { from = 130, to = 155, spell = 3764,  crafts = 30, when = { expert = "nohide" } },
    { from = 155, to = 170, spell = 7149,  crafts = 17, when = { expert = "nohide" },
      note = "Pattern from {H:Keena (Arathi), Jandia (Thousand Needles)}{A:Hammon Karwn (Arathi), Lardan "
        .. "(Ashenvale)}" },
    { from = 170, to = 175, spell = 6661,  crafts = 5,  when = { expert = "nohide" } },
    -- Expert, both paths
    { from = 175, to = 195, spell = 7156,  crafts = 26,
      note = "Bought Heavy Hide? Cure it first - 3 Salt each" },
    { from = 195, to = 210, spell = 10507, crafts = 21 },

    -- Artisan (210-300); past 225 the guide's untested draft
    { from = 210, to = 225, spell = 10548, crafts = 15,
      note = "Only the Artisan trainers teach this - not the Expert trainers in Thunder Bluff / Darnassus" },
    { from = 225, to = 235, spell = 10558, crafts = 12 },
    { from = 235, to = 250, spell = 19049, crafts = 15,
      note = "Pattern from {H:Werg Thickblade, Tirisfal Glades}{A:Leonard Porter, Western Plaguelands}" },
    { from = 250, to = 265, spell = 19049, crafts = 21 },
    { from = 265, to = 285, spell = 19082, crafts = 20,
      note = "Pattern from Jase Farlane, Light's Hope Chapel, Eastern Plaguelands" },
    { from = 285, to = 300, spell = 19082, crafts = 33, when = { a285 = "headband" } },
    { from = 285, to = 300, spell = 19100, crafts = 15, when = { a285 = "scorpid" } },
    { from = 285, to = 300, spell = 19098, crafts = 15, when = { a285 = "wicked" } },
    { from = 285, to = 300, spell = 1255018, crafts = 15, when = { a285 = "tooled" } },
  },
})
