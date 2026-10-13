-- Materials trackers: a small window per profession you can pin anywhere, open or not the rest
-- of CraftRoute is - that profession's route materials, what you have of what it needs. Each has
-- its own place, size, scale, sort and hidden items, and several can be up at once. Edit picks
-- which items it shows (hidden ones are only hidden there). Move one by its title, or in
-- EllesmereUI's unlock mode. /cr tracker or the Tracker button (the profession CraftRoute is on),
-- or the pop-out on the profession window's tab (that tab's profession). Kept per character.
local _, CR = ...

local ROW_H, MAX_ROWS = 20, 30
local DEF_W, MIN_W, MAX_W, MIN_S, MAX_S = 250, 180, 520, 0.6, 2
local MIN_H, MAX_H = 70, 900   -- a set height (nil: fits the list); shorter than the list scrolls

-- all the trackers' saved state: byProf[profession] = { shown, pos, width, scale, height,
-- collapsed, sort }; hidden[profession] = { [itemID] = true }
local function Root()
  local db = CraftRouteCharDB
  if not db then return {} end
  db.tracker = db.tracker or {}
  local t = db.tracker
  t.byProf = t.byProf or {}
  -- before 0.48 there was one tracker: its settings go to the profession it was showing
  if t.shown ~= nil or t.pos or t.width or t.scale or t.height or t.collapsed or t.sort or t.prof then
    local prof = t.prof or db.profession
    if prof and not t.byProf[prof] then
      t.byProf[prof] = { shown = t.shown, pos = t.pos, width = t.width, scale = t.scale, height = t.height,
                         collapsed = t.collapsed, sort = t.sort }
    end
    t.shown, t.pos, t.width, t.scale, t.height, t.collapsed, t.sort, t.prof = nil, nil, nil, nil, nil, nil, nil, nil
  end
  return t
end

-- items hidden from a profession's tracker
local function Hidden(prof)
  local s = Root()
  s.hidden = s.hidden or {}
  prof = prof or "?"
  s.hidden[prof] = s.hidden[prof] or {}
  return s.hidden[prof]
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

-- A labelled slider with its value (the size panel)
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


