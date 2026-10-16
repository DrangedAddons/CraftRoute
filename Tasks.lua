-- Non-crafting steps as tasks the route stops at: training a rank, a book or quest that replaces
-- the trainer, buying supplies, learning a recipe before crafting it, and leveling steps that
-- aren't crafts (fishing). Each says what to do, where (nearest NPCs, with a Blizzard map pin),
-- what it needs and costs, and ticks itself off when the game shows it's done - with a manual
-- "Mark as done" as the fallback.
-- NPC locations come from the TrainerSpells addon when it's installed (profession trainers and
-- recipe vendors), plus a few guide NPCs it doesn't list. A reagent's Vendor button asks Questie
-- for that item's sellers when clicked; those coordinates are not saved here.
local _, CR = ...

---------------------------------------------------------------------------
-- NPC places
---------------------------------------------------------------------------
-- Guide NPCs TrainerSpells doesn't have (Classic positions).
local EXTRA_NPCS = {
  ["Old Man Heming"] = { { uiMapID = 1434, x = 27.8, y = 77.2 } },
  ["Shandrina"]      = { { uiMapID = 1440, x = 50.0, y = 67.2, faction = "A" } },
  ["Nat Pagle"]      = { { uiMapID = 1445, x = 58.4, y = 60.2 } },
}

local npcIndex   -- [name] = { { name, uiMapID, x, y, faction }, ... }
local indexedOn  -- which table Index last finished (ApplyTrainerSpells replaces CR.npcIndex)
local function AddNpc(name, loc, faction)
  if type(name) ~= "string" or name == "" or type(loc) ~= "table" or not loc.uiMapID or not loc.x then return end
  local list = npcIndex[name]
  if not list then list = {}; npcIndex[name] = list end
  for _, p in ipairs(list) do
    if p.uiMapID == loc.uiMapID and math.abs(p.x - loc.x) < 0.5 and math.abs(p.y - loc.y) < 0.5 then return end
  end
  table.insert(list, { name = name, uiMapID = loc.uiMapID, x = loc.x, y = loc.y, faction = faction })
end

local function AddTrainersAndExtras()
  for _, trainers in pairs(type(TrainerSpellsProfessionTrainers) == "table" and TrainerSpellsProfessionTrainers or {}) do
    for _, t in ipairs(trainers) do
      for _, loc in ipairs(t.locations or {}) do AddNpc(t.names and t.names.enUS, loc, t.faction) end
    end
  end
  for name, locs in pairs(EXTRA_NPCS) do
    if not npcIndex[name] then for _, l in ipairs(locs) do AddNpc(name, l, l.faction) end end
  end
end

local function Index()
  -- Vendor NPCs are recorded while ApplyTrainerSpells walks sourceLocations. Reuse that
  -- table. Still add profession trainers and the few guide NPCs it doesn't list.
  if CR.npcIndex and CR.tsVendors then
    if indexedOn == CR.npcIndex then return npcIndex end
    npcIndex = CR.npcIndex
    AddTrainersAndExtras()
    indexedOn = npcIndex
    return npcIndex
  end
  if npcIndex then return npcIndex end
  npcIndex = {}
  for _, bySkill in pairs(type(TrainerSpellsBuiltin_ProfessionRecipe) == "table" and TrainerSpellsBuiltin_ProfessionRecipe or {}) do
    for _, entries in pairs(bySkill) do
      for _, data in pairs(entries) do
        if type(data) == "table" then
          for _, loc in ipairs(data.sourceLocations or {}) do AddNpc(loc.npcName, loc, loc.faction) end
        end
      end
    end
  end
  AddTrainersAndExtras()
  indexedOn = npcIndex
  return npcIndex
end

-- "A" / "Alliance" / "H" / "Horde" / "AH" / nil
local function ForMyFaction(f)
  if not f or f == "" or f == "AH" then return true end
  local mine = UnitFactionGroup and UnitFactionGroup("player")
  if f == "A" or f == "Alliance" then return mine == "Alliance" end
  if f == "H" or f == "Horde" then return mine == "Horde" end
  return true
end

local function WorldPos(uiMapID, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, uiMapID, CreateVector2D(x / 100, y / 100))
  if ok and cont and pos then return cont, pos.x, pos.y end
end

local function PlayerWorld()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local mapID = C_Map.GetBestMapForUnit("player")
  local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
  if not pos then return nil end
  local x, y = pos:GetXY()
  return WorldPos(mapID, x * 100, y * 100)
end

local function ZoneName(uiMapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID)
  return info and info.name or ("map " .. tostring(uiMapID))
end

