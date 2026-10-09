-- Non-crafting steps as tasks the route stops at: training a rank, a book or quest that replaces
-- the trainer, buying supplies, learning a recipe before crafting it, and leveling steps that
-- aren't crafts (fishing). Each says what to do, where (nearest NPCs, with a Blizzard map pin),
-- what it needs and costs, and ticks itself off when the game shows it's done - with a manual
-- "Mark as done" as the fallback.
-- NPC locations come from the TrainerSpells addon when it's installed (profession trainers and
-- recipe vendors), plus a few guide NPCs it doesn't list.
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
local function AddNpc(name, loc, faction)
  if type(name) ~= "string" or name == "" or type(loc) ~= "table" or not loc.uiMapID or not loc.x then return end
  local list = npcIndex[name]
  if not list then list = {}; npcIndex[name] = list end
  for _, p in ipairs(list) do
    if p.uiMapID == loc.uiMapID and math.abs(p.x - loc.x) < 0.5 and math.abs(p.y - loc.y) < 0.5 then return end
  end
  table.insert(list, { name = name, uiMapID = loc.uiMapID, x = loc.x, y = loc.y, faction = faction })
end

local function Index()
  if npcIndex then return npcIndex end
  npcIndex = {}
  for _, trainers in pairs(type(TrainerSpellsProfessionTrainers) == "table" and TrainerSpellsProfessionTrainers or {}) do
    for _, t in ipairs(trainers) do
      for _, loc in ipairs(t.locations or {}) do AddNpc(t.names and t.names.enUS, loc, t.faction) end
    end
  end
  for _, bySkill in pairs(type(TrainerSpellsBuiltin_ProfessionRecipe) == "table" and TrainerSpellsBuiltin_ProfessionRecipe or {}) do
    for _, entries in pairs(bySkill) do
      for _, data in pairs(entries) do
        if type(data) == "table" then
          for _, loc in ipairs(data.sourceLocations or {}) do AddNpc(loc.npcName, loc, loc.faction) end
        end
      end
    end
  end
  for name, locs in pairs(EXTRA_NPCS) do
    if not npcIndex[name] then for _, l in ipairs(locs) do AddNpc(name, l, l.faction) end end
  end
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
local function Nearest(places, max)
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
    if #trimmed >= (max or 3) then break end
  end
  return trimmed
end

-- Profession trainers who teach up to `rank` (1 Apprentice ... 4 Artisan) or beyond.
local function Trainers(profName, rank)
  local list = {}
  local trainers = type(TrainerSpellsProfessionTrainers) == "table" and TrainerSpellsProfessionTrainers[profName]
  for _, t in ipairs(trainers or {}) do
    if (t.rank or 1) >= (rank or 1) then
      for _, loc in ipairs(t.locations or {}) do
        table.insert(list, { name = t.names and t.names.enUS or "?", uiMapID = loc.uiMapID, x = loc.x, y = loc.y,
                             faction = t.faction })
      end
    end
  end
  return list
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

local function TrainerCost(profName, spell)
  local data = type(TrainerSpellsBuiltin_Profession) == "table" and TrainerSpellsBuiltin_Profession[profName]
  for _, bucket in pairs(data or {}) do
    local e = bucket[spell]
    if type(e) == "table" and e.cost then return e.cost end
  end
end

local function RecipeVendors(profName, spell)
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

-- Has this recipe been learned? nil when it can't be told (the profession was never opened).
local function RecipeLearned(profName, r)
  if CR.TradeSkillOpenFor and CR.TradeSkillOpenFor(profName) and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, r.spell)
    if ok and info and info.learned ~= nil then return info.learned end
  end
  local known = CR.ProfTable("known", profName)
  if not next(known) then return nil end
  return known[r.spell] and true or false
end

local function Check(ok, text) return { ok = ok and true or false, text = text } end

