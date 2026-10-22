local ADDON, CR = ...
_G.CraftRoute = CR

CR.professions = {}   -- [profName] = { recipes, names, byItem, routes }
CR.callbacks = {}
CR.extraNames = {}    -- fallback names for items that aren't recipe reagents (lures, quest items)
CR.itemNames = {}     -- itemID -> name, filled as recipe files register (one lookup, no GetItemInfo)

-- The Forever client uses the retail-style C_Item API; the old globals may not exist.
local C_Item = C_Item or {}
CR.GetItemInfo = C_Item.GetItemInfo or GetItemInfo
CR.GetItemCount = C_Item.GetItemCount or GetItemCount
CR.GetItemIcon = C_Item.GetItemIconByID or GetItemIcon
CR.IsEquippedItem = C_Item.IsEquippedItem or IsEquippedItem or function() return false end

-- Route text can carry faction-only parts: "{H:Horde text}" and "{A:Alliance text}".
-- The other faction's parts are removed, so players only see what applies to them.
-- The same source line is cleaned on every plan rebuild; keep the result for the session.
local factionTextCache = {}
function CR.FactionText(s)
  if not s or not s:find("{", 1, true) then return s end
  local mine = UnitFactionGroup("player") == "Alliance" and "A" or "H"
  local cacheKey = mine .. "\0" .. s
  local hit = factionTextCache[cacheKey]
  if hit ~= nil then return hit end
  local out = s:gsub("{([HA]):([^}]*)}", function(f, text) return f == mine and text or "" end)
  -- Tidy separators left behind by removed parts ("A, , B" / "by , B" / "B, ").
  local prev
  repeat
    prev = out
    out = out:gsub(",%s*,", ","):gsub("by%s*,%s*", "by "):gsub(",%s*/", " /"):gsub(",%s*$", "")
  until out == prev
  out = out:gsub("  +", " "):gsub(" %.", "."):gsub("^ ", "")
  factionTextCache[cacheKey] = out
  return out
end

-- Runs fn, printing any error to chat (script errors are hidden by default).
-- Runs fn; an error is printed to chat and also handed to the game's error handler (the
-- scriptErrors window / BugSack), with its stack, instead of being swallowed.
function CR.SafeCall(fn, ...)
  local args, n = { ... }, select("#", ...)
  local ok, err = xpcall(function() return fn(unpack(args, 1, n)) end, function(e)
    return tostring(e) .. (debugstack and ("\n" .. debugstack(2)) or "")
  end)
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4040CraftRoute error:|r " .. tostring(err):match("^[^\n]*"))
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(err) end
  end
  return ok
end

local function GetProf(name)
  local p = CR.professions[name]
  if not p then
    p = { name = name, recipes = {}, names = {}, byItem = {} }
    CR.professions[name] = p
  end
  return p
end

-- Called by Data/<Prof>Recipes.lua
function CR.RegisterRecipes(profName, recipes, names)
  local p = GetProf(profName)
  for spellID, r in pairs(recipes) do
    r.spell = spellID
    r.makes = r.makes or 1
    p.recipes[spellID] = r
    -- Prefer the trainer recipe as "the" producer when several recipes make the same item.
    if r.item and r.item > 0 then
      local cur = p.byItem[r.item] and p.recipes[p.byItem[r.item]]
      if not cur or (cur.src ~= "Trainer" and r.src == "Trainer") then
        p.byItem[r.item] = spellID
      end
    end
  end
  for id, n in pairs(names) do
    p.names[id] = n
    if not CR.itemNames[id] then CR.itemNames[id] = n end
  end
end

-- Called by Data/<Prof>Route.lua
-- A profession can have several routes (Cooking: solo or combined with Fishing).
-- mode is a short key, route.label the name shown in the mode dropdown.
function CR.RegisterRoute(profName, route, mode)
  local p = GetProf(profName)
  mode = mode or "solo"
  p.routes = p.routes or {}
  p.routeOrder = p.routeOrder or {}
  if not p.routes[mode] then table.insert(p.routeOrder, mode) end
  p.routes[mode] = route
  route.mode = mode
  route.id = route.id or (profName .. ":" .. mode)
  route.label = route.label or (profName .. " only")
end

function CR.GetProfession(name) return CR.professions[name] end

-- Professions with a route, primary crafting professions first.
local ORDER = { Herbalism = 40, Mining = 41, Skinning = 42, Cooking = 50, Fishing = 51, ["First Aid"] = 52 }

