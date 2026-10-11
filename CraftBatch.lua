-- Crafting progress for a batch started from CraftRoute (Create All, Create, a typed amount):
-- "Crafting Minor Mana Oil 3/50", counted from the game's cast events, so you can always see how
-- far through it you are - the cast bar itself only ever shows the one craft in progress.
-- Both the Craft tab and the profession-window view show it (CR.CraftBatchState).
local _, CR = ...

local batch   -- { spell, name, total, done, stopped, endedAt }
local listeners = {}

local function Fire() for _, fn in ipairs(listeners) do CR.SafeCall(fn) end end
function CR.OnCraftBatch(fn) table.insert(listeners, fn) end

-- Called just before CraftRecipe(spell, count).
function CR.StartCraftBatch(spell, name, total)
  batch = { spell = spell, name = name or "", total = math.max(1, total or 1), done = 0 }
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
    finished = batch.done >= batch.total, stopped = batch.stopped,
    frac = math.min(1, (batch.done + castFrac) / batch.total),
  }
end

-- "Crafting Minor Mana Oil  3/50" / "Made 50/50 Minor Mana Oil" / "Stopped at 12/50".
function CR.CraftBatchText(s)
  if s.finished then return string.format("Made %d/%d %s", s.done, s.total, s.name) end
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
        db.stepCrafts[prof][st.routeKey] = (db.stepCrafts[prof][st.routeKey] or 0) + 1
      end
      return
    end
  end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    pcall(ev.RegisterUnitEvent or ev.RegisterEvent, ev, e, "player")
  end
end
ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
  if unit ~= "player" then return end
  if event == "UNIT_SPELLCAST_SUCCEEDED" and spellID then CR.SafeCall(CR.CountStepCraft, spellID) end
  if not batch or batch.endedAt or spellID ~= batch.spell then return end
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    batch.done = batch.done + 1
    if batch.done >= batch.total then batch.endedAt = GetTime() end
  else
    -- interrupted (moved, stopped): the rest of the batch won't happen
    batch.stopped, batch.endedAt = true, GetTime()
  end
  Fire()
end)
