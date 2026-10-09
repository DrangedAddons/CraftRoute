local ADDON, CR = ...
_G.CraftRoute = CR

CR.professions = {}   -- [profName] = { recipes, names, byItem, routes }
CR.callbacks = {}
CR.extraNames = {}    -- fallback names for items that aren't recipe reagents (lures, quest items)

-- The Forever client uses the retail-style C_Item API; the old globals may not exist.
local C_Item = C_Item or {}
CR.GetItemInfo = C_Item.GetItemInfo or GetItemInfo
CR.GetItemCount = C_Item.GetItemCount or GetItemCount
CR.GetItemIcon = C_Item.GetItemIconByID or GetItemIcon
CR.IsEquippedItem = C_Item.IsEquippedItem or IsEquippedItem or function() return false end

-- Route text can carry faction-only parts: "{H:Horde text}" and "{A:Alliance text}".
-- The other faction's parts are removed, so players only see what applies to them.
function CR.FactionText(s)
  if not s or not s:find("{", 1, true) then return s end
  local mine = UnitFactionGroup("player") == "Alliance" and "A" or "H"
  s = s:gsub("{([HA]):([^}]*)}", function(f, text) return f == mine and text or "" end)
  -- Tidy separators left behind by removed parts ("A, , B" / "by , B" / "B, ").
  local prev
  repeat
    prev = s
    s = s:gsub(",%s*,", ","):gsub("by%s*,%s*", "by "):gsub(",%s*/", " /"):gsub(",%s*$", "")
  until s == prev
  return (s:gsub("  +", " "):gsub(" %.", "."):gsub("^ ", ""))
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
  for id, n in pairs(names) do p.names[id] = n end
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
local ORDER = { Cooking = 50, Fishing = 51, ["First Aid"] = 52 }
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
  goalMode = "next",        -- "next" | "tier" | "route" | "max" | "custom"
  customGoal = 225,
  choices = {},             -- [prof] = { [choiceKey] = optionKey }
  targets = {},             -- [prof] = { [spellID] = quantity }
  known = {},               -- [prof] = { [spellID] = true } (from the trade skill window)
  manualSkill = {},         -- [prof] = number, used when the profession isn't learned yet
  includeAlts = false,      -- count materials sitting on alts (via Syndicator) as owned
  routeMode = {},           -- [prof] = route mode key (e.g. Cooking: "solo" or "combo")
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
  elseif msg == "view" then
    if CR.DebugCompactView then CR.DebugCompactView() end
  elseif msg == "rankbar" then
    if CR.DebugRankBar then CR.DebugRankBar() end
  elseif msg == "recipes" then
    CR.SafeCall(CR.ShowWindow, "recipes")
  elseif msg == "help" then
    CR.Print("/cr - toggle window, /cr recipes - recipe picker, /cr skill <n> - planning skill if not learned yet")
  else
    CR.SafeCall(CR.ToggleWindow)
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
    -- Retail-style API (WoW Forever)
    for _, index in pairs({ GetProfessions() }) do
      local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
      if name and CR.professions[name] then
        -- skillLine opens the profession window (C_TradeSkillUI.OpenTradeSkill) for the Craft tab
        found[name] = { rank = rank, maxRank = maxRank, skillLine = skillLine, icon = icon }
      end
    end
  elseif C_SkillInfo and C_SkillInfo.GetNumSkillLines then
    for i = 1, C_SkillInfo.GetNumSkillLines() do
      local d = C_SkillInfo.GetSkillLineInfo(i)
      if d and d.name and CR.professions[d.name] then
        found[d.name] = { rank = d.skillRank or d.rank or 0, maxRank = d.maxRank or 0 }
      end
    end
  elseif GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
      if name and not isHeader and CR.professions[name] then
        found[name] = { rank = rank, maxRank = maxRank }
      end
    end
  end
  CR.skill = found
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
function CR.ScanTradeSkill()
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
    local profName
    if C_TradeSkillUI.GetBaseProfessionInfo then
      local info = C_TradeSkillUI.GetBaseProfessionInfo()
      profName = info and (info.professionName or info.parentProfessionName)
    end
    if not profName or not CR.professions[profName] then return end
    local prof = CR.professions[profName]
    local known = CR.ProfTable("known", profName)
    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
      local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
      if info and info.learned and prof.recipes[recipeID] then known[recipeID] = true end
    end
  elseif GetTradeSkillLine and GetNumTradeSkills then
    local profName = GetTradeSkillLine()
    if not profName or not CR.professions[profName] then return end
    local known = CR.ProfTable("known", profName)
    for i = 1, GetNumTradeSkills() do
      local _, kind = GetTradeSkillInfo(i)
      if kind ~= "header" and GetTradeSkillRecipeLink then
        local link = GetTradeSkillRecipeLink(i)
        local spellID = link and tonumber(link:match("enchant:(%d+)"))
        if spellID then known[spellID] = true end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Change notification (throttled so bag spam doesn't rebuild the plan 50x/sec)
---------------------------------------------------------------------------
function CR.OnChange(fn) table.insert(CR.callbacks, fn) end

local pending = false
function CR.NotifyChanged()
  if pending then return end
  pending = true
  C_Timer.After(0.25, function()
    pending = false
    CR.InvalidatePlan()
    CR.InvalidateLocations()
    for _, fn in ipairs(CR.callbacks) do CR.SafeCall(fn) end
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
  "PLAYERBANKSLOTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "PLAYER_LEVEL_UP", "PLAYER_EQUIPMENT_CHANGED",
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
    -- Until the player picks one, show a profession this character actually has.
    local db = CraftRouteCharDB
    if not db.profPicked and not CR.skill[db.profession] then
      for _, name in ipairs(CR.SupportedProfessions()) do
        if CR.skill[name] then db.profession = name break end
      end
    end
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
      or event == "TRADE_SKILL_LIST_UPDATE" or event == "NEW_RECIPE_LEARNED" then
    CR.ScanTradeSkill()
    CR.ScanSkills()
  end
  CR.NotifyChanged()
end

ev:SetScript("OnEvent", function(_, event, ...) CR.SafeCall(OnEvent, event, ...) end)