-- Professions with no crafting window to open. The keybind shows their guide on CraftRoute's
-- tab. The icon their gathering steps show:
CR.NO_WINDOW = { Fishing = true, Herbalism = true, Skinning = true }
CR.GATHER_ICON = {
  Fishing = "Interface\\Icons\\Trade_Fishing", Mining = "Interface\\Icons\\Trade_Mining",
  Herbalism = "Interface\\Icons\\Trade_Herbalism", Skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
}
function CR.SupportedProfessions()
  local list = {}
  for name, p in pairs(CR.professions) do
    if p.routes then table.insert(list, name) end
  end
  table.sort(list, function(a, b)
    local oa, ob = ORDER[a] or 10, ORDER[b] or 10
    if oa ~= ob then return oa < ob end
    return a < b
  end)
  return list
end

---------------------------------------------------------------------------
-- Saved variables (settings are per character)
---------------------------------------------------------------------------
local CHAR_DEFAULTS = {
  profession = "Leatherworking",
  goalMode = "tier",        -- "rank:<name>" | "custom" (anything else: your current rank)
  customGoal = 225,
  choices = {},             -- [prof] = { [choiceKey] = optionKey }
  targets = {},             -- [prof] = { [spellID] = quantity }
  known = {},               -- [prof] = { [spellID] = true } (from the trade skill window)
  manualSkill = {},         -- [prof] = number, used when the profession isn't learned yet
  includeAlts = false,      -- count materials sitting on alts (via Syndicator) as owned
  routeMode = {},           -- [prof] = route mode key (e.g. Cooking: "solo" or "combo")
  tasksDone = {},           -- [prof] = { [taskKey] = true } (steps ticked off with "Mark as done")
  showUnlearned = true,     -- list professions this character hasn't learned in the profession picker
}

local function ApplyDefaults(db, defaults)
  for k, v in pairs(defaults) do
    if db[k] == nil then
      db[k] = type(v) == "table" and {} or v
    end
  end
end

function CR.CharDB() return CraftRouteCharDB end

function CR.ProfTable(field, prof)
  local t = CraftRouteCharDB[field]
  prof = prof or CraftRouteCharDB.profession
  t[prof] = t[prof] or {}
  return t[prof]
end

---------------------------------------------------------------------------
-- Slash commands (registered first so /cr works even if something below breaks)
---------------------------------------------------------------------------
SLASH_CRAFTROUTE1 = "/craftroute"
SLASH_CRAFTROUTE2 = "/cr"
SlashCmdList.CRAFTROUTE = function(msg)
  if not CraftRouteCharDB then
    CR.Print("Not initialised - the addon failed to load. Any 'CraftRoute error' lines above say why.")
    return
  end
  msg = strtrim(msg or ""):lower()
  local skill = msg:match("^skill%s+(%d+)$")
  if skill then
    CR.ProfTable("manualSkill").value = tonumber(skill)
    CR.Print("Manual skill set to " .. skill .. " (only used while the profession isn't learned).")
    CR.NotifyChanged()
  elseif msg == "popup" then
    CR.DebugPopups()
  elseif msg == "probe" then
    if CR.ProbeUnderMouse then CR.ProbeUnderMouse() end
  elseif msg == "data" then
    local st = CR.tsStats or {}
    if (st.recipes or 0) > 0 then
      CR.Print(string.format("Recipe data: %d recipes read live from TrainerSpells (learn skill, source, vendors); "
        .. "%d differ from CraftRoute's built-in values. The rest use the built-in data.", st.recipes, st.changed or 0))
    else
      CR.Print("Recipe data: TrainerSpells not loaded - using CraftRoute's built-in recipe data.")
    end
  elseif msg == "bg" then
    if CR.DebugBackground then CR.DebugBackground() end
  elseif msg == "tracker" then
    -- the materials window (one profession's own tracker: double-click its icon there)
    if CR.ToggleAllMaterials then CR.ToggleAllMaterials() elseif CR.ToggleTracker then CR.ToggleTracker() end
  elseif msg == "all" then
    if CR.ToggleAllMaterials then CR.ToggleAllMaterials() end
  elseif msg == "trace" then
    if CR.ToggleCompactTrace then CR.ToggleCompactTrace() end
  elseif msg == "view" then
    if CR.DebugCompactView then CR.DebugCompactView() end
  elseif msg == "tasks reset" then
    CR.ResetTasks(CraftRouteCharDB.profession)
    CR.Print("Cleared the steps you marked as done for " .. tostring(CraftRouteCharDB.profession) .. ".")
  elseif msg == "rankbar" then
    if CR.DebugRankBar then CR.DebugRankBar() end
  elseif msg == "recipes" then
    CR.SafeCall(CR.ShowWindow, "recipes")
  elseif msg == "window" then
    -- the full CraftRoute window (Plan, Recipes, Professions)
    CR.SafeCall(CR.ToggleWindow)
  elseif msg == "help" then
    CR.Print("/cr - settings, /cr window - the CraftRoute window, /cr all - the Materials window, /cr recipes - recipe picker, /cr skill <n> - planning skill if not learned yet, /cr tasks reset - undo \"Mark as done\" for this profession")
  else
    -- /cr: the settings (the CraftRoute window is /cr window)
    if CR.OpenSettings then CR.SafeCall(CR.OpenSettings) else CR.SafeCall(CR.ToggleWindow) end
  end
end

-- A recipe's icon: the item it makes, or for enchants (which make no item) the spell's own
-- icon, as the spellbook / profession window shows it.
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
function CR.RecipeIcon(r)
  if not r then return QUESTION end
  if r.item and r.item > 0 then return CR.GetItemIcon(r.item) or QUESTION end
  local icon
  if C_Spell and C_Spell.GetSpellTexture then icon = C_Spell.GetSpellTexture(r.spell) end
  if not icon and GetSpellTexture then icon = GetSpellTexture(r.spell) end
  if not icon and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, r.spell)
    icon = ok and info and info.icon or nil
  end
  return icon or QUESTION
