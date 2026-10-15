-- All materials: one window over every profession you're leveling - each material any of their
-- routes still needs down the left, a column per profession (what that route needs of it), and the
-- total on the right (what you have of what they need together). Professions are the ones you've
-- learned whose route uses materials; an item hidden in a profession's own tracker is left out of
-- that profession's column. Open with the main window's "All" button or /cr all. Its place, scale
-- and whether it's open are kept per character (CraftRouteCharDB.trackerAll).
local _, CR = ...

local ROW_H, HEAD_H, MAX_ROWS = 20, 22, 25
local COL_W, TOTAL_W, MIN_NAME, MAX_NAME = 44, 74, 120, 220
local MIN_S, MAX_S = 0.6, 2

local frame, rows, cols, offset = nil, {}, {}, 0

local function Settings()
  local db = CraftRouteCharDB
  if not db then return {} end
  db.trackerAll = db.trackerAll or {}
  return db.trackerAll
end

-- an item hidden in that profession's own tracker
local function HiddenIn(prof, id)
  local t = CraftRouteCharDB and CraftRouteCharDB.tracker
  return t and t.hidden and t.hidden[prof] and t.hidden[prof][id] and true or false
end

-- { profs = { { name, cur, goal } }, items = { { id, name, per = { [prof] = n }, need, have, price, crafted } } }
local function Gather()
  local profs, byId, items = {}, {}, {}
  for _, name in ipairs(CR.SupportedProfessions()) do
    local _, _, detected = CR.GetSkill(name)
    local e = detected and CR.GetPlans and CR.GetPlans(name)
    local mats = e and e.plan and e.plan.materials
    local any = false
    for _, m in ipairs(mats or {}) do
      if (m.need or 0) > 0 and not HiddenIn(name, m.id) then
        any = true
        local it = byId[m.id]
        if not it then
          it = { id = m.id, name = m.name or CR.ItemName(m.id), per = {}, need = 0, have = 0, crafted = 0, price = m.price }
          byId[m.id] = it
          table.insert(items, it)
        end
        it.per[name] = (it.per[name] or 0) + m.need
        it.need = it.need + m.need
        it.have = math.max(it.have, m.have or 0)   -- (what you have is the same stock for each)
        it.crafted = it.crafted + (m.crafted or 0)
        it.price = it.price or m.price
      end
    end
    if any then table.insert(profs, { name = name, cur = e.cur, goal = e.goal }) end
  end
  -- still short first, then A to Z
  table.sort(items, function(a, b)
    local da, db = a.have >= a.need, b.have >= b.need
    if da ~= db then return not da end
    return (a.name or "") < (b.name or "")
  end)
  return profs, items
end

local function SavePos()
  local l, t = frame:GetLeft(), frame:GetTop()
  if l and t then Settings().pos = { "TOPLEFT", "BOTTOMLEFT", l, t } end
end

local function Place()
  frame:ClearAllPoints()
  frame:SetFrameStrata(CR.PopoutStrata and CR.PopoutStrata() or "HIGH")
  local p = Settings().pos
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120) end
end

