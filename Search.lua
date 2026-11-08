-- Recipe search: by name, or by what the crafted item has on it.
-- Base stats come from the recipe data (r.stats). Equip / Use / Chance on hit lines (healing,
-- spell damage, crit, mana regen...) aren't in it, so they're read from the item's tooltip once the
-- client has the item cached, and kept per item for the session.
local _, CR = ...

-- Short forms players type. Each maps to the start of a word in the item text.
local ALIAS = {
  int = "intellect", agi = "agility", str = "strength", sta = "stamina", stam = "stamina",
  spi = "spirit", def = "defense", crit = "critical", heal = "healing", res = "resistance",
  resist = "resistance", sp = "spells", mp5 = "mana", ap = "attack",
}

local itemText = {}     -- itemID -> lowercased tooltip effect lines ("" when it has none)
local pending = {}      -- itemID -> true while waiting for GET_ITEM_INFO_RECEIVED

local KEEP = { "^equip:", "^use:", "^chance on hit:", "^%+%d", "resistance", "block", "^set:" }

local function Keep(line)
  local l = line:lower()
  for _, p in ipairs(KEEP) do if l:find(p) then return l end end
end

local scanTip
local function TooltipLines(id)
  local out = {}
  if C_TooltipInfo and C_TooltipInfo.GetItemByID then
    local data = C_TooltipInfo.GetItemByID(id)
    if not data or not data.lines then return nil end
    for i = 2, #data.lines do
      local t = data.lines[i].leftText
      local k = t and Keep(t)
      if k then table.insert(out, k) end
    end
    return out
  end
  if not scanTip then
    scanTip = CreateFrame("GameTooltip", "CraftRouteScanTip", nil, "GameTooltipTemplate")
  end
  scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
  scanTip:SetItemByID(id)
  for i = 2, scanTip:NumLines() do
    local fs = _G["CraftRouteScanTipTextLeft" .. i]
    local k = fs and fs:GetText() and Keep(fs:GetText())
    if k then table.insert(out, k) end
  end
  scanTip:Hide()
  return out
end

local function Cached(id)
  if C_Item and C_Item.IsItemDataCachedByID then return C_Item.IsItemDataCachedByID(id) end
  return GetItemInfo(id) ~= nil
end

-- The item's effect text, or nil while the client is still fetching it.
local function EffectText(id)
  if not id or id == 0 then return "" end
  local t = itemText[id]
  if t then return t end
  if not Cached(id) then
    if not pending[id] then
      pending[id] = true
      if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id)
      else GetItemInfo(id) end
    end
    return nil
  end
  local ok, lines = pcall(TooltipLines, id)
  if not ok or not lines then return nil end
  t = table.concat(lines, "\n")
  itemText[id] = t
  return t
end

-- Does `word` start a word in `text`? (so "int" finds Intellect but not "Glinting")
local function WordStart(text, word)
  if text == "" then return false end
  local s = 1
  while true do
    local a = text:find(word, s, true)
    if not a then return false end
    if a == 1 or not text:sub(a - 1, a - 1):match("[%w']") then return true end
    s = a + 1
  end
end

-- Words of the search. A number joins the word after it: "+6 int" is one term, 6 Intellect.
local function Terms(q)
  local words = {}
  for w in q:gmatch("[^%s,]+") do
    w = w:gsub("^%+", "")
    if w ~= "" then table.insert(words, w) end
  end
  local out, i = {}, 1
  while i <= #words do
    local w = words[i]
    if w:match("^%d+$") and words[i + 1] then
      table.insert(out, { num = w, word = words[i + 1] })
      i = i + 2
    else
      table.insert(out, { word = w })
      i = i + 1
    end
  end
  return out
end

-- q: lowercased search text. Matches when the whole text is in the name (as before), or when every
-- word in it starts a word in the name, the recipe's stats or the item's equip / use lines.
function CR.RecipeMatches(r, q)
  if q == "" then return true end
  local name = r.name:lower()
  if not ALIAS[q] and name:find(q, 1, true) then return true end
  -- stats plus the category, so "chest" or "cloak" finds the slot
  local stats = ((r.stats or "") .. "; " .. (r.cat or "")):lower()
  local effects = r.item and EffectText(r.item) or ""
  for _, t in ipairs(Terms(q)) do
    -- an alias reads as its full word everywhere ("sp" is spells, not Spirit or Spitfire)
    local s = ALIAS[t.word] or t.word
    local hit
    if t.num then
      s = t.num .. " " .. s
      hit = WordStart(stats, s) or WordStart(effects, s)
    else
      hit = WordStart(name, s) or WordStart(stats, s) or WordStart(effects, s)
    end
    if not hit then return false end
  end
  return true
end