-- Places for this faction, nearest first (same continent by distance, then the rest), with
-- .zone, .dist (yards, same continent only) and .far (other continent).
-- The same trainer list is asked for on every row. Remember the answer until the player
-- moves into another ~5% of the map (or the place list itself changes).
local nearestCache = {}
local nearestSeq = 0
local listIDs = setmetatable({}, { __mode = "k" })
local function PlaceListID(places)
  local id = listIDs[places]
  if not id then
    nearestSeq = nearestSeq + 1
    id = nearestSeq
    listIDs[places] = id
  end
  return id
end
local function Nearest(places, max)
  max = max or 3
  local mapID, bx, by = 0, 0, 0
  if C_Map and C_Map.GetBestMapForUnit then
    mapID = C_Map.GetBestMapForUnit("player") or 0
    if mapID ~= 0 and C_Map.GetPlayerMapPosition then
      local pos = C_Map.GetPlayerMapPosition(mapID, "player")
      if pos then
        local x, y = pos:GetXY()
        bx = math.floor((x or 0) * 20)
        by = math.floor((y or 0) * 20)
      end
    end
  end
  local key = PlaceListID(places) .. "\0" .. mapID .. "\0" .. bx .. "," .. by .. "\0" .. max
  local hit = nearestCache[key]
  if hit then return hit end
  local out = {}
  local pc, px, py = PlayerWorld()
  for _, p in ipairs(places) do
    if ForMyFaction(p.faction) then
      local e = { name = p.name, uiMapID = p.uiMapID, x = p.x, y = p.y, zone = ZoneName(p.uiMapID) }
      local c, wx, wy = WorldPos(p.uiMapID, p.x, p.y)
      if pc and c then
        if c == pc then e.dist = math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2) else e.far = true end
      end
      table.insert(out, e)
    end
  end
  table.sort(out, function(a, b)
    if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
    if a.dist and b.dist then return a.dist < b.dist end
    return a.name < b.name
  end)
  local seen, trimmed = {}, {}
  for _, e in ipairs(out) do
    if not seen[e.name] then seen[e.name] = true; table.insert(trimmed, e) end
    if #trimmed >= max then break end
  end
  nearestCache[key] = trimmed
  return trimmed
end

-- Profession trainers who teach up to `rank` (1 Apprentice ... 4 Artisan) or beyond.
-- The list is stable for the session; callers must not rewrite its entries.
local trainerCache = {}
local function Trainers(profName, rank)
  rank = rank or 1
  local key = (profName or "") .. "\0" .. rank
  local cached = trainerCache[key]
  if cached then return cached end
  local list = {}
  local trainers = type(TrainerSpellsProfessionTrainers) == "table" and TrainerSpellsProfessionTrainers[profName]
  for _, t in ipairs(trainers or {}) do
    if (t.rank or 1) >= rank then
      for _, loc in ipairs(t.locations or {}) do
        table.insert(list, { name = t.names and t.names.enUS or "?", uiMapID = loc.uiMapID, x = loc.x, y = loc.y,
                             faction = t.faction })
      end
    end
  end
  trainerCache[key] = list
  return list
end

-- The nearest `max` trainers (this faction) who teach profName from `rank` up - for the start page.
function CR.NearestTrainers(profName, rank, max)
  return Nearest(Trainers(profName, rank), max)
end

-- NPCs named in a step's text (faction-filtered text), whole names only.
local textCache = {}
local function NpcsInText(text)
  if not text or text == "" then return {} end
  if textCache[text] then return textCache[text] end
  local list = {}
  for name, locs in pairs(Index()) do
    if #name >= 4 then
      local s, e = text:find(name, 1, true)
      if s and not text:sub(s - 1, s - 1):match("%a") and not text:sub(e + 1, e + 1):match("%a") then
        for _, l in ipairs(locs) do table.insert(list, l) end
      end
    end
  end
  textCache[text] = list
  return list
end

-- Blizzard map pin (and the on-screen tracking arrow) on a place.
function CR.PinPlace(place)
  if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
    CR.Print("Map pins aren't available in this client.")
    return
  end
  if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(place.uiMapID) then
    CR.Print("Can't place a map pin in " .. (place.zone or "that zone") .. ".")
    return
  end
  -- WaypointUI installed: place it through its API so the waypoint carries the NPC's name (a
  -- plain Blizzard pin has no name - WaypointUI would call it "Map Pin"). It sets the Blizzard
  -- pin too. Coordinates are 0-100 there.
  local nav = WaypointUIAPI and WaypointUIAPI.Navigation
  local named = false
  if nav and nav.NewUserNavigation then
    local ok, res = pcall(nav.NewUserNavigation, { name = place.name, mapID = place.uiMapID, x = place.x, y = place.y })
    named = ok and res ~= nil
  end
  if not named then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(place.uiMapID, place.x / 100, place.y / 100))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  end
  CR.Print(string.format("Map pin set: %s, %s (%.0f, %.0f).", place.name, place.zone or "", place.x, place.y))
