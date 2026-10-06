-- Main window + Plan tab.
local _, CR = ...
local GetItemInfo, GetItemCount, GetItemIcon, IsEquippedItem = CR.GetItemInfo, CR.GetItemCount, CR.GetItemIcon, CR.IsEquippedItem

local ROW_H = 18
local OPTION_BUTTON_W = 84   -- the "Choose" button on alternative rows
local frame

---------------------------------------------------------------------------
-- Shared widgets
---------------------------------------------------------------------------
-- Virtual scrolling list with mouse wheel + a draggable scrollbar.
-- Self-contained (no FauxScrollFrame/UIDropDownMenu) so it doesn't depend on Classic-only templates.
-- updateRow(row, item, index) fills a row from data.
local function Backdrop(f, r, g, b, a)
  f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  f:SetBackdropColor(r, g, b, a)
  f:SetBackdropBorderColor(CR.ThemeBorderColor())
  CR.ThemeRegisterBorder(f)   -- recoloured when the theme changes
end
CR.Backdrop = Backdrop

function CR.CreateList(name, parent, width, height, createRow, updateRow)
  local list = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  list:SetSize(width, height)
  Backdrop(list, 0, 0, 0, 0.35)
  list.data = {}
  list.rows = {}
  list.offset = 0
  -- Rows fill whatever height the list has; the window can be resized, so this changes.
  local visible = math.floor((height - 4) / ROW_H)

  local track = CreateFrame("Frame", nil, list, "BackdropTemplate")
  track:SetPoint("TOPRIGHT", -2, -2)
  track:SetPoint("BOTTOMRIGHT", -2, 2)
  track:SetWidth(10)
  Backdrop(track, 0.1, 0.1, 0.1, 0.8)
  local thumb = track:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0.6, 0.6, 0.6, 0.9)
  thumb:SetWidth(8)

  local function MaxOffset() return math.max(0, #list.data - visible) end

  function list:SetOffset(o)
    self.offset = math.max(0, math.min(MaxOffset(), math.floor(o + 0.5)))
    self:Refresh()
  end

  local function MakeRow(i)
    local row = CreateFrame("Button", nil, list)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 4, -2 - (i - 1) * ROW_H)
    row:SetPoint("RIGHT", track, "LEFT", -2, 0)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    createRow(row)
    list.rows[i] = row
    return row
  end

  function list:Refresh()
    local h = self:GetHeight()
    if type(h) == "number" and h > 0 then visible = math.max(1, math.floor((h - 4) / ROW_H)) end
    for i = #self.rows + 1, visible do MakeRow(i) end
    for i = visible + 1, #self.rows do self.rows[i]:Hide() end
    if self.offset > MaxOffset() then self.offset = MaxOffset() end
    for i = 1, visible do
      local row = self.rows[i]
      local item = self.data[self.offset + i]
      if item then
        updateRow(row, item, self.offset + i)
        row:Show()
      else
        row:Hide()
      end
    end
    local total = #self.data
    if total <= visible then
      track:Hide()
    else
      track:Show()
      local th = track:GetHeight() - 2
      local h = math.max(16, th * visible / total)
      thumb:SetHeight(h)
      thumb:ClearAllPoints()
      thumb:SetPoint("TOP", track, "TOP", 0, -1 - (th - h) * self.offset / MaxOffset())
    end
  end

  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(self, delta) self:SetOffset(self.offset - delta * 3) end)

  local function OffsetFromCursor()
    local _, y = GetCursorPosition()
    y = y / track:GetEffectiveScale()
    local frac = (track:GetTop() - y) / track:GetHeight()
    list:SetOffset(frac * (MaxOffset() + 1) - 0.5)
  end
  track:EnableMouse(true)
  track:SetScript("OnMouseDown", function(self)
    OffsetFromCursor()
    self:SetScript("OnUpdate", OffsetFromCursor)
  end)
  track:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)

  for i = 1, visible do MakeRow(i) end
  list:SetScript("OnSizeChanged", function(self)
    if self.onResize then self.onResize(self) end
    self:Refresh()
  end)
  return list
end

