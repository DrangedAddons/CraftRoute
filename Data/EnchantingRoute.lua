-- Leveling route transcribed from wow-professions.com's WoW Forever Enchanting guide
-- (https://www.wow-professions.com/forever/enchanting-leveling-guide, beta data, as of 8 Oct 2026).
-- 225-300 is the guide's untested Classic route (Enchanting ranges barely changed in Forever).
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

CR.RegisterRoute("Enchanting", {
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,

  tiers = {
    { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
    { name = "Journeyman", cap = 150, skill = 50,  level = 10,
      where = "{H:Godan (Orgrimmar), Lavinia Crowe (Undercity) or Teg Dawnstrider (Thunder Bluff)}"
        .. "{A:Lucan Cordell (Stormwind), Gimble Thistlefuzz (Ironforge) or Taladan (Darnassus)}" },
    { name = "Expert",     cap = 225, skill = 125, level = 20,
      where = "{H:Hgarth, on the hill above Sun Rock Retreat, Stonetalon Mountains}{A:Kitta Firewind, top of the "
        .. "Tower of Azora, Elwynn Forest} - the only Expert trainer for your faction (50 silver)" },
    { name = "Artisan",    cap = 300, skill = 200, level = 35,
      text = "Learn Artisan Enchanting (level 35, skill 200) from Annora in Uldaman (back entrance - bring a "
        .. "group). She only spawns once every mob in her area is dead. Learn every recipe she teaches - the "
        .. "230+ ones aren't taught anywhere else - and bring enough mats for 250 (about 100 Vision Dust)." },
  },

  commonMats = {
    [10940] = true, [10938] = true, [10939] = true, [11083] = true, [11082] = true, [11084] = true,
    [11137] = true, [11134] = true, [11135] = true, [11176] = true, [11174] = true, [16204] = true,
    [247786] = true, [6217] = true,
  },

  choices = {
    { key = "e20", label = "20-70", options = {
      { key = "essence", label = "Minor Deflect (Lesser Magic Essence)" },
      { key = "dust", label = "Chest - Inferior Stamina (Strange Dust)" },
    }},
    { key = "e70", label = "70-150", options = {
      { key = "essence", label = "Lesser Magic Essence path" },
      { key = "dust", label = "Strange Dust path" },
    }},
  },

  steps = {
    { kind = "guide", from = 1, to = 2,
      text = "Buy the Copper Rod and Motes of Magic from the Enchanting Supply vendor next to your trainer, "
        .. "not the AH. Starting-zone trainers don't have one (except Zephras Isle), so use the capital city "
        .. "trainer." },
    { from = 1,   to = 2,   spell = 7421,  crafts = 1 },
    { from = 2,   to = 20,  spell = 7418,  crafts = 18 },
    { from = 20,  to = 70,  spell = 7428,  crafts = 50, when = { e20 = "essence" },
      note = "A Greater Magic Essence splits into 3 Lesser" },
    { from = 20,  to = 70,  spell = 7420,  crafts = 50, when = { e20 = "dust" },
      note = "Or disenchant green items for dust" },

    -- 70-150: Lesser Magic Essence path
    { from = 70,  to = 100, spell = 7426,  crafts = 33, when = { e70 = "essence" } },
    { from = 100, to = 109, spell = 7426,  crafts = 18, when = { e70 = "essence" } },
    { from = 109, to = 110, spell = 7795,  crafts = 1,  when = { e70 = "essence" },
      note = "Silver Rod is made by Blacksmiths - buy it on the AH" },
    { from = 110, to = 130, spell = 7793,  crafts = 20, when = { e70 = "essence" },
      note = "Formula from {H:Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff) or Leo Sarn (Silverpine)}"
        .. "{A:Tilli Thistlefuzz (Ironforge)} - buy Formula: Minor Mana Oil and Formula: Lesser Wizard Oil there too, "
        .. "for 150 and 200" },
    { from = 130, to = 150, spell = 7793,  crafts = 32, when = { e70 = "essence" } },
    -- 70-150: Strange Dust path
    { from = 70,  to = 100, spell = 7457,  crafts = 30, when = { e70 = "dust" } },
    { from = 100, to = 109, spell = 7771,  crafts = 9,  when = { e70 = "dust" } },
    { from = 109, to = 110, spell = 7795,  crafts = 1,  when = { e70 = "dust" },
      note = "Silver Rod is made by Blacksmiths - buy it on the AH" },
    { from = 110, to = 130, spell = 7771,  crafts = 32, when = { e70 = "dust" } },
    { from = 130, to = 150, spell = 7863,  crafts = 20, when = { e70 = "dust" } },

    -- Expert
    { from = 150, to = 151, spell = 13628, crafts = 1 },
    { from = 151, to = 165, spell = 25125, crafts = 16,
      note = "Formula from {H:Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff) or Thaddeus Webb (Undercity)}"
        .. "{A:Vaean (Darnassus), Tilli Thistlefuzz (Ironforge) or Jessara Cordell (Stormwind)} - buy Formula: "
        .. "Lesser Wizard Oil there too, for 200. Maple Seed from Reagent vendors, Leaded Vial from Alchemy Supply" },
    { from = 165, to = 185, spell = 13637, crafts = 22,
      note = "Beta: Vision Dust is expensive with the level cap and Soul Dust isn't, so keep making these until 200 "
        .. "(around 22 more)" },
    { from = 185, to = 200, spell = 13661, crafts = 15 },
    { from = 200, to = 201, spell = 13702, crafts = 1 },
    { from = 201, to = 220, spell = 25126, crafts = 25,
      note = "Formula from {H:Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff) or Thaddeus Webb (Undercity)}"
        .. "{A:Vaean (Darnassus), Tilli Thistlefuzz (Ironforge) or Jessara Cordell (Stormwind)}. Stranglethorn "
        .. "Seed from Reagent vendors, Leaded Vial from Alchemy Supply" },
    { from = 220, to = 225, spell = 13746, crafts = 5 },

    -- Artisan (untested Classic route)
    { from = 225, to = 230, spell = 13815, crafts = 5,  note = "Untested in Forever (Classic route)" },
    { from = 230, to = 235, spell = 13836, crafts = 5 },
    { from = 235, to = 250, spell = 13858, crafts = 20 },
    { from = 250, to = 265, spell = 25127, crafts = 20,
      note = "Formula from Kania (Silithus inn, upstairs)" },
    { from = 265, to = 294, spell = 20017, crafts = 32,
      note = "Formula (bind on pickup) from {H:Daniel Bartlett, Undercity}{A:Mythrin'dir, Darnassus}" },
    { from = 294, to = 295, spell = 20051, crafts = 1,
      note = "Formula from Lorelae Wintersong, Nighthaven, Moonglade" },
    { from = 295, to = 300, spell = 20015, crafts = 5,
      note = "Formula from Lorelae Wintersong, Moonglade" },
  },
})