end

-- Reagent sellers for one item, from Questie, for this character's faction. Kept for the session
-- so a busy vendor list (thread, vials) is only walked once. A miss while Questie's zone map is
-- still starting is not remembered, so the next click tries again. An empty list is remembered:
-- the lookup finished and there was nothing to pin. Questie's Forever coordinates are already on
-- the redrawn maps, so these percentages go straight to the pin.
local vendorPlaces = {}

-- Deployable camping vendors. Questie kept spots where a player put one down, so the
-- nearest seller can be a bot that is not standing there. Field Repair Bot 74A is on
-- some seller lists and has no spawns in this database.
local CAMP_VENDOR = {
  [14337] = true,  -- Field Repair Bot 74A
  [242498] = true, -- Reagent Bot
  [254695] = true, -- Repair Bot
}

local function CanPinMap(uiMap)
  if not (C_Map and C_Map.CanSetUserWaypointOnMap) then return true end
  local ok, can = pcall(C_Map.CanSetUserWaypointOnMap, uiMap)
  return ok and can
end

local function QuestieZoneDB()
  local loader = QuestieLoader
  if not (loader and loader.ImportModule) then return nil end
  local okMod, zone = pcall(loader.ImportModule, loader, "ZoneDB")
  if not okMod or type(zone) ~= "table" or type(zone.GetUiMapIdByAreaId) ~= "function" then return nil end
  return zone
end

