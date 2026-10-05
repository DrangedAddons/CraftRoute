-- Cooking route transcribed from wow-professions.com's WoW Forever Cooking guide
-- (https://www.wow-professions.com/forever/cooking-leveling-guide, beta data, Oct 2026).
-- Every skill band is "make around N of ONE of these", so each band is a choice.
-- The guide's 225-300 part is the untested Classic route (beta was capped at level 30).
local _, CR = ...

local GIANT_EGG, ZESTY_CLAM, ALTERAC_SWISS = 12207, 7974, 8932

-- Builds one choice + its steps from { {key, label, spell, crafts, faction}, ... }.
local choices, steps = {}, {}
local function Band(key, label, from, to, opts, note)
  local c = { key = key, label = label, options = {} }
  for _, o in ipairs(opts) do
    table.insert(c.options, { key = o[1], label = o[2], faction = o[5] })
    table.insert(steps, { from = from, to = to, spell = o[3], crafts = o[4], when = { [key] = o[1] },
                          faction = o[5], note = note })
  end
  table.insert(choices, c)
end

table.insert(steps, { kind = "guide", from = 1, to = 50,
  text = "You need a fire to cook. In Forever the campfire is an item: craft Basic Campfire Kits from Simple "
    .. "Wood and a Flint and Tinder (sold next to the Cooking trainer), or use a fire already burning there. "
    .. "Buy spices and Refreshing Spring Water from the Cooking Supply vendor, not the AH." })

Band("c1", "1-50", 1, 50, {
  { "smallfish", "Brilliant Smallfish", 7751, 55 },
  { "mackerel", "Slitherskin Mackerel", 7752, 55 },
  { "wolf", "Charred Wolf Meat", 2538, 55 },
  { "boar", "Roasted Boar Meat", 2540, 55 },
  { "egg", "Herb Baked Egg", 8604, 55 },
  { "batwing", "Crispy Bat Wing", 15935, 55, "Horde" },
  { "scorpid", "Scorpid Surprise", 6413, 55, "Horde" },
  { "kabob", "Kaldorei Spider Kabob", 6412, 55, "Alliance" },
})
Band("c2", "50-100", 50, 100, {
  { "longjaw", "Longjaw Mud Snapper", 7753, 55 },
  { "albacore", "Rainbow Fin Albacore", 7827, 55 },
  { "bear", "Smoked Bear Meat", 8607, 70 },
  { "clams", "Boiled Clams", 6499, 55 },
  { "coyote", "Coyote Steak", 2541, 55 },
  { "strider", "Strider Stew", 6416, 55 },
}, "Train Journeyman before 75 or skill-ups stop")
Band("c3", "100-130", 100, 130, {
  { "catfish", "Bristle Whisker Catfish", 7755, 30 },
  { "crabcake", "Crab Cake", 2544, 40 },
  { "ribs", "Dry Pork Ribs", 2546, 35 },
  { "crabclaw", "Cooked Crab Claw", 2545, 35, "Alliance" },
})
Band("c4", "130-150", 130, 150, {
  { "catfish", "Bristle Whisker Catfish", 7755, 25 },
  { "omelet", "Curiously Tasty Omelet", 3376, 20 },
  { "clams", "Goblin Deviled Clams", 6500, 25 },
  { "lion", "Hot Lion Chops", 3398, 25, "Horde" },
})
Band("c5", "150-175", 150, 175, {
  { "omelet", "Curiously Tasty Omelet", 3376, 25 },
  { "lion", "Hot Lion Chops", 3398, 25, "Horde" },
}, "Omelet is yellow from 170")
Band("c6", "175-225", 175, 225, {
  { "trout", "Mithril Headed Trout", 20916, 50 },
  { "raptor", "Roast Raptor", 15855, 50 },
  { "bisque", "Soothing Turtle Bisque", 3400, 50 },
}, "Yellow from 215")
Band("c7", "225-275", 225, 275, {
  { "yellowtail", "Spotted Yellowtail", 18238, 65 },
  { "redgill", "Filet of Redgill", 18241, 65 },
  { "chowder", "Undermine Clam Chowder", 20626, 65 },
  { "monster", "Monster Omelet", 15933, 65 },
  { "wolf", "Tender Wolf Steak", 22480, 65 },
}, "Untested in Forever (Classic route)")
Band("c8", "275-300", 275, 300, {
  { "salmon", "Poached Sunscale Salmon", 18244, 35 },
  { "nightfin", "Nightfin Soup", 18243, 35 },
}, "Untested in Forever - yellow from 290")

CR.RegisterRoute("Cooking", {
  label = "Cooking only",
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 0,
      text = "Train Journeyman Cooking at any Cooking trainer (skill 50). Do it before 75 or you stop "
        .. "getting skill points." },
    { name = "Expert", cap = 225, skill = 125, level = 0,
      text = "Buy and read the Expert Cookbook (skill 125) from {H:Wulan, Shadowprey Village, Desolace}"
        .. "{A:Shandrina, Mystral Lake, Ashenvale}." },
    { name = "Artisan", cap = 300, skill = 225, level = 35,
      items = { { GIANT_EGG, 12 }, { ZESTY_CLAM, 10 }, { ALTERAC_SWISS, 20 } },
      text = "Artisan is the reward of 'Clamlette Surprise' from Dirge Quikcleave in Gadgetzan (level 35, skill "
        .. "225). Get the lead quest {H:'To Gadgetzan You Go!' from Zamja in Orgrimmar}{A:'I Know A Guy...' from "
        .. "Daryl Riknussun in Ironforge}. Bring 12 Giant Egg, "
        .. "10 Zesty Clam Meat and 20 Alterac Swiss, then buy every recipe Gikkix sells at Steamwheedle Port." },
  },

  choices = choices,
  steps = steps,
})

CR.extraNames[GIANT_EGG] = "Giant Egg"
CR.extraNames[ZESTY_CLAM] = "Zesty Clam Meat"
CR.extraNames[ALTERAC_SWISS] = "Alterac Swiss"
