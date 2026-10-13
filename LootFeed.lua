-- Loot progress feed: when you loot (or craft) something the route needs, a short row slides in -
-- "Copper Ore  60/100 > 61/100" - and fades out. Items the route doesn't need don't show, so it
-- sits beside EllesmereUI's loot feed (or Blizzard's chat) rather than repeating it. The counts are
-- the route's own: what it needs in total, and what you have as its materials list counts it.
-- /cr feed (on / off), /cr feed move (drag it), /cr feed test. Kept per character.
local _, CR = ...
local GetItemCount = CR.GetItemCount   -- (C_Item's in Forever: there's no global GetItemCount)

local ROW_W, ROW_H, GAP, MAX_ROWS = 280, 30, 2, 6
local SHOW_FOR, FADE_OUT = 6, 0.8
-- beside EllesmereUI's feed (its default: bottom right, 320 in, 260 up, 300 wide)
local DEFAULT_POS = { "BOTTOMRIGHT", "BOTTOMRIGHT", -640, 260 }

local anchor, rows = nil, {}   -- rows: shown, newest first
local why = false              -- /cr feed why: say in chat what each loot line did

local function Settings()
  local db = CraftRouteCharDB
  if not db then return { enabled = true } end
  db.lootFeed = db.lootFeed or { enabled = true }
  return db.lootFeed
end

---------------------------------------------------------------------------
-- The frames
---------------------------------------------------------------------------
local function Place()
  local s = Settings()
  local p = s.pos or DEFAULT_POS
  anchor:ClearAllPoints()
  anchor:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

local function Layout()
  for i, r in ipairs(rows) do
    r:ClearAllPoints()
    r:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, (i - 1) * (ROW_H + GAP))
  end
end

local function Release(r)
  for i, x in ipairs(rows) do if x == r then table.remove(rows, i) break end end
  r:Hide()
  r.free = true
  Layout()
end

local pool = {}
local function NewRow()
  for _, r in ipairs(pool) do if r.free then r.free = false return r end end
  local r = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  r:SetSize(ROW_W, ROW_H)
  CR.Backdrop(r, 0.05, 0.05, 0.07, 0.75)
  r.bar = r:CreateTexture(nil, "ARTWORK")
  r.bar:SetPoint("TOPLEFT", 1, -1)
  r.bar:SetPoint("BOTTOMLEFT", 1, 1)
  r.bar:SetWidth(3)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ROW_H - 6, ROW_H - 6)
  r.icon:SetPoint("LEFT", 8, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 6, -1)
  r.name:SetPoint("RIGHT", r, "RIGHT", -6, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  r.count = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  r.count:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 6, 1)
  r.count:SetPoint("RIGHT", r, "RIGHT", -6, 0)
  r.count:SetJustifyH("LEFT")
  r.fade = r:CreateAnimationGroup()
  local a = r.fade:CreateAnimation("Alpha")
  a:SetFromAlpha(1)
  a:SetToAlpha(0)
  a:SetDuration(FADE_OUT)
  a:SetStartDelay(SHOW_FOR)
  r.fade:SetScript("OnFinished", function() Release(r) end)
  -- hovering holds it (and shows the item)
  r:EnableMouse(true)
  r:SetScript("OnEnter", function(self)
    self.fade:Stop()
    self:SetAlpha(1)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:AddLine("CraftRoute: the route needs " .. (self.need or "?") .. ".", 0.4, 0.8, 1, true)
      GameTooltip:AddLine("Shift+drag to move the feed.", 0.6, 0.6, 0.6, true)
      GameTooltip:Show()
    end
  end)
  r:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    self.fade:Play()
  end)
  -- Shift+drag a row to move the whole feed
  r:RegisterForDrag("LeftButton")
  r:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then anchor:StartMoving() end
  end)
  r:SetScript("OnDragStop", function()
    anchor:StopMovingOrSizing()
    local point, _, rel, x, y = anchor:GetPoint()
    Settings().pos = { point, rel, x, y }
  end)
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, r) end
  table.insert(pool, r)
  return r
end

