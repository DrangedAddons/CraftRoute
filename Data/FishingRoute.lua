-- Fishing route transcribed from wow-professions.com's WoW Forever Fishing guide
-- (https://www.wow-professions.com/forever/fishing-leveling-guide, beta data, Oct 2026).
-- Fishing has no recipes: every step is an instruction ("guide" step). items = things to buy.
-- "Fish in one of these places" bands are choices, so you pick the spot that suits you.
-- {H:...} / {A:...} text is only shown to Horde / Alliance.
local _, CR = ...

local POLE, SHINY_BAUBLE, NIGHTCRAWLERS, BRIGHT_BAUBLES = 6256, 6529, 6530, 6532

local choices, steps = {}, {}
-- One choice whose options are places; each option becomes a guide step over [from, to].
local function Places(key, label, from, to, places)
  local c = { key = key, label = label, options = {} }
  for _, p in ipairs(places) do
    table.insert(c.options, { key = p[1], label = p[2], faction = p[4] })
    table.insert(steps, { kind = "guide", from = from, to = to, when = { [key] = p[1] }, faction = p[4],
                          text = p[3] })
  end
  table.insert(choices, c)
end

table.insert(steps, { kind = "guide", from = 1, to = 75, items = { { POLE, 1 }, { SHINY_BAUBLE, 2 } },
  text = "Learn Fishing from a Fishing trainer (they all stand next to water). Buy a Fishing Pole and a few "
    .. "Shiny Baubles from a Fishing or Trade Supply vendor - in capitals they stand next to the trainer. "
    .. "Equip the pole, put on a Shiny Bauble and fish in a starting zone (not a capital) until 75." })
Places("start", "1-75: fish in one starting zone", 1, 75, {
  { "durotar", "Durotar", "Trainer Lau'Tiki on the coast at Sen'jin Village; pole and baubles from Zansoa in "
    .. "Sen'jin Village.", "Horde" },
  { "mulgore", "Mulgore", "Trainer Uthan Stillwater at Stonebull Lake, next to Bloodhoof Village; pole and "
    .. "baubles from Wunna Darkmane in Bloodhoof Village.", "Horde" },
  { "tirisfal", "Tirisfal Glades", "Trainer Clyde Kellen at Brightwater Lake, east of Brill; pole and baubles "
    .. "from Martine Tramblay at the Death's Watch Waystation, south-east of Brill.", "Horde" },
  { "elwynn", "Elwynn Forest", "Trainer Lee Brown at Crystal Lake, east of Goldshire; pole and baubles from "
    .. "Tharynn Bouden in Goldshire.", "Alliance" },
  { "dunmorogh", "Dun Morogh", "Trainer Paxton Ganter at Iceflow Lake, on the way to Gnomeregan; pole and "
    .. "baubles from Gretta Ganter at Iceflow Lake.", "Alliance" },
  { "teldrassil", "Teldrassil", "Trainer Androl Oakhand in Rut'theran Village, on the shore next to the dock; "
    .. "pole and baubles from Nessa Shadowsong in Rut'theran Village.", "Alliance" },
  { "zephras", "Zephras Isle", "Trainer Baelann Swiftcurrent in Valanaar or Fenn Fairweather in Shen'dar "
    .. "Village; pole and baubles from Baelann Swiftcurrent or Belandiel Farflight." },
})

table.insert(steps, { kind = "guide", from = 75, to = 150,
  text = "If fish keep getting away, buy Nightcrawlers (need Fishing 50) from a Fishing Supply vendor." })
Places("mid", "75-150: fish in one of these", 75, 150, {
  { "orgrimmar", "Orgrimmar", "Fish in Orgrimmar until 150.", "Horde" },
  { "undercity", "Undercity", "Fish in Undercity until 150.", "Horde" },
  { "thunderbluff", "Thunder Bluff", "Fish in Thunder Bluff until 150.", "Horde" },
  { "barrens", "The Barrens", "Fish in The Barrens until 150.", "Horde" },
  { "silverpine", "Silverpine Forest", "Fish in Silverpine Forest until 150.", "Horde" },
  { "stormwind", "Stormwind City", "Fish in Stormwind City until 150.", "Alliance" },
  { "darnassus", "Darnassus", "Fish in Darnassus until 150.", "Alliance" },
  { "ironforge", "Ironforge", "Fish in Ironforge until 150.", "Alliance" },
  { "darkshore", "Darkshore", "Fish in Darkshore until 150.", "Alliance" },
  { "lochmodan", "Loch Modan", "Fish in Loch Modan until 150.", "Alliance" },
  { "westfall", "Westfall", "Fish in Westfall until 150.", "Alliance" },
})

table.insert(steps, { kind = "guide", from = 150, to = 225, items = { { BRIGHT_BAUBLES, 5 } },
  text = "Buy a bunch of Bright Baubles from Old Man Heming in Booty Bay (bottom of the town, near the "
    .. "fishing sign) and keep one on your pole." })
Places("expert", "150-225: fish in one of these", 150, 225, {
  { "dustwallow", "Dustwallow Marsh (recommended)", "Fish in Dustwallow Marsh until 225 - the Artisan quest "
    .. "starts there." },
  { "alterac", "Alterac Mountains", "Fish in Alterac Mountains until 225." },
  { "arathi", "Arathi Highlands", "Fish in Arathi Highlands until 225." },
  { "desolace", "Desolace", "Fish in Desolace until 225." },
  { "stv", "Stranglethorn Vale", "Fish in Stranglethorn Vale until 225." },
  { "swamp", "Swamp of Sorrows", "Fish in Swamp of Sorrows until 225." },
  { "needles", "Thousand Needles", "Fish in Thousand Needles until 225." },
})

table.insert(steps, { kind = "guide", from = 225, to = 300, items = { { BRIGHT_BAUBLES, 10 } },
  text = "Keep Bright Baubles on - in these zones fish get away without them." })
Places("artisan", "225-300: fish in one of these", 225, 300, {
  { "felwood", "Felwood", "Fish in Felwood until 300." },
  { "feralas", "Feralas", "Fish in Feralas until 300." },
  { "hinterlands", "The Hinterlands", "Fish in The Hinterlands until 300." },
  { "tanaris", "Tanaris", "Fish in Tanaris until 300." },
  { "ungoro", "Un'Goro Crater", "Fish in Un'Goro Crater until 300." },
  { "wpl", "Western Plaguelands", "Fish in Western Plaguelands until 300." },
})

CR.RegisterRoute("Fishing", {
  label = "Fishing only",
  source = "wow-professions.com (Forever beta)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Fishing at any Fishing trainer (skill 50, level 10)." },
    { name = "Expert", cap = 225, skill = 125, level = 20, book = 16083,
      text = "Buy and read 'Expert Fishing - The Bass and You' (skill 125, level 20) from Old Man Heming "
        .. "at the bottom of Booty Bay, near the fishing sign. Also on the Auction House." },
    { name = "Artisan", cap = 300, skill = 225, level = 35, quest = "Nat Pagle, Angler Extreme",
      has = { { 16967, 1 }, { 16970, 1 }, { 16968, 1 }, { 16969, 1 } },   -- the four quest fish
      text = "Quest 'Nat Pagle, Angler Extreme' from Nat Pagle, Tidefury Cove, Dustwallow Marsh (level 35, "
        .. "skill 225). Catch Feralas Ahi (Feralas, use Bright Baubles), Misty Reed Mahi Mahi (Swamp of "
        .. "Sorrows), Sar'theris Striker (Desolace) and Savage Coast Blue Sailfin (Stranglethorn Vale)." },
  },

  choices = choices,
  steps = steps,
})

CR.extraNames[POLE] = "Fishing Pole"
CR.extraNames[SHINY_BAUBLE] = "Shiny Bauble"
CR.extraNames[NIGHTCRAWLERS] = "Nightcrawlers"
CR.extraNames[BRIGHT_BAUBLES] = "Bright Baubles"
CR.extraNames[6533] = "Aquadynamic Fish Attractor"
CR.extraNames[8932] = "Alterac Swiss"
CR.extraNames[16967] = "Feralas Ahi"
CR.extraNames[16968] = "Sar'theris Striker"
CR.extraNames[16969] = "Savage Coast Blue Sailfin"
CR.extraNames[16970] = "Misty Reed Mahi Mahi"