-- One NPC's or object's spawns, as place records. nil, "down" if the zone map errors,
-- so the caller does not cache that lookup. Spawns, not a patrol path.
local function AddSpawns(places, zone, name, faction, spawns)
  if type(spawns) ~= "table" then return true end
  for areaId, spots in pairs(spawns) do
    local ok, uiMap = pcall(zone.GetUiMapIdByAreaId, zone, areaId)
    if not ok then return nil, "down" end
    -- Skip a map the pin cannot use, so the nearest pick is one PinPlace can place.
    if type(uiMap) == "number" and uiMap > 0 and CanPinMap(uiMap) and type(spots) == "table" then
      for s = 1, #spots do
        local spot = spots[s]
        local x, y = type(spot) == "table" and spot[1], type(spot) == "table" and spot[2]
        if type(x) == "number" and type(y) == "number" and x > 0 and x <= 100 and y > 0 and y <= 100 then
          places[#places + 1] = { name = name, uiMapID = uiMap, x = x, y = y, faction = faction }
        end
      end
    end
  end
  return true
end

-- nil, "down" when ZoneDB is not ready. Otherwise the place list.
local function VendorPlaces(itemID)
  local cached = vendorPlaces[itemID]
  if cached then return cached end
  local ids
  if type(ItemDB.vendors) == "function" then ids = ItemDB.vendors(itemID)
  elseif type(ItemDB.Get) == "function" then ids = ItemDB.Get(itemID, "vendors") end
  if type(ids) ~= "table" then
    vendorPlaces[itemID] = {}
    return vendorPlaces[itemID]
  end
  local zone = QuestieZoneDB()
  if not zone then return nil, "down" end
  local places = {}
  for i = 1, #ids do
    local npcID = ids[i]
    if type(npcID) == "number" and not CAMP_VENDOR[npcID] then
      local name = NpcDB.name(npcID)
      local faction = NpcDB.friendlyToFaction(npcID)
      -- Skip an id Questie doesn't name. A nil faction still counts as friendly, same as the
      -- trainer list.
      if type(name) == "string" and name ~= "" and ForMyFaction(faction) then
        local ok, down = AddSpawns(places, zone, name, faction, NpcDB.spawns(npcID))
        if not ok then return nil, down end
      end
    end
  end
  vendorPlaces[itemID] = places
  return places
end

-- Pin the nearest vendor who sells itemID. The button stays "Vendor" when this cannot.
function CR.PinVendorItem(itemID)
  if not itemID then return end
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not (loaded and loaded("Questie") and LibQuestieDB and ItemDB and NpcDB) then
    CR.Print("Questie is needed to find the nearest vendor.")
    return
  end
  if type(ItemDB.vendors) ~= "function" or type(NpcDB.name) ~= "function"
    or type(NpcDB.friendlyToFaction) ~= "function" or type(NpcDB.spawns) ~= "function"
    or (LibQuestieDB.RequireContract and not LibQuestieDB.RequireContract(4)) then
    CR.Print("Questie's database is too old to look up vendors.")
    return
  end
  local places, zoneDown = VendorPlaces(itemID)
  if zoneDown then
    CR.Print("Questie isn't ready to look up vendor maps yet.")
    return
  end
  local nearest = places and Nearest(places, 1)
  local place = nearest and nearest[1]
  if not place then
    CR.Print("No vendor location for " .. CR.ItemName(itemID) .. ".")
    return
  end
  CR.PinPlace(place)
end

-- Anvils, forges, and fires, one list per Questie object name. Same cache rules as vendors.
-- The first IdsByName builds Questie's object name index, so this stays on the click.
local objectPlaces = {}
local function ObjectPlaces(name)
  local cached = objectPlaces[name]
  if cached then return cached end
  local ids = ObjectDB.IdsByName(name)
  if type(ids) ~= "table" then
    objectPlaces[name] = {}
    return objectPlaces[name]
  end
  local zone = QuestieZoneDB()
  if not zone then return nil, "down" end
  local places = {}
  for i = 1, #ids do
    local id = ids[i]
    if type(id) == "number" then
      -- No faction filter. Object factionID is a mask, not "A" / "H". Distance picks the capital.
      local ok, down = AddSpawns(places, zone, name, nil, ObjectDB.spawns(id))
      if not ok then return nil, down end
    end
  end
  objectPlaces[name] = places
  return places
end

-- Pin the nearest Questie object among `names`. `phrase` finishes "No location for ...".
function CR.PinNearestStructure(names, phrase)
  if type(names) ~= "table" or #names == 0 then return end
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not (loaded and loaded("Questie") and LibQuestieDB and ObjectDB) then
    CR.Print("Questie is needed to find the nearest one.")
    return
  end
  if type(ObjectDB.IdsByName) ~= "function" or type(ObjectDB.spawns) ~= "function"
    or (LibQuestieDB.RequireContract and not LibQuestieDB.RequireContract(4)) then
    CR.Print("Questie's database is too old to look up that.")
    return
  end
  local places = {}
  for i = 1, #names do
    local list, down = ObjectPlaces(names[i])
    if down then
      CR.Print("Questie isn't ready to look up maps yet.")
      return
    end
    if type(list) == "table" then
      for j = 1, #list do places[#places + 1] = list[j] end
    end
  end
  local nearest = Nearest(places, 1)
  local place = nearest and nearest[1]
  if not place then
    CR.Print("No location for " .. (phrase or "that") .. ".")
    return
  end
  CR.PinPlace(place)
end

---------------------------------------------------------------------------
-- Tasks
---------------------------------------------------------------------------
local RANK_NAMES = { "Apprentice", "Journeyman", "Expert", "Artisan" }
local function RankFor(learn)
  learn = learn or 1
  if learn <= 50 then return 1 elseif learn <= 125 then return 2 elseif learn <= 200 then return 3 end
  return 4
end

-- 75 Apprentice, 150 Journeyman, 225 Expert, 300 Artisan
local function RankOfCap(cap)
  if cap <= 75 then return 1 elseif cap <= 150 then return 2 elseif cap <= 225 then return 3 end
  return 4
end

-- The rank (skill needed, level) that raises skillName's max to cap, from its own route.
local function RankTier(skillName, cap)
  local prof = CR.professions[skillName]
  for _, route in pairs(prof and prof.routes or {}) do
    if type(route) == "table" then
      for _, tier in ipairs(route.tiers or {}) do
        if tier.cap == cap then return tier end
      end
    end
  end
end

local function DoneTable(profName) return CR.ProfTable("tasksDone", profName) end

-- (total anywhere, for "more in your bank / on alts"; and on you)
local function Owned(itemID)
  local bags = CR.BagsAndElsewhere(itemID)
  local _, total = CR.GetLocations(itemID)
  return math.max(bags, total or 0), bags
end

-- First sentence of a step's text, for a title.
local function FirstSentence(text)
  local s = (text or ""):match("^(.-[%.!])%s") or text or ""
  if #s > 70 then s = s:sub(1, 67) .. "..." end
  return s
end

local emptyPlaces = {}
local function TrainerCost(profName, spell)
  local p = CR.professions[profName]
  local r = p and p.recipes[spell]
  if r and r.cost then return r.cost end
  local costs = CR.tsCost and CR.tsCost[profName]
  if costs then return costs[spell] end
  -- ApplyTrainerSpells hasn't run: walk the addon tables once for this spell.
  local data = type(TrainerSpellsBuiltin_Profession) == "table" and TrainerSpellsBuiltin_Profession[profName]
  for _, bucket in pairs(data or {}) do
    local e = bucket[spell]
    if type(e) == "table" and e.cost then return e.cost end
  end
end

local function RecipeVendors(profName, spell)
  local vendors = CR.tsVendors and CR.tsVendors[profName]
  if vendors then return vendors[spell] or emptyPlaces end
  local list = {}
  local data = type(TrainerSpellsBuiltin_ProfessionRecipe) == "table" and TrainerSpellsBuiltin_ProfessionRecipe[profName]
  for _, bucket in pairs(data or {}) do
    local e = bucket[spell]
    if type(e) == "table" then
      for _, loc in ipairs(e.sourceLocations or {}) do
        table.insert(list, { name = loc.npcName or "?", uiMapID = loc.uiMapID, x = loc.x, y = loc.y, faction = loc.faction })
      end
    end
  end
  return list
end

local function KeyOf(st)
  return string.format("%s:%s:%s:%s", st.kind or "?", tostring(st.from or 0), tostring(st.to or ""),
    (st.text or ""):sub(1, 48))
end

-- Has this recipe been learned? nil when it can't be told (the profession was never opened
-- and no saved scan exists). false only when a scan exists and this spell isn't in it.
-- That nil-vs-false split is what the learn-task uses; the profession window's own check
-- (CR.RecipeLearned) stays nil when unknown.
local function RecipeLearned(profName, r)
  local info = CR.LiveRecipeInfo and CR.LiveRecipeInfo(profName, r.spell)
  if info and info.learned ~= nil then return info.learned end
  local known = CR.ProfTable("known", profName)
  if not next(known) then return nil end
  return known[r.spell] and true or false
