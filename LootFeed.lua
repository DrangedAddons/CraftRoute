-- Loot progress: when you loot (or craft) something the route needs, a short row of CraftRoute's
-- own slides in - "Copper Ore   61/100" - and fades out (movable in EllesmereUI's unlock
-- mode, or with /cr feed move). /cr feed ellesmere instead writes it on the second line of
-- EllesmereUI's own loot-feed row for the item (CraftRoute's row only when that feed isn't
-- showing it). Items the route doesn't need don't show. The counts are the route's own: what it
-- needs in total, and what you have as its materials list counts it. /cr feed (on / off),
-- /cr feed test, /cr feed why. Kept per character.
local _, CR = ...
local GetItemCount = CR.GetItemCount   -- (C_Item's in Forever: there's no global GetItemCount)

local GAP, MAX_ROWS = 3, 6
-- size and scale: the settings (Loot feed panel / EllesmereUI unlock mode), else these
local DEF_W, DEF_H, DEF_SCALE = 360, 42, 1
local MIN_W, MAX_W, MIN_H, MAX_H, MIN_S, MAX_S = 200, 700, 24, 90, 0.5, 2
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

local function W() return Settings().width or DEF_W end
local function H() return Settings().height or DEF_H end
local function Scale() return Settings().scale or DEF_SCALE end

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
    r:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, (i - 1) * (H() + GAP))
  end
end

local function Release(r)
  for i, x in ipairs(rows) do if x == r then table.remove(rows, i) break end end
  r:Hide()
  r.free = true
  Layout()
end

local pool = {}
---------------------------------------------------------------------------
-- The look: EllesmereUI's loot feed settings (Forever Essentials: style, background, border,
-- quality colours, text size, how long rows stay) when "Match EllesmereUI's loot feed look" is on,
-- else CraftRoute's own. Our width / height / scale always apply.
---------------------------------------------------------------------------
local EUI_DEFAULTS = {   -- EllesmereUI's own defaults, for settings it hasn't saved
  style = "BAR", bgR = 0.05, bgG = 0.05, bgB = 0.05, bgA = 0.3, borderSize = 1,
  borderR = 0, borderG = 0, borderB = 0, qualityBorder = true, barWidth = 3, textSize = 13, duration = 5,
}
local TOAST_GOLD, TOAST_EDGE = { 0.69, 0.54, 0.23 }, { 0.35, 0.27, 0.14 }
local TOAST_TOP, TOAST_BOTTOM = { 0.19, 0.14, 0.09 }, { 0.055, 0.04, 0.024 }
local CR_BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }

local function MatchEllesmere()
  return Settings().matchEllesmere ~= false and EllesmereUI and EllesmereUI.IS_FOREVER and EllesmereUI.PP and true or false
end
local function EG(k)
  local db = EllesmereUIDB and EllesmereUIDB.lootFeed
  local v = db and db[k]
  if v == nil then v = EUI_DEFAULTS[k] end
  return v
end
local function Accent()
  local c = EllesmereUI and EllesmereUI.ELLESMERE_GREEN
  if c then return c.r, c.g, c.b end
  return 0.05, 0.82, 0.62
