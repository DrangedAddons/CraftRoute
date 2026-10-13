-- Have/need for the selected profession's plan, drawn on the Ellesmere Forever
-- Essentials loot row for that item. The row's own second line is used (the one
-- reputation and currency already use), so the font, size and colour stay whatever
-- that feed style set. Nothing of Ellesmere's is edited, and no extra row is added.
-- Only CraftRouteCharDB.profession is counted: the profession picked on the Plan tab
-- or in the crafting window.
local _, CR = ...

local painted = setmetatable({}, { __mode = "k" })
local paintedCallout = setmetatable({}, { __mode = "k" })

local watchUntil = 0
local scheduled = false

local function Feed()
  local eui = EllesmereUI
  local feed = eui and eui._LootFeed
  if not feed or not feed.Get then return nil end
  if not feed.Get("enabled") or not feed.Get("items") then return nil end
  return feed
end

-- The live feed anchor. Unlock registration is the only place that anchor is
-- reachable; getFrame returns nil while the feed is switched off.
local function Anchor()
  local reg = EllesmereUI and EllesmereUI._unlockRegisteredElements
  local elem = reg and reg.EUI_LootFeed
  if not elem or not elem.getFrame then return nil end
  local ok, frame = pcall(elem.getFrame)
  if ok then return frame end
end

local function ItemID(link)
  if type(link) ~= "string" then return nil end
  return tonumber(link:match("item:(%d+)"))
end

-- Owned (bags, bank, mail, and alts when that option is on) plus mats the plan
-- crafts on the way, capped the same way the item tooltip caps it.
local function ProgressText(byId, itemID)
  local m = byId and itemID and byId[itemID]
  if not m or not m.need or m.need <= 0 then return nil end
  local have = (m.have or 0) + (m.crafted or 0)
  if have < 0 then have = 0 end
  if have > m.need then have = m.need end
  return string.format("%d/%d", have, m.need)
end

local function PlanById()
  local db = CraftRouteCharDB
  if not db or not db.profession or not CR.GetPlans then return nil end
  local entry = CR.GetPlans(db.profession)
  return entry and entry.plan and entry.plan.byId
end

-- Ilvl / "Quest Item" already sit on the second line. Leave those rows alone.
local function Occupied(data)
  return data and (data.sub or data.questSub) or nil
end

local function PlaceName(name, icon, value, twoLine)
  name:ClearAllPoints()
  name:SetPoint("RIGHT", value, "LEFT", -8, 0)
  if twoLine then
    name:SetPoint("BOTTOMLEFT", icon, "RIGHT", 6, 1)
  else
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  end
end

local function RestoreRow(row)
  if not painted[row] then return end
  painted[row] = nil
  local name, sub, icon, value = row.name, row.sub, row.icon, row.value
  if not (name and sub and icon and value) then return end
  local own = Occupied(row.data)
  sub:SetText(own or "")
  sub:SetShown(own ~= nil)
  PlaceName(name, icon, value, own ~= nil)
end

local function PaintRow(row, progress)
  local name, sub, icon, value = row.name, row.sub, row.icon, row.value
  if not (name and sub and icon and value) then return end
  if Occupied(row.data) or not progress then
    RestoreRow(row)
    return
  end
  sub:SetText(progress)
  sub:SetShown(true)
  PlaceName(name, icon, value, true)
  painted[row] = true
end

-- Icon Tray draws the name on a callout parented to the newest tile, not on the tile.
local function CalloutOf(row)
  if not row.GetNumChildren or row:GetNumChildren() < 1 then return nil end
  for _, child in ipairs({ row:GetChildren() }) do
    if child.sub and child.name and child.value and not child.data then
      return child
    end
  end
end

-- Same points ShowCallout uses when a row has a second line. barWidth is read
-- back so the inset matches the accent bar they just laid out.
local function PlaceCallout(callout, subText)
  local feed = EllesmereUI._LootFeed
  local bw = feed and feed.Get and feed.Get("barWidth") or 0
  local right = -(bw + 8)
  local name, sub, value = callout.name, callout.sub, callout.value
  name:ClearAllPoints()
  sub:ClearAllPoints()
  value:ClearAllPoints()
  sub:SetText(subText or "")
  sub:SetShown(subText ~= nil and subText ~= "")
  if subText and subText ~= "" then
    name:SetPoint("BOTTOMLEFT", callout, "LEFT", 8, 1)
    name:SetPoint("RIGHT", callout, "RIGHT", right, 0)
    value:SetPoint("TOPRIGHT", callout, "RIGHT", right, -1)
    sub:SetPoint("TOPLEFT", callout, "LEFT", 8, -1)
    sub:SetPoint("RIGHT", value, "LEFT", -8, 0)
  else
    value:SetPoint("RIGHT", callout, "RIGHT", right, 0)
    name:SetPoint("LEFT", callout, "LEFT", 8, 0)
    name:SetPoint("RIGHT", value, "LEFT", -8, 0)
  end
end

local function PaintCallout(row, progress)
  local callout = CalloutOf(row)
  if not callout or not callout:IsShown() then return end
  local own = row.data and row.data.sub or nil
  if own or not progress then
    if paintedCallout[callout] then
      paintedCallout[callout] = nil
      PlaceCallout(callout, own)
    end
    return
  end
  PlaceCallout(callout, progress)
  paintedCallout[callout] = true
end

local function PaintVisible()
  local feed = Feed()
  if not feed then return end
  local anchor = Anchor()
  if not anchor or not anchor.GetChildren then return end
  local byId = PlanById()
  local tray = feed.Get("style") == "TRAY"
  for _, row in ipairs({ anchor:GetChildren() }) do
    if row:IsShown() and row.data and row.data.link and row.name then
      local progress = ProgressText(byId, ItemID(row.data.link))
      if tray then
        RestoreRow(row)
        PaintCallout(row, progress)
      else
        PaintRow(row, progress)
      end
    end
  end
end

local function Soon()
  if scheduled then return end
  scheduled = true
  C_Timer.After(0, function()
    scheduled = false
    CR.SafeCall(PaintVisible)
  end)
end

-- The loot line often arrives before the bag count, and an uncached item is
-- drawn a moment later. A couple of follow-up paints land on the settled row.
local function OnLoot()
  if not Feed() then return end
  watchUntil = GetTime() + 3
  Soon()
  C_Timer.After(0.25, Soon)
  C_Timer.After(1.5, Soon)
end

local installed = false
local function Install()
  if installed then return end
  if not (EllesmereUI and EllesmereUI._LootFeed and EllesmereUI._unlockRegisteredElements) then return end
  installed = true
  if EllesmereUI._LootFeed.ApplyStyle then
    hooksecurefunc(EllesmereUI._LootFeed, "ApplyStyle", Soon)
  end
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("CHAT_MSG_LOOT")
  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  frame:SetScript("OnEvent", function(_, event)
    if event == "CHAT_MSG_LOOT" then
      OnLoot()
    elseif GetTime() <= watchUntil and Feed() then
      Soon()
    end
  end)
  CR.OnChange(Soon)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
  Install()
  if installed then
    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
  end
end)