end

local function Check(ok, text) return { ok = ok and true or false, text = text } end

-- Is a quest with this title in the quest log? nil when the log can't be read.
-- A readable answer is kept until QUEST_LOG_UPDATE. An unreadable log is not cached.
local questCache = {}
do
  local qf = CreateFrame("Frame")
  if pcall(qf.RegisterEvent, qf, "QUEST_LOG_UPDATE") then
    qf:SetScript("OnEvent", function() wipe(questCache) end)
  end
end
local function QuestInLog(title)
  if questCache[title] ~= nil then return questCache[title] end
  local found
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    found = false
    for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
      local info = C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.title == title then found = true; break end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    found = false
    for i = 1, GetNumQuestLogEntries() or 0 do
      local name, _, _, isHeader = GetQuestLogTitle(i)
      if not isHeader and name == title then found = true; break end
    end
  else
    return nil
  end
  questCache[title] = found
  return found
end

-- The rank's quest (st.quest = its title): picked up, or done once the rank it rewards is
-- learned. Shown, not required - turning it in is what trains the rank.
local function QuestCheck(checks, title, trained)
  if type(title) ~= "string" then return end
  local inLog = QuestInLog(title)
  local label = trained and ("Quest '" .. title .. "' done")
    or (inLog and ("Quest '" .. title .. "' picked up") or ("Pick up the quest '" .. title .. "'"))
  table.insert(checks, Check(trained or inLog, label))
end

-- Learned this recipe? Spellbook first (works with the profession closed), then what the
-- profession window showed. nil = can't tell yet.
local function KnowsRecipe(profName, spell)
  if IsPlayerSpell and IsPlayerSpell(spell) then return true end
  local p = CR.professions[profName]
  local r = p and p.recipes[spell]
  local known = r and RecipeLearned(profName, r)
  if known == nil and IsPlayerSpell then known = false end   -- the spellbook answered: not learned
  return known
end

