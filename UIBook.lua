-- The game's Professions book (K): each section you haven't learned yet ("Visit a trainer...")
-- gets CraftRoute's picker instead. First / Second Profession: a big icon - click it for every
-- primary profession's icon, pick one - and beside it the nearest trainers who teach it, with
-- map pins. Cooking / Fishing / First Aid: their nearest trainers. Once a section is learned it's
-- Blizzard's own again.
local _, CR = ...

local EMPTY_ICON = "Interface\\Icons\\INV_Misc_Book_09"   -- "pick one" placeholder (drawn dull brown in Refresh)

local built, hidden, ours = {}, {}, {}   -- per section frame (kept here, not on Blizzard's frames); our overlays
local picker   -- the shared icon grid

local function Info(name)
  for _, g in ipairs(CR.PROFESSION_GROUPS or {}) do
    for _, spec in ipairs(g.list) do
      if spec[1] == name then return spec end
    end
  end
end

local function Picks()
  local db = CraftRouteCharDB
  if not db then return {} end
  db.bookPicks = db.bookPicks or {}
  return db.bookPicks
end

local function Learned()
  local set = {}
  for _, n in ipairs(CR.LearnedProfessionNames and CR.LearnedProfessionNames() or {}) do set[n] = true end
  return set
end

-- Trainer rows: Pin + name and zone (distance)
local function TrainerRows(host, n, width)
  local rows = {}
  for i = 1, n do
    local r = CreateFrame("Frame", nil, host)
    r:SetSize(width, 24)
    r.pin = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
    r.pin:SetSize(40, 20)
    r.pin:SetPoint("LEFT", 0, 0)
    r.pin:SetText("Pin")
    CR.ThemeRegisterButton(r.pin)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", r.pin, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(true)
    rows[i] = r
  end
  return rows
end

local function FillTrainers(o, prof)
  local near = prof and CR.NearestTrainers and CR.NearestTrainers(prof, 1, #o.rows) or {}
  for i, r in ipairs(o.rows) do
    local t = near[i]
    if t then
      local where = t.zone or ""
      if t.dist then where = where .. string.format(" (%d yd)", math.floor(t.dist / 10 + 0.5) * 10)
      elseif t.far then where = where .. " (other continent)" end
      r.text:SetText(t.name .. "\n" .. CR.ColorText(where, "aaaaaa"))
      r.pin:SetScript("OnClick", function() CR.PinPlace(t) end)
      r:Show()
    else
      r:Hide()
    end
  end
  if not prof then
    o.note:SetText("")
  elseif #near == 0 then
    o.note:SetText(type(TrainerSpellsProfessionTrainers) == "table"
      and "No trainer for your faction in the data - ask a city guard."
      or "Install TrainerSpells for trainer pins - or ask a city guard.")
  else
    o.note:SetText("")
  end
end

-- The icon grid that drops down from a First / Second Profession icon
local function Picker()
  if picker then return picker end
  local p = CreateFrame("Frame", "CraftRouteBookPicker", UIParent, "BackdropTemplate")
  p:SetFrameStrata("FULLSCREEN_DIALOG")
  CR.Backdrop(p, 0.05, 0.05, 0.07, 0.97)
  p:EnableMouse(true)
  p:Hide()
  p.buttons = {}
  local COLS, SIZE, GAP = 3, 40, 6
  local i = 0
  for _, g in ipairs(CR.PROFESSION_GROUPS or {}) do
    if g.title ~= "" and not g.title:find("^Secondary") then
      for _, spec in ipairs(g.list) do
        i = i + 1
        local b = CreateFrame("Button", nil, p)
        b:SetSize(SIZE, SIZE)
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        b:SetPoint("TOPLEFT", 8 + col * (SIZE + GAP), -8 - row * (SIZE + GAP))
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexture(spec[2])
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b.spec = spec
        b:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText(spec[1])
          GameTooltip:AddLine(spec[3], 1, 1, 1, true)
          if self.taken then GameTooltip:AddLine(self.taken, 1, 0.5, 0.4, true) end
          GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        b:SetScript("OnClick", function(self)
          if self.taken then return end
          Picks()[p.slot] = spec[1]
          p:Hide()
          if p.onPick then p.onPick() end
        end)
        table.insert(p.buttons, b)
      end
    end
  end
  local rows = math.ceil(i / COLS)
  p:SetSize(16 + COLS * SIZE + (COLS - 1) * GAP, 16 + rows * SIZE + (rows - 1) * GAP)
  -- a click anywhere else closes it (Frame:IsMouseOver - Forever has no global MouseIsOver)
  p:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  p:SetScript("OnHide", function(self) pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  p:SetScript("OnEvent", function(self)
    if not self:IsMouseOver() and not (self.anchor and self.anchor:IsMouseOver()) then self:Hide() end
  end)
  picker = p
  return p
end

local function OpenPicker(o)
  local p = Picker()
  if p:IsShown() and p.slot == o.slot then p:Hide() return end
  p.slot, p.anchor, p.onPick = o.slot, o.icon, function() CR.SafeCall(CR.RefreshBook) end
  local learned, picks = Learned(), Picks()
  local other = picks[o.slot == 1 and 2 or 1]
  for _, b in ipairs(p.buttons) do
    local name = b.spec[1]
    b.taken = learned[name] and "Already learned." or (name == other and "Picked for your other profession.") or false
    b.icon:SetDesaturated(b.taken ~= nil)
    b.icon:SetAlpha(b.taken and 0.45 or 1)
  end
  p:ClearAllPoints()
  p:SetPoint("TOPLEFT", o.icon, "BOTTOMLEFT", 0, -4)
  p:Show()
end

-- First / Second Profession: icon (click to pick) and name, trainers to the right
local function BuildPrimary(f, slot)
  local o = CreateFrame("Frame", nil, f)
  o:SetAllPoints()
  o:SetFrameLevel(f:GetFrameLevel() + 5)
  o.slot = slot
  o.icon = CreateFrame("Button", nil, o)
  o.icon:SetSize(52, 52)
  o.icon:SetPoint("TOPLEFT", 26, -44)
  o.icon.tex = o.icon:CreateTexture(nil, "ARTWORK")
  o.icon.tex:SetAllPoints()
  o.icon.border = o.icon:CreateTexture(nil, "OVERLAY")
  o.icon.border:SetPoint("TOPLEFT", -2, 2)
  o.icon.border:SetPoint("BOTTOMRIGHT", 2, -2)
  o.icon.border:SetColorTexture(1, 0.82, 0, 0.0)
  o.icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  o.icon:SetScript("OnClick", function() OpenPicker(o) end)
  o.icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Pick a profession")
    GameTooltip:AddLine("Click to choose from every primary profession.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  o.icon:SetScript("OnLeave", GameTooltip_Hide)
  o.name = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  o.name:SetPoint("TOPLEFT", o.icon, "TOPRIGHT", 12, -4)
  o.sub = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  o.sub:SetPoint("TOPLEFT", o.name, "BOTTOMLEFT", 0, -4)
  o.sub:SetWidth(230)
  o.sub:SetJustifyH("LEFT")
  o.sub:SetWordWrap(true)
  o.head = o:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  o.head:SetPoint("TOPLEFT", o, "TOPLEFT", 380, -22)
  o.head:SetText("Nearest trainers")
  o.rows = TrainerRows(o, 3, 340)
  for i, r in ipairs(o.rows) do r:SetPoint("TOPLEFT", o.head, "BOTTOMLEFT", 0, -4 - (i - 1) * 30) end
  o.note = o:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  o.note:SetPoint("TOPLEFT", o.head, "BOTTOMLEFT", 0, -6)
  o.note:SetWidth(340)
  o.note:SetJustifyH("LEFT")
  function o:Refresh()
    local prof = Picks()[slot]
    if prof and Learned()[prof] then prof = nil end   -- learned it in the other section
    local spec = prof and Info(prof)
    self.icon.tex:SetTexture(spec and spec[2] or EMPTY_ICON)
    -- nothing picked: the book drawn grey and tinted the window's brown, like an empty mold
    self.icon.tex:SetDesaturated(spec == nil)
    if spec then self.icon.tex:SetVertexColor(1, 1, 1, 1) else self.icon.tex:SetVertexColor(0.62, 0.47, 0.30, 0.9) end
    self.name:SetText(spec and spec[1] or "Select a profession")
    self.sub:SetText(spec and spec[3] or "Click the icon to pick one.")
    self.head:SetShown(spec ~= nil)
    FillTrainers(self, spec and spec[1])
  end
  return o
end

-- Cooking / Fishing / First Aid: the nearest trainers
local function BuildSecondary(f, prof)
  local o = CreateFrame("Frame", nil, f)
  o:SetAllPoints()
  o:SetFrameLevel(f:GetFrameLevel() + 5)
  o.head = o:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  o.head:SetPoint("TOPLEFT", o, "TOPLEFT", 18, -52)
  o.head:SetText("Nearest trainers")
  local w = math.max(150, (f:GetWidth() or 250) - 36)
  o.rows = TrainerRows(o, 3, w)
  for i, r in ipairs(o.rows) do r:SetPoint("TOPLEFT", o.head, "BOTTOMLEFT", 0, -4 - (i - 1) * 30) end
  o.note = o:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  o.note:SetPoint("TOPLEFT", o.head, "BOTTOMLEFT", 0, -6)
  o.note:SetWidth(w)
  o.note:SetJustifyH("LEFT")
  o.note:SetWordWrap(true)
  function o:Refresh() FillTrainers(self, prof) end
  return o
end

-- The sections are found by their headers ("First Profession", "Cooking"...) wherever they sit -
-- the crafting window's Professions page (its overview tab) or the Professions book - and are
-- only taken over while Blizzard's "Visit a trainer..." text shows in them.
local HEADERS = { ["First Profession"] = 1, ["Second Profession"] = 2,
                  Cooking = "Cooking", Fishing = "Fishing", ["First Aid"] = "First Aid" }

local function Regions(f)
  local ok, list = pcall(function() return { f:GetRegions() } end)
  return ok and list or {}
end
local function Children(f)
  local ok, list = pcall(function() return { f:GetChildren() } end)
  return ok and list or {}
end

-- every visible frame under root holding a section header; { host, kind, visit = FontStrings }
local function Scan(root, out, depth)
  if depth > 9 or not (root and root.IsVisible and root:IsVisible()) then return end
  local kind, visit = nil, {}
  for _, r in ipairs(Regions(root)) do
    if r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText then
      local t = r:GetText()
      if type(t) == "string" then
        if HEADERS[t] then kind = HEADERS[t] end
        if t:find("^Visit a") then table.insert(visit, r) end
      end
    end
  end
  if kind then table.insert(out, { host = root, kind = kind, visit = visit }) end
  for _, c in ipairs(Children(root)) do
    if not ours[c] then Scan(c, out, depth + 1) end   -- (not into our own overlays)
  end
end

function CR.RefreshBook()
  local found = {}
  for _, root in ipairs({ ProfessionsFrame, ProfessionsBookFrame }) do
    if root and root:IsShown() then Scan(root, found, 0) end
  end
  if #found == 0 then return end
  local prof1, prof2 = nil, nil
  if GetProfessions then prof1, prof2 = GetProfessions() end
  local learned = Learned()
  for _, sec in ipairs(found) do
    local f, kind = sec.host, sec.kind
    local visitShown = false
    for _, r in ipairs(sec.visit) do if r:IsShown() then visitShown = true end end
    local notLearned
    if kind == 1 then notLearned = prof1 == nil
    elseif kind == 2 then notLearned = prof2 == nil
    else notLearned = not learned[kind] end
    local empty = visitShown and notLearned
    local o = built[f]
    if empty and not o then
      o = (type(kind) == "number") and BuildPrimary(f, kind) or BuildSecondary(f, kind)
      built[f] = o
      ours[o] = true   -- (Scan skips it)
    end
    if o then
      o:SetShown(empty)
      if empty then o:Refresh() end
    end
    -- Blizzard's own text: hidden while ours shows, back once the section's learned
    if empty then
      hidden[f] = sec.visit
      for _, r in ipairs(sec.visit) do r:SetAlpha(0) end
    elseif hidden[f] then
      for _, r in ipairs(hidden[f]) do r:SetAlpha(1) end
      hidden[f] = nil
    end
  end
end

local function Soon()
  CR.SafeCall(CR.RefreshBook)
  C_Timer.After(0.05, function() CR.SafeCall(CR.RefreshBook) end)
  C_Timer.After(0.3, function() CR.SafeCall(CR.RefreshBook) end)
end

local hookedPF, hookedBook = false, false
local function Hook()
  if ProfessionsFrame and not hookedPF then
    hookedPF = true
    ProfessionsFrame:HookScript("OnShow", Soon)
    ProfessionsFrame:HookScript("OnHide", function() if picker then picker:Hide() end end)
    if ProfessionsFrame.SetTab then hooksecurefunc(ProfessionsFrame, "SetTab", Soon) end
    if ProfessionsFrame.RightTabSelected then hooksecurefunc(ProfessionsFrame, "RightTabSelected", Soon) end
  end
  if ProfessionsBookFrame and not hookedBook then
    hookedBook = true
    ProfessionsBookFrame:HookScript("OnShow", Soon)
    ProfessionsBookFrame:HookScript("OnHide", function() if picker then picker:Hide() end end)
    if type(ProfessionsBookFrame_Update) == "function" then
      hooksecurefunc("ProfessionsBookFrame_Update", Soon)
    end
  end
end

local watch = CreateFrame("Frame")
watch:RegisterEvent("ADDON_LOADED")
watch:RegisterEvent("PLAYER_LOGIN")
watch:RegisterEvent("SKILL_LINES_CHANGED")
watch:SetScript("OnEvent", function(_, event)
  if event == "SKILL_LINES_CHANGED" then
    Soon()
  else
    Hook()   -- the windows load on demand: try again as each addon loads
  end
end)
