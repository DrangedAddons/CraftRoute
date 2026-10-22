-- Exercises the profession-open path without the WoW client.
-- Run from the repo root: lua5.1 tools/test_open_path.lua
local fails = 0
local function eq(actual, expected, what)
  if actual ~= expected then
    fails = fails + 1
    io.stderr:write(string.format("FAIL %s: got %s, expected %s\n", what, tostring(actual), tostring(expected)))
  end
end

local function syntaxCheck()
  local n = 0
  local pipe = io.popen("find . -name '*.lua' -not -path './tools/sources/*' -not -path './.git/*'")
  for path in pipe:lines() do
    local ok = os.execute(string.format("luac5.1 -p %q", path))
    if ok ~= 0 then
      fails = fails + 1
      io.stderr:write("FAIL syntax " .. path .. "\n")
    end
    n = n + 1
  end
  pipe:close()
  eq(n > 40, true, "syntax-checked the addon lua files")
end

syntaxCheck()

local timers = {}
local now = 0
local frames = {}
local env = setmetatable({
  wipe = function(t) for k in pairs(t) do t[k] = nil end end,
  strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end,
  DEFAULT_CHAT_FRAME = { AddMessage = function() end },
  C_Timer = {
    After = function(delay, fn)
      timers[#timers + 1] = { at = now + delay, fn = fn }
    end,
  },
  SlashCmdList = {},
  CreateFrame = function()
    local f = {}
    function f:RegisterEvent() end
    function f:SetScript(name, fn) self[name] = fn end
    frames[#frames + 1] = f
    return f
  end,
}, { __index = _G })

local function pump(dt)
  now = now + (dt or 0)
  for _ = 1, 30 do
    local due, dueI
    for i, t in ipairs(timers) do
      if t.at <= now and (not due or t.at < due.at) then due, dueI = t, i end
    end
    if not due then return end
    table.remove(timers, dueI)
    due.fn()
  end
  error("timer pump did not settle")
end

local chunk = assert(loadfile("Core.lua"))
setfenv(chunk, env)
local CR = {}
chunk("CraftRoute", CR)

local recipeCalls = 0
local ready = true
local profName = "Leatherworking"
env.C_TradeSkillUI = {
  GetAllRecipeIDs = function()
    recipeCalls = recipeCalls + 1
    return { 1, 2 }
  end,
  GetRecipeInfo = function(id)
    return { learned = id == 1, numAvailable = 4 }
  end,
  GetBaseProfessionInfo = function()
    return { professionName = profName }
  end,
  IsTradeSkillReady = function() return ready end,
}
CR.TradeSkillOpenFor = function(name)
  return ready and name == (profName == "Smelting" and "Mining" or profName)
end

local planWipes = 0
CR.InvalidatePlan = function() planWipes = planWipes + 1 end
local bumps = 0
local origBump = CR.BumpLiveRecipes
CR.BumpLiveRecipes = function()
  bumps = bumps + 1
  origBump()
end
local refreshes = 0
CR.RefreshCompact = function() refreshes = refreshes + 1 end
CR.InvalidateLocations = function() end

CR.RegisterRecipes("Leatherworking", {
  [1] = { name = "Light Leather", item = 2318, reagents = { { 2934, 1 } } },
}, { [2318] = "Light Leather" })
CR.RegisterRecipes("Mining", {
  [2] = { name = "Smelt Copper", item = 2840, reagents = {} },
}, {})
CR.RegisterRecipes("Cooking", {
  [3] = { name = "Charred Wolf Meat", item = 2680, reagents = {} },
}, {})
CR.RegisterRecipes("Herbalism", {}, {})
CR.NO_WINDOW = { Herbalism = true, Fishing = true, Skinning = true }

env.CraftRouteCharDB = {
  profession = "Leatherworking",
  known = {}, manualSkill = {}, choices = {}, targets = {}, tasksDone = {}, routeMode = {},
  profPicked = true,
}
-- ProfTable indexes these. Empty tables are enough for the scan.
env.CraftRouteDB = {}

local infoCalls = 0
env.GetProfessions = function() return 11, 12, nil, nil, 15, nil end
env.GetProfessionInfo = function(index)
  infoCalls = infoCalls + 1
  if index == 11 then return "Herbalism", "i", 5, 75, 0, 0, 101 end
  if index == 12 then return "Leatherworking", "i", 40, 150, 0, 0, 202 end
  if index == 15 then return "Cooking", "i", 1, 75, 0, 0, 303 end
end

local ev = frames[1]
ev.OnEvent(ev, "PLAYER_LOGIN")
pump(0.25)
-- login notifies once; that is not the open path
planWipes = 0
bumps = 0
recipeCalls = 0
refreshes = 0
infoCalls = 0

eq(CR.skill.Leatherworking.skillLine, 202, "scan stores the skill line")
eq(CR.skill.Cooking.rank, 1, "scan stores cooking")
eq(CR.professionSlots[1].name, "Herbalism", "slot 1 stays the first primary")
eq(CR.professionSlots[5].name, "Cooking", "slot 5 stays cooking")
eq(CR.FallbackProfession(), 202, "fallback skips herbalism and uses the cached line")
eq(select(2, CR.FallbackProfession()), "Leatherworking", "fallback name")
eq(infoCalls, 0, "fallback does not walk GetProfessionInfo again")

-- Plain open: recipes already known, skill unchanged. One deferred walk, no plan wipe.
CR.ProfTable("known", "Leatherworking")[1] = true
ev.OnEvent(ev, "TRADE_SKILL_SHOW")
ev.OnEvent(ev, "TRADE_SKILL_LIST_UPDATE")
eq(recipeCalls, 0, "the show event does not walk recipes before the tab can paint")
pump(0)
eq(recipeCalls, 1, "two show events share one recipe walk")
eq(planWipes, 0, "an unchanged open does not wipe the plan")
eq(refreshes, 1, "the tab still refreshes so craft counts update")
eq(CR.LiveRecipeInfo("Leatherworking", 1).numAvailable, 4, "the walk filled the live map")
eq(recipeCalls, 1, "reading a recipe does not walk the list again")
pump(0.25)
eq(planWipes, 0, "no follow-up notify rebuilds the plan")
eq(bumps, 0, "the live map is not thrown away")

-- A newly learned recipe rebuilds the plan, and does not scan a second time.
CR.ProfTable("known", "Leatherworking")[1] = nil
recipeCalls = 0
refreshes = 0
ev.OnEvent(ev, "NEW_RECIPE_LEARNED")
pump(0)
eq(CR.ProfTable("known", "Leatherworking")[1], true, "the new recipe is saved")
eq(recipeCalls, 1, "learning walks once")
pump(0.25)
eq(planWipes, 1, "a new recipe rebuilds the plan")
eq(bumps, 0, "that rebuild keeps the live map")
eq(recipeCalls, 1, "the rebuild does not walk recipes again")

-- Skill-up is a plan rebuild. The stamp moves with SKILL_LINES_CHANGED, so the
-- recipe event that follows does not rebuild a second time.
planWipes = 0
bumps = 0
recipeCalls = 0
refreshes = 0
CR.skill.Leatherworking.rank = 41
ev.OnEvent(ev, "SKILL_LINES_CHANGED")
pump(0.25)
eq(planWipes, 1, "a skill-up rebuilds the plan once")
planWipes = 0
ev.OnEvent(ev, "TRADE_SKILL_UPDATE")
pump(0)
eq(planWipes, 0, "the recipe event after a skill-up does not schedule another rebuild")
eq(refreshes >= 1, true, "the tab still refreshes after the recipe event")
pump(0.25)
eq(planWipes, 0, "no second plan wipe follows")

-- Window not ready yet: retry, then one walk.
ready = false
recipeCalls = 0
refreshes = 0
CR.QueueOpenRecipeScan()
pump(0)
eq(recipeCalls, 0, "a not-ready window does not walk")
ready = true
pump(0.1)
eq(recipeCalls, 1, "the retry walks once the window is ready")

-- Smelting is Mining.
profName = "Smelting"
ready = true
local seen, changed = CR.ReadOpenRecipes()
eq(seen, "Mining", "smelting window records Mining")
eq(changed, false, "an unlearned smelt recipe does not count as newly known")
profName = "Leatherworking"

-- Dropdown-style notify: keep the plan unless a real change arrives in the same window.
planWipes = 0
bumps = 0
local sawSkip = false
CR.OnChange(function()
  sawSkip = CR._notifyOpts and CR._notifyOpts.skipCompact or false
end)
CR.NotifyChanged({ keepPlan = true, keepLive = true, keepLocations = true, skipCompact = true })
pump(0.25)
eq(planWipes, 0, "a fresh plan is kept")
eq(bumps, 0, "a fresh recipe map is kept")
eq(sawSkip, true, "the profession tab can skip its second redraw")

planWipes = 0
sawSkip = true
CR.NotifyChanged({ keepPlan = true, skipCompact = true })
CR.NotifyChanged()
pump(0.25)
eq(planWipes, 1, "a bag update in the same window still rebuilds the plan")
eq(sawSkip, false, "that bag update lets the profession tab redraw")

-- One reopen ladder. The second call replaces the first.
local hits = 0
CR.ScheduleUnique("compact-reopen", { 0, 0.1 }, function() hits = hits + 1 end)
CR.ScheduleUnique("compact-reopen", { 0, 0.1 }, function() hits = hits + 10 end)
pump(0.1)
eq(hits, 20, "only the latest reopen ladder runs")

-- The profession files parse. Compact builds its loader without a frame.
local function loadAddon(path)
  local c = assert(loadfile(path))
  setfenv(c, env)
  c("CraftRoute", CR)
end
local okCompact, errCompact = pcall(loadAddon, "Compact.lua")
if not okCompact then
  fails = fails + 1
  io.stderr:write("FAIL Compact.lua load: " .. tostring(errCompact) .. "\n")
end
local okKey, errKey = pcall(loadAddon, "Keybind.lua")
if not okKey then
  fails = fails + 1
  io.stderr:write("FAIL Keybind.lua load: " .. tostring(errKey) .. "\n")
else
  local scans = 0
  local origScan = CR.ScanSkills
  CR.ScanSkills = function()
    scans = scans + 1
    origScan()
  end
  env.GetTime = function() return now end
  env.InCombatLockdown = function() return false end
  env.HideUIPanel = function() end
  local shown = true
  env.ProfessionsFrame = { IsShown = function() return shown end, Hide = function() end }
  local noted = false
  CR.NoteCompactSession = function() noted = true end
  env.CraftRoute_KeybindPressed()
  eq(noted, true, "closing snapshots the compact session before the window lets go")
  eq(scans, 0, "closing does not rescan professions")

  shown = false
  noted = false
  local opened
  env.C_TradeSkillUI.OpenTradeSkill = function(line) opened = line end
  local before = infoCalls
  env.CraftRoute_KeybindPressed()
  eq(scans, 1, "opening scans professions once")
  eq(opened, 202, "opening uses the cached skill line")
  eq(infoCalls - before, 3, "opening does not walk the profession list a second time")
  eq(noted, false, "opening does not take the close snapshot")
end

if fails > 0 then
  io.stderr:write(fails .. " failed\n")
  os.exit(1)
end
print("open-path tests passed")