-- Stats as numbers, for the Filter > Stats list: { key, label, group }, in list order.
CR.STATS = {
  { "sta", "Stamina", "Attributes" }, { "str", "Strength", "Attributes" }, { "agi", "Agility", "Attributes" },
  { "int", "Intellect", "Attributes" }, { "spi", "Spirit", "Attributes" },
  { "heal", "Healing", "Spell" }, { "spell", "Spell damage", "Spell" },
  { "fire", "Fire damage", "Spell" }, { "frost", "Frost damage", "Spell" },
  { "shadow", "Shadow damage", "Spell" }, { "nature", "Nature damage", "Spell" },
  { "arcane", "Arcane damage", "Spell" }, { "holy", "Holy damage", "Spell" },
  { "scrit", "Spell crit %", "Spell" }, { "shit", "Spell hit %", "Spell" }, { "mp5", "Mana per 5 sec", "Spell" },
  { "ap", "Attack power", "Physical" }, { "rap", "Ranged attack power", "Physical" },
  { "crit", "Crit %", "Physical" }, { "hit", "Hit %", "Physical" },
  { "armor", "Armor", "Defense" }, { "def", "Defense", "Defense" }, { "dodge", "Dodge %", "Defense" },
  { "parry", "Parry %", "Defense" }, { "block", "Block", "Defense" }, { "hp5", "Health per 5 sec", "Defense" },
  { "rfire", "Fire", "Resistances" }, { "rfrost", "Frost", "Resistances" }, { "rnature", "Nature", "Resistances" },
  { "rshadow", "Shadow", "Resistances" }, { "rarcane", "Arcane", "Resistances" },
  { "slots", "Bag slots", "Bags" },
}
local PRIMARY = { stamina = "sta", strength = "str", agility = "agi", intellect = "int", spirit = "spi",
  defense = "def" }
local SCHOOL = { fire = true, frost = true, shadow = true, nature = true, arcane = true, holy = true }

local function Add(t, k, v)
  v = tonumber(v)
  if k and v then t[k] = (t[k] or 0) + v end
end

-- One line of stats / effect text (lowercased) into t.
local function ParseLine(t, l)
  local n, w = l:match("^%+(%d+) (%a+)$")
  if n and PRIMARY[w] then Add(t, PRIMARY[w], n) return end
  n, w = l:match("^%+?(%d+) (%a+) resistance")
  if n then Add(t, "r" .. w, n) return end
  n = l:match("^(%d+) armor$") if n then Add(t, "armor", n) return end
  n = l:match("^(%d+) block$") if n then Add(t, "block", n) return end
  n = l:match("^(%d+) slot") if n then Add(t, "slots", n) return end
  if not l:find("^equip:") then return end
  -- healing / spell damage, in the wordings the game uses
  n = l:match("damage and healing done by magical spells and effects by up to (%d+)")
  if n then Add(t, "heal", n) Add(t, "spell", n) return end
  n = l:match("healing done by up to (%d+)") or l:match("healing done by spells and effects by up to (%d+)")
  if n then Add(t, "heal", n) end
  n = l:match("and damage done by up to (%d+)")
  if n then Add(t, "spell", n) end
  local school
  school, n = l:match("damage done by (%a+) spells and effects by up to (%d+)")
  if school and SCHOOL[school] then Add(t, school, n) end
  Add(t, "mp5", l:match("restores (%d+) mana per 5"))
  Add(t, "hp5", l:match("restores (%d+) health per 5"))
  if l:find("critical strike with spells") then Add(t, "scrit", l:match("by (%d+)%%"))
  elseif l:find("critical strike") then Add(t, "crit", l:match("by (%d+)%%")) end
  if l:find("hit with spells") then Add(t, "shit", l:match("by (%d+)%%"))
  elseif l:find("chance to hit") then Add(t, "hit", l:match("by (%d+)%%")) end
  Add(t, "rap", l:match("%+(%d+) ranged attack power"))
  if not l:find("ranged attack power") then Add(t, "ap", l:match("%+(%d+) attack power")) end
  Add(t, "def", l:match("increased defense %+(%d+)"))
  Add(t, "dodge", l:match("chance to dodge an attack by (%d+)%%"))
  Add(t, "parry", l:match("chance to parry an attack by (%d+)%%"))
  Add(t, "block", l:match("block value of your shield by (%d+)"))
end

local statsOf = {}   -- recipe -> { key = value }, once its item's tooltip is in
function CR.ItemStats(r)
  local t = statsOf[r]
  if t then return t end
  t = {}
  -- r.stats parts are split by "," or " · " (\194\183 is the middle dot in UTF-8)
  local stats = (r.stats or ""):gsub("\194\183", ",")
  for part in stats:gmatch("[^,]+") do
    ParseLine(t, (part:lower():gsub("^%s+", ""):gsub("%s+$", "")))
  end
  local fx = r.item and EffectText(r.item)
  if fx then
    for l in fx:gmatch("[^\n]+") do ParseLine(t, l) end
    statsOf[r] = t   -- effects not in yet: work it out again next time
  elseif not r.item then
    statsOf[r] = t
  end
  return t
end

-- Items that arrive while a search is up: refresh once things settle.
local ev = CreateFrame("Frame")
ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
local queued = false
ev:SetScript("OnEvent", function(_, _, id)
  if not (id and pending[id]) then return end
  pending[id] = nil
  if queued then return end
  queued = true
  C_Timer.After(0.3, function()
    queued = false
    if CR.RefreshCompact then CR.RefreshCompact() end
  end)
end)