end
local function Gradient(tex, dir, r1, g1, b1, a1, r2, g2, b2, a2)
  tex:SetColorTexture(1, 1, 1, 1)
  if CreateColor and tex.SetGradient then
    tex:SetGradient(dir, CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
  else
    tex:SetColorTexture(r1, g1, b1, a1)
  end
end
local function Font(fs, size, fallback)
  if MatchEllesmere() and EllesmereUI.ApplyModuleFont then
    if pcall(EllesmereUI.ApplyModuleFont, fs, nil, size, "essentials") then return end
  end
  fs:SetFontObject(fallback)
end

-- Lay a row out in the current look. qc: the item's quality colour (or nil); done: has enough.
local function StyleRow(r, qc, done)
  local h = H()
  local PP = EllesmereUI and EllesmereUI.PP
  if not MatchEllesmere() then
    -- CraftRoute's own: dark plate, 1 px theme border, gold / green bar for in progress / done
    r:SetBackdrop(CR_BACKDROP)
    r:SetBackdropColor(0.05, 0.05, 0.07, 0.75)
    r:SetBackdropBorderColor(CR.ThemeBorderColor())
    r.bg:Hide()
    r.iconBg:Hide()
    if r.euiBorder and PP then pcall(PP.HideBorder, r) end
    r.bar:ClearAllPoints()
    r.bar:SetPoint("TOPLEFT", 1, -1)
    r.bar:SetPoint("BOTTOMLEFT", 1, 1)
    r.bar:SetWidth(3)
    r.bar:SetColorTexture(done and 0.25 or 1, done and 1 or 0.82, done and 0.25 or 0, 0.9)
    r.bar:Show()
    r.icon:ClearAllPoints()
    r.icon:SetSize(h - 8, h - 8)
    r.icon:SetPoint("LEFT", 9, 0)
    r.name:SetFontObject("GameFontHighlight")
    r.count:SetFontObject("GameFontNormalLarge")
    r.fadeAlpha:SetStartDelay(SHOW_FOR)
    return
  end
  -- EllesmereUI's look (its Icon Tray has no room for text: rows as Box then)
  local style = EG("style")
  if style == "TRAY" then style = "BOX" end
  local bar, toast = style == "BAR", style == "TOAST"
  r:SetBackdrop(nil)
  r.bg:Show()
  if toast then
    local a = EG("bgA")
    Gradient(r.bg, "VERTICAL", TOAST_BOTTOM[1], TOAST_BOTTOM[2], TOAST_BOTTOM[3], a, TOAST_TOP[1], TOAST_TOP[2], TOAST_TOP[3], a)
  else
    local cr, cg, cb, ca = EG("bgR"), EG("bgG"), EG("bgB"), EG("bgA")
    Gradient(r.bg, "HORIZONTAL", cr, cg, cb, ca, cr, cg, cb, bar and 0 or ca)
  end
  -- its accent bar (Bar): the item's quality colour, or the accent
  r.bar:ClearAllPoints()
  r.bar:SetPoint("TOPLEFT")
  r.bar:SetPoint("BOTTOMLEFT")
  local bw = EG("barWidth")
  local useQ = qc and EG("qualityBorder")
  if bar and bw > 0 then
    r.bar:SetWidth(bw)
    if useQ then r.bar:SetColorTexture(qc.r, qc.g, qc.b, 1) else r.bar:SetColorTexture(Accent()) end
    r.bar:Show()
  else
    r.bar:Hide()
  end
  -- the icon: inset beside the bar (Bar), framed in the quality colour (Toast), or full height (Box)
  r.icon:ClearAllPoints()
  local edge = toast and 2 or 1
  if bar then
    r.icon:SetSize(h - 8, h - 8)
    r.icon:SetPoint("LEFT", bw > 0 and bw + 5 or 4, 0)
  elseif toast then
    r.icon:SetSize(h - 10, h - 10)
    r.icon:SetPoint("LEFT", 6, 0)
  else
    r.icon:SetSize(h, h)
    r.icon:SetPoint("LEFT")
  end
  r.iconBg:ClearAllPoints()
  r.iconBg:SetPoint("TOPLEFT", r.icon, "TOPLEFT", -edge, edge)
  r.iconBg:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", edge, -edge)
  if toast then
    if useQ then r.iconBg:SetColorTexture(qc.r, qc.g, qc.b, 1)
    else r.iconBg:SetColorTexture(TOAST_EDGE[1], TOAST_EDGE[2], TOAST_EDGE[3], 1) end
  else
    r.iconBg:SetColorTexture(0, 0, 0, 1)
  end
  r.iconBg:SetShown(bar or toast)
  -- its border (not on Bar): gold on Toast, else the quality or border colour
  local size = EG("borderSize")
  if PP and not bar and size > 0 then
    if not r.euiBorder then
      r.euiBorder = pcall(PP.CreateBorder, r, 0, 0, 0, 1, 1, "OVERLAY", 2)
    end
    local br, bgc, bb
    if toast then br, bgc, bb = TOAST_GOLD[1], TOAST_GOLD[2], TOAST_GOLD[3]
    elseif useQ then br, bgc, bb = qc.r, qc.g, qc.b
    else br, bgc, bb = EG("borderR"), EG("borderG"), EG("borderB") end
    pcall(PP.UpdateBorder, r, size, br, bgc, bb, 1)
    pcall(PP.ShowBorder, r)
  elseif r.euiBorder and PP then
    pcall(PP.HideBorder, r)
  end
  local ts = EG("textSize")
  Font(r.name, ts, "GameFontHighlight")
  Font(r.count, ts + 3, "GameFontNormalLarge")
  r.fadeAlpha:SetStartDelay(EG("duration"))
end

local function NewRow()
  for _, r in ipairs(pool) do if r.free then r.free = false return r end end
  local r = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  r:SetSize(W(), H())
  r.bg = r:CreateTexture(nil, "BACKGROUND")
  r.bg:SetAllPoints()
  r.bar = r:CreateTexture(nil, "ARTWORK")
  r.iconBg = r:CreateTexture(nil, "ARTWORK")
  r.icon = r:CreateTexture(nil, "ARTWORK", nil, 1)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- one line: icon, the item, and on the right what you have now of what the route needs
  r.count = r:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  r.count:SetPoint("RIGHT", r, "RIGHT", -10, 0)
  r.count:SetJustifyH("RIGHT")
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
  r.name:SetPoint("RIGHT", r.count, "LEFT", -10, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  r.fade = r:CreateAnimationGroup()
  local a = r.fade:CreateAnimation("Alpha")
  a:SetFromAlpha(1)
  a:SetToAlpha(0)
  a:SetDuration(FADE_OUT)
  a:SetStartDelay(SHOW_FOR)
  r.fadeAlpha = a
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
  r.count:SetText(CR.ColorText(string.format("%d/%d", math.min(r.after, r.need), r.need), c))
  StyleRow(r, qc and qc.r and qc or nil, done)
  -- CraftRoute's own look: the EllesmereUI global font, if that's on
  if not MatchEllesmere() and CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, r) end
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

---------------------------------------------------------------------------
-- EllesmereUI's loot feed (Forever Essentials), when it's on: the progress goes on the second line
-- of its own row for the item, instead of a row of ours. Its rows are plain frames that keep the
-- item they show (row.data.link) and a second-line font string (row.sub); CraftRoute only writes
-- that line, after EllesmereUI has filled the row.
---------------------------------------------------------------------------
local euiAnchor
local function IsEuiRow(f)
  return type(rawget(f, "data")) == "table" and type(rawget(f, "sub")) == "table" and rawget(f, "key") ~= nil
    and type(rawget(f, "name")) == "table" and type(rawget(f, "icon")) == "table"
end
local function EuiRows()
  if not (EllesmereUI and EllesmereUI.IS_FOREVER) then return {} end
  if not euiAnchor then
    -- its feed's frame has no name: find it once, by the rows it holds
    for _, c in ipairs({ UIParent:GetChildren() }) do
      if not c:GetName() and c ~= anchor then
        for _, r in ipairs({ c:GetChildren() }) do
          if IsEuiRow(r) then euiAnchor = c break end
        end
      end
      if euiAnchor then break end
    end
  end
  local out = {}
  if euiAnchor then
    for _, r in ipairs({ euiAnchor:GetChildren() }) do
      if IsEuiRow(r) and r:IsShown() then table.insert(out, r) end
    end
  end
  return out
end

-- Put the progress on EllesmereUI's row for itemID; false if there's no such row showing
local function ShowInEllesmere(itemID, before, after, need)
  for _, r in ipairs(EuiRows()) do
    local link = r.data and r.data.link
    if type(link) == "string" and tonumber(link:match("item:(%d+)")) == itemID then
      -- its Icon Tray style is small tiles with no second line: CraftRoute's own row then
      local w = tonumber(r:GetWidth()) or 0
      if w > 0 and w < 140 then return false end
      local done = after >= need
      r.sub:SetText(CR.ColorText("Route  ", "66ccff")
        .. CR.ColorText(string.format("%d/%d", math.min(after, need), need), done and "40ff40" or "ffd100"))
      r.sub:Show()
      -- two lines: the name moves up (as EllesmereUI lays out a row with a second line)
      if r.name and r.icon and r.value then
        r.name:ClearAllPoints()
        r.name:SetPoint("RIGHT", r.value, "LEFT", -8, 0)
        r.name:SetPoint("BOTTOMLEFT", r.icon, "RIGHT", 6, 1)
      end
      return true
    end
  end
  return false
end

-- New width / height / scale (nil: unchanged), kept per character; rows already made follow.
function CR.LootFeedSetSize(w, h, scale)
  local s = Settings()
  if w then s.width = math.floor(math.max(MIN_W, math.min(MAX_W, w)) + 0.5) end
  if h then s.height = math.floor(math.max(MIN_H, math.min(MAX_H, h)) + 0.5) end
  if scale then s.scale = math.max(MIN_S, math.min(MAX_S, math.floor(scale * 20 + 0.5) / 20)) end
  if not anchor then return end
  anchor:SetSize(W(), H())
  -- a new scale keeps the feed's bottom-left corner where it is on screen (its rows grow up from it)
  local old, new = tonumber(anchor:GetScale()) or 1, Scale()
  if math.abs(old - new) > 0.001 then
    local l, bottom = anchor:GetLeft(), anchor:GetBottom()
    anchor:SetScale(new)
    if l and bottom then
      anchor:ClearAllPoints()
      anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * old / new, bottom * old / new)
      Settings().pos = { "BOTTOMLEFT", "BOTTOMLEFT", l * old / new, bottom * old / new }
    end
  end
  for _, r in ipairs(pool) do
    r:SetSize(W(), H())
    if r.itemID and not r.free then Fill(r) end
  end
  Layout()