-- One profession's tracker: its window, its controls and its settings.
local count = 0
local function NewTracker(PROF)
  count = count + 1
  -- each new one starts a little down / left of the last, so they don't sit on top of each other
  local DEFAULT_POS = { "RIGHT", "RIGHT", -60 - (count - 1) * 24, 120 - (count - 1) * 24 }
  local frame, sizePanel, sizePanelSync
  local editing, offset = false, 0
  local Refresh, SetSize, SizePanel, Toggle, Build, RegisterUnlock
  local function Settings()
    local t = Root()
    t.byProf[PROF] = t.byProf[PROF] or {}
    return t.byProf[PROF]
  end
  local function Prof() return PROF end
  local function Width() return Settings().width or (frame and tonumber(frame:GetWidth())) or DEF_W end
  local function Scale() return Settings().scale or 1 end
  local function Place()
    local p = Settings().pos or DEFAULT_POS
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end
  local function SavePos()
    local point, _, rel, x, y = frame:GetPoint()
    Settings().pos = { point, rel, x, y }
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

  function Refresh()
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
    -- in route order: where each is first used (a step's reagent, or something a step has you buy);
    -- still needed first, what you have enough of below
    local firstAt, pos = {}, 0
    local function Seen(id) pos = pos + 1 if id and not firstAt[id] then firstAt[id] = pos end end
    for _, st in ipairs(e and e.plan and e.plan.steps or {}) do
      if st.recipe then for _, rg in ipairs(st.recipe.reagents or {}) do Seen(rg[1]) end end
      for _, it in ipairs(st.items or {}) do Seen(it[1]) end
      for _, it in ipairs(st.has or {}) do Seen(it[1]) end
    end
    local byName = Settings().sort == "name"
    table.sort(list, function(a, b)
      local da, db = a.have >= a.need, b.have >= b.need
      if da ~= db then return not da end
      if not byName then
        local fa, fb = firstAt[a.id] or math.huge, firstAt[b.id] or math.huge
        if fa ~= fb then return fa < fb end
      end
      return a.name < b.name
    end)
    local collapsed = Settings().collapsed
    local editBar = editing and not collapsed
    local top = 28 + (editBar and 22 or 0)
    -- how many lines fit: the set height's worth, or (no height set) the whole list
    local setH = Settings().height
    -- the Shopping list button along the bottom (with Auctionator)
    -- the bottom line: Alts (always) and, with Auctionator, the cost and the cart
    local bottomBar = not collapsed and #list > 0
    local shop = bottomBar and CR.HasAuctionator()
    local bottom = 8 + (bottomBar and 22 or 0)
    local vis = setH and math.max(1, math.floor((setH - top - bottom) / ROW_H)) or math.min(#list, MAX_ROWS)
    offset = math.max(0, math.min(offset, #list - vis))
    local scrolling = #list > vis
    local shown = math.min(vis, #list - offset)
    frame.body:ClearAllPoints()
    frame.body:SetPoint("TOPLEFT", 8, -top)
    frame.body:SetPoint("RIGHT", frame, "RIGHT", scrolling and -16 or -8, 0)
    for i = 1, shown do
      local m, r = list[offset + i], Row(i)
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
        Refresh()
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
    frame.note:SetText(note or "")
    frame.body:SetShown(not collapsed)
    frame.note:SetShown(not collapsed and frame.note:GetText() ~= "")
    -- Edit: All / None above the list
    frame.allBtn:SetShown(editBar)
    frame.noneBtn:SetShown(editBar)
    frame.vendorBtn:SetShown(editBar)
    frame.sortDD:SetShown(editBar)
    if editBar and frame.sortDD.Sync then frame.sortDD:Sync() end
    if not editBar and frame.sortDD.menu then frame.sortDD.menu:Hide() end
    -- the scrollbar: a thin track with a thumb for where you are
    frame.track:SetShown(scrolling and not collapsed)
    frame.thumb:SetShown(scrolling and not collapsed)
    if scrolling and not collapsed then
      local trackH = vis * ROW_H
      frame.track:ClearAllPoints()
      frame.track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -top)
      frame.track:SetHeight(trackH)
      local thumbH = math.max(12, trackH * vis / #list)
      local maxOff = #list - vis
      frame.thumb:SetHeight(thumbH)
      frame.thumb:ClearAllPoints()
      frame.thumb:SetPoint("TOP", frame.track, "TOP", 0, -((trackH - thumbH) * (maxOff > 0 and offset / maxOff or 0)))
    end
    -- never taller than the list: a taller setting stops after the last line
    frame.shop:SetShown(shop)
    frame.shop.items = list
    -- what's still to buy of the materials shown costs (vendor or AH price; the route's own crafts aren't bought)
    local cost, unpriced = 0, 0
    for _, it in ipairs(list) do
      if not hidden[it.id] and (it.missing or 0) > 0 and (it.crafted or 0) == 0 then
        if it.price then cost = cost + it.price * it.missing else unpriced = unpriced + 1 end
      end
    end
    frame.cost:SetShown(shop)
    frame.alts:SetShown(bottomBar)
    frame.alts:Sync()
    frame.alts:ClearAllPoints()
    if shop then frame.alts:SetPoint("RIGHT", frame.shop, "LEFT", -28, 0)
    else frame.alts:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -44, 5) end
    frame.cost:SetText(CR.ColorText("Cost  ", "aaaaaa") .. CR.FormatMoney(cost)
      .. (unpriced > 0 and CR.ColorText(string.format("  (+%d unpriced)", unpriced), "ff9966") or ""))
    frame.note:ClearAllPoints()
    frame.note:SetPoint("BOTTOMLEFT", 8, bottom - 2)
    frame.note:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    local autoH = top + shown * ROW_H + (frame.note:IsShown() and 18 or 0) + bottom
    frame:SetHeight(collapsed and 26 or math.min(setH or autoH, autoH))
    -- never wider than it needs to be: the longest name and count in full (and the title bar);
    -- with no width set, exactly that
    local m = frame.measure
    -- measured in the font the lines really use (EllesmereUI's global font, if that's on)
    local function SameFont(fs)
      local font, size, flags = fs:GetFont()
      if font and type(size) == "number" then m:SetFont(font, size, flags) else m:SetFontObject("GameFontHighlightSmall") end
    end
    local nameW, countW = 0, 0
    if frame.rows[1] then SameFont(frame.rows[1].name) end
    for _, it in ipairs(list) do
      m:SetText(it.name)
      nameW = math.max(nameW, tonumber(m:GetStringWidth()) or 0)
      m:SetText(string.format("%d/%d", it.need, it.need) .. (((it.crafted or 0) > 0 and it.have < it.need)
        and string.format(" +%d make", it.crafted) or ""))
      countW = math.max(countW, tonumber(m:GetStringWidth()) or 0)
    end
    local rowW = 8 + (editing and 18 or 0) + (ROW_H - 4) + 5 + nameW + 6 + countW + 2 + 8 + (scrolling and 8 or 0)
    SameFont(frame.title)
    m:SetText(frame.title:GetText() or "")
    local headW = 8 + (tonumber(m:GetStringWidth()) or 0) + 4 + 40 + 3 + 16 + 3 + 18 + 2 + 18 + 6
    -- (the cost line and its cart fit too)
    local costW = 0
    if shop then
      SameFont(frame.cost)
      m:SetText(frame.cost:GetText() or "")
      costW = 8 + (tonumber(m:GetStringWidth()) or 0) + 6 + 46 + 24 + 16
    end
    local needW = math.ceil(math.max(rowW, headW, costW, editBar and 286 or 0))   -- (All / None / Vendor / Sort fit)
    frame:SetWidth(math.min(Settings().width or needW, needW))
    frame.edit:SetText(editing and "Done" or "Edit")
    frame.collapse:SetText(collapsed and "+" or "-")
    if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, frame) end
  end

  function Build()
    if frame then return end
    frame = CreateFrame("Frame", "CraftRouteTracker" .. PROF:gsub("[^%w]", ""), UIParent, "BackdropTemplate")
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
    frame.close = HeaderButton(bar, "x", 18, "Close this tracker", function() Toggle(false) end)
    frame.close:SetPoint("RIGHT", -4, 0)
    frame.collapse = HeaderButton(bar, "-", 18, "Collapse / expand", function()
      Settings().collapsed = not Settings().collapsed or nil
      Refresh()
    end)
    frame.collapse:SetPoint("RIGHT", frame.close, "LEFT", -2, 0)
    -- size and scale (a small panel)
    frame.size = CreateFrame("Button", nil, bar)
    frame.size:SetSize(16, 16)
    frame.size:SetPoint("RIGHT", frame.collapse, "LEFT", -3, 0)
    frame.size:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    frame.size:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    frame.size:SetScript("OnClick", function(self) SizePanel(self) end)
    frame.size:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText("Size and scale")
      GameTooltip:AddLine("Ctrl+mouse wheel over the tracker also scales it.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    frame.size:SetScript("OnLeave", GameTooltip_Hide)
    frame.edit = HeaderButton(bar, "Edit", 40, "Pick which materials this list shows", function()
      editing = not editing
      if editing then Settings().collapsed = nil end
      Refresh()
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
    -- Shopping list: an Auctionator list of what's still needed of the materials shown (hidden ones
    -- left out); things the route makes itself aren't bought
    frame.shop = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.shop:SetSize(24, 18)
    frame.shop:SetPoint("BOTTOMRIGHT", -16, 6)
    frame.shop:SetText("")
    if CR.ThemeRegisterButton then CR.ThemeRegisterButton(frame.shop) end
    if CR.AddCartIcon then CR.AddCartIcon(frame.shop, false) end
    -- beside it: what the shown materials still to buy cost
    frame.cost = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.cost:SetPoint("LEFT", frame, "BOTTOMLEFT", 8, 15)
    -- the Count alts' materials setting (the same one as elsewhere), as a short "Alts" tickbox
    frame.alts = CR.CreateAltsCheck(frame, "Alts")
    frame.alts:SetSize(18, 18)
    frame.alts:Hide()
    frame.cost:SetPoint("RIGHT", frame.alts, "LEFT", -6, 0)
    frame.cost:SetJustifyH("LEFT")
    frame.cost:SetWordWrap(false)
    frame.cost:Hide()
    frame.shop:SetScript("OnClick", function(self)
      local prof = Prof()
      local hidden = Hidden(prof)
      local mats = {}
      for _, m in ipairs(self.items or {}) do
        if not hidden[m.id] then table.insert(mats, m) end
      end
      CR.CreateShoppingList({ prof = prof .. " tracker", materials = mats })
    end)
    frame.shop:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText("Auctionator shopping list")
      GameTooltip:AddLine("What you still need of the materials this list shows. Hidden ones are left out, and so "
        .. "is anything the route makes itself.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    frame.shop:SetScript("OnLeave", GameTooltip_Hide)
    frame.shop:Hide()
    frame.measure = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- (sizing only)
    frame.measure:Hide()
    frame.track = frame:CreateTexture(nil, "ARTWORK")
    frame.track:SetWidth(4)
    frame.track:SetColorTexture(1, 1, 1, 0.08)
    frame.thumb = frame:CreateTexture(nil, "OVERLAY")
    frame.thumb:SetWidth(4)
    frame.thumb:SetColorTexture(1, 0.82, 0, 0.7)
    frame.track:Hide()
    -- the mouse wheel scrolls the list
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      -- Ctrl+wheel: bigger / smaller
      if IsControlKeyDown() then
        SetSize(nil, Scale() + delta * 0.05)
        if sizePanelSync then sizePanelSync() end
        return
      end
      offset = math.max(0, offset - delta)
      Refresh()
    end)
    -- Edit: show every material, or none
    local function SetAll(show)
      local prof = Prof()
      local e = CR.GetPlans and prof and CR.GetPlans(prof)
      local hidden = Hidden(prof)
      for _, m in ipairs(e and e.plan and e.plan.materials or {}) do hidden[m.id] = (not show) or nil end
      Refresh()
    end
    frame.allBtn = HeaderButton(frame, "All", 50, "Show every material", function() SetAll(true) end)
    frame.allBtn:SetPoint("TOPLEFT", 8, -26)
    frame.noneBtn = HeaderButton(frame, "None", 50, "Hide every material (then tick the ones you want)", function() SetAll(false) end)
    frame.noneBtn:SetPoint("LEFT", frame.allBtn, "RIGHT", 4, 0)
    -- Vendor: untick everything a vendor sells (thread, dyes, flux...) - or, if they're all unticked
    -- already, tick them back
    frame.vendorBtn = HeaderButton(frame, "Vendor", 56, "Untick the items vendors sell (click again to tick them back)", function()
      local prof = Prof()
      local e = CR.GetPlans and prof and CR.GetPlans(prof)
      local hidden = Hidden(prof)
      local vendor, anyShown = {}, false
      for _, m in ipairs(e and e.plan and e.plan.materials or {}) do
        if CR.IsVendorItem and CR.IsVendorItem(m.id) then
          table.insert(vendor, m.id)
          if not hidden[m.id] then anyShown = true end
        end
      end
      if #vendor == 0 then CR.Print("Tracker: none of these materials is known as a vendor item.") return end
      for _, id in ipairs(vendor) do hidden[id] = anyShown or nil end
      Refresh()
    end)
    frame.vendorBtn:SetPoint("LEFT", frame.noneBtn, "RIGHT", 4, 0)
    -- the order: route order (the step that first uses each) or A-Z
    frame.sortDD = CR.CreateDropdown(frame, 92, {
      { value = "route", text = "Route order" }, { value = "name", text = "A-Z" },
    }, function() return Settings().sort == "name" and "name" or "route" end, function(v)
      Settings().sort = (v == "name") and "name" or nil
      Refresh()
    end)
    frame.sortDD:SetHeight(18)
    frame.sortDD:SetPoint("LEFT", frame.vendorBtn, "RIGHT", 4, 0)
    frame.sortDD:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText("Sort")
      GameTooltip:AddLine("Route order: by the step that first uses each material. A-Z: by name. Still-needed ones stay on top either way.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    frame.sortDD:SetScript("OnLeave", GameTooltip_Hide)
    frame.allBtn:Hide()
    frame.noneBtn:Hide()
    frame.vendorBtn:Hide()
    frame.sortDD:Hide()
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
      local x, y = GetCursorPosition()
      local sc = frame:GetEffectiveScale()
      self.x0, self.y0 = x / sc, y / sc
      self.w0, self.h0 = frame:GetWidth(), frame:GetHeight()
      self:SetScript("OnUpdate", function()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / sc, cy / sc
        SetSize(self.w0 + (cx - self.x0), nil, self.h0 + (self.y0 - cy))
      end)
    end)
    grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    grip:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Drag to resize")
      GameTooltip:AddLine("Shorter than the list: it scrolls (mouse wheel). The gear's Reset fits it to the list again.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", GameTooltip_Hide)
    frame.grip = grip
    frame:SetScript("OnShow", function() Refresh() end)
    frame:SetScript("OnHide", function()
      editing = false
      if sizePanel then sizePanel:Hide() end
    end)
  end

  -- New width / scale / height (nil: unchanged), kept per character.
  function SetSize(w, scale, h)
    local s = Settings()
    if w then s.width = math.floor(math.max(MIN_W, math.min(MAX_W, w)) + 0.5) end
    if h then s.height = math.floor(math.max(MIN_H, math.min(MAX_H, h)) + 0.5) end
    if scale then s.scale = math.max(MIN_S, math.min(MAX_S, math.floor(scale * 20 + 0.5) / 20)) end
    if not frame then return end
    -- (the width itself is set by the refresh below: never wider than the list needs)
    -- a new scale keeps the window's top-left corner where it is on screen (its position is in
    -- its own scaled units, so it would otherwise drift)
    local old, new = tonumber(frame:GetScale()) or 1, Scale()
    if math.abs(old - new) > 0.001 then
      local l, t = frame:GetLeft(), frame:GetTop()
      frame:SetScale(new)
      if l and t then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * old / new, t * old / new)
        SavePos()
      end
    end
    Refresh()
  end

  -- The size panel (the gear on the title bar): width and scale sliders, and Reset
  function SizePanel(owner)
    if not sizePanel then
      -- on UIParent: as the tracker's child it would scale too, moving the slider you're dragging
      local p = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
      p:SetSize(240, 168)
      p:SetFrameStrata("DIALOG")
      CR.Backdrop(p, 0.05, 0.05, 0.07, 0.97)
      p:EnableMouse(true)
      p:Hide()
      local wsl = Slider(p, "Width", MIN_W, MAX_W, 10, Width, function(v) SetSize(v, nil) end, "%d")
      wsl:SetPoint("TOPLEFT", 12, -10)
      wsl:SetPoint("RIGHT", p, "RIGHT", -12, 0)
      local ssl = Slider(p, "Scale", MIN_S, MAX_S, 0.05, Scale, function(v) SetSize(nil, v) end, "%.2f")
      ssl:SetPoint("TOPLEFT", 12, -50)
      ssl:SetPoint("RIGHT", p, "RIGHT", -12, 0)
      local hsl = Slider(p, "Height (shorter scrolls)", MIN_H, MAX_H, 10,
        function() return Settings().height or math.floor(frame:GetHeight() + 0.5) end,
        function(v) SetSize(nil, nil, v) end, "%d")
      hsl:SetPoint("TOPLEFT", 12, -90)
      hsl:SetPoint("RIGHT", p, "RIGHT", -12, 0)
      local reset = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
      reset:SetSize(80, 22)
      reset:SetPoint("BOTTOMLEFT", 12, 10)
      reset:SetText("Reset")
      if CR.ThemeRegisterButton then CR.ThemeRegisterButton(reset) end
      reset:SetScript("OnClick", function()
        Settings().width, Settings().scale, Settings().height = nil, nil, nil
        SetSize()
        wsl:Sync() ssl:Sync() hsl:Sync()
      end)
      sizePanelSync = function() if p:IsShown() then wsl:Sync() ssl:Sync() hsl:Sync() end end
      p:SetScript("OnShow", function(self) wsl:Sync() ssl:Sync() hsl:Sync() pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
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

  -- show (true) / hide (false) / toggle (nil); remembered, so it comes back after a reload
  function Toggle(show)
    Build()
    if show == nil then show = not frame:IsShown() end
    Settings().shown = show or nil
    frame:SetShown(show)
    Refresh()
  end

  -- EllesmereUI's unlock mode: a mover like its own frames
  function RegisterUnlock()
    if not (EllesmereUI and EllesmereUI.RegisterUnlockElements and EllesmereUI.MakeUnlockElement) then return end
    EllesmereUI:RegisterUnlockElements({
      EllesmereUI.MakeUnlockElement({
        key = "CraftRouteTracker_" .. PROF:gsub("[^%w]", ""),
        label = "CraftRoute Tracker: " .. PROF,
        group = "CraftRoute",
        getFrame = function() Build() return frame end,
        getSize = function() Build() return frame:GetWidth(), frame:GetHeight() end,
        setWidth = function(_, w) SetSize(w, nil) end,
        setHeight = function(_, h) SetSize(nil, nil, h) end,
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

  return { Refresh = function() Refresh() end, Toggle = function(show) Toggle(show) end,
           Build = function() Build() end, Shown = function() return frame and frame:IsShown() end,
           Settings = Settings, RegisterUnlock = function() RegisterUnlock() end }
end

local trackers = {}   -- [profession] = tracker
local loggedIn = false
local function Tracker(prof)
  if not trackers[prof] then
    trackers[prof] = NewTracker(prof)
    if loggedIn then CR.SafeCall(trackers[prof].RegisterUnlock) end
  end
  return trackers[prof]
end

-- every tracker that's up
function CR.RefreshTracker()
  for _, t in pairs(trackers) do t.Refresh() end
end

-- prof's tracker (default: the profession picked in CraftRoute): show (true) / hide (false) /
-- toggle (nil)
function CR.ToggleTracker(show, prof)
  prof = prof or (CraftRouteCharDB and CraftRouteCharDB.profession)
  if not prof then return end
  Tracker(prof).Toggle(show)
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
    GameTooltip:AddLine("A small list of this profession's route materials you can pin anywhere on screen - it "
      .. "stays up with CraftRoute closed. Each profession has its own. Edit picks what it shows.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  -- the trackers that were up come back
  for prof, st in pairs(Root().byProf) do
    if st.shown then Tracker(prof).Toggle(true) end
  end
  for _, t in pairs(trackers) do CR.SafeCall(t.RegisterUnlock) end
  loggedIn = true   -- (trackers made from here on register their own mover)
  -- bags, the plan, the picked profession changing: refresh
  CR.OnChange(CR.RefreshTracker)
end)