local function Fill(r)
  local done = r.after >= r.need
  local c = done and "40ff40" or "ffd100"
  r.icon:SetTexture(CR.GetItemIcon(r.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
  local _, _, quality = CR.GetItemInfo(r.itemID)
  local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
  r.name:SetText(CR.ItemName(r.itemID))
  if qc and qc.r then r.name:SetTextColor(qc.r, qc.g, qc.b) else r.name:SetTextColor(1, 1, 1) end
  r.count:SetText(CR.ColorText(string.format("%d/%d", math.min(r.before, r.need), r.need), "aaaaaa")
    .. CR.ColorText("  >  ", "888888")
    .. CR.ColorText(string.format("%d/%d", math.min(r.after, r.need), r.need), c)
    .. (done and CR.ColorText("  done", "40ff40") or ""))
  r.bar:SetColorTexture(done and 0.25 or 1, done and 1 or 0.82, done and 0.25 or 0, 0.9)
end

local function Show(itemID, before, after, need)
  if not anchor then return end
  -- the same item again while its row is up: that row carries on from where it started
  for _, r in ipairs(rows) do
    if r.itemID == itemID then
      r.after, r.need = after, need
      Fill(r)
      r.fade:Stop()
      r:SetAlpha(1)
      r.fade:Play()
      return
    end
  end
  local r = NewRow()
  r.itemID, r.before, r.after, r.need = itemID, before, after, need
  Fill(r)
  table.insert(rows, 1, r)
  while #rows > MAX_ROWS do Release(rows[#rows]) end
  Layout()
  r:SetAlpha(1)
  r:Show()
  r.fade:Stop()
  r.fade:Play()
end

local function Build()
  if anchor then return end
  anchor = CreateFrame("Frame", "CraftRouteLootFeed", UIParent)
  anchor:SetSize(ROW_W, ROW_H)
  anchor:SetFrameStrata("MEDIUM")
  anchor:SetMovable(true)
  anchor:SetClampedToScreen(true)
  Place()
  -- /cr feed move: a handle to drag it by
  local h = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  h:SetAllPoints()
  CR.Backdrop(h, 0.2, 0.5, 0.9, 0.5)
  h.text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.text:SetPoint("CENTER")
  h.text:SetText("CraftRoute loot feed - drag, then /cr feed move")
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() anchor:StartMoving() end)
  h:SetScript("OnDragStop", function()
    anchor:StopMovingOrSizing()
    local point, _, rel, x, y = anchor:GetPoint()
    Settings().pos = { point, rel, x, y }
  end)
  h:SetFrameLevel(anchor:GetFrameLevel() + 20)
  h:Hide()
  anchor.handle = h
end

---------------------------------------------------------------------------
-- Loot: the client's own (localised) "You receive loot / You create" lines
---------------------------------------------------------------------------
local FORMATS = { "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
                  "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF" }
local patterns
local function Patterns()
  if patterns then return patterns end
  patterns = {}
  for _, key in ipairs(FORMATS) do
    local fmt = _G[key]
    if type(fmt) == "string" and fmt ~= "" then
      -- escape the pattern characters (not %), then %s -> the link, %d -> the count
      local p = fmt:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
      table.insert(patterns, "^" .. p .. "$")
    end
  end
  return patterns
end

-- this character's loot line: item ID and how many, else nil
local function ParseLoot(text)
  for _, p in ipairs(Patterns()) do
    local link, n = text:match(p)
    if link then
      local id = tonumber(link:match("item:(%d+)"))
      if id then return id, tonumber(n) or 1 end
    end
  end
end

-- what the route (the profession picked in CraftRoute) needs of it in total
local function RouteNeed(itemID)
  local e = CR.GetPlans and CR.GetPlans()
  local m = e and e.plan and e.plan.byId and e.plan.byId[itemID]
  return m and m.need
end

local function Why(msg) if why then CR.Print("|cff66ccffloot feed|r " .. msg) end end

local function OnLoot(text)
  if not Settings().enabled then Why("off (/cr feed turns it on)") return end
  local id, n = ParseLoot(text or "")
  if not id then
    -- another player's loot is expected here; anything else is a line it doesn't recognise
    Why("not your loot / not a recognised line: " .. tostring(text):gsub("|", "||"))
    return
  end
  local need = RouteNeed(id)
  if not need or need <= 0 then
    local e = CR.GetPlans and CR.GetPlans()
    Why(string.format("%s x%d - no row: the %s route doesn't need it%s", CR.ItemName(id), n,
      tostring(CraftRouteCharDB and CraftRouteCharDB.profession),
      (e and e.goal) and string.format(" (its plan runs to skill %d)", e.goal) or ""))
    return
  end
  Why(string.format("%s x%d - row: the route needs %d", CR.ItemName(id), n, need))
  -- read the count once the bags really have it: the loot line can come before the bag update,
  -- and the shared count cache is only refreshed a moment after that - so wait for the bag count to
  -- move (up to 1.5s; if it never does it was already in), then count this item fresh
  local bags0 = GetItemCount(id, false) or 0
  local tries = 0
  local function Read()
    tries = tries + 1
    if (GetItemCount(id, false) or 0) == bags0 and tries < 15 then C_Timer.After(0.1, Read) return end
    if CR.InvalidateLocation then CR.InvalidateLocation(id) end
    local after = CR.HaveCount(id)
    Show(id, math.max(0, after - n), after, need)
  end
  C_Timer.After(0.1, Read)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_LOOT")
ev:SetScript("OnEvent", function(_, event, text)
  if event == "PLAYER_LOGIN" then
    Build()
  elseif event == "CHAT_MSG_LOOT" then
    CR.SafeCall(OnLoot, text)
  end
end)

-- /cr feed [move | test]
function CR.LootFeedCommand(arg)
  Build()
  local s = Settings()
  if arg == "move" then
    local h = anchor.handle
    h:SetShown(not h:IsShown())
    CR.Print(h:IsShown() and "Loot feed: drag the blue bar where you want it, then /cr feed move again."
      or "Loot feed position saved.")
  elseif arg == "test" then
    local e = CR.GetPlans and CR.GetPlans()
    local m = e and e.plan and e.plan.materials and e.plan.materials[1]
    if m then
      Show(m.id, math.max(0, m.have - 1), m.have, m.need)
    else
      CR.Print("Loot feed: the current route needs no materials to show.")
    end
  elseif arg == "why" then
    why = not why
    CR.Print("Loot feed: " .. (why and "saying in chat why each loot does or doesn't get a row (/cr feed why again to stop)."
      or "no longer explaining loot in chat."))
  elseif arg == "reset" then
    s.pos = nil
    Place()
    CR.Print("Loot feed moved back beside EllesmereUI's loot feed.")
  else
    s.enabled = not s.enabled
    CR.Print("Loot progress feed " .. (s.enabled and "on" or "off") .. ". (/cr feed move to place it, /cr feed test to see it.)")
  end
end