end

local function Build()
  if anchor then return end
  anchor = CreateFrame("Frame", "CraftRouteLootFeed", UIParent)
  anchor:SetSize(W(), H())
  anchor:SetScale(Scale())
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
    local before = math.max(0, after - n)
    -- CraftRoute's own row; or (/cr feed ellesmere) on EllesmereUI's row when it shows this loot
    if not (Settings().inEllesmere and ShowInEllesmere(id, before, after, need)) then
      Show(id, before, after, need)
    end
  end
  C_Timer.After(0.1, Read)
end

-- EllesmereUI's unlock mode: CraftRoute's own rows get a mover there like EllesmereUI's frames
-- (its public RegisterUnlockElements / MakeUnlockElement - what its own modules use).
local function RegisterUnlock()
  if not (EllesmereUI and EllesmereUI.RegisterUnlockElements and EllesmereUI.MakeUnlockElement) then return end
  local function Pos()
    local p = Settings().pos or DEFAULT_POS
    return { point = p[1], relPoint = p[2], x = p[3], y = p[4] }
  end
  EllesmereUI:RegisterUnlockElements({
    EllesmereUI.MakeUnlockElement({
      key = "CraftRouteLootFeed",
      label = "CraftRoute Loot Progress",
      group = "CraftRoute",
      getFrame = function() Build() return anchor end,
      getSize = function() return W(), H() end,
      setWidth = function(_, w) CR.LootFeedSetSize(w, nil, nil) end,
      setHeight = function(_, h) CR.LootFeedSetSize(nil, h, nil) end,
      isHidden = function() return not Settings().enabled end,
      savePos = function(_, point, relPoint, x, y)
        if not point then return end
        Settings().pos = { point, relPoint or point, x or 0, y or 0 }
        if not EllesmereUI._unlockActive then Place() end
      end,
      loadPos = Pos,
      clearPos = function() Settings().pos = nil Place() end,
      applyPos = function() Build() Place() end,
    }),
  }, "CraftRoute")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_LOOT")
