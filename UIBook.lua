-- The game's Professions book (K): each section you haven't learned yet ("Visit a trainer...")
-- gets CraftRoute's picker instead. First / Second Profession: a big icon - click it for every
-- primary profession's icon, pick one - and beside it the nearest trainers who teach it, with
-- map pins. Cooking / Fishing / First Aid: their nearest trainers. Once a section is learned it's
-- Blizzard's own again.
local _, CR = ...

local PRIMARY = { "PrimaryProfession1", "PrimaryProfession2" }
local SECONDARY = { "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3" }
local SECONDARY_NAMES = { "Cooking", "Fishing", "First Aid" }   -- the book's order
local EMPTY_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"   -- "pick one" placeholder

local hooked, built, hidden = false, {}, {}   -- (kept here, not on Blizzard's frames)
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

-- Blizzard's "Visit a trainer..." text in an empty section: hidden while ours shows, back after
local function BlizzardText(f)
  local list = {}
  for _, k in ipairs({ "missingText", "MissingText" }) do
    local v = rawget(f, k)
    if type(v) == "table" and v.SetAlpha then table.insert(list, v) end
  end
  for _, r in ipairs({ f:GetRegions() }) do
    if r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText then
      local t = r:GetText()
      if type(t) == "string" and t:find("^Visit a") then table.insert(list, r) end
    end
  end
  return list
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
    self.icon.tex:SetDesaturated(false)
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

-- Which secondary each section is: its header text if it says, else the book's order
local function SecondaryName(f, i)
  for _, r in ipairs({ f:GetRegions() }) do
    if r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText then
      local t = r:GetText()
      for _, n in ipairs(SECONDARY_NAMES) do if t == n then return n end end
    end
  end
  return SECONDARY_NAMES[i]
end

function CR.RefreshBook()
  local book = ProfessionsBookFrame
  if not (book and book:IsShown()) then return end
  local prof1, prof2 = nil, nil
  if GetProfessions then prof1, prof2 = GetProfessions() end
  local learned = Learned()
  local function Section(fname, empty, make)
    local f = _G[fname]
    if not f then return end
    local o = built[fname]
    if empty and not o then o = make(f); built[fname] = o end
    if o then
      o:SetShown(empty)
      if empty then o:Refresh() end
    end
    -- Blizzard's own text: hidden while ours shows
    if empty then
      hidden[f] = BlizzardText(f)
      for _, r in ipairs(hidden[f]) do r:SetAlpha(0) end
    elseif hidden[f] then
      for _, r in ipairs(hidden[f]) do r:SetAlpha(1) end
      hidden[f] = nil
    end
  end
  Section(PRIMARY[1], prof1 == nil, function(f) return BuildPrimary(f, 1) end)
  Section(PRIMARY[2], prof2 == nil, function(f) return BuildPrimary(f, 2) end)
  for i, fname in ipairs(SECONDARY) do
    local f = _G[fname]
    if f then
      local name = SecondaryName(f, i)
      Section(fname, not learned[name], function(sf) return BuildSecondary(sf, name) end)
    end
  end
end

local function Hook()
  if hooked or not ProfessionsBookFrame then return end
  hooked = true
  ProfessionsBookFrame:HookScript("OnShow", function() CR.SafeCall(CR.RefreshBook) end)
  ProfessionsBookFrame:HookScript("OnHide", function() if picker then picker:Hide() end end)
  if type(ProfessionsBookFrame_Update) == "function" then
    hooksecurefunc("ProfessionsBookFrame_Update", function() CR.SafeCall(CR.RefreshBook) end)
  end
  CR.SafeCall(CR.RefreshBook)
end

local watch = CreateFrame("Frame")
watch:RegisterEvent("ADDON_LOADED")
watch:RegisterEvent("PLAYER_LOGIN")
watch:RegisterEvent("SKILL_LINES_CHANGED")
watch:SetScript("OnEvent", function(_, event, name)
  if event == "SKILL_LINES_CHANGED" then
    CR.SafeCall(CR.RefreshBook)
  elseif event == "PLAYER_LOGIN" or name == "Blizzard_ProfessionsBook" then
    Hook()
  end
end)
