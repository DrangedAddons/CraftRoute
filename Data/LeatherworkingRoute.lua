-- Leveling route transcribed from wow-professions.com's WoW Forever Leatherworking guide
-- (https://www.wow-professions.com/forever/leatherworking-leveling-guide, beta data, Oct 2026).
-- Reagents per craft come from the recipe database; only skill ranges + craft counts live here.
-- The guide stops at 225 - beyond that CraftRoute fills the gap automatically (see Planner.lua).
local _, CR = ...

CR.RegisterRoute("Leatherworking", {
  id = "Leatherworking",   -- keeps choices saved before routes had ids
  source = "wow-professions.com (Forever beta)",
  routeEnd = 225,
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
    { key = "apprentice", label = "1-45", options = {
      { key = "scraps",  label = "Ruined Leather Scraps" },
      { key = "leather", label = "Bought Light Leather" },
    }},
    { key = "journeyman", label = "55-125", options = {
      { key = "hide",    label = "Cured Medium Hide" },
      { key = "nohide",  label = "No Medium Hide" },
    }},
    { key = "expert", label = "130-175", options = {
      { key = "nohide",  label = "No Heavy Hide" },
      { key = "hide",    label = "Cured Heavy Hide" },
    }},
    { key = "thick", label = "175-200", options = {
      { key = "thick",   label = "Thick Leather (live)" },
      { key = "heavy",   label = "Heavy Leather (beta)" },
    }},
  },

  steps = {
    -- Apprentice
    { from = 1,   to = 30,  spell = 2881,  crafts = 33, when = { apprentice = "scraps" }, note = "Yellow from 20" },
    { from = 30,  to = 45,  spell = 2152,  crafts = 20, when = { apprentice = "scraps" }, note = "Yellow from 30" },
    { from = 1,   to = 45,  spell = 2152,  crafts = 50, when = { apprentice = "leather" } },
    { from = 45,  to = 55,  spell = 3756,  crafts = 10 },

    -- Journeyman: Cured Medium Hide path
    { from = 55,  to = 80,  spell = 3763,  crafts = 25, when = { journeyman = "hide" }, note = "Keep the belts" },
    { from = 80,  to = 100, spell = 3817,  crafts = 25, when = { journeyman = "hide" }, note = "Yellow 90, green 97" },
    { from = 100, to = 125, spell = 3766,  crafts = 25, when = { journeyman = "hide" } },
    -- Journeyman: no Medium Hide path
    { from = 55,  to = 75,  spell = 3756,  crafts = 20, when = { journeyman = "nohide" }, note = "Last 5 points yellow" },
    { from = 75,  to = 80,  spell = 20648, crafts = 7,  when = { journeyman = "nohide" }, note = "Keep the Medium Leather" },
    { from = 80,  to = 95,  spell = 3763,  crafts = 17, when = { journeyman = "nohide" }, note = "Yellow from 85" },
    { from = 95,  to = 105, spell = 2167,  crafts = 11, when = { journeyman = "nohide" } },
    { from = 105, to = 115, spell = 2168,  crafts = 11, when = { journeyman = "nohide" }, note = "Yellow at 110" },
    { from = 115, to = 120, spell = 7135,  crafts = 6,  when = { journeyman = "nohide" }, note = "Yellow the whole way" },
    { from = 120, to = 125, spell = 3764,  crafts = 5,  when = { journeyman = "nohide" } },
    { from = 125, to = 130, spell = 20649, crafts = 7,  note = "Keep the Heavy Leather" },

    -- Expert 130-175: no Heavy Hide path
    { from = 130, to = 150, spell = 3764,  crafts = 21, when = { expert = "nohide" }, note = "Yellow at 145" },
    { from = 150, to = 165, spell = 7149,  crafts = 15, when = { expert = "nohide" },
      note = "Pattern from {H:Keena (Arathi), Jandia (Thousand Needles)}{A:Hammon Karwn (Arathi), Lardan "
        .. "(Ashenvale)}" },
    { from = 165, to = 175, spell = 9201,  crafts = 10, when = { expert = "nohide" },
      note = "Can start at 160 if Moss Agate is expensive" },
    -- Expert 130-175: Cured Heavy Hide path
    { from = 130, to = 140, spell = 3818,  crafts = 20, when = { expert = "hide" }, note = "Keep the hides" },
    { from = 140, to = 155, spell = 3764,  crafts = 16, when = { expert = "hide" }, note = "Yellow at 145" },
    { from = 155, to = 165, spell = 7151,  crafts = 10, when = { expert = "hide" } },
    { from = 165, to = 175, spell = 7156,  crafts = 10, when = { expert = "hide" } },

    -- 175-200
    { from = 175, to = 180, spell = 10487, crafts = 5,  when = { thick = "thick" } },
    { from = 180, to = 200, spell = 10507, crafts = 20, when = { thick = "thick" } },
    { from = 175, to = 185, spell = 6661,  crafts = 10, when = { thick = "heavy" } },
    { from = 185, to = 200, spell = 9206,  crafts = 18, when = { thick = "heavy" }, note = "Yellow at 190" },

    -- 200-225
    { from = 200, to = 205, spell = 10507, crafts = 6,  note = "Yellow here, may need an extra" },
    { from = 205, to = 225, spell = 10548, crafts = 20 },
  },
})