ev:SetScript("OnEvent", function(_, event, text)
  if event == "PLAYER_LOGIN" then
    Build()
    CR.SafeCall(RegisterUnlock)
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
  elseif arg == "ellesmere" then
    s.inEllesmere = not s.inEllesmere
    CR.Print(s.inEllesmere
      and "Loot feed: the count goes on EllesmereUI's loot-feed row for the item (CraftRoute's own row only when that feed isn't showing it)."
      or "Loot feed: CraftRoute's own rows (move them in EllesmereUI's unlock mode or with /cr feed move).")
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

---------------------------------------------------------------------------
-- Settings panel (the "Loot feed" button on the main window): on / off, where the count goes,
-- width / height / scale, and test / move / reset.
---------------------------------------------------------------------------
local panel
local function Slider(parent, label, lo, hi, step, get, set, fmt)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(250, 34)
  f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.label:SetPoint("TOPLEFT", 0, 0)
  f.label:SetText(label)
  f.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.value:SetPoint("TOPRIGHT", 0, 0)
  local sl = CreateFrame("Slider", nil, f, "BackdropTemplate")
  sl:SetOrientation("HORIZONTAL")
  sl:SetPoint("TOPLEFT", 0, -16)
  sl:SetPoint("TOPRIGHT", 0, -16)
  sl:SetHeight(12)
  CR.Backdrop(sl, 0.08, 0.08, 0.1, 0.95)
  sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  sl:SetMinMaxValues(lo, hi)
  sl:SetValueStep(step)
  if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
  sl:EnableMouseWheel(true)
  sl:SetScript("OnMouseWheel", function(self, d) self:SetValue(self:GetValue() + d * step) end)
  sl:SetScript("OnValueChanged", function(_, v)
    if f.syncing then return end
    set(v)
    f.value:SetText(string.format(fmt, get()))
  end)
  function f:Sync()
    self.syncing = true
    sl:SetValue(get())
    self.value:SetText(string.format(fmt, get()))
    self.syncing = false
  end
  return f
end

CR.MakeSlider = Slider   -- (the tracker's size panel uses it too)

local function Check(parent, label, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(22, 22)
  cb:SetHitRectInsets(0, -220, 0, 0)   -- the whole line toggles it
  cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  cb.text:SetText(label)
  cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  function cb:Sync() self:SetChecked(get() and true or false) end
  return cb
end

local function BuildPanel(owner)
  local p = CreateFrame("Frame", "CraftRouteLootFeedSettings", owner, "BackdropTemplate")
  p:SetSize(280, 300)
  p:SetFrameStrata("DIALOG")
  CR.Backdrop(p, 0.05, 0.05, 0.07, 0.97)
  p:EnableMouse(true)
  p:Hide()
  local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("Loot feed")
  if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(title) end
  local s = Settings
  local y = -32
  local items = {}
  local function Add(w, h)
    w:SetPoint("TOPLEFT", 12, y)
    if w.SetPoint and w.GetObjectType and w:GetObjectType() == "Frame" then w:SetPoint("RIGHT", p, "RIGHT", -14, 0) end
    y = y - h
    table.insert(items, w)
  end
  Add(Check(p, "Show loot progress for the route", function() return s().enabled end,
    function(v) s().enabled = v end), 24)
  if EllesmereUI and EllesmereUI.IS_FOREVER then
    Add(Check(p, "Match EllesmereUI's loot feed look", function() return s().matchEllesmere ~= false end,
      function(v)
        s().matchEllesmere = v
        for _, r in ipairs(rows) do Fill(r) end
      end), 24)
    Add(Check(p, "Put the count in EllesmereUI's loot feed", function() return s().inEllesmere end,
      function(v) s().inEllesmere = v end), 30)
  else
    y = y - 6
  end
  Add(Slider(p, "Width", MIN_W, MAX_W, 10, W, function(v) CR.LootFeedSetSize(v, nil, nil) end, "%d"), 40)
  Add(Slider(p, "Height", MIN_H, MAX_H, 1, H, function(v) CR.LootFeedSetSize(nil, v, nil) end, "%d"), 40)
  Add(Slider(p, "Scale", MIN_S, MAX_S, 0.05, Scale, function(v) CR.LootFeedSetSize(nil, nil, v) end, "%.2f"), 46)
  local function Btn(text, x, fn)
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetSize(80, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
    b:SetScript("OnClick", fn)
    return b
  end
  Btn("Test", 12, function() CR.LootFeedCommand("test") end)
  Btn("Move", 98, function() CR.LootFeedCommand("move") end)
  Btn("Reset", 184, function()
    local st = s()
    st.width, st.height, st.scale, st.pos = nil, nil, nil, nil
    CR.LootFeedSetSize()
    if anchor then Place() end
    for _, w in ipairs(items) do w:Sync() end
  end)
  y = y - 30
  local note = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  note:SetPoint("TOPLEFT", 12, y)
  note:SetPoint("RIGHT", p, "RIGHT", -12, 0)
  note:SetJustifyH("LEFT")
  note:SetWordWrap(true)
  note:SetText(EllesmereUI and "Also movable and resizable in EllesmereUI's unlock mode (\"CraftRoute Loot Progress\")."
    or "Move drags it; Reset puts size and place back.")
  p:SetHeight(-y + 40)
  function p:Sync() for _, w in ipairs(items) do w:Sync() end end
  p:SetScript("OnShow", function(self) self:Sync() pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  p:SetScript("OnHide", function(self) pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  p:SetScript("OnEvent", function(self)
    if not self:IsMouseOver() and not (self.button and self.button:IsMouseOver()) then self:Hide() end
  end)
  return p
end

-- The main window's "Loot feed" button
function CR.LootFeedButton(owner)
  local b = CreateFrame("Button", nil, owner, "UIPanelButtonTemplate")
  b:SetSize(90, 22)
  b:SetText("Loot feed")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
  b:SetScript("OnClick", function(self)
    Build()
    panel = panel or BuildPanel(owner)
    panel.button = self
    panel:ClearAllPoints()
    panel:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
    panel:SetShown(not panel:IsShown())
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Loot feed")
    GameTooltip:AddLine("When you loot something the route needs: on / off, where it shows, its size and place.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end