end

-- Each profession's colour, for its skill bar (both windows): picked from its theme - Alchemy's
-- green, Enchanting's violet, Leatherworking's tan, Blacksmithing's forge orange...
local PROFESSION_COLORS = {
  Alchemy        = { 0.36, 0.78, 0.32 },
  Blacksmithing  = { 0.93, 0.47, 0.18 },
  Enchanting     = { 0.66, 0.42, 0.96 },
  Engineering    = { 0.95, 0.76, 0.24 },
  Leatherworking = { 0.80, 0.53, 0.28 },
  Tailoring      = { 0.86, 0.38, 0.64 },
  Mining         = { 0.60, 0.66, 0.74 },
  Herbalism      = { 0.42, 0.76, 0.36 },
  Skinning       = { 0.72, 0.55, 0.40 },
  Cooking        = { 0.96, 0.58, 0.22 },
  ["First Aid"]  = { 0.88, 0.24, 0.24 },
  Fishing        = { 0.28, 0.60, 0.94 },
}
function CR.ProfessionColor(name)
  local c = name and PROFESSION_COLORS[name]
  if c then return c[1], c[2], c[3] end
  return 0.92, 0.68, 0.28   -- gold for anything else
end

-- Two-column tooltip lines can't wrap, so long labels are cut short (with "...") rather than
-- stretching the tooltip across the screen. Single lines use the wrap flag instead.
function CR.TipShort(text, max)
  max = max or 46
  text = tostring(text or "")
  if #text <= max then return text end
  return text:sub(1, max - 3):gsub("%s+$", "") .. "..."
end

function CR.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffCraftRoute|r: " .. tostring(msg))
end

---------------------------------------------------------------------------
-- Profession skill detection
---------------------------------------------------------------------------
CR.skill = {}   -- [profName] = { rank, maxRank }

