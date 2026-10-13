-- Skinning route from wow-professions.com's Classic Skinning guide
-- (https://www.wow-professions.com/classic/skinning-leveling-guide-classic-wow) - a stand-in until
-- there's a Forever one; gathering changes little between the two. Every step is an instruction
-- ("guide" step); the guide has one path per faction, so there's nothing to choose.
-- What you can skin: up to skill 100, mobs up to level skill / 10 + 10; from 100, skill / 5.
local _, CR = ...

local KNIFE = 7005

local steps = {
  { kind = "guide", from = 1, to = 75, items = { { KNIFE, 1 } },
    text = "Buy a Skinning Knife from a Leatherworking Supply or General Goods vendor near your trainer - it "
      .. "only has to be in your bags. Kill and skin beasts; a red or orange mob is likely, but not certain, to "
      .. "give a point. (The very first area of a starting zone has nothing you can skin.)" },
  { kind = "guide", from = 1, to = 75, faction = "Horde", gather = true,
    text = "Skin beasts from Sen'jin Village in Durotar towards Orgrimmar. 50 is enough if you don't reach 75 "
      .. "before Orgrimmar." },
  { kind = "guide", from = 1, to = 75, faction = "Alliance", gather = true,
    text = "Skin beasts around the lake near Ironforge in Dun Morogh, then on towards Loch Modan. 50 is enough if "
      .. "you don't reach 75." },
  { kind = "guide", from = 75, to = 165, faction = "Horde", gather = true,
    text = "Skin beasts through The Barrens towards Camp Taurajo - reach 125 before you get there - then on into "
      .. "Thousand Needles." },
  { kind = "guide", from = 75, to = 155, faction = "Alliance", gather = true,
    text = "Skin beasts in Loch Modan to 115, then along the river through the Wetlands towards Menethil Harbor "
      .. "(at least 125 by then), and on to 155 for the raptors in Arathi." },
  { kind = "guide", from = 165, to = 205, faction = "Horde", gather = true,
    text = "Skin beasts in Thousand Needles until 205 before you leave." },
  { kind = "guide", from = 155, to = 205, faction = "Alliance", gather = true,
    text = "Skin the raptors in the Arathi Highlands until 205 - the higher ones in the south-east only from "
      .. "180." },
  { kind = "guide", from = 205, to = 280, gather = true,
    text = "Skin beasts around Camp Mojache in Feralas to 230, then in the yeti caves (or the hippogryphs to the "
      .. "south if the caves are busy) until 280." },
  { kind = "guide", from = 280, to = 300, gather = true,
    text = "Skin the higher yetis and beasts outside the second Feralas cave until 300 - or move on to "
      .. "Un'Goro Crater." },
}

CR.RegisterRoute("Skinning", {
  label = "Skinning",
  source = "wow-professions.com (Classic guide - stand-in)",
  routeEnd = 300,
  maxSkill = 300,
  noAutoFill = true,

  tiers = {
    { name = "Apprentice", cap = 75, skill = 0, level = 0 },
    { name = "Journeyman", cap = 150, skill = 50, level = 10,
      text = "Train Journeyman Skinning at any Skinning trainer (skill 50, level 10)." },
    { name = "Expert", cap = 225, skill = 125, level = 20,
      text = "Train Expert Skinning at a Skinning trainer (skill 125, level 20)." },
    { name = "Artisan", cap = 300, skill = 200, level = 35,
      text = "Train Artisan Skinning at a Skinning trainer (skill 200, level 35)." },
  },

  steps = steps,
})

CR.extraNames[KNIFE] = "Skinning Knife"
