-- Builds a leveling plan: which recipes to craft between the current skill and a goal,
-- plus target crafts the player picked, and the net materials all of that needs.
local _, CR = ...
local GetItemInfo, GetItemCount, GetItemIcon, IsEquippedItem = CR.GetItemInfo, CR.GetItemCount, CR.GetItemIcon, CR.IsEquippedItem

local ceil, floor, max, min = math.ceil, math.floor, math.max, math.min
-- Placeholder prices for ranking auto-filled recipes without AH data: common leveling mats are
-- assumed cheap, anything else (dragonscales, essences...) expensive so it isn't picked by accident.
local UNKNOWN_COMMON_PRICE = 2000
local UNKNOWN_RARE_PRICE = 50000

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function ItemName(prof, id)
  return (prof and prof.names[id]) and ((GetItemInfo(id)) or prof.names[id]) or CR.ItemName(id)
end
CR.ItemName = function(id)
  local name = GetItemInfo(id)
  if name then return name end
  for _, p in pairs(CR.professions) do
    if p.names[id] then return p.names[id] end
  end
  return CR.extraNames[id] or ("item:" .. id)
end

function CR.OwnedCount(itemID)
  if not itemID or itemID == 0 then return 0 end
  local n = GetItemCount(itemID, true) or 0
  if IsEquippedItem and IsEquippedItem(itemID) then n = n + 1 end
  return n
end

