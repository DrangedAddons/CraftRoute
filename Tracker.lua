-- Materials tracker: a small window of its own you can pin anywhere, open or not the rest of
-- CraftRoute is - the route's materials, what you have of what it needs. Edit picks which items
-- it shows (hidden ones are only hidden here). Move it by its title, or in EllesmereUI's unlock
-- mode. /cr tracker, or the Tracker button on the main window. Kept per character.
local _, CR = ...

local ROW_H, MAX_ROWS = 20, 30
local DEF_W, MIN_W, MAX_W, MIN_S, MAX_S = 250, 180, 520, 0.6, 2
local DEFAULT_POS = { "RIGHT", "RIGHT", -60, 120 }

local frame
local editing = false

local function Settings()
  local db = CraftRouteCharDB
  if not db then return {} end
  db.tracker = db.tracker or {}
  return db.tracker
end

-- items hidden from the tracker for this route's profession
local function Hidden(prof)
  local s = Settings()
  s.hidden = s.hidden or {}
  prof = prof or "?"
  s.hidden[prof] = s.hidden[prof] or {}
  return s.hidden[prof]
end

local function Width() return Settings().width or DEF_W end
local function Scale() return Settings().scale or 1 end
-- the profession it shows: the one popped out from the profession window's tab, else CraftRoute's
local function Prof() return Settings().prof or (CraftRouteCharDB and CraftRouteCharDB.profession) end

local function Place()
  local p = Settings().pos or DEFAULT_POS
  frame:ClearAllPoints()
  frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

local function SavePos()
  local point, _, rel, x, y = frame:GetPoint()
  Settings().pos = { point, rel, x, y }
end

