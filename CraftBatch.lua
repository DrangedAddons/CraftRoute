-- Crafting progress for a batch started from CraftRoute (Create All, Create, a typed amount):
-- "Crafting Minor Mana Oil 3/50", counted from the game's cast events, so you can always see how
-- far through it you are - the cast bar itself only ever shows the one craft in progress.
-- Both the Craft tab and the profession-window view show it (CR.CraftBatchState).
local _, CR = ...

local batch   -- { spell, name, total, done, stopped, endedAt }
local listeners = {}

local function Fire() for _, fn in ipairs(listeners) do CR.SafeCall(fn) end end
function CR.OnCraftBatch(fn) table.insert(listeners, fn) end

-- The route step a batch is for: the first step of the plan crafting this recipe.
local function StepFor(spell)
  local prof = CraftRouteCharDB and CraftRouteCharDB.profession
  local entry = prof and CR.GetPlans and CR.GetPlans(prof)
  for _, st in ipairs(entry and entry.plan.steps or {}) do
    if st.spell == spell and st.recipe then return st, prof end
  end
end

-- Called just before CraftRecipe(spell, count).
function CR.StartCraftBatch(spell, name, total)
  batch = { spell = spell, name = name or "", total = math.max(1, total or 1), done = 0 }
  local st = StepFor(spell)
  if st then batch.routeKey, batch.stepKind = st.routeKey, st.kind end
  Fire()
end

-- Stop a running batch once its step's done (skill reached, the step's count made): the estimate
-- of crafts left can be on the high side, and over-crafting wastes materials. Checked after each
-- skill-up and craft; the plan is rebuilt first, so "done" means the step has left the route.
-- The batch's step as the route has it now (nil once it's done).
local function OpenStep()
  if CR.InvalidatePlan then CR.InvalidatePlan() end
  local prof = CraftRouteCharDB and CraftRouteCharDB.profession
  local entry = prof and CR.GetPlans and CR.GetPlans(prof)
  for _, st in ipairs(entry and entry.plan.steps or {}) do
    if st.spell == batch.spell and st.recipe then
      -- the same step - or it's become "finish this step" (its items are kept for later steps)
      if batch.routeKey == nil or st.routeKey == batch.routeKey or st.finish then return st, prof end
    end
  end
end
local function StepStillOpen() return OpenStep() ~= nil end

-- A craft is starting: could it be the step's last? Then end the queue now - the game starts the
-- next craft the moment one finishes, before the skill-up arrives, so stopping after the last
-- one would be one craft too late. Count-based: exactly the last one. Level-based, one point to
-- go: if this one gives the point the step's done with nothing wasted; if not, you press Create
-- again (never an extra craft).
local function CheckLastCraft()
  if not batch or batch.endedAt or batch.lastCraft or not batch.stepKind then return end
  if batch.done + 1 >= batch.total then return end   -- the batch ends after this one anyway
  local st, prof = OpenStep()
  if not st then return end
  local cur = CR.GetSkill(st.skill or prof)
  local byCount = st.finish or st.keepNeed
  local last = (st.crafts or 99) <= 1
    or (not byCount and cur >= (st.stepTo or st.to or 0) - 1)
  if not last then return end
  local TS = C_TradeSkillUI
  if TS and TS.StopRecipeRepeat then pcall(TS.StopRecipeRepeat) end
  batch.lastCraft = true
  Fire()
end

local function CheckStepDone()
  if not batch or batch.endedAt or not batch.stepKind or batch.done >= batch.total then return end
  if StepStillOpen() then return end
  local TS = C_TradeSkillUI
  if TS and TS.StopRecipeRepeat then pcall(TS.StopRecipeRepeat) end
  batch.stopped, batch.stepDone, batch.endedAt = true, true, GetTime()
  CR.Print(string.format("Step done - stopped crafting %s at %d/%d so nothing's wasted.", batch.name, batch.done, batch.total))
  Fire()
end