local function Cell(parent, justify, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetJustifyH(justify)
  fs:SetWordWrap(false)
  return fs
end

local function Row(i)
  local r = rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, frame.body)
  r:SetHeight(ROW_H)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ROW_H - 4, ROW_H - 4)
  r.icon:SetPoint("LEFT", 0, 0)
  r.name = Cell(r, "LEFT")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
  r.cells = {}
  r.total = Cell(r, "RIGHT")
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.06)
  r:SetScript("OnEnter", function(self)
    local it = self.it
    if not it then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetItemByID(it.id)
    for _, p in ipairs(frame.profs or {}) do
      local n = it.per[p.name]
      if n then GameTooltip:AddDoubleLine(p.name, tostring(n), 0.8, 0.8, 0.8, 1, 1, 1) end
    end
    GameTooltip:AddLine(string.format("Together %d - you have %d%s.", it.need, it.have,
      it.crafted > 0 and string.format(", %d made on the way", it.crafted) or ""), 0.4, 0.8, 1, true)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:RegisterForDrag("LeftButton")
  r:SetScript("OnDragStart", function() frame:StartMoving() end)
  r:SetScript("OnDragStop", function() frame:StopMovingOrSizing() SavePos() end)
  rows[i] = r
  if CR.NoteThemeFonts then CR.NoteThemeFonts(r) end
  return r
end

-- a profession's column heading: its icon (its name and route on hover)
local function Col(i)
  local c = cols[i]
  if c then return c end
  c = CreateFrame("Frame", nil, frame)
  c:SetSize(COL_W, HEAD_H)
  c.icon = c:CreateTexture(nil, "ARTWORK")
  c.icon:SetSize(18, 18)
  c.icon:SetPoint("RIGHT", -2, 0)
  c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  c:EnableMouse(true)
  c:SetScript("OnEnter", function(self)
    local p = self.p
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(p.name)
    if p.cur and p.goal then GameTooltip:AddLine(string.format("Route %d > %d", p.cur, p.goal), 1, 1, 1) end
    GameTooltip:Show()
  end)
  c:SetScript("OnLeave", GameTooltip_Hide)
  cols[i] = c
  return c
end

local function Refresh()
  if not (frame and frame:IsShown()) then return end
  local profs, items = Gather()
  frame.profs = profs
  -- the name column: as wide as the longest name (within limits)
  local m = frame.measure
  local nameW = MIN_NAME
  for _, it in ipairs(items) do
    m:SetText(it.name or "")
    nameW = math.max(nameW, (tonumber(m:GetStringWidth()) or 0) + 4)
  end
  nameW = math.min(MAX_NAME, math.ceil(nameW))
  local left = 8 + (ROW_H - 4) + 5 + nameW
  local width = left + #profs * COL_W + TOTAL_W + 8 + 10

  -- headings
  for i, p in ipairs(profs) do
    local c = Col(i)
    c.p = p
    c.icon:SetTexture(CR.ProfessionIcon and CR.ProfessionIcon(p.name) or "Interface\\Icons\\INV_Misc_QuestionMark")
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", frame, "TOPLEFT", left + (i - 1) * COL_W, -28)
    c:Show()
  end
  for i = #profs + 1, #cols do cols[i]:Hide() end
  frame.totalHead:ClearAllPoints()
  frame.totalHead:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -28 - 5)

  -- rows
  local vis = math.min(#items, MAX_ROWS)
  offset = math.max(0, math.min(offset, #items - vis))
  local top = 28 + HEAD_H + 2
  for i = 1, vis do
    local it, r = items[offset + i], Row(i)
    r.it = it
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -top - (i - 1) * ROW_H)
    r:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    r.icon:SetTexture(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(it.id) or (GetItemIcon and GetItemIcon(it.id)))
    r.name:SetWidth(nameW)
    r.name:SetText(it.name or "?")
    for j, p in ipairs(profs) do
      local fs = r.cells[j]
      if not fs then fs = Cell(r, "RIGHT") r.cells[j] = fs end
      fs:ClearAllPoints()
      fs:SetPoint("RIGHT", r, "LEFT", left - 8 + j * COL_W - 2, 0)
      fs:SetWidth(COL_W - 4)
      local n = it.per[p.name]
      fs:SetText(n and tostring(n) or CR.ColorText("-", "555555"))
      fs:Show()
    end
    for j = #profs + 1, #r.cells do r.cells[j]:Hide() end
    r.total:ClearAllPoints()
    r.total:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.total:SetWidth(TOTAL_W)
    local enough = it.have >= it.need
    r.total:SetText(CR.ColorText(string.format("%d/%d", it.have, it.need), enough and "40ff40" or "ffd100")
      .. ((it.crafted > 0 and not enough) and CR.ColorText(" +", "33ccff") or ""))
    r:Show()
  end
  for i = vis + 1, #rows do rows[i]:Hide() end

  -- the scroll mark, when there's more than fits
  local scrolling = #items > vis
  frame.track:SetShown(scrolling)
  frame.thumb:SetShown(scrolling)
  if scrolling then
    local trackH = vis * ROW_H
    frame.track:ClearAllPoints()
    frame.track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -top)
    frame.track:SetHeight(trackH)
    local thumbH = math.max(12, trackH * vis / #items)
    frame.thumb:ClearAllPoints()
    frame.thumb:SetPoint("TOP", frame.track, "TOP", 0, -(trackH - thumbH) * offset / math.max(1, #items - vis))
    frame.thumb:SetHeight(thumbH)
  end

  -- what's still to buy (not what a route makes itself), as the trackers count it
  local cost, unpriced = 0, 0
  for _, it in ipairs(items) do
    local missing = it.need - it.have
    if missing > 0 and it.crafted == 0 then
      if it.price then cost = cost + it.price * missing else unpriced = unpriced + 1 end
    end
  end
  frame.cost:SetText(#items > 0 and (CR.ColorText("Cost  ", "aaaaaa") .. CR.FormatMoney(cost)
    .. (unpriced > 0 and CR.ColorText(string.format("  (+%d unpriced)", unpriced), "ff9966") or "")) or "")
  frame.empty:SetShown(#items == 0)
  frame:SetSize(math.max(width, 260), top + math.max(1, vis) * ROW_H + 30)
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, frame) end
end

local function Build()
  if frame then return end
  frame = CreateFrame("Frame", "CraftRouteAllMaterials", UIParent, "BackdropTemplate")
  frame:SetSize(400, 200)
  frame:SetScale(Settings().scale or 1)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  if frame.SetDontSavePosition then pcall(frame.SetDontSavePosition, frame, true) end
  CR.Backdrop(frame, 0.04, 0.04, 0.05, 0.85)
  frame:Hide()
  -- moved by any free space (the rows too)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() frame:StartMoving() end)
  frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() SavePos() end)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.title:SetPoint("TOPLEFT", 8, -8)
  frame.title:SetText("All Materials")
  if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(frame.title) end
  frame.close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.close:SetSize(18, 18)
  frame.close:SetPoint("TOPRIGHT", -4, -4)
  frame.close:SetText("x")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(frame.close) end
  frame.close:SetScript("OnClick", function() CR.ToggleAllMaterials(false) end)

  frame.itemHead = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.itemHead:SetText("Material")
  frame.itemHead:SetPoint("TOPLEFT", 8, -28 - 5)
  frame.totalHead = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.totalHead:SetText("Total")
  frame.body = frame
  frame.measure = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.measure:SetAlpha(0)

  frame.track = frame:CreateTexture(nil, "ARTWORK")
  frame.track:SetWidth(4)
  frame.track:SetColorTexture(1, 1, 1, 0.08)
  frame.thumb = frame:CreateTexture(nil, "OVERLAY")
  frame.thumb:SetWidth(4)
  frame.thumb:SetColorTexture(1, 0.82, 0.35, 0.6)

  frame.cost = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.cost:SetPoint("BOTTOMLEFT", 8, 9)
  frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.empty:SetPoint("TOPLEFT", 8, -28 - HEAD_H - 4)
  frame.empty:SetText("No materials needed - none of your professions' routes uses any right now.")

  -- the wheel scrolls; Ctrl+wheel scales
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    if IsControlKeyDown() then
      local s = math.max(MIN_S, math.min(MAX_S, math.floor(((Settings().scale or 1) + delta * 0.05) * 20 + 0.5) / 20))
      local l, t = frame:GetLeft(), frame:GetTop()
      local old = frame:GetScale()
      Settings().scale = s
      frame:SetScale(s)
      -- (the top-left corner stays put on screen)
      if l and t then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * old / s, t * old / s)
        SavePos()
      end
      return
    end
    offset = offset - delta * 3
    Refresh()
  end)
  Place()
end

-- show (true) / hide (false) / toggle (nil); remembered, so it comes back after a reload
function CR.ToggleAllMaterials(show)
  Build()
  if show == nil then show = not frame:IsShown() end
  Settings().shown = show or nil
  if show then Place() end
  frame:SetShown(show)
  Refresh()
end
CR.RefreshAllMaterials = Refresh

-- The main window's "All" button (beside "Tracker")
function CR.AllMaterialsButton(owner)
  local b = CreateFrame("Button", nil, owner, "UIPanelButtonTemplate")
  b:SetSize(44, 22)
  b:SetText("All")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
  b:SetScript("OnClick", function() CR.ToggleAllMaterials() end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("All materials")
    GameTooltip:AddLine("One window with every material your professions' routes still need: a column per "
      .. "profession, and the total you need of each against what you have.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGOUT" then
    if frame and frame:IsShown() then SavePos() end
    return
  end
  if Settings().shown then CR.ToggleAllMaterials(true) end
  -- bags, plans, skills changing: refresh
  CR.OnChange(Refresh)
end)