function CR.ScanSkills()
  local found = {}
  if GetProfessions and GetProfessionInfo then
    -- Retail-style API (WoW Forever). Slots stay in GetProfessions order
    -- (primary, primary, archaeology, fishing, cooking, first aid) so the
    -- keybind can reopen from this scan instead of walking the list again.
    local p1, p2, arch, fish, cook, firstAid = GetProfessions()
    local indices = { p1, p2, arch, fish, cook, firstAid }
    local slots = {}
    for i = 1, 6 do
      local index = indices[i]
      if index then
        local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
        if name then
          slots[i] = { name = name, skillLine = skillLine, rank = rank, maxRank = maxRank }
          if CR.professions[name] then
            found[name] = { rank = rank, maxRank = maxRank, skillLine = skillLine, icon = icon }
          end
        end
      end
    end
    CR.professionSlots = slots
  elseif C_SkillInfo and C_SkillInfo.GetNumSkillLines then
    CR.professionSlots = nil
    for i = 1, C_SkillInfo.GetNumSkillLines() do
      local d = C_SkillInfo.GetSkillLineInfo(i)
      if d and d.name and CR.professions[d.name] then
        found[d.name] = { rank = d.skillRank or d.rank or 0, maxRank = d.maxRank or 0 }
      end
    end
  elseif GetNumSkillLines and GetSkillLineInfo then
    CR.professionSlots = nil
    for i = 1, GetNumSkillLines() do
      local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
      if name and not isHeader and CR.professions[name] then
        found[name] = { rank = rank, maxRank = maxRank }
      end
    end
  end
  CR.skill = found
end