local function HeaderButton(parent, text, w, tip, fn)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 18)
  b:SetText(text)
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
  b:SetScript("OnClick", fn)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(tip)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local function Row(i)
  local r = frame.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, frame.body)
  r:SetHeight(ROW_H)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
  r:SetPoint("RIGHT", frame.body, "RIGHT", 0, 0)
  r.check = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
  r.check:SetSize(18, 18)
  r.check:SetPoint("LEFT", -2, 0)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ROW_H - 4, ROW_H - 4)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.count = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.count:SetPoint("RIGHT", -2, 0)
  r.count:SetJustifyH("RIGHT")
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
  r.name:SetPoint("RIGHT", r.count, "LEFT", -6, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.06)
  r:SetScript("OnEnter", function(self)
    if not self.m then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetItemByID(self.m.id)
    GameTooltip:AddLine(string.format("Route needs %d - you have %d%s.", self.m.need, self.m.have,
      (self.m.crafted or 0) > 0 and string.format(", %d made on the way", self.m.crafted) or ""), 0.4, 0.8, 1, true)
    if editing then GameTooltip:AddLine("Untick to hide it from this list.", 0.6, 0.6, 0.6, true) end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  -- in Edit, clicking anywhere on the line ticks / unticks it
  r:SetScript("OnClick", function(self) if editing then self.check:Click() end end)
  frame.rows[i] = r
  return r
end

function CR.RefreshTracker()
  if not (frame and frame:IsShown()) then return end
  local prof = Prof()
  local e = CR.GetPlans and prof and CR.GetPlans(prof)
  local hidden = Hidden(prof)
  local cur = e and e.cur
  frame.title:SetText((prof or "CraftRoute") .. (e and e.goal and cur and CR.ColorText(string.format("  %d > %d", cur, e.goal), "aaaaaa") or ""))
  -- the materials (what you buy or gather; things the route makes itself say so), not yet had first
  local list = {}
  for _, m in ipairs(e and e.plan and e.plan.materials or {}) do
    if editing or not hidden[m.id] then table.insert(list, m) end
  end
  table.sort(list, function(a, b)
    local da, db = a.have >= a.need, b.have >= b.need
    if da ~= db then return not da end
    return a.name < b.name
  end)
  local shown = math.min(#list, MAX_ROWS)
  for i = 1, shown do
    local m, r = list[i], Row(i)
    r.m = m
    local made = m.crafted or 0
    local done = m.have >= m.need
    r.icon:SetTexture(CR.GetItemIcon(m.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    r.icon:ClearAllPoints()
    r.icon:SetPoint("LEFT", editing and 18 or 0, 0)
    r.check:SetShown(editing)
    r.check:SetChecked(not hidden[m.id])
    r.check:SetScript("OnClick", function(self)
      Hidden(prof)[m.id] = (not self:GetChecked()) or nil
      CR.RefreshTracker()
    end)
    r.name:SetText(m.name)
    local dim = editing and hidden[m.id]
    if done then r.name:SetTextColor(0.5, 0.5, 0.5) elseif dim then r.name:SetTextColor(0.45, 0.45, 0.45) else r.name:SetTextColor(1, 1, 1) end
    if made > 0 and m.have < m.need then
      r.count:SetText(CR.ColorText(string.format("%d/%d", math.min(m.have, m.need), m.need), "aaaaaa")
        .. CR.ColorText(string.format(" +%d make", made), "33ccff"))
    else
      r.count:SetText(CR.ColorText(string.format("%d/%d", math.min(m.have, m.need), m.need), done and "40ff40" or "ffd100"))
    end
    r:Show()
  end
  for i = shown + 1, #frame.rows do frame.rows[i]:Hide() end
  local note
  if not e then note = "No route for this profession."
  elseif #list == 0 then note = (e.plan.materials and #e.plan.materials > 0) and "Everything is hidden - Edit to show items."
    or "This part of the route needs no materials." end
  frame.note:SetText(note or (#list > MAX_ROWS and string.format("+%d more", #list - MAX_ROWS) or ""))
  frame.note:SetShown(frame.note:GetText() ~= "")
  local bodyH = shown * ROW_H
  local collapsed = Settings().collapsed
  frame.body:SetShown(not collapsed)
  frame.note:SetShown(not collapsed and frame.note:GetText() ~= "")
  frame:SetHeight(collapsed and 26 or (30 + bodyH + (frame.note:IsShown() and 18 or 0) + 6))
  frame.edit:SetText(editing and "Done" or "Edit")
  frame.collapse:SetText(collapsed and "+" or "-")
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, frame) end
end

local function Build()
  if frame then return end
  frame = CreateFrame("Frame", "CraftRouteTracker", UIParent, "BackdropTemplate")
  frame:SetSize(Width(), 60)
  frame:SetScale(Scale())
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  CR.Backdrop(frame, 0.04, 0.04, 0.05, 0.85)
  Place()
  frame:Hide()
  -- drag by the title bar
  local bar = CreateFrame("Frame", nil, frame)
  bar:SetPoint("TOPLEFT", 0, 0)
  bar:SetPoint("TOPRIGHT", 0, 0)
  bar:SetHeight(24)
  bar:EnableMouse(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", function() frame:StartMoving() end)
  bar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() SavePos() end)
  frame.title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.title:SetPoint("LEFT", 8, 0)
  if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(frame.title) end
  frame.close = HeaderButton(bar, "x", 18, "Close the tracker (/cr tracker opens it)", function() CR.ToggleTracker(false) end)
  frame.close:SetPoint("RIGHT", -4, 0)
  frame.collapse = HeaderButton(bar, "-", 18, "Collapse / expand", function()
    Settings().collapsed = not Settings().collapsed or nil
    CR.RefreshTracker()
  end)
  frame.collapse:SetPoint("RIGHT", frame.close, "LEFT", -2, 0)
  -- size and scale (a small panel)
  frame.size = CreateFrame("Button", nil, bar)
  frame.size:SetSize(16, 16)
  frame.size:SetPoint("RIGHT", frame.collapse, "LEFT", -3, 0)
  frame.size:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  frame.size:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  frame.size:SetScript("OnClick", function(self) CR.TrackerSizePanel(self) end)
  frame.size:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Size and scale")
    GameTooltip:Show()
  end)
  frame.size:SetScript("OnLeave", GameTooltip_Hide)
  frame.edit = HeaderButton(bar, "Edit", 40, "Pick which materials this list shows", function()
    editing = not editing
    if editing then Settings().collapsed = nil end
    CR.RefreshTracker()
  end)
  frame.edit:SetPoint("RIGHT", frame.size, "LEFT", -3, 0)
  frame.title:SetPoint("RIGHT", frame.edit, "LEFT", -4, 0)
  frame.title:SetJustifyH("LEFT")
  frame.title:SetWordWrap(false)
  frame.body = CreateFrame("Frame", nil, frame)
  frame.body:SetPoint("TOPLEFT", 8, -28)
  frame.body:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
  frame.body:SetHeight(1)
  frame.rows = {}
  frame.note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.note:SetPoint("BOTTOMLEFT", 8, 6)
  frame.note:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
  frame.note:SetJustifyH("LEFT")
  -- the corner grip: drag to make it wider / narrower (its height follows the list)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(12, 12)
  grip:SetPoint("BOTTOMRIGHT", -2, 2)
  grip:SetFrameLevel(frame:GetFrameLevel() + 10)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function(self)
    self.x0 = GetCursorPosition() / frame:GetEffectiveScale()
    self.w0 = frame:GetWidth()
    self:SetScript("OnUpdate", function()
      local x = GetCursorPosition() / frame:GetEffectiveScale()
      CR.TrackerSetSize(self.w0 + (x - self.x0), nil)
    end)
  end)
  grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
  frame.grip = grip
  frame:SetScript("OnShow", function() CR.RefreshTracker() end)
  frame:SetScript("OnHide", function() editing = false end)
end

-- New width / scale (nil: unchanged), kept per character.
function CR.TrackerSetSize(w, scale)
  local s = Settings()
  if w then s.width = math.floor(math.max(MIN_W, math.min(MAX_W, w)) + 0.5) end
  if scale then s.scale = math.max(MIN_S, math.min(MAX_S, math.floor(scale * 20 + 0.5) / 20)) end
  if not frame then return end
  frame:SetWidth(Width())
  frame:SetScale(Scale())
end

-- The size panel (the gear on the title bar): width and scale sliders, and Reset
local sizePanel
function CR.TrackerSizePanel(owner)
  if not sizePanel then
    local p = CreateFrame("Frame", "CraftRouteTrackerSize", frame, "BackdropTemplate")
    p:SetSize(240, 128)
    p:SetFrameStrata("DIALOG")
    CR.Backdrop(p, 0.05, 0.05, 0.07, 0.97)
    p:EnableMouse(true)
    p:Hide()
    local wsl = CR.MakeSlider(p, "Width", MIN_W, MAX_W, 10, Width, function(v) CR.TrackerSetSize(v, nil) end, "%d")
    wsl:SetPoint("TOPLEFT", 12, -10)
    wsl:SetPoint("RIGHT", p, "RIGHT", -12, 0)
    local ssl = CR.MakeSlider(p, "Scale", MIN_S, MAX_S, 0.05, Scale, function(v) CR.TrackerSetSize(nil, v) end, "%.2f")
    ssl:SetPoint("TOPLEFT", 12, -50)
    ssl:SetPoint("RIGHT", p, "RIGHT", -12, 0)
    local reset = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    reset:SetSize(80, 22)
    reset:SetPoint("BOTTOMLEFT", 12, 10)
    reset:SetText("Reset")
    if CR.ThemeRegisterButton then CR.ThemeRegisterButton(reset) end
    reset:SetScript("OnClick", function()
      Settings().width, Settings().scale = nil, nil
      CR.TrackerSetSize()
      wsl:Sync() ssl:Sync()
    end)
    p:SetScript("OnShow", function(self) wsl:Sync() ssl:Sync() pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
    p:SetScript("OnHide", function(self) pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
    p:SetScript("OnEvent", function(self)
      if not self:IsMouseOver() and not (self.owner and self.owner:IsMouseOver()) then self:Hide() end
    end)
    sizePanel = p
  end
  sizePanel.owner = owner
  sizePanel:ClearAllPoints()
  sizePanel:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)
  sizePanel:SetShown(not sizePanel:IsShown())
end

-- show (true) / hide (false) / toggle (nil); remembered, so it comes back after a reload. prof:
-- the profession to show (from the profession window's tab); nil keeps CraftRoute's picked one.
function CR.ToggleTracker(show, prof)
  Build()
  if show == nil then show = not frame:IsShown() or (prof ~= nil and prof ~= Prof()) end
  Settings().prof = prof
  Settings().shown = show or nil
  frame:SetShown(show)
  CR.RefreshTracker()
end

-- EllesmereUI's unlock mode: a mover like its own frames
local function RegisterUnlock()
  if not (EllesmereUI and EllesmereUI.RegisterUnlockElements and EllesmereUI.MakeUnlockElement) then return end
  EllesmereUI:RegisterUnlockElements({
    EllesmereUI.MakeUnlockElement({
      key = "CraftRouteTracker",
      label = "CraftRoute Materials Tracker",
      group = "CraftRoute",
      getFrame = function() Build() return frame end,
      getSize = function() Build() return frame:GetWidth(), frame:GetHeight() end,
      setWidth = function(_, w) CR.TrackerSetSize(w, nil) end,
      isHidden = function() return not Settings().shown end,
      savePos = function(_, point, relPoint, x, y)
        if not point then return end
        Settings().pos = { point, relPoint or point, x or 0, y or 0 }
        if not EllesmereUI._unlockActive then Place() end
      end,
      loadPos = function()
        local p = Settings().pos or DEFAULT_POS
        return { point = p[1], relPoint = p[2], x = p[3], y = p[4] }
      end,
      clearPos = function() Settings().pos = nil Place() end,
      applyPos = function() Build() Place() end,
    }),
  }, "CraftRoute")
end

-- The main window's "Tracker" button
function CR.TrackerButton(owner)
  local b = CreateFrame("Button", nil, owner, "UIPanelButtonTemplate")
  b:SetSize(80, 22)
  b:SetText("Tracker")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
  b:SetScript("OnClick", function() CR.ToggleTracker() end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Materials tracker")
    GameTooltip:AddLine("A small list of the route's materials you can pin anywhere on screen - it stays up "
      .. "with CraftRoute closed. Edit picks what it shows.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  Build()
  if Settings().shown then frame:Show() end
  CR.SafeCall(RegisterUnlock)
  -- bags, the plan, the picked profession changing: refresh
  CR.OnChange(CR.RefreshTracker)
end)