-- Simple dropdown: a button that opens a list of options below it.
-- options: { {value=, text=} } (or a function returning that), getter() -> value, setter(value)
local openMenu
function CR.CreateDropdown(parent, width, options, getter, setter)
  local dd = CreateFrame("Button", nil, parent, "BackdropTemplate")
  dd:SetSize(width, 20)
  Backdrop(dd, 0.08, 0.08, 0.08, 0.9)
  dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dd.text:SetPoint("LEFT", 6, 0)
  dd.text:SetPoint("RIGHT", -16, 0)
  dd.text:SetJustifyH("LEFT")
  dd.text:SetWordWrap(false)
  local arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  arrow:SetPoint("RIGHT", -5, 0)
  arrow:SetText("v")
  local hl = dd:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.08)

  local function Opts() return type(options) == "function" and options() or options end

  local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetClampedToScreen(true)
  Backdrop(menu, 0.05, 0.05, 0.05, 0.97)
  menu:Hide()
  menu.buttons = {}

  local function BuildMenu()
    local opts = Opts()
    for i, o in ipairs(opts) do
      local b = menu.buttons[i]
      if not b then
        b = CreateFrame("Button", nil, menu)
        b:SetHeight(18)
        b:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 18)
        b:SetPoint("RIGHT", -2, 0)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 6, 0)
        local bhl = b:CreateTexture(nil, "HIGHLIGHT")
        bhl:SetAllPoints()
        bhl:SetColorTexture(0.2, 0.6, 1, 0.3)
        menu.buttons[i] = b
      end
      local selected = getter() == o.value
      b.text:SetText((selected and "|cff33ccff> |r" or "   ") .. o.text)
      b:SetScript("OnClick", function()
        menu:Hide()
        setter(o.value)
        dd:Sync()
      end)
      b:Show()
    end
    for i = #opts + 1, #menu.buttons do menu.buttons[i]:Hide() end
    menu:SetSize(math.max(width, 160), #opts * 18 + 4)
  end

  dd:SetScript("OnClick", function()
    if menu:IsShown() then menu:Hide() return end
    if openMenu and openMenu ~= menu then openMenu:Hide() end
    BuildMenu()
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
    menu:Show()
    openMenu = menu
  end)
  dd:SetScript("OnHide", function() menu:Hide() end)

  function dd:Sync()
    local v = getter()
    for _, o in ipairs(Opts()) do
      if o.value == v then self.text:SetText(o.text) return end
    end
    self.text:SetText(tostring(v))
  end
  dd:Sync()
  return dd
end

function CR.ColorText(text, hex) return "|cff" .. hex .. text .. "|r" end

local function QualityHex(q)
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c and c.hex then return c.hex:sub(5) end -- "|cffRRGGBB"
  return "ffffff"
end
CR.QualityHex = QualityHex

function CR.ItemMinLevel(itemID)
  if not itemID or itemID == 0 then return nil end
  local _, _, _, _, minLevel = GetItemInfo(itemID)
  return minLevel
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function CreateWindow()
  frame = CreateFrame("Frame", "CraftRouteFrame", UIParent, "BackdropTemplate")
  frame:SetSize(1010, 540)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetBackdrop(CR.DEFAULT_BACKDROP)   -- the chosen theme is applied once the window is built
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    CraftRouteDB.pos = { point, rel, x, y }
  end)
  if CraftRouteDB.pos then
    local p = CraftRouteDB.pos
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end
  table.insert(UISpecialFrames, "CraftRouteFrame")

  -- Resizable from the bottom-right corner; the size is remembered.
  local MIN_W, MIN_H = 1010, 540   -- wide enough for the Craft tab's two previews + route
  frame:SetResizable(true)
  if frame.SetResizeBounds then
    frame:SetResizeBounds(MIN_W, MIN_H, 2000, 1400)
  elseif frame.SetMinResize then
    frame:SetMinResize(MIN_W, MIN_H)
  end
  if CraftRouteDB.size then
    frame:SetSize(math.max(MIN_W, CraftRouteDB.size[1]), math.max(MIN_H, CraftRouteDB.size[2]))
  end
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(14, 14)
  grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetFrameLevel(frame:GetFrameLevel() + 10)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    CraftRouteDB.size = { frame:GetWidth(), frame:GetHeight() }
    local point, _, rel, x, y = frame:GetPoint()
    CraftRouteDB.pos = { point, rel, x, y }
    CR.RefreshWindow()
  end)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 18, -16)
  title:SetText("CraftRoute")
  frame.crTitle = title

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  frame.panels = {}
  frame.tabs = {}
  local function AddTab(key, label, x)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(100, 22)
    b:SetPoint("TOPLEFT", x, -14)
    b:SetText(label)
    b:SetScript("OnClick", function() CR.ShowWindow(key) end)
    frame.tabs[key] = b
    CR.ThemeRegisterButton(b)
  end
  AddTab("craft", "Craft", 130)
  AddTab("plan", "Plan", 234)
  AddTab("recipes", "Recipes", 338)

  -- Look picker: only when EllesmereUI is installed, to match its four styles.
  if CR.HasEllesmere() then
    local lookLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lookLabel:SetPoint("TOPLEFT", 456, -19)
    lookLabel:SetText("Look:")
    CR.ThemeRegisterAccentText(lookLabel)
    local lookDD = CR.CreateDropdown(frame, 170, function()
      local opts = {}
      for _, t in ipairs(CR.THEMES) do
        if not t.foreverOnly or EllesmereUI.IS_FOREVER then
          local text = t.text
          if t.key == "auto" then
            local ok, look = pcall(EllesmereUI.RenderedLook)
            for _, x in ipairs(CR.THEMES) do
              if ok and x.key == look then text = text .. " (" .. x.text .. ")" end
            end
          end
          table.insert(opts, { value = t.key, text = text })
        end
      end
      return opts
    end, function() return CraftRouteDB.theme or "default" end,
    function(v)
      CraftRouteDB.theme = v
      CR.ApplyTheme(frame)
      CR.RefreshWindow()
    end)
    lookDD:SetPoint("LEFT", lookLabel, "RIGHT", 6, 0)
    lookDD:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")  -- beside it, so it never covers the open menu
      GameTooltip:SetText("CraftRoute look")
      GameTooltip:AddLine("Match one of EllesmereUI's styles, or follow whichever one EllesmereUI is using. "
        .. "Pick \"CraftRoute default\" to go back to the original look at any time.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    lookDD:SetScript("OnLeave", GameTooltip_Hide)
    lookDD:HookScript("OnClick", GameTooltip_Hide)  -- and it goes away once the menu opens
    frame.lookDD = lookDD
  end

  frame.panels.plan = CR.CreatePlanPanel(frame)
  frame.panels.recipes = CR.CreateRecipesPanel(frame)
  frame.panels.craft = CR.CreateCraftPanel(frame)
  for _, p in pairs(frame.panels) do
    p:SetPoint("TOPLEFT", 14, -42)
    p:SetPoint("BOTTOMRIGHT", -14, 12)
  end
  frame:SetScript("OnShow", function() CR.RefreshWindow() end)
  CR.ApplyTheme(frame)
end

function CR.ShowWindow(tab)
  if not frame then CreateWindow() end
  -- the last tab used is remembered, so the window reopens where you left it (e.g. on Craft)
  tab = tab or frame.current or CraftRouteDB.lastTab or "craft"
  if not frame.panels[tab] then tab = "craft" end
  CraftRouteDB.lastTab = tab
  frame.current = tab
  for key, p in pairs(frame.panels) do p:SetShown(key == tab) end
  for key, b in pairs(frame.tabs) do
    if key == tab then b:LockHighlight() else b:UnlockHighlight() end
    CR.ThemeSetButtonActive(b, key == tab)
  end
  frame:Show()
  CR.RefreshWindow()
  -- the Craft tab opens the profession window itself (this runs from a click or /cr)
  if tab == "craft" and frame.panels.craft.AutoOpen then frame.panels.craft:AutoOpen() end
end

function CR.ToggleWindow()
  if frame and frame:IsShown() then frame:Hide() else CR.ShowWindow() end
end

function CR.RefreshWindow()
  if not frame or not frame:IsShown() then return end
  local p = frame.panels[frame.current]
  if p and p.Refresh then p:Refresh() end
  -- rows are created as lists grow, so give new ones EllesmereUI's font too
  if CR.ActiveTheme() == "eui" then CR.ApplyThemeFonts(frame) end
end

CR.OnChange(function() CR.RefreshWindow() end)

---------------------------------------------------------------------------
-- Plan panel
---------------------------------------------------------------------------
-- Goals are named after the profession ranks (Apprentice 75 ... Artisan 300).
local function GoalOptions()
  local profName = CraftRouteCharDB.profession
  local route = CR.Route(profName)
  local info = CR.RankInfo(profName)
  local function RankText(prefix, r)
    return r and string.format("%s: %s (%d)", prefix, r.name, r.cap) or prefix
  end
  local opts = {
    { value = "next",  text = "Next target recipe" },
    { value = "tier",  text = RankText("My rank", info.current) },
    { value = "level", text = RankText("My level's highest rank", info.levelRank) },
  }
  for _, r in ipairs(info.ranks) do
    table.insert(opts, { value = "rank:" .. r.name, text = string.format("%s (%d)", r.name, r.cap) })
  end
  table.insert(opts, { value = "route", text = string.format("End of guide (%d)", route and route.routeEnd or 300) })
  table.insert(opts, { value = "custom", text = "Custom skill" })
  return opts
end

local SKILL_TAG = { Fishing = { "Fish", "4fc3f7" }, Cooking = { "Cook", "ffb74d" } }

-- Range column; in the combined guide it also says which skill the step is for.
local function RangeText(st, route)
  local range = st.from and st.to and string.format("%d-%d", st.from, st.to) or ""
  local tag = route and route.sequential and st.skill and SKILL_TAG[st.skill]
  if tag then return CR.ColorText(tag[1], tag[2]) .. " " .. range end
  return range
end

-- Returns rangeText, rowText, and for long instruction rows (plainText, color) to word-wrap.
local function StepRowText(st, profName, route)
  if st.kind == "train" then
    local color = st.ok == false and "ff4040" or "ffd100"
    local warn = st.ok == false and "  (character level too low!)" or ""
    return CR.ColorText(string.format("%3s", st.from > 0 and st.from or ""), "aaaaaa"), nil, st.text .. warn, color
  elseif st.kind == "guide" then
    if st.train then return RangeText(st, route), nil, st.text, "ffd100" end
    return RangeText(st, route), nil, st.text, "e0e0e0"
  end
  if st.kind == "fork" then
    return RangeText(st, route),
           CR.ColorText((route and route.sequential and (st.text .. " - ") or "Guide alternatives - ")
             .. "choose ONE:", CR.AccentHex())
  elseif st.kind == "option" then
    -- An option is shown as what you'd craft ("20x Cured Heavy Hide, 16x Hillman's Leather
    -- Gloves, ..."), so the choice is between tangible crafts; the Materials panel shows what each
    -- needs as you switch. Underneath: the guide's name for the path and its cost.
    -- Options with nothing to craft (fishing spots) keep their name and what you catch there.
    local cost = st.cost > 0 and (" · " .. CR.FormatMoney(st.cost) .. (st.unpriced and "+" or "")) or ""
    local dim = st.selected and nil or "d8c690"
    if st.crafts and #st.crafts > 0 then
      local parts = {}
      for _, c in ipairs(st.crafts) do
        local name = dim and CR.ColorText(c.recipe.name, dim) or CR.ColorText(c.recipe.name, QualityHex(c.recipe.q))
        table.insert(parts, (c.estimated and "~" or "") .. c.n .. "x " .. name)
      end
      local label = CR.ColorText(st.letter .. ": ", st.selected and "ffffff" or "d8c690") .. table.concat(parts, ", ")
      return "", label, nil, nil, CR.ColorText(st.label, "888888") .. cost
    end
    local parts = {}
    for i = 1, math.min(3, #(st.catch or {})) do
      local c = st.catch[i]
      table.insert(parts, (c.n and (c.n .. " ") or "") .. CR.ItemName(c.id):gsub("^Raw ", ""))
    end
    if #parts > 0 then parts[1] = "catches " .. parts[1] end
    local label = CR.ColorText(st.letter .. ": " .. st.label, st.selected and "ffffff" or "d8c690")
    return "", label, nil, nil, CR.ColorText(table.concat(parts, ", "), "999999") .. cost
  end
  local r = st.recipe or CR.professions[profName].recipes[st.spell]
  local name = CR.ColorText(r.name, QualityHex(r.q))
  if st.kind == "craft" then
    local note = st.note and CR.ColorText("  " .. st.note, st.auto and "ff9966" or "999999") or ""
    local bar = st.fork and CR.ColorText("| ", "40ff40") or ""
    local count = (st.estimated and "~" or "") .. st.crafts .. "x "
    return RangeText(st, route), bar .. count .. name .. note
  elseif st.kind == "target" then
    local lvl = CR.ItemMinLevel(r.item)
    return CR.ColorText(tostring(st.from), "33ccff"),
           CR.ColorText("Target: ", "33ccff") .. string.format("%dx %s", st.crafts, name)
             .. CR.ColorText(lvl and ("  (equip Lv " .. lvl .. ")") or "", "aaaaaa")
  else -- extra
    return "", CR.ColorText("  + ", "aaaaaa") .. string.format("%dx %s", st.crafts, name)
             .. CR.ColorText("  " .. st.text, "888888")
  end
end

function CR.CreatePlanPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  local db = function() return CraftRouteCharDB end

  -- Profession picker: every supported profession, the ones this character has first.
  local function SkillLabel(name)
    local cur, maxRank, detected = CR.GetSkill(name)
    return detected and string.format("%s  %d/%d", name, cur, maxRank)
      or (name .. CR.ColorText("  (not learned)", "888888"))
  end
  local profDD = CR.CreateDropdown(panel, 190, function()
    local learned, other = {}, {}
    for _, name in ipairs(CR.SupportedProfessions()) do
      local _, _, detected = CR.GetSkill(name)
      table.insert(detected and learned or other, { value = name, text = SkillLabel(name) })
    end
    -- Unlearned ones are listed unless the player unticked "Show professions I haven't learned".
    -- The selected profession always stays listed, and if nothing is learned yet everything shows.
    local showAll = db().showUnlearned or #learned == 0
    for _, o in ipairs(other) do
      if showAll or o.value == db().profession then table.insert(learned, o) end
    end
    return learned
  end, function() return db().profession end,
  function(v) db().profession = v; db().profPicked = true; CR.NotifyChanged() end)
  profDD:SetPoint("TOPLEFT", 4, -6)

  -- Route mode (Cooking/Fishing: on its own or the combined guide)
  local modeDD = CR.CreateDropdown(panel, 140, function()
    local prof = CR.professions[db().profession]
    local opts = {}
    for _, mode in ipairs(prof.routeOrder or {}) do
      table.insert(opts, { value = mode, text = prof.routes[mode].label })
    end
    return opts
  end, function() return CR.Route(db().profession).mode end,
  function(v) db().routeMode[db().profession] = v; CR.NotifyChanged() end)
  modeDD:SetPoint("LEFT", profDD, "RIGHT", 8, 0)

  local goalLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  goalLabel:SetPoint("TOPLEFT", 360, -9)
  goalLabel:SetText("Goal:")

  -- Shown instead of the goal controls for guides followed in order.
  local seqText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  seqText:SetPoint("TOPLEFT", 360, -10)
  seqText:SetPoint("RIGHT", panel, "RIGHT", -4, 0)
  seqText:SetJustifyH("LEFT")

  local goalDD = CR.CreateDropdown(panel, 150, GoalOptions,
    function() return db().goalMode end,
    function(v) db().goalMode = v; CR.NotifyChanged() end)
  goalDD:SetPoint("LEFT", goalLabel, "RIGHT", 6, 0)

  local goalBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  goalBox:SetSize(40, 20)
  goalBox:SetPoint("LEFT", goalDD, "RIGHT", 12, 0)
  goalBox:SetAutoFocus(false)
  goalBox:SetNumeric(true)
  goalBox:SetMaxLetters(3)
  goalBox:SetScript("OnEnterPressed", function(self)
    db().customGoal = tonumber(self:GetText()) or 225
    db().goalMode = "custom"
    self:ClearFocus()
    CR.NotifyChanged()
  end)
  goalBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local goalWhy = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  goalWhy:SetPoint("LEFT", goalBox, "RIGHT", 8, 0)
  goalWhy:SetPoint("RIGHT", panel, "RIGHT", -4, 0)
  goalWhy:SetJustifyH("LEFT")

  -- Steps list (left)
  local stepsTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  stepsTitle:SetPoint("TOPLEFT", 4, -40)
  stepsTitle:SetText("Steps")
  CR.ThemeRegisterAccentText(stepsTitle)

  local unlearnedCB = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  unlearnedCB:SetSize(20, 20)
  unlearnedCB:SetPoint("LEFT", stepsTitle, "RIGHT", 16, 0)
  unlearnedCB.label = unlearnedCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  unlearnedCB.label:SetPoint("LEFT", unlearnedCB, "RIGHT", 2, 0)
  unlearnedCB.label:SetText("Show professions I haven't learned")
  unlearnedCB:SetScript("OnClick", function(self)
    db().showUnlearned = self:GetChecked() and true or false
    profDD:Sync()
  end)
  unlearnedCB:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Show professions I haven't learned")
    GameTooltip:AddLine("Ticked, the profession list also offers professions this character doesn't have, "
      .. "so you can check their route and costs. Untick to list only your own professions.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  unlearnedCB:SetScript("OnLeave", GameTooltip_Hide)

  local steps = CR.CreateList("CraftRouteStepsScroll", panel, 460, 382, function(row)
    row.range = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.range:SetPoint("LEFT", 2, 0)
    row.range:SetWidth(76)
    row.range:SetJustifyH("LEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 80, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", -2, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    -- Alternative ("choose ONE") rows: a tinted panel with an accent bar and a Choose button.
    row.optBg = row:CreateTexture(nil, "BACKGROUND")
    row.optBg:SetPoint("TOPLEFT", 74, 0)
    row.optBg:SetPoint("BOTTOMRIGHT", 0, 0)
    row.optBg:SetColorTexture(1, 1, 1, 1)
    row.optBg:Hide()
    row.optBar = row:CreateTexture(nil, "BORDER")
    row.optBar:SetPoint("TOPLEFT", 74, 0)
    row.optBar:SetPoint("BOTTOMLEFT", 74, 0)
    row.optBar:SetWidth(3)
    row.optBar:SetColorTexture(1, 1, 1, 1)
    row.optBar:Hide()
    row.optTop = row:CreateTexture(nil, "BORDER")   -- divider between neighbouring options
    row.optTop:SetPoint("TOPLEFT", 74, 0)
    row.optTop:SetPoint("TOPRIGHT", 0, 0)
    row.optTop:SetHeight(1)
    row.optTop:SetColorTexture(0, 0, 0, 0.9)
    row.optTop:Hide()
    local function Choose()
      local st = row.step
      if st and st.kind == "option" and not st.selected then
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        CR.ProfTable("choices", st.routeID)[st.choice] = st.option
        CR.NotifyChanged()
      end
    end
    row.optBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
    row.optBtn:SetSize(OPTION_BUTTON_W, 16)
    row.optBtn:SetPoint("RIGHT", -2, 0)
    Backdrop(row.optBtn, 0.25, 0.2, 0.05, 0.9)
    row.optBtn.crOwnBorder = true   -- coloured by its own selected state, not the theme
    row.optBtn.label = row.optBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.optBtn.label:SetPoint("CENTER")
    local btnHl = row.optBtn:CreateTexture(nil, "HIGHLIGHT")
    btnHl:SetAllPoints()
    btnHl:SetColorTexture(1, 0.85, 0.3, 0.2)
    row.optBtn:SetScript("OnClick", Choose)
    row.optBtn:SetScript("OnEnter", function() row:GetScript("OnEnter")(row) end)
    row.optBtn:SetScript("OnLeave", GameTooltip_Hide)
    row.optBtn:Hide()

    row:SetScript("OnEnter", function(self)
      local st = self.step
      if not st then return end
      if st.kind == "guide" or st.kind == "train" then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local range = st.to and st.to > (st.from or 0) and string.format(" %d-%d", st.from, st.to) or ""
        GameTooltip:SetText((st.skill or db().profession) .. range)
        GameTooltip:AddLine(st.text, 1, 1, 1, true)
        if st.catchInfo then GameTooltip:AddLine(st.catchInfo, 0.31, 0.76, 0.97, true) end
        local function Items(list, title)
          if list and #list > 0 then
            GameTooltip:AddLine(title, 1, 0.82, 0)
            for _, it in ipairs(list) do
              GameTooltip:AddDoubleLine("  " .. CR.ItemName(it[1]), it[2], 1, 1, 1, 1, 1, 1)
            end
          end
        end
        Items(st.items, "Buy / bring:")
        Items(st.yields, "Expected catch:")
        GameTooltip:Show()
      elseif st.kind == "option" then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(st.letter .. ": " .. st.label .. string.format("  (%d-%d)", st.from, st.to))
        GameTooltip:AddLine(st.selected and "Selected - this is what the materials and cost count."
          or "Click Choose to use this one instead.", 0.6, 0.8, 1)
        if st.crafts and #st.crafts > 0 then
          GameTooltip:AddLine("You'll craft:", 1, 0.82, 0)
          for _, c in ipairs(st.crafts) do
            local qr, qg, qb = 1, 1, 1
            local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[c.recipe.q]
            if qc then qr, qg, qb = qc.r, qc.g, qc.b end
            GameTooltip:AddDoubleLine("  " .. c.recipe.name, (c.estimated and "~" or "") .. c.n .. "x",
              qr, qg, qb, 1, 1, 1)
          end
        end
        if #st.mats > 0 then GameTooltip:AddLine("Needs:", 1, 0.82, 0) end
        for _, m in ipairs(st.mats) do
          local have = CR.HaveCount(m.id)
          GameTooltip:AddDoubleLine("  " .. CR.ItemName(m.id), string.format("%d/%d", math.min(have, m.n), m.n),
            1, 1, 1, 1, 1, 1)
        end
        if st.cost > 0 then
          GameTooltip:AddDoubleLine("Cost (Auctionator)", CR.FormatMoney(st.cost) .. (st.unpriced and " + unpriced items" or ""))
        end
        GameTooltip:Show()
      elseif st.recipe then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        CR.RecipeTooltip(GameTooltip, st.recipe, st.crafts)
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", Choose)  -- clicking anywhere on an option's panel chooses it too
  end, function(row, line)
    -- line = { step, range, text, cont, option, button } - long text spans several lines
    local st = line.step
    row.step = st
    row.range:SetText(line.range or "")
    row.text:SetText(line.text)
    row.icon:SetTexCoord(0, 1, 0, 1)

    -- Alternative rows: green panel when chosen, dark gold when not; button on the first line.
    if line.option then
      local sel = st.selected
      row.optBg:SetVertexColor(sel and 0.15 or 0.4, sel and 0.45 or 0.3, sel and 0.15 or 0.05, sel and 0.35 or 0.22)
      row.optBar:SetVertexColor(sel and 0.25 or 0.9, sel and 1 or 0.7, sel and 0.25 or 0.15, 1)
      row.optBg:Show()
      row.optBar:Show()
      row.optTop:SetShown(line.button)
    else
      row.optBg:Hide()
      row.optBar:Hide()
      row.optTop:Hide()
    end
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    if line.button then
      local sel = st.selected
      row.optBtn.label:SetText(sel and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t Selected" or "Choose")
      row.optBtn.label:SetTextColor(sel and 0.4 or 1, sel and 1 or 0.82, sel and 0.4 or 0)
      row.optBtn:SetBackdropColor(sel and 0.08 or 0.3, sel and 0.25 or 0.22, sel and 0.08 or 0.03, 0.95)
      row.optBtn:SetBackdropBorderColor(sel and 0.3 or 0.9, sel and 0.8 or 0.7, sel and 0.3 or 0.15, 1)
      row.optBtn:SetEnabled(not sel)
      row.optBtn:Show()
      row.text:SetPoint("RIGHT", row.optBtn, "LEFT", -4, 0)
    else
      row.optBtn:Hide()
      row.text:SetPoint("RIGHT", -2, 0)
    end

    if line.option and line.button then
      -- radio marker: UI-RadioButton holds unchecked (left quarter) and checked (second quarter)
      row.icon:SetTexture("Interface\\Buttons\\UI-RadioButton")
      if st.selected then row.icon:SetTexCoord(0.25, 0.5, 0, 1) else row.icon:SetTexCoord(0, 0.25, 0, 1) end
      row.icon:Show()
    elseif line.cont then
      row.icon:Hide()
    elseif st.recipe and st.recipe.item > 0 then
      row.icon:SetTexture(GetItemIcon(st.recipe.item))
      row.icon:Show()
    elseif st.kind == "train" or (st.kind == "guide" and st.train) then
      row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
      row.icon:Show()
    elseif st.kind == "guide" then
      row.icon:SetTexture(st.skill == "Cooking" and "Interface\\Icons\\INV_Misc_Food_15"
        or "Interface\\Icons\\Trade_Fishing")
      row.icon:Show()
    else
      row.icon:Hide()
    end
  end)

  -- Word-wraps every step row to the steps column's current width, measuring with a hidden
  -- font string. Colour codes are carried over line breaks, so a coloured note stays coloured.
  local measure = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  measure:Hide()
  local function WrapWidth()
    local w = steps:GetWidth()
    -- text starts after the range column + icon (96px) and stops before the scrollbar (18px)
    return (type(w) == "number" and w > 0) and (w - 96 - 18) or 340
  end
  local function Fits(text, width)
    measure:SetText(text)
    local w = measure:GetStringWidth()
    if type(w) ~= "number" then return #text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") <= width / 5.6 end
    return w <= width
  end
  -- Colour active at the end of a text fragment ("|cffXXXXXX" or nil).
  local function OpenColor(text, color)
    for code in text:gmatch("|[cr]%x*") do
      if code == "|r" then color = nil else color = code:sub(1, 10) end
    end
    return color
  end
  local function Wrap(text, width)
    local lines, cur, color = {}, "", nil
    for word in text:gmatch("%S+") do
      local try = cur == "" and word or (cur .. " " .. word)
      if cur ~= "" and not Fits(try, width) then
        table.insert(lines, cur .. (color and "|r" or ""))
        cur = (color or "") .. word
      else
        cur = try
      end
      color = OpenColor(word, color)
    end
    if cur ~= "" then table.insert(lines, cur) end
    return lines
  end

  local function StepLines(plan, route)
    local out = {}
    local width = WrapWidth()
    for _, st in ipairs(plan.steps) do
      local range, text, plain, color, detail = StepRowText(st, plan.prof, route)
      if plain then text = CR.ColorText(plain, color) end
      if st.kind == "option" then
        -- Option name beside its Choose button, details on the lines below, all on one tinted panel.
        for i, l in ipairs(Wrap(text, width - OPTION_BUTTON_W - 8)) do
          table.insert(out, { step = st, text = l, cont = i > 1, option = true, button = i == 1 })
        end
        for _, l in ipairs(Wrap(detail, width)) do
          table.insert(out, { step = st, text = l, cont = true, option = true })
        end
      else
        for i, l in ipairs(Wrap(text, width)) do
          table.insert(out, { step = st, range = i == 1 and range or nil, text = l, cont = i > 1 })
        end
      end
      if st.catchInfo then
        for _, l in ipairs(Wrap(CR.ColorText(st.catchInfo, "4fc3f7"), width)) do
          table.insert(out, { step = st, text = l, cont = true })
        end
      end
    end
    return out
  end
  -- Steps take ~56% of the width, materials the rest; both follow the window size.
  steps:SetPoint("TOPLEFT", 0, -56)
  steps:SetPoint("BOTTOMLEFT", 0, 50)
  local lastWidth
  steps.onResize = function()
    local pw = panel:GetWidth()
    if type(pw) == "number" and pw > 0 then steps:SetWidth(math.floor((pw - 6) * 0.56)) end
    -- re-wrap for the new width
    local w = steps:GetWidth()
    if w ~= lastWidth then
      lastWidth = w
      if panel:IsShown() and panel.lastPlan then
        steps.data = StepLines(panel.lastPlan, panel.lastRoute)
      end
    end
  end
  panel:SetScript("OnSizeChanged", function() steps.onResize() end)

  -- Materials list (right)
  local matTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  matTitle:SetPoint("BOTTOMLEFT", steps, "TOPRIGHT", 10, 4)
  matTitle:SetText("Materials")
  CR.ThemeRegisterAccentText(matTitle)
  local matHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  matHdr:SetPoint("TOPRIGHT", -28, -42)
  matHdr:SetText("have / need      cost to buy")

  local mats = CR.CreateList("CraftRouteMatsScroll", panel, 360, 382, function(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 2, 0)
    -- cost is pinned right, count before it, and the name takes whatever width is left
    row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.cost:SetPoint("RIGHT", -2, 0)
    row.cost:SetWidth(100)
    row.cost:SetJustifyH("RIGHT")
    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.count:SetPoint("RIGHT", row.cost, "LEFT", -6, 0)
    row.count:SetWidth(70)
    row.count:SetJustifyH("RIGHT")
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetPoint("RIGHT", row.count, "LEFT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
      if not self.mat then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.mat.id) -- CraftRoute lines are added by the tooltip hook
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Where you have it:", 1, 0.82, 0)
      CR.AddLocationLines(GameTooltip, self.mat.id)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
      if IsModifiedClick("CHATLINK") and self.mat then
        local _, link = GetItemInfo(self.mat.id)
        if link then ChatEdit_InsertLink(link) end
      end
    end)
  end, function(row, m)
    row.mat = m
    row.icon:SetTexture(GetItemIcon(m.id))
    row.name:SetText(m.name)
    local covered = m.have + m.crafted
    local color = covered >= m.need and "40ff40" or "ffffff"
    local count = CR.ColorText(string.format("%d/%d", math.min(m.have, m.need), m.need), color)
    if m.crafted > 0 then count = count .. CR.ColorText(" +" .. m.crafted, "33ccff") end
    row.count:SetText(count)
    if m.crafted > 0 then
      row.cost:SetText(CR.ColorText("crafted", "33ccff"))
    elseif m.missing == 0 then
      row.cost:SetText(CR.ColorText("done", "40ff40"))
    else
      local txt = CR.FormatMoney(m.missingCost)
      if m.priceSrc == "vendor" then txt = CR.ColorText("vendor ", "aaaaaa") .. txt end
      row.cost:SetText(txt)
    end
  end)
  mats:SetPoint("TOPLEFT", steps, "TOPRIGHT", 6, 0)
  mats:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 50)

  -- Footer
  local totals = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  totals:SetPoint("BOTTOMLEFT", 4, 8)
  totals:SetPoint("RIGHT", panel, "RIGHT", -200, 0)
  totals:SetJustifyH("LEFT")

  local shop = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  shop:SetSize(190, 22)
  shop:SetPoint("BOTTOMRIGHT", -2, 4)
  shop:SetText("Auctionator shopping list")
  CR.ThemeRegisterButton(shop)
  shop:SetScript("OnClick", function()
    local e = CR.GetPlans()
    if e then CR.CreateShoppingList(e.plan) end
  end)

  local altsCB = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  altsCB:SetSize(20, 20)
  altsCB:SetPoint("BOTTOMLEFT", shop, "TOPLEFT", 0, 2)
  altsCB.label = altsCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  altsCB.label:SetPoint("LEFT", altsCB, "RIGHT", 2, 0)
  altsCB.label:SetText("Count items on alts as owned")
  altsCB:SetScript("OnClick", function(self)
    db().includeAlts = self:GetChecked() and true or false
    CR.NotifyChanged()
  end)
  altsCB:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Count items on alts")
    GameTooltip:AddLine("When ticked, materials on your other characters (bags, bank, mail) count towards 'have'.", 1, 1, 1, true)
    GameTooltip:AddLine("Unticked, only this character's bags, bank and mail count. Hover a material to see where everything is either way.", 1, 1, 1, true)
    if not CR.HasSyndicator() then
      GameTooltip:AddLine("Needs Syndicator (installed with Baganator) to see alts.", 1, 0.5, 0.3, true)
    end
    GameTooltip:Show()
  end)
  altsCB:SetScript("OnLeave", GameTooltip_Hide)

  local beyond = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  beyond:SetPoint("BOTTOMLEFT", totals, "TOPLEFT", 0, 4)
  beyond:SetPoint("RIGHT", panel, "RIGHT", -200, 0)
  beyond:SetJustifyH("LEFT")

  function panel:Refresh()
    local profName = db().profession
    local e = CR.GetPlans(profName)
    if not e then return end
    local route = e.route
    profDD:Sync()
    modeDD:Sync()
    modeDD:SetShown(#(CR.professions[profName].routeOrder or {}) > 1)

    -- Goal controls only make sense for single-skill routes.
    local seq = route.sequential
    goalLabel:SetShown(not seq)
    goalDD:SetShown(not seq)
    goalBox:SetShown(not seq)
    goalWhy:SetShown(not seq)
    seqText:SetShown(seq)
    if seq then
      local parts = {}
      for _, sk in ipairs(route.skills) do table.insert(parts, SkillLabel(sk)) end
      seqText:SetText("Follow in order - " .. table.concat(parts, CR.ColorText("  |  ", "666666")))
    else
      goalDD:Sync()
      goalBox:SetText(tostring(db().customGoal or ""))
      goalWhy:SetText(string.format("-> %d  |cffaaaaaa(%s)|r", e.goal, e.why or ""))
    end

    panel.lastPlan, panel.lastRoute = e.plan, route
    steps.onResize()
    steps.data = StepLines(e.plan, route)
    steps:Refresh()
    mats.data = e.plan.materials
    mats:Refresh()

    local t = string.format("Cost to buy what's missing: %s", CR.FormatMoney(e.plan.missingCost))
    if e.plan.unpriced > 0 then
      t = t .. CR.ColorText(string.format("  (+%d items with no price - scan the AH)", e.plan.unpriced), "ff9966")
    end
    if not CR.HasAuctionator() then t = CR.ColorText("Install Auctionator for material prices.", "ff9966") end
    totals:SetText(t)
    shop:SetEnabled(CR.HasAuctionator())
    altsCB:SetChecked(db().includeAlts)
    unlearnedCB:SetChecked(db().showUnlearned)

    if #e.plan.beyond > 0 then
      local names = {}
      for _, b in ipairs(e.plan.beyond) do
        table.insert(names, string.format("%s (%d)", b.recipe.name, b.recipe.learn))
      end
      beyond:SetText("Targets past this goal: " .. table.concat(names, ", "))
    else
      beyond:SetText("")
    end
  end

  return panel
end