-- "orange" | "yellow" | "green" | "grey" | "red" (can't learn yet)
function CR.Difficulty(r, skill)
  if skill < (r.learn or 1) then return "red" end
  if skill < r.y then return "orange" end
  if skill < r.g then return "yellow" end
  if skill < r.x then return "green" end
  return "grey"
end

CR.DIFF_COLORS = {
  red = "ff4040", orange = "ff8040", yellow = "ffff00", green = "40bf40", grey = "808080",
}

-- Average crafts per skill point at this skill (classic formula: (grey - skill) / (grey - yellow)).
local function CraftsPerPoint(r, skill)
  if skill < r.y then return 1 end
  if skill >= r.x then return math.huge end
  return (r.x - r.y) / (r.x - skill)
end

-- The route in use for a profession (Cooking/Fishing have a solo and a combined route).
function CR.Route(profOrName)
  local prof = type(profOrName) == "table" and profOrName or CR.professions[profOrName]
  if not prof or not prof.routes then return nil end
  local mode = CraftRouteCharDB.routeMode and CraftRouteCharDB.routeMode[prof.name]
  return (mode and prof.routes[mode]) or prof.routes[prof.routeOrder[1]]
end

local function FactionOK(t)
  return not t.faction or t.faction == UnitFactionGroup("player")
end
CR.FactionOK = FactionOK

-- Choices are stored per route, so the combined guide shares picks between Cooking and Fishing.
local function RouteChoice(route, key)
  local chosen = CR.ProfTable("choices", route.id)[key]
  for _, c in ipairs(route.choices or {}) do
    if c.key == key then
      local first
      for _, o in ipairs(c.options) do
        if FactionOK(o) then
          if o.key == chosen then return chosen end
          first = first or o.key
        end
      end
      return first
    end
  end
  return chosen
end

local function StepActive(route, step)
  if not FactionOK(step) then return false end
  if not step.when then return true end
  for key, opt in pairs(step.when) do
    local picked = RouteChoice(route, key)
    if type(opt) == "table" then
      local hit = false
      for _, o in ipairs(opt) do if o == picked then hit = true end end
      if not hit then return false end
    elseif picked ~= opt then
      return false
    end
  end
  return true
end

-- The Mining smelting recipe that makes this bar, if this character has Mining and the skill for it.
function CR.Smelter(itemID)
  local mining = CR.professions.Mining
  local spell = mining and mining.byItem[itemID]
  if not spell then return nil end
  local skill, _, detected = CR.GetSkill("Mining")
  local r = mining.recipes[spell]
  if detected and skill >= (r.learn or 1) then return r end
end

-- Expected crafts to go from skill lo to hi with one recipe (stops when it turns grey).
-- Expected crafts (unrounded) over [lo, hi); points past grey count as one tough craft each.
local function CraftWeight(r, lo, hi)
  local n = 0
  for sk = lo, hi - 1 do
    n = n + min(CraftsPerPoint(r, sk), 4)
  end
  return n
end

local function EstimateCrafts(r, lo, hi)
  local n = 0
  for sk = lo, hi - 1 do
    if sk >= r.x then break end
    n = n + CraftsPerPoint(r, sk)
  end
  return math.max(1, ceil(n - 0.01))
end

-- A guide step's craft count scaled to the part you still have to do. Weighted by difficulty:
-- the last yellow points of a step take more crafts than its first orange ones.
local function ScaleCrafts(r, guideCrafts, from, to, lo, hi)
  local full = CraftWeight(r, from, to)
  if full <= 0 then return ceil(guideCrafts * (hi - lo) / (to - from) - 0.01) end
  return math.max(1, ceil(guideCrafts * CraftWeight(r, lo, hi) / full - 0.01))
end

-- Selected targets that aren't owned yet: { {recipe, qty, owned} }
function CR.ActiveTargets(profName)
  local prof = CR.professions[profName]
  local list = {}
  for spellID, qty in pairs(CR.ProfTable("targets", profName)) do
    local r = prof.recipes[spellID]
    if r then
      local owned = CR.OwnedCount(r.item)
      if owned < qty then
        table.insert(list, { recipe = r, qty = qty - owned, owned = owned })
      end
    end
  end
  table.sort(list, function(a, b)
    if a.recipe.learn ~= b.recipe.learn then return a.recipe.learn < b.recipe.learn end
    return a.recipe.name < b.recipe.name
  end)
  return list
end

---------------------------------------------------------------------------
-- Goal
---------------------------------------------------------------------------
-- Profession ranks (Apprentice, Journeyman, Expert, Artisan) for goal choices:
--   current     = the rank you have now (the first one if the profession isn't learned)
--   levelRank   = the highest rank your character level can learn
--   blocked     = the first rank your level can't learn yet (nil if none)
-- On the beta (level 30) Artisan's level 35 requirement blocks it; on live it opens normally.
function CR.RankInfo(profName)
  local route = CR.Route(profName)
  local ranks = route and route.tiers or {}
  local cur, maxRank = CR.GetSkill(profName)
  local info = { ranks = ranks }
  -- The rank whose cap is your max skill; if not learned, the rank your skill falls in.
  for _, t in ipairs(ranks) do
    if t.cap == maxRank then info.current = t end
  end
  if not info.current then
    for _, t in ipairs(ranks) do
      if t.cap > cur then info.current = t break end
    end
    info.current = info.current or ranks[#ranks]
  end
  local level = UnitLevel("player")
  for _, t in ipairs(ranks) do
    if (t.level or 0) <= level then
      info.levelRank = t
    elseif not info.blocked then
      info.blocked = t
    end
  end
  return info
end

function CR.ResolveGoal(profName, cur, maxRank)
  local prof = CR.professions[profName]
  local route = CR.Route(prof)
  local db = CraftRouteCharDB
  local mode = db.goalMode
  local goal, why
  local rinfo = CR.RankInfo(profName)
  if mode == "next" then
    for _, t in ipairs(CR.ActiveTargets(profName)) do
      if t.recipe.learn > cur then
        goal, why = t.recipe.learn, "next target: " .. t.recipe.name
        break
      end
    end
    if not goal then mode = "tier" end
  end
  local rankName = mode:match("^rank:(.+)$")
  if rankName then
    for _, t in ipairs(rinfo.ranks) do
      if t.name == rankName then goal, why = t.cap, rankName end
    end
    if not goal then mode = "tier" end
  end
  if mode == "tier" then
    local r = rinfo.current
    goal = r and r.cap or route.maxSkill
    why = r and ("your current rank, " .. r.name) or "max skill"
  elseif mode == "level" then
    local r = rinfo.levelRank
    goal = r and r.cap or route.maxSkill
    why = rinfo.blocked
      and string.format("%s needs level %d, you're %d", rinfo.blocked.name, rinfo.blocked.level, UnitLevel("player"))
      or "your level can learn every rank"
  elseif mode == "route" then
    goal, why = route.routeEnd, "end of guide route"
  elseif mode == "max" then
    goal, why = route.maxSkill, "max skill"
  elseif mode == "custom" then
    goal, why = tonumber(db.customGoal) or route.routeEnd, "custom"
  end
  goal = max(min(goal, route.maxSkill), cur)
  return goal, why
end

---------------------------------------------------------------------------
-- Auto-fill for skill ranges the guide doesn't cover (currently 225+)
---------------------------------------------------------------------------
local function MakeCostFn(prof)
  local cache = {}
  local function ItemCost(id, depth)
    if cache[id] then return cache[id] end
    local price = CR.GetUnitPrice(id)
    local route = CR.Route(prof)
    local common = route and route.commonMats and route.commonMats[id]
    if not price and common then price = UNKNOWN_COMMON_PRICE end
    if not price and depth < 2 and prof.byItem[id] then
      local r = prof.recipes[prof.byItem[id]]
      local c = 0
      for _, rg in ipairs(r.reagents) do c = c + rg[2] * ItemCost(rg[1], depth + 1) end
      price = c / r.makes
    end
    price = price or UNKNOWN_RARE_PRICE
    cache[id] = price
    return price
  end
  return function(r)
    local c = 0
    for _, rg in ipairs(r.reagents) do c = c + rg[2] * ItemCost(rg[1], 0) end
    return c
  end
end

local function AutoSteps(prof, from, to)
  local known = CR.ProfTable("known", prof.name)
  local cost = MakeCostFn(prof)
  local steps, cur = {}, nil
  for s = from, to - 1 do
    local best, bestCost, bestCrafts
    for spellID, r in pairs(prof.recipes) do
      -- Vendor patterns count only if a vendor of your faction (or a neutral one) sells them.
      local obtainable = r.src == "Trainer" or known[spellID]
        or (r.src:find("^Sold by") and CR.FactionText(r.src):find("^Sold by %S"))
      if r.item > 0 and obtainable and r.learn <= s and s < r.g then
        local cpp = CraftsPerPoint(r, s)
        local c = cost(r) * cpp
        if not bestCost or c < bestCost then best, bestCost, bestCrafts = r, c, cpp end
      end
    end
    if not best then break end
    if cur and cur.spell == best.spell then
      cur.to = s + 1
      cur.rawCrafts = cur.rawCrafts + bestCrafts
    else
      local how = (best.src == "Trainer" or known[best.spell]) and "" or (" - pattern " .. CR.FactionText(best.src):lower())
      cur = { from = s, to = s + 1, spell = best.spell, rawCrafts = bestCrafts, auto = true,
              note = "Auto-picked, not from the guide" .. how }
      table.insert(steps, cur)
    end
  end
  for _, st in ipairs(steps) do st.crafts = ceil(st.rawCrafts - 0.01) end
  return steps
end

---------------------------------------------------------------------------
-- Plan
---------------------------------------------------------------------------
-- Skill of any profession the route touches (the combined guide spans two).
local function SkillOf(name)
  local cur, maxRank, detected = CR.GetSkill(name)
  return cur, maxRank or 0, detected
end

-- Scales a route step to the part still ahead of the player. Returns nil if it's done.
-- Steps can be on another skill (combined guide), "train" steps stay until the tier is learned,
-- and "learnStep" steps only show while the profession isn't learned at all.
local function ClipStep(route, rprof, st, index, profName, cur, goal)
  local skillName = st.skill or profName
  if skillName ~= profName and not route.sequential then return nil end
  local scur, smax, detected = SkillOf(skillName)
  local c = skillName == profName and cur or scur
  if route.sequential then goal = route.maxSkill end
  if st.learnStep then
    if detected then return nil end
  elseif st.trainCap then
    if (detected and smax >= st.trainCap) or c >= st.to then return nil end
  elseif c >= st.to or (not route.sequential and st.from >= goal) then
    return nil
  end
  local lo, hi = max(st.from, c), min(st.to, goal)
  if st.trainCap or st.learnStep then lo, hi = st.from, st.to end
  local frac = (st.to > st.from) and (hi - lo) / (st.to - st.from) or 1
  local out = { kind = st.kind or "craft", from = lo, to = hi, skill = skillName, catches = st.catches,
                note = st.note and CR.FactionText(st.note), text = st.text and CR.FactionText(st.text),
                fork = st.when ~= nil, index = index,
                stepFrom = st.from, stepTo = st.to,   -- the guide's full range, for progress bars
                -- A band's general instruction goes above its "pick one" block (forks sort at lo - 0.6).
                sort = route.sequential and index or ((st.kind == "guide" and not st.when) and lo - 0.8 or lo),
                train = (st.trainCap or st.learnStep) and true or nil,
                -- for the task cards (Tasks.lua)
                trainCap = st.trainCap, learnStep = st.learnStep, book = st.book, quest = st.quest,
                chosen = st.when ~= nil, ownSkill = st.skill, nearTrainer = st.nearTrainer, recipes = st.recipes, has = st.has, learns = st.learns, books = st.books }
  if out.kind == "craft" then
    local r = rprof.recipes[st.spell]
    if not r then return nil end
    out.spell = st.spell
    if st.crafts then
      out.crafts = (lo == st.from and hi == st.to) and st.crafts
        or ScaleCrafts(r, st.crafts, st.from, st.to, lo, hi)
    else
      out.crafts, out.estimated = EstimateCrafts(r, lo, hi), true
    end
  else
    local scale = out.train and 1 or frac
    out.items, out.yields = {}, {}
    for _, it in ipairs(st.items or {}) do table.insert(out.items, { it[1], ceil(it[2] * scale - 0.01) }) end
    for _, it in ipairs(st.yields or {}) do table.insert(out.yields, { it[1], floor(it[2] * scale) }) end
  end
  return out
end

-- Collect the route steps still ahead (clipped to the goal unless the route is followed in
-- order), scaled for partial progress, plus auto-fill for gaps in single-skill crafting routes.
local function CollectSteps(route, rprof, profName, cur, goal)
  local out, covered = {}, {}
  for i, st in ipairs(route.steps) do
    if StepActive(route, st) then
      local e = ClipStep(route, rprof, st, i, profName, cur, goal)
      if e then
        table.insert(out, e)
        if not e.train then table.insert(covered, { e.from, e.to }) end
      end
    end
  end
  if route.sequential or route.noAutoFill then return out end
  -- Find uncovered ranges and auto-fill them.
  table.sort(covered, function(a, b) return a[1] < b[1] end)
  local pos = cur
  local gaps = {}
  for _, c in ipairs(covered) do
    if c[1] > pos then table.insert(gaps, { pos, c[1] }) end
    pos = max(pos, c[2])
  end
  if goal > pos then table.insert(gaps, { pos, goal }) end
  for _, g in ipairs(gaps) do
    for _, st in ipairs(AutoSteps(rprof, g[1], g[2])) do
      st.kind, st.sort, st.skill = "craft", st.from, profName
      table.insert(out, st)
    end
  end
  return out
end

local function OptionMatches(w, key)
  if type(w) == "table" then
    for _, k in ipairs(w) do if k == key then return true end end
    return false
  end
  return w == key
end

-- Where the guide offers alternatives ("do A or B"), returns a header row plus one row per
-- option with a short material summary. Only the picked option's steps go into the plan.
local function ForkEvents(route, rprof, profName, cur, goal)
  local out = {}
  for _, c in ipairs(route.choices or {}) do
    -- The fork shows while any of its steps is still ahead.
    local lo, hi, firstIndex, skillName
    for i, st in ipairs(route.steps) do
      if st.when and st.when[c.key] and FactionOK(st) then
        local e = ClipStep(route, rprof, st, i, profName, cur, goal)
        if e then
          lo, hi = min(lo or e.from, e.from), max(hi or e.to, e.to)
          firstIndex = firstIndex or i
          skillName = skillName or e.skill
        end
      end
    end
    -- Once you're past the part where the options differ (e.g. both leatherworking 1-45 paths end
    -- in Light Armor Kits from 30), the choice no longer matters - don't show it.
    if lo then
      local sigs, distinct = {}, 0
      for _, o in ipairs(c.options) do
        if FactionOK(o) then
          local parts = {}
          for i, st in ipairs(route.steps) do
            if st.when and OptionMatches(st.when[c.key], o.key) and FactionOK(st)
                and ClipStep(route, rprof, st, i, profName, cur, goal) then
              table.insert(parts, st.spell and ("s" .. st.spell) or ("g" .. tostring(st.text)))
            end
          end
          local sig = table.concat(parts, ",")
          if not sigs[sig] then sigs[sig] = true; distinct = distinct + 1 end
        end
      end
      if distinct < 2 then lo = nil end
    end
    if lo then
      local picked = RouteChoice(route, c.key)
      local base = route.sequential and (firstIndex - 0.5) or (lo - 0.6)
      table.insert(out, { kind = "fork", from = lo, to = hi, sort = base, text = CR.FactionText(c.label),
                          skill = skillName })
      local n = 0
      for _, o in ipairs(c.options) do
        if FactionOK(o) then
          n = n + 1
          -- Net materials for this option; items it makes for itself cancel out.
          -- crafts: what this option has you make (shown as the option itself, in route order)
          local net, cost, unpriced, catch, crafts = {}, 0, false, {}, {}
          for i, st in ipairs(route.steps) do
            if st.when and OptionMatches(st.when[c.key], o.key) and FactionOK(st) then
              local e = ClipStep(route, rprof, st, i, profName, cur, goal)
              if e and e.kind == "craft" then
                local r = rprof.recipes[e.spell]
                table.insert(crafts, { recipe = r, n = e.crafts, estimated = e.estimated })
                for _, rg in ipairs(r.reagents) do net[rg[1]] = (net[rg[1]] or 0) + rg[2] * e.crafts end
                if r.item > 0 then net[r.item] = (net[r.item] or 0) - e.crafts * r.makes end
              elseif e then
                for _, it in ipairs(e.items) do net[it[1]] = (net[it[1]] or 0) + it[2] end
                for _, it in ipairs(e.yields) do table.insert(catch, { id = it[1], n = it[2] }) end
                for _, id in ipairs(st.catches or {}) do table.insert(catch, { id = id }) end
              end
            end
          end
          local mats = {}
          for id, cnt in pairs(net) do
            if cnt > 0 then
              table.insert(mats, { id = id, n = cnt })
              local price = CR.GetUnitPrice(id)
              if price then cost = cost + price * cnt else unpriced = true end
            end
          end
          table.sort(mats, function(a, b) return a.n > b.n end)
          table.insert(out, { kind = "option", from = lo, to = hi, sort = base + n * 0.01, skill = skillName,
            choice = c.key, option = o.key, label = CR.FactionText(o.label), letter = string.char(64 + n),
            routeID = route.id, selected = picked == o.key, mats = mats, cost = cost, unpriced = unpriced,
            catch = catch, crafts = crafts })
        end
      end
    end
  end
  return out
end

function CR.BuildPlan(profName, cur, goal)
  local route = CR.Route(profName)
  -- The combined guide's recipes are Cooking recipes even when Fishing is selected.
  local prof = CR.professions[route.recipeProf or profName]
  local _, maxRank, detected = CR.GetSkill(profName)
  local plan = {
    prof = profName, route = route, from = cur, goal = goal, steps = {}, materials = {}, byId = {},
    beyond = {}, totalCost = 0, missingCost = 0, unpriced = 0,
  }

  local events = {}
  for _, st in ipairs(CollectSteps(route, prof, profName, cur, goal)) do table.insert(events, st) end
  for _, e in ipairs(ForkEvents(route, prof, profName, cur, goal)) do table.insert(events, e) end

  local targets = route.sequential and {} or CR.ActiveTargets(prof.name)
  for _, t in ipairs(targets) do
    local r = t.recipe
    if r.learn <= goal then
      local at = max(r.learn, cur)
      table.insert(events, { kind = "target", from = at, to = at, spell = r.spell, crafts = t.qty, sort = at + 0.1 })
    else
      table.insert(plan.beyond, t)
    end
  end

  -- Trainer milestones (routes followed in order spell these out as their own steps)
  local tiers = route.sequential and {} or (route.tiers or {})
  if not detected and not route.sequential then
    table.insert(events, { kind = "train", from = 0, sort = -1, text = "Learn Apprentice " .. profName, ok = true,
                           apprentice = true, rankIndex = 1 })
  end
  for i = 2, #tiers do
    local tier, prev = tiers[i], tiers[i - 1]
    if goal > prev.cap and (maxRank or 0) < tier.cap then
      local lvlOK = UnitLevel("player") >= tier.level
      local text = CR.FactionText(tier.text or string.format("Train %s %s (skill %d, level %d)%s", tier.name,
        profName, tier.skill, tier.level, tier.where and (" - " .. tier.where) or ""))
      -- Listed where you can first train it (before any "do one of these" block at that skill).
      local at = max(tier.skill, cur)
      -- rank details for the task card (Tasks.lua): what it needs, and when it's done
      table.insert(events, { kind = "train", from = at, sort = at - 0.7, text = text, ok = lvlOK,
                             items = tier.items, skill = profName, rankIndex = i, cap = tier.cap,
                             tierName = tier.name, need = tier.skill, level = tier.level,
                             book = tier.book, quest = tier.quest, has = tier.has, recipes = tier.recipes })
    end
  end

  table.sort(events, function(a, b)
    if a.sort ~= b.sort then return a.sort < b.sort end
    -- Instructions ("buy a hammer first") before crafts starting at the same skill.
    if (a.kind == "guide") ~= (b.kind == "guide") then return a.kind == "guide" end
    if (a.to or 0) ~= (b.to or 0) then return (a.to or 0) < (b.to or 0) end
    return (a.index or 0) < (b.index or 0)
  end)

  -- Simulate: route-made intermediates feed later steps; shortfalls of craftable
  -- intermediates (cured hides, belts...) become extra crafts; everything else is a material.
  local pool, bagsLeft, need, crafted, usage, made = {}, {}, {}, {}, {}, {}
  local Consume

  local function Bags(id)
    if bagsLeft[id] == nil then bagsLeft[id] = CR.HaveCount(id) end
    return bagsLeft[id]
  end

  local function AddUsage(id, label, n, skillAt)
    usage[id] = usage[id] or {}
    table.insert(usage[id], { label = label, n = n, at = skillAt })
  end

  local function Craft(r, crafts, label, skillAt, depth)
    for _, rg in ipairs(r.reagents) do
      Consume(rg[1], rg[2] * crafts, label, skillAt, depth)
    end
    if r.item > 0 then
      pool[r.item] = (pool[r.item] or 0) + crafts * r.makes
      made[r.item] = (made[r.item] or 0) + crafts * r.makes
    end
  end

  -- Smelting: with Mining learned, bars you're short of can come from ore you already have
  -- (counted in the materials only - smelting isn't added to the route).
  -- How many of `recipe` can be made from what's in bags/bank (and smeltable from ore)?
  local function Smeltable(recipe, depth)
    local n = math.huge
    for _, rg in ipairs(recipe.reagents) do
      local avail = Bags(rg[1])
      local sub = depth < 3 and CR.Smelter(rg[1])
      if sub then avail = avail + Smeltable(sub, depth + 1) * sub.makes end
      n = min(n, floor(avail / rg[2]))
    end
    return n == math.huge and 0 or n
  end

  Consume = function(id, qty, label, skillAt, depth)
    local fromPool = min(pool[id] or 0, qty)
    pool[id] = (pool[id] or 0) - fromPool
    qty = qty - fromPool
    if qty <= 0 then return end
    AddUsage(id, label, qty, skillAt)
    need[id] = (need[id] or 0) + qty
    local producer = prof.byItem[id] and prof.recipes[prof.byItem[id]]
    local smelter = not producer and depth < 3 and CR.Smelter(id)
    if producer and not (route.noExpand and route.noExpand[id]) and depth < 3 and producer.learn <= max(skillAt, cur) then
      local fromBags = min(Bags(id), qty)
      bagsLeft[id] = bagsLeft[id] - fromBags
      local short = qty - fromBags
      if short > 0 then
        local n = ceil(short / producer.makes)
        crafted[id] = (crafted[id] or 0) + short
        table.insert(plan.steps, { kind = "extra", from = skillAt, spell = producer.spell, crafts = n,
                                   recipe = producer, text = "for " .. label })
        Craft(producer, n, "Extra " .. producer.name .. " (" .. label .. ")", skillAt, depth + 1)
        pool[id] = pool[id] - short -- Craft() added n*makes; any rounding leftover stays pooled
      end
    elseif smelter then
      -- Use the bars you have, then smelt only as many as your ore covers; the rest is bought.
      local fromBags = min(Bags(id), qty)
      bagsLeft[id] = bagsLeft[id] - fromBags
      local short = qty - fromBags
      local n = short > 0 and min(ceil(short / smelter.makes), Smeltable(smelter, depth)) or 0
      if n > 0 then
        local got = min(short, n * smelter.makes)
        crafted[id] = (crafted[id] or 0) + got
        -- Not a route step: the guide doesn't send you smelting, it just needs the bars. The ore
        -- still counts towards them in the materials, and the Craft tab offers "Smelt" on the
        -- bar itself when you're short.
        local smeltLabel = smelter.name .. " (" .. label .. ")"
        for _, rg in ipairs(smelter.reagents) do
          local amount = rg[2] * n
          Consume(rg[1], amount, smeltLabel, skillAt, depth + 1)
          -- Raw ore isn't drawn from bags by Consume; reserve it so later steps can't reuse it.
          if not CR.Smelter(rg[1]) then bagsLeft[rg[1]] = Bags(rg[1]) - min(Bags(rg[1]), amount) end
        end
        pool[id] = (pool[id] or 0) + (n * smelter.makes - got)
      end
    end
  end

  -- Extra intermediate crafts get listed before the step that needs them.
  for _, e in ipairs(events) do
    if e.kind == "craft" or e.kind == "target" then
      local r = prof.recipes[e.spell]
      e.recipe = r
      local label
      if e.kind == "craft" then
        label = string.format("%s %d-%d (%s)", e.skill or profName, e.from, e.to, r.name)
      else
        label = "Target: " .. r.name
      end
      Craft(r, e.crafts, label, e.from, 0)
    elseif e.kind == "guide" or e.kind == "train" then
      local label = e.train and ((e.skill or profName) .. " training")
        or string.format("%s %d-%d", e.skill or profName, e.from or 0, e.to or 0)
      for _, it in ipairs(e.items or {}) do Consume(it[1], it[2], label, e.from or 0, 3) end
      for _, it in ipairs(e.yields or {}) do
        pool[it[1]] = (pool[it[1]] or 0) + it[2]
        made[it[1]] = (made[it[1]] or 0) + it[2]
      end
    end
    table.insert(plan.steps, e)
  end
  plan.made = made

  -- Gathering steps: say which later crafts need what you catch there ("Catches Raw Trout
  -- for Cook 175-225"), so you know which spot gives the fish the next cooking step uses.
  for i, e in ipairs(plan.steps) do
    if e.kind == "guide" and ((e.yields and #e.yields > 0) or e.catches) then
      local ids = {}
      for _, it in ipairs(e.yields or {}) do ids[it[1]] = true end
      for _, id in ipairs(e.catches or {}) do ids[id] = true end
      local uses, seen = {}, {}
      for j = i + 1, #plan.steps do
        local c = plan.steps[j]
        if c.kind == "craft" and c.recipe then
          for _, rg in ipairs(c.recipe.reagents) do
            local txt = ids[rg[1]] and string.format("%s for %s %d-%d", ItemName(prof, rg[1]),
              c.skill or profName, c.from, c.to)
            if txt and not seen[txt] then
              seen[txt] = true
              table.insert(uses, txt)
            end
          end
        end
      end
      if #uses > 0 then e.catchInfo = "Catches " .. table.concat(uses, "; ") .. "." end
    end
  end

  -- Materials
  for id, n in pairs(need) do
    local have = CR.HaveCount(id)
    local m = { id = id, name = ItemName(prof, id), need = n, have = have, crafted = crafted[id] or 0, usage = usage[id] }
    m.missing = max(0, n - have - m.crafted)
    if m.crafted == 0 then
      m.price, m.priceSrc = CR.GetUnitPrice(id)
      if m.price then
        m.totalCost = m.price * n
        m.missingCost = m.price * m.missing
        plan.totalCost = plan.totalCost + m.totalCost
        plan.missingCost = plan.missingCost + m.missingCost
      elseif m.missing > 0 then
        plan.unpriced = plan.unpriced + 1
      end
    end
    table.insert(plan.materials, m)
    plan.byId[id] = m
  end
  table.sort(plan.materials, function(a, b)
    if (a.crafted > 0) ~= (b.crafted > 0) then return a.crafted == 0 end
    return a.name < b.name
  end)
  return plan
end

---------------------------------------------------------------------------
-- Cached plans for UI + tooltips
---------------------------------------------------------------------------
local cache = {}
function CR.InvalidatePlan() wipe(cache) end

function CR.GetPlans(profName)
  profName = profName or CraftRouteCharDB.profession
  if cache[profName] then return cache[profName] end
  local route = CR.Route(profName)
  if not route then return nil end
  local cur, maxRank = CR.GetSkill(profName)
  local goal, why
  if route.sequential then
    goal, why = route.maxSkill, "full guide"
  else
    goal, why = CR.ResolveGoal(profName, cur, maxRank)
  end
  local entry = {
    cur = cur, maxRank = maxRank, goal = goal, why = why, route = route,
    plan = CR.BuildPlan(profName, cur, goal),
  }
  if goal < route.maxSkill then
    entry.full = CR.BuildPlan(profName, cur, route.maxSkill)
  else
    entry.full = entry.plan
  end
  cache[profName] = entry
  return entry
end