-- The task for a train / guide step, or nil.
function CR.StepTask(st, profName)
  -- One task object per plan step. The step table is new on every plan build, so bag
  -- counts and skill checks are redone when the plan is. A second caller in the same
  -- refresh (the route list and the action list) reuses that object.
  if st._taskProf == profName then
    if st._taskNil then return nil end
    if st._task then return st._task end
  end
  local function Finish(t)
    st._taskProf = profName
    if t then st._task, st._taskNil = t, nil else st._task, st._taskNil = nil, true end
    return t
  end
  if st.recipe or (st.kind ~= "train" and st.kind ~= "guide") then return Finish(nil) end
  local skillName = st.skill or profName
  local cur, maxRank, learned = CR.GetSkill(skillName)
  local text = CR.FactionText(st.text or "")
  local t = { step = st, key = KeyOf(st), skillName = skillName, text = text, checks = {}, places = {},
              profName = profName }
  local conds = {}   -- what the game can confirm; all true = done
  local prep = {}    -- the part to do now (buy, learn) - for a rank you can't learn yet
  local function Cond(ok, label) table.insert(conds, ok and true or false); table.insert(t.checks, Check(ok, label)) end
  local function Prep(ok, label) table.insert(prep, ok and true or false); Cond(ok, label) end
  local need, trained   -- skill the rank needs; is it learned

  -- The step's objectives: supplies to have on you (items: also on the shopping list; has: already
  -- counted there as a later craft's reagents) and recipes to learn. Once the rank is trained,
  -- quest items handed in are gone - they show ticked.
  local rprofName = (CR.Route(profName) or {}).recipeProf or profName
  local function Objectives(trainedNow)
    local cost = 0
    for _, list in ipairs({ st.items or {}, st.has or {} }) do
      for _, it in ipairs(list) do
        local total, have = Owned(it[1])
        local label = string.format("%d/%d %s in your bags", math.min(have, it[2]), it[2], CR.ItemName(it[1]))
        if trainedNow then
          table.insert(t.checks, Check(true, CR.ItemName(it[1]) .. " (handed in)"))
        else
          if have < it[2] and total > have then label = label .. CR.ColorText("  (more in your bank / on alts)", "ffd100") end
          Prep(have >= it[2], label)
          -- where to get it (a fishing spot): the line gets its own Pin button
          local spot = it[3]
          if spot then
            t.checks[#t.checks].place = { name = CR.ItemName(it[1]) .. " (" .. spot.name .. ")", uiMapID = spot.uiMapID, x = spot.x, y = spot.y,
                                          zone = ZoneName(spot.uiMapID) }
            t.checks[#t.checks].text = label .. CR.ColorText("  -  " .. spot.name .. ", " .. ZoneName(spot.uiMapID), "aaaaaa")
          end
          local price = CR.GetUnitPrice and CR.GetUnitPrice(it[1])
          if price and total < it[2] then cost = cost + price * (it[2] - total) end
        end
      end
    end
    if cost > 0 then t.cost = (t.cost or 0) + cost end
    for _, spell in ipairs(st.recipes or {}) do
      local pr = CR.professions[rprofName]
      local r = pr and pr.recipes[spell]
      local known = KnowsRecipe(rprofName, spell)
      Prep(known == true, "Learned " .. (r and r.name or ("recipe " .. spell))
        .. (known == nil and CR.ColorText("  (open " .. rprofName .. " once to check)", "aaaaaa") or ""))
    end
  end

  if st.kind == "train" then
    local rank = st.rankIndex or 1
    if st.apprentice or not st.cap then
      t.kind, t.title, t.icon = "train", "Learn " .. skillName, "Interface\\Icons\\INV_Misc_Book_09"
      t.text = "Find a " .. skillName .. " trainer and learn " .. skillName .. "."
      Cond(learned, skillName .. " learned")
      t.places = Nearest(Trainers(skillName, 1))
    else
      t.kind = st.book and "book" or (st.quest and "quest" or "train")
      t.title = (st.tierName or RANK_NAMES[rank] or "Next rank") .. " " .. skillName
      t.icon = st.book and "Interface\\Icons\\INV_Misc_Book_11" or (st.quest and "Interface\\Icons\\INV_Misc_Note_01"
        or "Interface\\Icons\\INV_Misc_Book_09")
      if st.need then table.insert(t.checks, Check(cur >= st.need, string.format("%s skill %d (you: %d)", skillName, st.need, cur))) end
      if st.level and st.level > 0 then
        local lvl = UnitLevel("player") or 1
        table.insert(t.checks, Check(lvl >= st.level, string.format("Level %d (you: %d)", st.level, lvl)))
      end
      need, trained = st.need, learned and maxRank >= st.cap
      if st.book then
        local _, bags = Owned(st.book)
        local ok, label = bags > 0 or trained, "Bought " .. CR.ItemName(st.book)
        if st.need and cur < st.need and not trained then Prep(ok, label) else table.insert(t.checks, Check(ok, label)) end
      end
      QuestCheck(t.checks, st.quest, learned and maxRank >= st.cap)
      Objectives(trained)
      Cond(learned and maxRank >= st.cap, string.format("%s %s learned (max skill %d)", st.tierName or "", skillName, st.cap))
      if st.book or st.quest then
        t.places = Nearest(NpcsInText(text))
      else
        t.places = Nearest(Trainers(skillName, rank))
        if t.text == "" then t.text = "Learn " .. t.title .. " from a " .. skillName .. " trainer." end
      end
      if st.book then
        local price = CR.GetUnitPrice and CR.GetUnitPrice(st.book)
        if price and not trained then t.cost = (t.cost or 0) + price end
      end
    end
  else
    -- guide step
    t.kind = "guide"
    t.icon = (CR.GATHER_ICON and CR.GATHER_ICON[skillName]) or "Interface\\Icons\\INV_Misc_Note_01"
    -- its title: the step's own, else its first sentence (then not repeated in the details)
    if st.title then
      t.title = st.title
    else
      t.title = FirstSentence(text)
      local rest = text:sub(#t.title + 1):gsub("^%s+", "")
      if t.title:sub(-3) ~= "..." and rest ~= "" then t.text = rest end
    end
    if st.learnStep then Cond(learned, skillName .. " learned") end
    if st.learns then Prep(learned, skillName .. " learned") end
    if st.trainCap then
      trained = learned and maxRank >= st.trainCap
      local tier = RankTier(skillName, st.trainCap)
      need = tier and tier.skill
      Cond(trained, string.format("%s trained to %d", skillName, st.trainCap))
      QuestCheck(t.checks, st.quest, trained)
      if st.book then
        local _, bags = Owned(st.book)
        local ok, label = bags > 0 or trained, "Bought " .. CR.ItemName(st.book)
        if need and cur < need and not trained then Prep(ok, label) else table.insert(t.checks, Check(ok, label)) end
      end
    end
    -- books to buy now for a rank read later: { itemID, profession, cap it trains to }
    for _, b in ipairs(st.books or {}) do
      local _, bags = Owned(b[1])
      local _, bmax = CR.GetSkill(b[2])
      Prep(bags > 0 or (bmax or 0) >= b[3], "Bought " .. CR.ItemName(b[1])
        .. ((bmax or 0) >= b[3] and CR.ColorText("  (read)", "aaaaaa") or ""))
    end
    Objectives(trained)
    -- leveling that isn't crafting (fishing): done at the skill
    -- (a training / learning step's range only says when it applies - it's done once trained)
    -- (the solo Fishing guide's tips and shopping steps sit beside a "fish here" step over the
    -- same range, so only the chosen spot is the fishing itself)
    local activity = not st.trainCap and not st.learnStep
      and ((st.yields and #st.yields > 0) or st.catches or st.chosen or st.gather or st.ownSkill == "Fishing")
    if activity and st.to and st.to > (st.from or 0) then
      Cond(cur >= st.to, string.format("%s %d (you: %d)", skillName, st.to, cur))
      -- over the guide's whole step (the plan's own range starts at your skill, so it'd never fill)
      t.progress = { from = st.stepFrom or st.from or 0, to = st.to, cur = cur }
    elseif ((st.items and #st.items > 0) or (st.has and #st.has > 0)) and not st.trainCap and not st.learnStep then
      t.kind = "buy"
    end
    t.places = Nearest(NpcsInText(text))
    -- sold by supply vendors who stand next to these trainers - only when none of the vendors the
    -- step names has a known position (then the pins are the trainers, and say so)
    if st.nearTrainer and #t.places == 0 then
      local list = {}
      for _, p in ipairs(t.places) do table.insert(list, p) end
      for _, prof in ipairs(st.nearTrainer) do
        for _, p in ipairs(Trainers(prof, 1)) do
          -- Copy. Trainers() is cached, and rewriting p.name would stick on the next call.
          table.insert(list, { name = p.name .. " (" .. prof .. " trainer)", uiMapID = p.uiMapID,
                               x = p.x, y = p.y, faction = p.faction })
        end
      end
      t.places = Nearest(list)
      if #t.places > 0 then t.text = t.text .. "\n\nThe supply vendor stands next to the trainer." end
    end
    -- a rank learned from a trainer (combined guide): its requirements, and the trainers
    if st.trainCap then t.kind = st.book and "book" or (st.quest and "quest" or "train") end
    if st.trainCap then
      local tier = RankTier(skillName, st.trainCap)
      if tier then
        if tier.skill then
          table.insert(t.checks, 1, Check(cur >= tier.skill, string.format("%s skill %d (you: %d)", skillName, tier.skill, cur)))
        end
        if tier.level and tier.level > 0 then
          local lvl = UnitLevel("player") or 1
          table.insert(t.checks, 2, Check(lvl >= tier.level, string.format("Level %d (you: %d)", tier.level, lvl)))
        end
      end
      if #t.places == 0 and not st.quest and not st.book then t.places = Nearest(Trainers(skillName, RankOfCap(st.trainCap))) end
    end
    -- a tip with nothing to check and nobody to visit stays a note in the list - no stop
    if #conds == 0 and #t.places == 0 then return Finish(nil) end
    -- nothing the game can check: you're past it once your skill has moved beyond the step
    if #conds == 0 and st.to and st.to > (st.from or 0) and cur >= st.to then table.insert(conds, true) end
  end

  t.auto = #conds > 0
  t.done = t.auto
  for _, ok in ipairs(conds) do if not ok then t.done = false end end
  if not t.done and DoneTable(profName)[t.key] then t.done, t.manual = true, true end

  -- A rank you can't learn yet (skill below what it needs) doesn't hold up the route: whatever
  -- is to be done now (buy the book, the cheese, the recipes) stops it as its own task; then it
  -- waits, and the route stops on it again the moment your skill reaches `need`.
  if not t.done and need and cur < need and not trained then
    local prepDone = true
    for _, ok in ipairs(prep) do if not ok then prepDone = false end end
    local wait = string.format("At %s %d the route stops here again to %s.", skillName, need,
      st.book and "read the book" or (st.quest and "do the quest" or "train the rank"))
    -- (only a book is bought ahead; a quest's items come once you have the quest)
    if prepDone or not st.book or DoneTable(profName)[t.key .. ":prep"] then
      t.waiting = need
      t.text = t.text .. "\n\n" .. wait
    else
      t.key = t.key .. ":prep"
      t.prep = true
      t.text = t.text .. "\n\nGet these now. " .. wait
    end
  end
  return Finish(t)
end

-- A "learn this recipe first" task for a craft step, or nil (learned, or can't tell yet).
function CR.RecipeTask(st, profName)
  local r = st.recipe
  if not r then return nil end
  local route = CR.Route(profName)
  local rprofName = (route and route.recipeProf) or profName
  if not (CR.professions[rprofName] and CR.professions[rprofName].recipes[r.spell]) then return nil end
  local learned = RecipeLearned(rprofName, r)
  if learned ~= false then return nil end
  local key = "recipe:" .. r.spell
  if DoneTable(profName)[key] then return nil end
  local cur = CR.GetSkill(rprofName)
  local t = { key = key, kind = "recipe", step = st, recipe = r, profName = profName, skillName = rprofName,
              title = "Learn " .. r.name, icon = CR.RecipeIcon(r), checks = {}, places = {} }
  table.insert(t.checks, Check(cur >= (r.learn or 1), string.format("%s skill %d (you: %d)", rprofName, r.learn or 1, cur)))
  local src = r.src or ""
  if src:find("Trainer") then
    t.text = "Learn it from a " .. rprofName .. " trainer."
    t.cost = TrainerCost(rprofName, r.spell)
    t.places = Nearest(Trainers(rprofName, RankFor(r.learn)))
  else
    t.text = (r.pattern and ("Get " .. r.pattern .. ". ") or "") .. CR.FactionText(src) .. "."
    t.places = Nearest(RecipeVendors(rprofName, r.spell))
    if #t.places == 0 then t.places = Nearest(NpcsInText(CR.FactionText(src))) end
  end
  table.insert(t.checks, Check(false, "Recipe learned"))
  t.auto = true
  return t
end

-- Where a recipe comes from, for the Destinations view: a line of text, the nearest places to get
-- it (map pins, from TrainerSpells), and the trainer's price if a trainer teaches it.
function CR.RecipeSource(profName, r)
  local src = r.src or ""
  if src:find("Trainer") then
    return "Taught by " .. profName .. " trainers", Nearest(Trainers(profName, RankFor(r.learn))),
      TrainerCost(profName, r.spell)
  end
  local places = Nearest(RecipeVendors(profName, r.spell))
  if #places == 0 then places = Nearest(NpcsInText(CR.FactionText(src))) end
  return (r.pattern and (r.pattern .. ": ") or "") .. CR.FactionText(src), places
end

-- The route as things to do, in order: open tasks (each as { task = ... }) and crafts (the step
-- itself). A craft whose recipe isn't learned yet is preceded by a "learn it" task. Finished
-- tasks drop out.
function CR.ActionSteps(entry, profName)
  local list = {}
  for _, st in ipairs(entry and entry.plan.steps or {}) do
    if (st.kind == "craft" or st.kind == "extra" or st.kind == "target") and st.recipe then
      local rt = CR.RecipeTask(st, profName)
      if rt then table.insert(list, { task = rt, kind = "task", from = st.from, planStep = st }) end
      table.insert(list, st)
    elseif st.kind == "train" or st.kind == "guide" then
      local t = CR.StepTask(st, profName)
      if t and not t.done and not t.waiting then table.insert(list, { task = t, kind = "task", from = st.from, planStep = st }) end
    end
  end
  return list
end

function CR.MarkTaskDone(task, done)
  DoneTable(task.profName)[task.key] = done and true or nil
  CR.InvalidatePlan()
  CR.NotifyChanged()
end

-- Forget manual ticks (/cr tasks reset).
function CR.ResetTasks(profName)
  wipe(DoneTable(profName))
  CR.InvalidatePlan()
  CR.NotifyChanged()
end
