-- Where materials are: this character's bags/bank/mail, plus alts.
-- Uses Syndicator's public API (installed with Baganator) when present - it records every
-- character's bags, bank, mail and equipped items. Without it, only this character is known.
local _, CR = ...
local GetItemCount = CR.GetItemCount

local function HasSyndicator()
  return Syndicator and Syndicator.API and Syndicator.API.GetInventoryInfoByItemID
    and (not Syndicator.API.IsReady or Syndicator.API.IsReady())
end
CR.HasSyndicator = HasSyndicator

local function MyFullName()
  local cur = HasSyndicator() and Syndicator.API.GetCurrentCharacter and Syndicator.API.GetCurrentCharacter()
  return cur
end

-- Returns { {name=, isMe=, bags=, bank=, mail=, total=} ... } with this character first, and the grand total.
local cache = {}
function CR.GetLocations(itemID)
  if cache[itemID] then return cache[itemID].list, cache[itemID].total end
  local list, total = {}, 0
  local me = MyFullName()
  local foundMe = false
  if HasSyndicator() then
    local ok, info = pcall(Syndicator.API.GetInventoryInfoByItemID, itemID, false, false)
    for _, c in ipairs(ok and info and info.characters or {}) do
      local full = c.character .. "-" .. (c.realmNormalized or "")
      local isMe = full == me or (me == nil and c.character == UnitName("player"))
      -- Live counts for this character; Syndicator's snapshot can lag a bag update.
      local e = { name = c.character, class = c.className, isMe = isMe,
                  bags = c.bags or 0, bank = c.bank or 0, mail = c.mail or 0 }
      if isMe then
        foundMe = true
        e.bags = GetItemCount(itemID, false) or 0
        e.bank = math.max(e.bank, (GetItemCount(itemID, true) or 0) - e.bags)
      end
      e.total = e.bags + e.bank + e.mail
      if e.total > 0 then table.insert(list, e) end
    end
  end
  if not foundMe then
    local bags = GetItemCount(itemID, false) or 0
    local all = GetItemCount(itemID, true) or 0
    local e = { name = UnitName("player"), isMe = true, bags = bags, bank = all - bags, mail = 0, total = all }
    if all > 0 then table.insert(list, e) end
  end
  table.sort(list, function(a, b)
    if a.isMe ~= b.isMe then return a.isMe end
    return a.total > b.total
  end)
  for _, e in ipairs(list) do total = total + e.total end
  cache[itemID] = { list = list, total = total }
  return list, total
end

function CR.InvalidateLocations() wipe(cache) end

-- Crafting equipment: it has to be on the character doing the crafting (bags or equipped), so
-- one in the bank or on an alt doesn't count - unlike materials, which can be fetched or mailed.
CR.TOOLS = {
  [5956] = true,                                        -- Blacksmith Hammer
  [2901] = true,                                        -- Mining Pick
  [7005] = true,                                        -- Skinning Knife
  [6256] = true, [6365] = true, [6366] = true, [6367] = true,   -- fishing poles
  [6219] = true,                                        -- Arclight Spanner
  [10498] = true,                                       -- Gyromatic Micro-Adjustor
  [6218] = true, [6339] = true, [11130] = true, [11145] = true, [16207] = true,   -- Runed rods
  [9149] = true,                                        -- Philosopher's Stone
  [4471] = true,                                        -- Flint and Tinder
}
function CR.IsTool(itemID) return CR.TOOLS[itemID] or false end

-- Materials "have": this character's bags + bank + mail, and alts too if the setting is on
-- ("Count alts' materials" on the Plan tab, the Craft tab and the profession-window tab).
function CR.HaveCount(itemID)
  if CR.TOOLS[itemID] then return GetItemCount(itemID, false) or 0 end
  local list = CR.GetLocations(itemID)
  local n = 0
  for _, e in ipairs(list) do
    if e.isMe or CraftRouteCharDB.includeAlts then n = n + e.total end
  end
  return n
end

-- Tooltip block: "You: 12 bags, 30 bank" / "Altname: 50 bank".
function CR.AddLocationLines(tooltip, itemID)
  local list = CR.GetLocations(itemID)
  if #list == 0 then
    tooltip:AddLine("  You don't have any" .. (HasSyndicator() and " on any character." or "."), 0.6, 0.6, 0.6)
    return
  end
  for _, e in ipairs(list) do
    local parts = {}
    if e.bags > 0 then table.insert(parts, e.bags .. " bags") end
    if e.bank > 0 then table.insert(parts, e.bank .. " bank") end
    if e.mail > 0 then table.insert(parts, e.mail .. " mail") end
    local who = e.isMe and (e.name .. " (you)") or e.name
    local c = e.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
    local counted = e.isMe or CraftRouteCharDB.includeAlts
    tooltip:AddDoubleLine("  " .. who, table.concat(parts, ", ") .. (counted and "" or " |cff808080(not counted)|r"),
      c and c.r or 1, c and c.g or 1, c and c.b or 1, 1, 1, 1)
  end
  if not HasSyndicator() then
    tooltip:AddLine("  Install Syndicator (comes with Baganator) to see alts.", 0.6, 0.6, 0.6)
  end
end

-- Refresh when Syndicator updates any character's cache.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  if Syndicator and Syndicator.CallbackRegistry then
    for _, ev in ipairs({ "BagCacheUpdate", "MailCacheUpdate", "Ready" }) do
      pcall(Syndicator.CallbackRegistry.RegisterCallback, Syndicator.CallbackRegistry, ev,
        function() CR.NotifyChanged() end, CR)
    end
  end
end)