-- "Leatherworking:75:150|Mining:10:75", compared after a profession window opens
-- so an unchanged skill does not throw the route plan away.
function CR.SkillStamp()
  local parts = {}
  for name, s in pairs(CR.skill or {}) do
    parts[#parts + 1] = name .. ":" .. tostring(s.rank) .. ":" .. tostring(s.maxRank)
  end
  table.sort(parts)
  return table.concat(parts, "|")
end

-- What to load into an empty window: first primary with a crafting window
-- (Mining's is smelting), else the second, else Cooking, then First Aid.
-- Uses the list ScanSkills just stored. The live API is only the fallback
-- for a call that arrives before the first scan.
function CR.FallbackProfession()
  local slots = CR.professionSlots
  if slots then
    for _, i in ipairs({ 1, 2, 5, 6 }) do
      local s = slots[i]
      if s and s.skillLine and s.name and not (CR.NO_WINDOW and CR.NO_WINDOW[s.name]) then
        return s.skillLine, s.name
      end
    end
    return nil
  end
  if not (GetProfessions and GetProfessionInfo) then return nil end
  local p1, p2, _, _, cook, firstAid = GetProfessions()
  for _, index in ipairs({ p1 or false, p2 or false, cook or false, firstAid or false }) do
    if index then
      local name, _, _, _, _, _, skillLine = GetProfessionInfo(index)
      if name and skillLine and not (CR.NO_WINDOW and CR.NO_WINDOW[name]) then return skillLine, name end
    end
  end
end

-- Returns current skill, tier max rank, and whether it was detected from the client.
function CR.GetSkill(prof)
  prof = prof or CraftRouteCharDB.profession
  local s = CR.skill[prof]
  if s then return s.rank, s.maxRank, true end
  return CR.ProfTable("manualSkill", prof).value or 1, 0, false
end

---------------------------------------------------------------------------
-- Known recipes (scanned whenever the profession window is open)
---------------------------------------------------------------------------
-- One pass of the open profession window, shared by every learned/craftable check
-- until the next plan refresh. Calling GetRecipeInfo per recipe on each of those
-- checks was most of the cost of the Craft (destinations) view.
local liveRecipes = { prof = nil, token = -1, map = {} }
local liveToken = 0

function CR.BumpLiveRecipes()
  liveToken = liveToken + 1
end

function CR.LiveRecipeInfo(profName, spell)
  if not profName or not spell then return nil end
  if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo) then return nil end
  if not (CR.TradeSkillOpenFor and CR.TradeSkillOpenFor(profName)) then return nil end
  if liveRecipes.prof ~= profName or liveRecipes.token ~= liveToken then
    local map = {}
    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
      local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
      if ok and info then map[recipeID] = info end
    end
    liveRecipes.prof, liveRecipes.token, liveRecipes.map = profName, liveToken, map
  end
  return liveRecipes.map[spell]
end

-- nil: the profession window has never shown this recipe, so learned-or-not is unknown.
-- true/false: the open window said so, or (true only) a previous scan saved it.
function CR.RecipeLearned(profName, recipe)
  if not recipe then return nil end
  local info = CR.LiveRecipeInfo(profName, recipe.spell)
  if info and info.learned ~= nil then return info.learned end
  if not profName then return nil end
  local known = CR.ProfTable("known", profName)
  if known[recipe.spell] then return true end
  return nil
end

-- How many can be made from bags right now. While that profession's window is open,
-- numAvailable comes from the single live scan above.
function CR.CraftsReady(profName, recipe)
  if not recipe then return 0 end
  local info = CR.LiveRecipeInfo(profName, recipe.spell)
  if info and type(info.numAvailable) == "number" then return info.numAvailable end
  local n = math.huge
  for _, rg in ipairs(recipe.reagents or {}) do
    local per = rg[2] or 1
    if per < 1 then per = 1 end
    local bags = CR.GetItemCount(rg[1], false) or 0
    n = math.min(n, math.floor(bags / per))
  end
  if n == math.huge then return 0 end
  return n
end

local function OpenProfessionFromUI()
  if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    local name = info and (info.professionName or info.parentProfessionName)
    if name == "Smelting" then return "Mining" end
    return name
  end
  if GetTradeSkillLine then
    local name = GetTradeSkillLine()
    if name == "Smelting" then return "Mining" end
    return name ~= "" and name or nil
  end
end

-- One walk of the open profession window. Fills the live map (learned and how
-- many you can make) and the saved known list. Returns the profession and
-- whether a recipe was newly marked known. nil when nothing is open yet.
function CR.ReadOpenRecipes()
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
    local profName = OpenProfessionFromUI()
    if not profName or profName == "" or not CR.professions[profName] then return nil, false end
    if CR.TradeSkillOpenFor and not CR.TradeSkillOpenFor(profName) then return nil, false end
    local prof = CR.professions[profName]
    local known = CR.ProfTable("known", profName)
    local map = {}
    local learnedChanged = false
    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
      local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
      if ok and info then
        map[recipeID] = info
        if info.learned and prof.recipes[recipeID] and not known[recipeID] then
          known[recipeID] = true
          learnedChanged = true
        end
      end
    end
    liveRecipes.prof, liveRecipes.token, liveRecipes.map = profName, liveToken, map
    return profName, learnedChanged
  end
  if GetTradeSkillLine and GetNumTradeSkills then
    local profName = OpenProfessionFromUI()
    if not profName or not CR.professions[profName] then return nil, false end
    local known = CR.ProfTable("known", profName)
    local learnedChanged = false
    for i = 1, GetNumTradeSkills() do
      local _, kind = GetTradeSkillInfo(i)
      if kind ~= "header" and GetTradeSkillRecipeLink then
        local link = GetTradeSkillRecipeLink(i)
        local spellID = link and tonumber(link:match("enchant:(%d+)"))
        if spellID and not known[spellID] then
          known[spellID] = true
          learnedChanged = true
        end
      end
    end
    return profName, learnedChanged
  end
  return nil, false
end

function CR.ScanTradeSkill()
  CR.ReadOpenRecipes()
end

-- The profession window's show event used to walk every recipe before the
-- CraftRoute tab could paint, then NotifyChanged walked them again. This
-- waits a frame, walks once, and rebuilds the route only when skill or the
-- known list actually changed.
local recipeScanQueued = false
local recipeScanTries = 0
function CR.QueueOpenRecipeScan()
  if recipeScanQueued then return end
  recipeScanQueued = true
  recipeScanTries = 0
  local function run()
    recipeScanQueued = false
    local prof, learnedChanged = CR.ReadOpenRecipes()
    if not prof then
      recipeScanTries = recipeScanTries + 1
      if recipeScanTries < 4 and C_Timer and C_Timer.After then
        recipeScanQueued = true
        C_Timer.After(0.1, function() CR.SafeCall(run) end)
      end
      return
    end
    local stamp = CR.SkillStamp()
    local stampChanged = stamp ~= CR.skillStamp
    CR.skillStamp = stamp
    if learnedChanged or stampChanged then
      CR.NotifyChanged({ keepLive = true })
    elseif CR.RefreshCompact then
      CR.SafeCall(CR.RefreshCompact)
    end
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function() CR.SafeCall(run) end)
  else
    run()
  end
end

-- One generation of timers. A second call for the same key drops the first
-- set, so the profession tab's reopen ladder does not stack on itself.
CR._schedGen = {}
function CR.ScheduleUnique(key, delays, fn)
  local gen = (CR._schedGen[key] or 0) + 1
  CR._schedGen[key] = gen
  for _, delay in ipairs(delays) do
    C_Timer.After(delay, function()
      if CR._schedGen[key] ~= gen then return end
      fn()
    end)
  end
end