-- The task for a train / guide step, or nil.
function CR.StepTask(st, profName)
  if st.recipe or (st.kind ~= "train" and st.kind ~= "guide") then return nil end
  local skillName = st.skill or profName
  local cur, maxRank, learned = CR.GetSkill(skillName)
  local text = CR.FactionText(st.text or "")
  local t = { step = st, key = KeyOf(st), skillName = skillName, text = text, checks = {}, places = {},
              profName = profName }
  local conds = {}   -- what the game can confirm; all true = done
  local function Cond(ok, label) table.insert(conds, ok and true or false); table.insert(t.checks, Check(ok, label)) end

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
      if st.book then
        local _, bags = Owned(st.book)
        table.insert(t.checks, Check(bags > 0 or maxRank >= st.cap, "Bought " .. CR.ItemName(st.book)))
      end
      Cond(learned and maxRank >= st.cap, string.format("%s %s learned (max skill %d)", st.tierName or "", skillName, st.cap))
      if st.book or st.quest then
        t.places = Nearest(NpcsInText(text))
      else
        t.places = Nearest(Trainers(skillName, rank))
        if t.text == "" then t.text = "Learn " .. t.title .. " from a " .. skillName .. " trainer." end
      end
      if st.book then
        local price = CR.GetUnitPrice and CR.GetUnitPrice(st.book)
        if price then t.cost = price end
      end
    end
  else
    -- guide step
    t.kind = "guide"
    t.icon = (skillName == "Fishing") and "Interface\\Icons\\Trade_Fishing" or "Interface\\Icons\\INV_Misc_Note_01"
    t.title = FirstSentence(text)
    if st.learnStep then Cond(learned, skillName .. " learned") end
    if st.trainCap then
      Cond(learned and maxRank >= st.trainCap, string.format("%s trained to %d", skillName, st.trainCap))
      if st.book then
        local _, bags = Owned(st.book)
        table.insert(t.checks, Check(bags > 0 or maxRank >= st.trainCap, "Bought " .. CR.ItemName(st.book)))
      end
    end
    local cost = 0
    -- supplies count once they're on you (bags or equipped) - one in the bank or on an alt
    -- doesn't help at the anvil
    for _, it in ipairs(st.items or {}) do
      local total, have = Owned(it[1])
      local label = string.format("%d/%d %s in your bags", math.min(have, it[2]), it[2], CR.ItemName(it[1]))
      if have < it[2] and total > have then label = label .. CR.ColorText("  (more in your bank / on alts)", "ffd100") end
      Cond(have >= it[2], label)
      local price = CR.GetUnitPrice and CR.GetUnitPrice(it[1])
      if price and total < it[2] then cost = cost + price * (it[2] - total) end
    end
    if cost > 0 then t.cost = cost end
    -- leveling that isn't crafting (fishing): done at the skill
    -- (a training / learning step's range only says when it applies - it's done once trained)
    -- (the solo Fishing guide's tips and shopping steps sit beside a "fish here" step over the
    -- same range, so only the chosen spot is the fishing itself)
    local activity = not st.trainCap and not st.learnStep
      and ((st.yields and #st.yields > 0) or st.catches or st.chosen or st.ownSkill == "Fishing")
    if activity and st.to and st.to > (st.from or 0) then
      Cond(cur >= st.to, string.format("%s %d (you: %d)", skillName, st.to, cur))
      t.progress = { from = st.from or 0, to = st.to, cur = cur }
    elseif st.items and #st.items > 0 and not st.trainCap and not st.learnStep then
      t.kind = "buy"
    end
    t.places = Nearest(NpcsInText(text))
    -- sold by supply vendors who stand next to these trainers
    if st.nearTrainer then
      local list = {}
      for _, p in ipairs(t.places) do table.insert(list, p) end
      for _, prof in ipairs(st.nearTrainer) do
        for _, p in ipairs(Trainers(prof, 1)) do table.insert(list, p) end
      end
      t.places = Nearest(list)
      if #t.places > 0 then t.text = t.text .. "\n\nThe supply vendor stands next to the trainer." end
    end
    -- a rank learned from a trainer (combined guide): its requirements, and the trainers
    if st.trainCap then t.kind = st.book and "book" or (st.quest and "quest" or "train") end
    if st.trainCap and not st.book and not st.quest then
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
      if #t.places == 0 then t.places = Nearest(Trainers(skillName, RankOfCap(st.trainCap))) end
    end
    -- a tip with nothing to check and nobody to visit stays a note in the list - no stop
    if #conds == 0 and #t.places == 0 then return nil end
    -- nothing the game can check: you're past it once your skill has moved beyond the step
    if #conds == 0 and st.to and st.to > (st.from or 0) and cur >= st.to then table.insert(conds, true) end
  end

  t.auto = #conds > 0
  t.done = t.auto
  for _, ok in ipairs(conds) do if not ok then t.done = false end end
  if not t.done and DoneTable(profName)[t.key] then t.done, t.manual = true, true end
  return t
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
      if t and not t.done then table.insert(list, { task = t, kind = "task", from = st.from, planStep = st }) end
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
