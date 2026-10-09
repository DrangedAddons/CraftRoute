-- Combined route transcribed from wow-professions.com's WoW Forever Fishing and Cooking guide
-- (https://www.wow-professions.com/forever/fishing-and-cooking-leveling-guide, beta data, Oct 2026).
-- Followed in order (sequential): each step belongs to one skill and disappears once that skill
-- passes its end. Fishing steps "yield" the fish the guide says you'll catch; cooking steps use
-- them up, so the materials list only shows fish you're short of. Cook counts without a number
-- are estimated from the recipe's skill colours ("cook all of them until X").
-- Everything from level 35 (Artisan) is the untested Classic route.
local _, CR = ...

local POLE, SHINY_BAUBLE, NIGHTCRAWLERS = 6256, 6529, 6530
local SMALLFISH, LONGJAW, CATFISH, MACKEREL = 6291, 6289, 6308, 6303
local TROUT, REDGILL, SUNSCALE, NIGHTFIN, WHITESCALE = 8365, 13758, 13760, 13759, 13889
local GIANT_EGG, ZESTY_CLAM, ALTERAC_SWISS = 12207, 7974, 8932
local F, C = "Fishing", "Cooking"

local START = { { POLE, 1 }, { SHINY_BAUBLE, 2 } }
local ATTRACTOR = " Buy any Aquadynamic Fish Attractor you see and keep it for the Artisan quest."
local STD_CATCH = { { SMALLFISH, 45 }, { LONGJAW, 30 } }

local route = {
  id = "FishingCooking",
  label = "Fishing + Cooking",
  source = "wow-professions.com (Forever beta)",
  sequential = true,
  recipeProf = "Cooking",
  skills = { F, C },
  routeEnd = 300,
  maxSkill = 300,

  choices = {
    { key = "zone", label = "Fishing 1-75: pick your starting zone", options = {
      { key = "mulgore", label = "Mulgore (recommended)", faction = "Horde" },
      { key = "durotar", label = "Durotar", faction = "Horde" },
      { key = "tirisfal", label = "Tirisfal Glades", faction = "Horde" },
      { key = "zephras_h", label = "Zephras Isle", faction = "Horde" },
      { key = "elwynn", label = "Elwynn Forest (recommended)", faction = "Alliance" },
      { key = "dunmorogh", label = "Dun Morogh", faction = "Alliance" },
      { key = "teldrassil", label = "Teldrassil", faction = "Alliance" },
      { key = "zephras_a", label = "Zephras Isle", faction = "Alliance" },
    }},
    { key = "capital", label = "Fishing 75-130: pick a capital", options = {
      { key = "thunderbluff", label = "Thunder Bluff", faction = "Horde" },
      { key = "undercity", label = "Undercity", faction = "Horde" },
      { key = "orgrimmar", label = "Orgrimmar", faction = "Horde" },
      { key = "stormwind", label = "Stormwind City", faction = "Alliance" },
    }},
    { key = "final", label = "Cooking 250-300: cook either (or both)", options = {
      { key = "salmon", label = "Poached Sunscale Salmon" },
      { key = "nightfin", label = "Nightfin Soup" },
    }},
  },

  steps = {
    -- Fishing 1-75 in a starting zone
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "mulgore" }, items = START, yields = STD_CATCH,
      text = "Learn Fishing from Uthan Stillwater at Stonebull Lake. Buy Recipe: Brilliant Smallfish, Recipe: "
        .. "Longjaw Mud Snapper, a Fishing Pole and a Shiny Bauble from Harn Longcast in Bloodhoof Village. Fish "
        .. "Stonebull Lake until 75 (about 45 Smallfish, 30 Longjaw)." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "durotar" }, items = START,
      yields = { { MACKEREL, 70 } },
      text = "Learn Fishing from Lau'Tiki on the coast south of Sen'jin Village. Buy Recipe: Slitherskin "
        .. "Mackerel, a Fishing Pole and a Shiny Bauble from Zansoa in Sen'jin Village. Fish the coast next to "
        .. "Lau'Tiki until 75 (about 70 Slitherskin Mackerel)." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "tirisfal" }, items = START,
      yields = { { SMALLFISH, 30 }, { LONGJAW, 20 } },
      text = "Learn Fishing from Clyde Kellen at Brightwater Lake. Buy Recipe: Brilliant Smallfish, a Fishing "
        .. "Pole and a Shiny Bauble from Martine Tramblay at the Death's Watch Waystation, south-east of Brill. "
        .. "Fish Brightwater Lake until 75 (about 30 Smallfish, 20 Longjaw)." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = { "zephras_h", "zephras_a" } }, items = START,
      yields = STD_CATCH,
      text = "Learn Fishing from Fenn Fairweather (Shen'dar Village) or Baelann Swiftcurrent (Valanaar). Buy a "
        .. "Fishing Pole and a Shiny Bauble from Belandiel Farflight or Baelann Swiftcurrent. Fish any lake or "
        .. "river on Zephras Isle until 75 and keep every fish. In Valanaar, buy Recipe: Brilliant Smallfish "
        .. "and Recipe: Longjaw Mud Snapper from Nyalah Brightfire." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "elwynn" }, items = START, yields = STD_CATCH,
      text = "Learn Fishing from Lee Brown at Crystal Lake. Buy Recipe: Brilliant Smallfish, Recipe: Longjaw Mud "
        .. "Snapper, a Fishing Pole and a Shiny Bauble from Tharynn Bouden in Goldshire. Fish Crystal Lake, east "
        .. "of Goldshire, until 75 (about 45 Smallfish, 30 Longjaw)." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "dunmorogh" }, items = START,
      yields = STD_CATCH,
      text = "Learn Fishing from Paxton Ganter at Iceflow Lake. Buy Recipe: Brilliant Smallfish, a Fishing Pole "
        .. "and a Shiny Bauble from Gretta Ganter at Iceflow Lake. Fish Iceflow Lake until 75." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 1, to = 75, when = { zone = "teldrassil" }, items = START,
      yields = STD_CATCH,
      text = "Learn Fishing from Astaia in Darnassus (there's no trainer in Dolanaar). Buy Recipe: Brilliant "
        .. "Smallfish and Recipe: Longjaw Mud Snapper from Nyoma in Dolanaar, and a Fishing Pole and a Shiny "
        .. "Bauble from Narret Shadowgrove. Fish Lake Al'Ameth, south of Dolanaar, until 75." .. ATTRACTOR },
    { kind = "guide", skill = F, from = 50, to = 130, trainCap = 150,
      text = "Learn Journeyman Fishing from your Fishing trainer (level 10)." },

    -- Fishing 75-130 in a capital, Cooking 1-100
    { kind = "guide", skill = F, from = 75, to = 130, when = { capital = "thunderbluff" },
      yields = { { SMALLFISH, 20 }, { LONGJAW, 60 }, { CATFISH, 30 } },
      text = "Fish the pond near the Thunder Bluff Auction House until 130 (nothing gets away from 75). Naal "
        .. "Mistrunner sells Recipe: Bristle Whisker Catfish and Recipe: Longjaw Mud Snapper." },
    { kind = "guide", skill = F, from = 75, to = 130, when = { capital = "undercity" },
      yields = { { SMALLFISH, 13 }, { LONGJAW, 40 }, { CATFISH, 20 } },
      text = "Fish the Undercity canals until 130 - about a third of the catch is junk, so you get fewer fish. "
        .. "Ronald Burch sells Recipe: Bristle Whisker Catfish, Lizbeth Cromwell Recipe: Longjaw Mud Snapper." },
    { kind = "guide", skill = F, from = 75, to = 130, when = { capital = "orgrimmar" },
      yields = { { SMALLFISH, 20 }, { LONGJAW, 60 }, { CATFISH, 30 } },
      text = "Fish the pond in the Valley of Honor (where the Fishing trainer stands) until 130. Nobody in "
        .. "Orgrimmar sells the Catfish or Longjaw recipes - buy them on the AH or in Thunder Bluff." },
    { kind = "guide", skill = F, from = 75, to = 130, when = { capital = "stormwind" },
      yields = { { SMALLFISH, 20 }, { LONGJAW, 60 }, { CATFISH, 30 } },
      text = "Fish the canals of Stormwind City until 130. Buy Recipe: Bristle Whisker Catfish from Catherine "
        .. "Leland (and Recipe: Longjaw Mud Snapper from Tharynn Bouden in Goldshire if you don't have it). Buy "
        .. "20 Alterac Swiss from Ben Trias for the Artisan Cooking quest later." },
    { kind = "guide", skill = C, from = 1, to = 50, learnStep = true,
      text = "Learn Cooking from a Cooking trainer: {H:Aska Mistrunner (Thunder Bluff), Eunice Burch "
        .. "(Undercity) or Zamja (Orgrimmar)}{A:Stephen Ryback (Stormwind)}." },
    { skill = C, from = 1, to = 50, spell = 7751, when = { zone = { "mulgore", "tirisfal", "zephras_h", "elwynn",
        "dunmorogh", "teldrassil", "zephras_a" } }, note = "Cook all your Raw Brilliant Smallfish" },
    { skill = C, from = 1, to = 50, spell = 7752, when = { zone = "durotar" },
      note = "Cook all your Raw Slitherskin Mackerel" },
    { kind = "guide", skill = C, from = 1, to = 100, trainCap = 150,
      text = "Learn Journeyman Cooking from the same trainer (at 50)." },
    { skill = C, from = 50, to = 100, spell = 7753, note = "Cook all your Longjaw - you'll catch more later" },

    -- Fishing 130-205 and Cooking 100-175 (Expert: Fishing needs level 20 + 125, Cooking needs 125)
    { kind = "guide", skill = F, from = 100, to = 205, trainCap = 225, book = 16083,
      text = "Go to Booty Bay{H: (take the boat from Ratchet)}. Buy and read 'Expert Fishing - The Bass and You' "
        .. "from Old Man Heming (level 20, Fishing 125). Buy Recipe: Mithril Head Trout and Recipe: Filet of "
        .. "Redgill from Kelsey Yance." },
    { kind = "guide", skill = F, from = 130, to = 205, faction = "Horde", items = { { NIGHTCRAWLERS, 5 } },
      yields = { { LONGJAW, 95 }, { CATFISH, 145 } },
      text = "Fly from Ratchet to Sun Rock Retreat (Stonetalon Mountains) and buy 5 Nightcrawlers from Kulwia "
        .. "(keep 3 for Dustwallow Marsh). Attach one and fish the open water until 205." },
    { kind = "guide", skill = C, from = 100, to = 175, trainCap = 225, faction = "Horde", book = 16072,
      text = "Fly to Shadowprey Village (Desolace): buy the Expert Cookbook from Wulan (top floor of the "
        .. "eastern-most building) and read it at Cooking 125. Buy 20 Alterac Swiss from Innkeeper Sikewa "
        .. "for the Artisan Cooking quest." },
    { kind = "guide", skill = F, from = 130, to = 205, faction = "Alliance", items = { { NIGHTCRAWLERS, 5 } },
      yields = { { LONGJAW, 95 }, { CATFISH, 145 } },
      text = "Fly from Ratchet to Astranaar and ride south-east to Mystral Lake (Ashenvale). Buy the Expert "
        .. "Cookbook and 5 Nightcrawlers from Shandrina (keep 3 for Dustwallow). Fish Mystral Lake with a "
        .. "Nightcrawler until 205." },
    { kind = "guide", skill = C, from = 100, to = 175, trainCap = 225, faction = "Alliance", book = 16072,
      text = "Read the Expert Cookbook (from Shandrina) as soon as you reach Cooking 125 - without it you stop "
        .. "getting points at 150." },
    { skill = C, from = 100, to = 175, spell = 7755, note = "Cook all your Bristle Whisker Catfish" },

    -- Artisan Fishing quest and Dustwallow Marsh (level 35, untested on beta)
    { kind = "guide", skill = F, from = 205, to = 225, catches = { TROUT },
      text = "No Nightcrawlers left? Buy 3 from Kilxx in Ratchet (nobody in Dustwallow sells them). Fish any "
        .. "inland open water in Dustwallow Marsh (not the ocean) until 225, Nightcrawler on." },
    { kind = "guide", skill = F, from = 205, to = 255, trainCap = 300,
      text = "Quest 'Nat Pagle, Angler Extreme' from Nat Pagle, Tidefury Cove, Dustwallow Marsh (level 35, "
        .. "Fishing 225). Catch Feralas Ahi (Feralas - use the Aquadynamic Fish Attractor or Bright Baubles from "
        .. "Sheendra Tallgrass / Vivianna), Misty Reed Mahi Mahi (Swamp of Sorrows), Sar'theris Striker "
        .. "(Desolace) and Savage Coast Blue Sailfin (Stranglethorn Vale)." },
    { kind = "guide", skill = F, from = 225, to = 255, catches = { TROUT },
      text = "Keep fishing in Dustwallow Marsh until 255. Cook at {H:Brackenwall Village}{A:Theramore Isle} or "
        .. "on a campfire." },
    { skill = C, from = 175, to = 225, spell = 20916,
      note = "Cook your Mithril Head Trout - stop at 225 and keep the rest" },

    -- Artisan Cooking quest
    { kind = "guide", skill = C, from = 175, to = 250, trainCap = 300,
      items = { { GIANT_EGG, 12 }, { ZESTY_CLAM, 10 }, { ALTERAC_SWISS, 20 } },
      text = "Fly to Gadgetzan and take 'Clamlette Surprise' from Dirge Quikcleave (level 35, Cooking 225), "
        .. "rewarding Artisan Cooking. Bring 12 Giant Egg (Rocs in Tanaris), 10 Zesty Clam Meat (Big-mouth "
        .. "Clams from Steeljaw Snappers and Surf Gliders) and the 20 Alterac Swiss. At Steamwheedle Port buy "
        .. "Recipe: Nightfin Soup, Poached Sunscale Salmon and Spotted Yellowtail from Gikkix." },

    -- Fishing to 300 in Feralas, Cooking to 300
    { kind = "guide", skill = F, from = 255, to = 300, items = { { NIGHTCRAWLERS, 10 } },
      catches = { REDGILL, SUNSCALE, NIGHTFIN, WHITESCALE },
      text = "Fly to {H:Camp Mojache}{A:Feathermoon Stronghold} in Feralas. Buy Recipe: Baked Salmon and 10 "
        .. "Nightcrawlers from {H:Sheendra Tallgrass}{A:Vivianna}. Fish any inland Feralas water except "
        .. "Jademir Lake, a new Nightcrawler every 10 minutes, until 300." },
    { skill = C, from = 225, to = 250, spell = 18241, note = "Cook any leftover Trout first" },
    { skill = C, from = 250, to = 300, spell = 18244, when = { final = "salmon" } },
    { skill = C, from = 250, to = 300, spell = 18243, when = { final = "nightfin" } },
  },
}

CR.RegisterRoute("Cooking", route, "combo")
CR.RegisterRoute("Fishing", route, "combo")