---------------------------------------------------------------------------
-- Change notification (throttled so bag spam doesn't rebuild the plan 50x/sec)
---------------------------------------------------------------------------
function CR.OnChange(fn) table.insert(CR.callbacks, fn) end

-- opts.keepLive / keepPlan / keepLocations: this notify must not throw away a
-- scan or a plan the caller just built. opts.skipCompact: the profession tab
-- already redrew. A second caller that needs a fresh plan clears those flags.
local pending = false
local pendingOpts
function CR.NotifyChanged(opts)
  opts = opts or {}
  if not pendingOpts then
    pendingOpts = {
      keepLive = opts.keepLive and true or false,
      keepPlan = opts.keepPlan and true or false,
      keepLocations = opts.keepLocations and true or false,
      skipCompact = opts.skipCompact and true or false,
    }
  else
    if not opts.keepLive then pendingOpts.keepLive = false end
    if not opts.keepPlan then pendingOpts.keepPlan = false end
    if not opts.keepLocations then pendingOpts.keepLocations = false end
    if not opts.skipCompact then pendingOpts.skipCompact = false end
  end
  if pending then return end
  pending = true
  C_Timer.After(0.25, function()
    local o = pendingOpts or {}
    pending = false
    pendingOpts = nil
    CR._notifyOpts = o
    if not o.keepLive then CR.BumpLiveRecipes() end
    if not o.keepPlan then CR.InvalidatePlan() end
    if not o.keepLocations and CR.InvalidateLocations then CR.InvalidateLocations() end
    for _, fn in ipairs(CR.callbacks) do CR.SafeCall(fn) end
    CR._notifyOpts = nil
  end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")

-- Registering an event the client doesn't know is an error, and Forever lacks some
-- Classic ones (e.g. TRADE_SKILL_UPDATE), so check each first.
local function SafeRegister(event)
  if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then return end
  pcall(ev.RegisterEvent, ev, event)
end

for _, event in ipairs({
  "ADDON_LOADED", "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE",
  "TRADE_SKILL_LIST_UPDATE", "NEW_RECIPE_LEARNED", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED",
  "PLAYERBANKSLOTS_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_EQUIPMENT_CHANGED",
  "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN",
}) do
  SafeRegister(event)
end

local function OnEvent(event, ...)
  -- The game refused something CraftRoute did ("Interface action failed because of an AddOn"):
  -- say exactly what, so it can be fixed. FORBIDDEN = a function addons may never call;
  -- BLOCKED = a protected action attempted in combat or from tainted code.
  if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    local addon, func = ...
    if addon == ADDON then
      CR.Print(string.format("|cffff4040the game %s %s|r (%s)",
        event == "ADDON_ACTION_FORBIDDEN" and "forbids addons calling" or "blocked a call to", tostring(func), event))
    end
    return
  end
  if event == "ADDON_LOADED" then
    if ... ~= ADDON then return end
    CraftRouteDB = CraftRouteDB or {}
    CraftRouteCharDB = CraftRouteCharDB or {}
    ApplyDefaults(CraftRouteCharDB, CHAR_DEFAULTS)
    -- 0.6.2 replaced the "Max (300)" goal with the named Artisan rank.
    if CraftRouteCharDB.goalMode == "max" then CraftRouteCharDB.goalMode = "rank:Artisan" end
    if not CR.professions[CraftRouteCharDB.profession] then
      CraftRouteCharDB.profession = "Leatherworking"
    end
    return
  end
  if not CraftRouteCharDB then return end
  if event == "PLAYER_LOGIN" or event == "SKILL_LINES_CHANGED" then
    CR.ScanSkills()
    -- The stamp is what a later profession-window open compares against.
    CR.skillStamp = CR.SkillStamp()
    -- Until the player picks one, show a profession this character actually has.
    local db = CraftRouteCharDB
    if not db.profPicked and not CR.skill[db.profession] then
      for _, name in ipairs(CR.SupportedProfessions()) do
        if CR.skill[name] then db.profession = name break end
      end
    end
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
      or event == "TRADE_SKILL_LIST_UPDATE" or event == "NEW_RECIPE_LEARNED" then
    CR.ScanSkills()
    -- Next frame: one recipe walk. A plain open does not rebuild the route.
    CR.QueueOpenRecipeScan()
    return
  end
  CR.NotifyChanged()
end

ev:SetScript("OnEvent", function(_, event, ...) CR.SafeCall(OnEvent, event, ...) end)
