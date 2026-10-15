-- Skinning route from wow-professions.com's Classic Skinning guide
-- (https://www.wow-professions.com/classic/skinning-leveling-guide-classic-wow) - a stand-in until
-- there's a Forever one; gathering changes little between the two. Every step is an instruction
-- ("guide" step): the training (the guide's trainers, per faction), the knife,
-- and the skinning itself by zone - 1-75 Durotar / Dun Morogh, 75-115 The Barrens / Loch Modan,
-- 115-155 The Barrens / Wetlands, 155-205 Thousand Needles / Arathi Highlands, 205-300 Feralas
-- (Un'Goro Crater at the end). One path per faction, so there's nothing to choose. Each step has a
-- short title (the route list, the card's heading) and its details (the card's text).
-- What you can skin: up to skill 100, mobs up to level skill / 10 + 10; from 100, skill / 5.
local _, CR = ...

local KNIFE = 7005
local H, A = "Horde", "Alliance"

local steps = {
  -- the knife (learning Skinning itself is CraftRoute's own first step while it isn't learned)
  { kind = "guide", from = 1, to = 75, items = { { KNIFE, 1 } }, nearTrainer = { "Skinning" },
    title = "Buy a Skinning Knife",
    text = "Buy a Skinning Knife from a Leatherworking Supply or General Goods vendor near your trainer. It only "
      .. "has to be in your bags, not equipped." },

  -- 1-75
  { kind = "guide", from = 1, to = 75, faction = H, gather = true, title = "Durotar: Sen'jin Village to Orgrimmar",
    text = "Skin beasts on the way from Sen'jin Village to Orgrimmar - not in the starting area (levels 1-6), "
      .. "there's nothing to skin there. Aim for 75; 50 is enough to move on." },
  { kind = "guide", from = 1, to = 75, faction = A, gather = true, title = "Dun Morogh: the lake by Ironforge",
    text = "Circle the lake near Ironforge skinning beasts until 50, then carry on towards Loch Modan until "
      .. "about 75." },
  { kind = "guide", from = 50, to = 150, trainCap = 150, title = "Train Journeyman Skinning",
    text = "Learn Journeyman Skinning (skill 50, level 10) from {H:Thuwd in Orgrimmar}"
      .. "{A:Balthus Stoneflayer in Ironforge}." },

  -- 75-155
  { kind = "guide", from = 75, to = 125, faction = H, gather = true, title = "The Barrens: on to Camp Taurajo",
    text = "Skin beasts through The Barrens, working south towards Camp Taurajo. Reach 125 before you get "
      .. "there - Expert is trained at Camp Taurajo." },
  { kind = "guide", from = 75, to = 115, faction = A, gather = true, title = "Loch Modan",
    text = "Skin beasts around Loch Modan until 115, then head into the Wetlands." },
  { kind = "guide", from = 115, to = 155, faction = A, gather = true, title = "Wetlands: the river to Menethil Harbor",
    text = "Follow the river through the Wetlands towards Menethil Harbor, skinning beasts - some here can't be "
      .. "skinned yet at the low end. Reach at least 125 by Menethil, fly to Ironforge for Expert, then fly "
      .. "back and keep going until 155 (for the level 31 raptors in the Arathi Highlands)." },
  { kind = "guide", from = 125, to = 225, trainCap = 225, title = "Train Expert Skinning",
    text = "Learn Expert Skinning (skill 125, level 20) from {H:Dranh at Camp Taurajo in The Barrens}"
      .. "{A:Balthus Stoneflayer in Ironforge - fly there from Menethil Harbor}." },
  { kind = "guide", from = 125, to = 155, faction = H, gather = true, title = "The Barrens: Camp Taurajo to Thousand Needles",
    text = "From Camp Taurajo skin your way south through The Barrens towards Thousand Needles." },

  -- 155-205
  { kind = "guide", from = 155, to = 205, faction = H, gather = true, title = "Thousand Needles",
    text = "Skin beasts through Thousand Needles. Reach 205 before you leave." },
  { kind = "guide", from = 155, to = 205, faction = A, gather = true, title = "Arathi Highlands: the raptors",
    text = "Skin the raptors in the Arathi Highlands - the lower ones until 170, then the higher ones. Leave "
      .. "the level 36-37 raptors in the south-east until you have 180." },
  { kind = "guide", from = 200, to = 300, trainCap = 300, title = "Train Artisan Skinning",
    text = "Learn Artisan Skinning (skill 200, level 35) at 205 from {H:Kulleg Stonehorn at Camp Mojache in "
      .. "Feralas - travel through Tanaris and fly there}{A:Balthus Stoneflayer in Ironforge}." },

  -- 205-300
  { kind = "guide", from = 205, to = 230, gather = true, title = "Feralas: around Camp Mojache",
    text = "Skin the beasts around Camp Mojache in Feralas until 230 - fine for Alliance too." },
  { kind = "guide", from = 230, to = 260, gather = true, title = "Feralas: the yeti cave",
    text = "Skin the yetis in the Feralas yeti cave until 260. If someone's farming the cave, go south and skin "
      .. "the hippogryphs instead." },
  { kind = "guide", from = 260, to = 280, gather = true, title = "Feralas: the second yeti cave",
    text = "Skin the higher yetis in the second yeti cave, then the beasts in front of it, until 280." },
  { kind = "guide", from = 280, to = 300, gather = true, title = "Feralas or Un'Goro Crater",
    text = "Keep skinning the beasts in front of the second Feralas cave until 300 - or fly to Un'Goro Crater "
      .. "and skin there." },
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
