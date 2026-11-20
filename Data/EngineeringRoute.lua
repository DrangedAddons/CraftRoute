-- Leveling route transcribed from wow-professions.com's WoW Forever Engineering guide
-- (https://www.wow-professions.com/forever/engineering-leveling-guide, beta data, as of 8 Nov 2026).
-- Past 225 is the guide's untested Classic route (Engineering ranges are unchanged in Forever).
-- Powders, bolts, tubes and frames are Engineering recipes, so shortfalls become extra crafts.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local HAMMER = 5956

-- Gnomish / Goblin (quest IDs from the vanilla database, the same in Forever; Nov 2026). The first
-- quest has an ID per quest giver. The Pledge of Secrecy: right-click the pledge to sign it.
local ENG_GIVERS = "{A:Springspindle Fizzlegear|Lilliam Sparkspindle|Tinkerwiz}{H:Tinkerwiz|Graham Van Talen}"
local GNOMISH_TEXT = "Gnome Engineering is from {A:Springspindle Fizzlegear in Ironforge, Lilliam Sparkspindle in "
  .. "Stormwind or Tinkerwiz in Ratchet; hand it in to Tinkmaster Overspark in Tinker Town, Ironforge}{H:Tinkerwiz "
  .. "in Ratchet or Graham Van Talen in Undercity; take the boat from Ratchet to Booty Bay and hand it in to "
  .. "Oglethorpe Obnoticus}. He gives The Pledge of Secrecy and Show Your Work."
  .. "\n\nYou get the Ultrasafe Transporter - Gadgetzan (Gnomish only), and can make the Gnomish Death Ray "
  .. "and Gnomish Battle Chicken (bind on pickup)."
  .. "\n\nSwitching from Goblin? Read Soothsaying for Dummies at Steamwheedle Port, Tanaris first."
local GOBLIN_TEXT = "Goblin Engineering is from {A:Springspindle Fizzlegear in Ironforge, Lilliam Sparkspindle in "
  .. "Stormwind or Tinkerwiz in Ratchet}{H:Tinkerwiz in Ratchet or Graham Van Talen in Undercity}. Hand it in to "
  .. "Nixx Sprocketspring in Gadgetzan, Tanaris: he gives The Pledge of Secrecy and Show Your Work."
  .. "\n\nYou get the Dimensional Ripper - Everlook (Goblin only), and can make Goblin Sapper Charges and "
  .. "Goblin Rocket Boots."
  .. "\n\nSwitching from Gnomish? Read Soothsaying for Dummies at Steamwheedle Port, Tanaris first."
local function GnomishSpec(path)
  return { spell = 20219, name = "Gnomish Engineer", level = 30, skill = 200, card = 10790, final = "Show Your Work",
    finalNpc = "{A:Tinkmaster Overspark}{H:Oglethorpe Obnoticus}", path = path,
    giver = "{A:Tinkmaster Overspark}{H:Oglethorpe Obnoticus}",
    -- Mithril Tube, Accurate Scope (schematic), Bronze Tube, Gyromatic Micro-Adjustor, Advanced Target
    -- Dummy and its parts: Iron Strut, Bronze Framework, Gyrochronatom, Gold Power Core
    patterns = { 12589, 3979, 3938, 12590, 3965, 3958, 3953, 3961, 12584 },
    patternItems = { [3979] = 13310 },
    patternNpcs = { [3979] = "Mazk Snipeshot" },
    tools = { 10498 },   -- Gyromatic Micro-Adjustor (the Accurate Scope needs it)
    chain = {
      { quest = "Gnome Engineering", ids = { A = { 3630, 3632, 3634 }, H = { 3635, 3637 } }, npc = ENG_GIVERS,
        note = "{A:Take the manual to Tinkmaster Overspark in Tinker Town, Ironforge}"
          .. "{H:Take the manual to Oglethorpe Obnoticus in Booty Bay}" },
      { quest = "The Pledge of Secrecy", ids = { A = 3640, H = 3642 },
        note = "Right-click the pledge in your bags to sign it, then hand it in" },
      { final = true, ids = { A = 3641, H = 3643 }, items = { { 10559, 6 }, { 4407, 1 }, { 4392, 2 } } },
    } }
end
local GNOMISH_CRAFT, GNOMISH_BUY = GnomishSpec("craft"), GnomishSpec("buy")
local function GoblinSpec(path)
  return { spell = 20222, name = "Goblin Engineer", level = 30, skill = 200, card = 10791, final = "Show Your Work",
    finalNpc = "Nixx Sprocketspring", path = path, giver = "Nixx Sprocketspring",
    -- Big Iron Bomb, Solid Dynamite, Explosive Sheep and their parts: Heavy Blasting Powder, Silver
    -- Contact, Solid Blasting Powder, Whirring Bronze Gizmo, Bronze Framework
    patterns = { 3967, 12586, 3955, 3945, 3973, 12585, 3942, 3953 },
    chain = {
      { quest = "Goblin Engineering", ids = { A = { 3629, 4181, 3633 }, H = { 3526, 3633 } }, npc = ENG_GIVERS,
        note = "Take the manual to Nixx Sprocketspring in Gadgetzan, Tanaris" },
      { quest = "The Pledge of Secrecy", ids = { A = 3638, H = 3638 },
        note = "Right-click the pledge in your bags to sign it, then hand it in" },
      { final = true, ids = { A = 3639, H = 3639 }, items = { { 4394, 20 }, { 10507, 20 }, { 4384, 5 } } },
    } }
end
local GOBLIN_CRAFT, GOBLIN_BUY = GoblinSpec("craft"), GoblinSpec("buy")

CR.RegisterRoute("Engineering", {
  -- Change Specialisation, at the end once you have one (wow-professions.com's Gnomish vs Goblin guide)
  specChange = { at = 300,
    text = "To switch, unlearn Engineering in the Skills tab of your character window - you lose every "
      .. "recipe and all your skill. Level it back to 200, then read Soothsaying for Dummies in a hut at "
      .. "Steamwheedle Port, Tanaris. Then do the other specialization's quest (pick it below)." },
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
    { key = "spec", label = "200 specialization", options = {
      { key = "none", label = "Not now" },
      { key = "gnomish", label = "Gnomish Engineering" },
      { key = "goblin", label = "Goblin Engineering" },
    }},
    { key = "gnomish", label = "Gnomish quest items", options = {
      { key = "craft", label = "Craft them (get the schematics, buy the materials)" },
      { key = "buy", label = "Buy the finished items on the AH" },
    }},
    { key = "goblin", label = "Goblin quest items", options = {
      { key = "craft", label = "Craft them (buy the materials)" },
      { key = "buy", label = "Buy the finished items on the AH" },
    }},
  },

  steps = {
    { kind = "guide", from = 1, to = 30, items = { { HAMMER, 1 } }, nearTrainer = { "Engineering", "Blacksmithing" },
      text = "Buy a Blacksmith Hammer - most recipes need it. Most trainers have a Blacksmithing or Engineering "
        .. "Supply vendor nearby{A:; in Dun Morogh buy it from Thrawn Boltar in Kharanos}; on Zephras Isle buy "
        .. "it from Aedi Thriceforged in Shen'dar Village. In the capitals (the Blacksmithing guide's list): "
        .. "{H:Sumi (Orgrimmar), Samuel Van Brunt (Undercity), Taur Stonehoof (Thunder Bluff)}"
        .. "{A:Kaita Deepforge (Stormwind City), Thurgrum Deepforge (Ironforge)}." },
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
    { from = 175, to = 194, spell = 12585, crafts = 60, note = "Save them for later" },
    { from = 194, to = 195, spell = 12590, crafts = 1,  note = "Keep it - recipes need it" },
    { from = 195, to = 200, spell = 12589, crafts = 6,  note = "Keep all 6 if you might pick Gnomish Engineering" },

    -- Artisan
    -- Specialization quests (wow-professions.com's Gnomish vs Goblin Engineering guide, Nov 2026)
    { kind = "guide", from = 200, to = 200,
      text = "Engineering specialization: at Engineering 200 and level 30 you can pick Gnomish or Goblin "
        .. "Engineering with a short quest chain. Optional - you don't need one to level. Most items one makes "
        .. "can be used by either, so the choice mostly comes down to the teleporter and a few bind on pickup "
        .. "trinkets. Pick one under the 200 specialization choice for its quest steps. Switching later: see "
        .. "Change Specialisation at the end of the route." },
    -- Gnomish / Goblin: a Prerequisites card, then the quest card - crafting the items or buying them
    { kind = "guide", from = 200, to = 200, when = { spec = "gnomish", gnomish = "craft" }, specPart = "prep",
      title = "Gnomish Engineering: Prerequisites",
      text = "Get all of this before you start the quests. Schematic: Accurate Scope is sold by Mazk Snipeshot "
        .. "in the Old Port Authority, Booty Bay. The Accurate Scope also needs a Gyromatic Micro-Adjustor (a "
        .. "tool - it isn't used up) and your Arclight Spanner.",
      spec = GNOMISH_CRAFT },
    { kind = "guide", from = 200, to = 200, when = { spec = "gnomish", gnomish = "craft" }, specPart = "quests",
      title = "Become a Gnomish Engineer", text = GNOMISH_TEXT, spec = GNOMISH_CRAFT },
    { kind = "guide", from = 200, to = 200, when = { spec = "gnomish", gnomish = "buy" }, specPart = "prep",
      title = "Gnomish Engineering: Prerequisites",
      text = "Buy all of this before you start the quests.",
      spec = GNOMISH_BUY },
    { kind = "guide", from = 200, to = 200, when = { spec = "gnomish", gnomish = "buy" }, specPart = "quests",
      title = "Become a Gnomish Engineer", text = GNOMISH_TEXT, spec = GNOMISH_BUY },
    { kind = "guide", from = 200, to = 200, when = { spec = "goblin", goblin = "craft" }, specPart = "prep",
      title = "Goblin Engineering: Prerequisites",
      text = "Get all of this before you start the quests. Every recipe is from the trainer.",
      spec = GOBLIN_CRAFT },
    { kind = "guide", from = 200, to = 200, when = { spec = "goblin", goblin = "craft" }, specPart = "quests",
      title = "Become a Goblin Engineer", text = GOBLIN_TEXT, spec = GOBLIN_CRAFT },
    { kind = "guide", from = 200, to = 200, when = { spec = "goblin", goblin = "buy" }, specPart = "prep",
      title = "Goblin Engineering: Prerequisites",
      text = "Buy all of this before you start the quests.",
      spec = GOBLIN_BUY },
    { kind = "guide", from = 200, to = 200, when = { spec = "goblin", goblin = "buy" }, specPart = "quests",
      title = "Become a Goblin Engineer", text = GOBLIN_TEXT, spec = GOBLIN_BUY },
    { from = 200, to = 215, spell = 12591, crafts = 20, note = "Keep all 20 for the bombs at 238" },
    { from = 215, to = 238, spell = 12599, crafts = 40,
      note = "Keep 40 for the bombs. Past 225 is untested in Forever (Classic route)" },
    { from = 238, to = 250, spell = 12619, crafts = 20 },
    { from = 250, to = 260, spell = 19788, crafts = 30, note = "Yellow from 250" },
    { from = 260, to = 285, spell = 19791, crafts = 35,
      note = "Schematic from {H:Sovik, Orgrimmar}{A:Gearcutter Cogspinner, Ironforge}" },
    { from = 285, to = 300, spell = 19795, crafts = 20,
      note = "Schematic (bind on pickup) from Xizzer Fizzbolt, Everlook, Winterspring" },
  },
})

CR.extraNames[HAMMER] = "Blacksmith Hammer"