-- For the bars: nil when there's nothing to show, else
-- { name, done, total, current (the one being made, 1-based), finished, stopped, frac (0-1 overall) }.
-- A finished or stopped batch stays up for a few seconds.
function CR.CraftBatchState()
  if not batch then return nil end
  if batch.endedAt and GetTime() - batch.endedAt > 6 then return nil end
  local castFrac = 0
  local _, _, _, startMS, endMS, isTradeSkill, _, _, castSpell = UnitCastingInfo("player")
  if not batch.endedAt and isTradeSkill and startMS and endMS and endMS > startMS
      and (castSpell == nil or castSpell == batch.spell) then
    castFrac = math.max(0, math.min(1, (GetTime() * 1000 - startMS) / (endMS - startMS)))
  end
  return {
    name = batch.name, done = batch.done, total = batch.total,
    current = math.min(batch.done + 1, batch.total),
    finished = batch.done >= batch.total, stopped = batch.stopped, stepDone = batch.stepDone, shortOne = batch.shortOne,
    frac = math.min(1, (batch.done + castFrac) / batch.total),
  }
end

-- Is a batch of this recipe running (not finished or stopped)?
function CR.CraftBatchRunning(spell)
  return batch and not batch.endedAt and batch.spell == spell or false
end

-- "Crafting Minor Mana Oil  3/50" / "Made 50/50 Minor Mana Oil" / "Stopped at 12/50".
function CR.CraftBatchText(s)
  if s.finished then return string.format("Made %d/%d %s", s.done, s.total, s.name) end
  if s.shortOne then return string.format("No skill point that time - press Create to carry on (%d/%d)", s.done, s.total) end
  if s.stepDone then return string.format("Step done - stopped at %d/%d %s", s.done, s.total, s.name) end
  if s.stopped then return string.format("Stopped at %d/%d %s", s.done, s.total, s.name) end
  return string.format("Crafting %s  %d/%d", s.name, s.current, s.total)
end

-- A craft of the current guide step's recipe, made while you're in that step's range (from any
-- window): counted for the step, so its count goes down by one per craft (Planner.lua).
function CR.CountStepCraft(spellID)
  local db = CraftRouteCharDB
  local prof = db and db.profession
  local entry = prof and CR.GetPlans and CR.GetPlans(prof)
  for _, st in ipairs(entry and entry.plan.steps or {}) do
    if st.routeKey and st.spell == spellID and not st.finish then
      local cur = CR.GetSkill(st.skill or prof)
      if cur >= (st.stepFrom or st.from or 0) and cur < (st.stepTo or st.to or 0) then
        db.stepCrafts = db.stepCrafts or {}
        db.stepCrafts[prof] = db.stepCrafts[prof] or {}
        -- the first craft counted: start from where your skill says you are in the step
        local base = db.stepCrafts[prof][st.routeKey]
          or math.max(0, (st.guideCrafts or 0) - (st.crafts or 0))
        db.stepCrafts[prof][st.routeKey] = base + 1
      end
      return
    end
  end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
                     "SKILL_LINES_CHANGED" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    if e == "SKILL_LINES_CHANGED" then pcall(ev.RegisterEvent, ev, e) else pcall(ev.RegisterUnitEvent or ev.RegisterEvent, ev, e, "player") end
  end
end
ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
  if event == "SKILL_LINES_CHANGED" then
    -- after the skill scan (Core) has run: is the batch's step done now?
    if batch and not batch.endedAt then C_Timer.After(0.1, function() CR.SafeCall(CheckStepDone) end) end
    return
  end
  if unit ~= "player" then return end
  if event == "UNIT_SPELLCAST_START" then
    if batch and spellID == batch.spell then CR.SafeCall(CheckLastCraft) end
    return
  end
  if event == "UNIT_SPELLCAST_SUCCEEDED" and spellID then CR.SafeCall(CR.CountStepCraft, spellID) end
  if not batch or batch.endedAt or spellID ~= batch.spell then return end
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    batch.done = batch.done + 1
    if batch.done >= batch.total then batch.endedAt = GetTime() end
    if batch.lastCraft and not batch.endedAt then
      -- the queue was ended before this craft: done, or (no skill point that time) one more click
      C_Timer.After(0.3, function()
        if not batch or batch.endedAt then return end
        batch.stopped, batch.endedAt = true, GetTime()
        if StepStillOpen() then
          batch.shortOne = true
          CR.Print(string.format("No skill point on that %s - press Create to carry on.", batch.name))
        else
          batch.stepDone = true
          CR.Print(string.format("Step done - stopped crafting %s at %d/%d so nothing's wasted.", batch.name, batch.done, batch.total))
        end
        Fire()
      end)
      return
    end
    C_Timer.After(0.3, function() CR.SafeCall(CheckStepDone) end)   -- a count-made step ends here
  else
    -- interrupted (moved, stopped): the rest of the batch won't happen
    batch.stopped, batch.endedAt = true, GetTime()
  end
  Fire()
end)
