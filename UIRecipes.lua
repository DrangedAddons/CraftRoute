-- Recipes tab: filterable list of every recipe; tick the ones you want to craft.
local _, CR = ...
local GetItemInfo, GetItemCount, GetItemIcon, IsEquippedItem = CR.GetItemInfo, CR.GetItemCount, CR.GetItemIcon, CR.IsEquippedItem

-- Recipe details appended to an item tooltip (used by both tabs).
function CR.RecipeTooltip(tt, r, crafts)
  if r.item > 0 then
    tt:SetItemByID(r.item)
  else
    tt:SetText(r.name)
  end
  local skill = CR.GetSkill()
  tt:AddLine(" ")
  tt:AddLine("|cff33ccffCraftRoute recipe|r")
  local diff = CR.Difficulty(r, skill)
  tt:AddDoubleLine("Learn at", CR.ColorText(tostring(r.learn), CR.DIFF_COLORS[diff]), 0.8, 0.8, 0.8, 1, 1, 1)
  tt:AddDoubleLine("Orange / yellow / green / grey",
    string.format("|cffff8040%d|r / |cffffff00%d|r / |cff40bf40%d|r / |cff808080%d|r", r.learn, r.y, r.g, r.x),
    0.8, 0.8, 0.8)
  if r.pattern then tt:AddDoubleLine("Pattern", r.pattern, 0.8, 0.8, 0.8, 1, 1, 1) end
  tt:AddLine("Source: " .. CR.FactionText(r.src), 0.8, 0.8, 0.8, true)
  local mult = crafts or 1
  tt:AddLine(crafts and string.format("Reagents (x%d):", crafts) or "Reagents:", 0.8, 0.8, 0.8)
  for _, rg in ipairs(r.reagents) do
    local need = rg[2] * mult
    local have = CR.HaveCount(rg[1])
    tt:AddDoubleLine("  " .. CR.ItemName(rg[1]), string.format("%d/%d", math.min(have, need), need),
      1, 1, 1, have >= need and 0.25 or 1, 1, have >= need and 0.25 or 1)
  end
  if r.makes > 1 then tt:AddLine("Makes " .. r.makes, 0.8, 0.8, 0.8) end
end

local CATEGORY_GROUPS = {
  { value = "all",     text = "All categories" },
  { value = "leather", text = "Leather armor", match = "^Leather " },
  { value = "mail",    text = "Mail armor",    match = "^Mail " },
  { value = "cloak",   text = "Cloaks",        match = "^Cloaks$" },
  { value = "misc",    text = "Kits, bags & reagents" },
}

local function CategoryMatches(group, cat)
  if group == "all" then return true end
  for _, g in ipairs(CATEGORY_GROUPS) do
    if g.value == group then
      if g.match then return cat:find(g.match) ~= nil end
      return not (cat:find("^Leather ") or cat:find("^Mail ") or cat == "Cloaks")
    end
  end
  return true
end

function CR.CreateRecipesPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  local filter = { text = "", group = "all", selectedOnly = false, hideGrey = false }

  local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  search:SetSize(200, 20)
  search:SetPoint("TOPLEFT", 10, -6)
  search:SetAutoFocus(false)
  local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("LEFT", 2, 0)
  hint:SetText("Search name / stats (e.g. Intellect)")
  search:SetScript("OnTextChanged", function(self)
    filter.text = self:GetText():lower()
    hint:SetShown(self:GetText() == "")
    panel:Refresh()
  end)
  search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  local catDD = CR.CreateDropdown(panel, 150, CATEGORY_GROUPS,
    function() return filter.group end,
    function(v) filter.group = v; panel:Refresh() end)
  catDD:SetPoint("LEFT", search, "RIGHT", 10, 0)

  local function Check(label, x, key)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", x, -4)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.text:SetText(label)
    cb:SetChecked(filter[key])
    cb:SetScript("OnClick", function(self) filter[key] = self:GetChecked(); panel:Refresh() end)
    return cb
  end
  Check("Selected only", 410, "selectedOnly")
  Check("Only recipes that still give skill-ups", 520, "hideGrey")

  local help = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  help:SetPoint("TOPLEFT", 10, -30)
  local HELP_TEXT = "Tick recipes to add them as targets. Shift-click the tick to craft more than one. Learn skill is coloured for your current skill."
  help:SetText(HELP_TEXT)

  -- Column headers, x offsets match the row layout below.
  -- The name column takes any extra width when the window is resized; the others shift with it.
  local NAME_W = 330
  local headers = {}
  for _, h in ipairs({ { 44, "Recipe" }, { 56, "Learn" }, { 102, "Yel / Grn / Grey" }, { 196, "Equip Lv" },
                       { 256, "Category" } }) do
    local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetText(h[2])
    fs.offset = h[1]
    table.insert(headers, fs)
  end
  local function PlaceHeaders(nameW)
    for i, fs in ipairs(headers) do
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", i == 1 and fs.offset or (nameW + fs.offset), -48)
    end
  end
  PlaceHeaders(NAME_W)

  local list = CR.CreateList("CraftRouteRecipeScroll", panel, 826, 410, function(row)
    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(18, 18)
    row.check:SetPoint("LEFT", 0, 0)
    row.check:SetScript("OnClick", function(self)
      local targets = CR.ProfTable("targets")
      local spell = row.recipe.spell
      if IsShiftKeyDown() then
        targets[spell] = (targets[spell] or 0) + 1
      elseif targets[spell] then
        targets[spell] = nil
      else
        targets[spell] = 1
      end
      CR.NotifyChanged()
      panel:Refresh()
    end)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 22, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetWidth(NAME_W)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.learn = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.learn:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
    row.learn:SetWidth(36)
    row.learn:SetJustifyH("RIGHT")
    row.range = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.range:SetPoint("LEFT", row.learn, "RIGHT", 10, 0)
    row.range:SetWidth(90)
    row.range:SetJustifyH("LEFT")
    row.lvl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.lvl:SetPoint("LEFT", row.range, "RIGHT", 4, 0)
    row.lvl:SetWidth(50)
    row.lvl:SetJustifyH("CENTER")
    row.cat = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.cat:SetPoint("LEFT", row.lvl, "RIGHT", 10, 0)
    row.cat:SetPoint("RIGHT", -2, 0)
    row.cat:SetJustifyH("LEFT")
    row.cat:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      CR.RecipeTooltip(GameTooltip, self.recipe)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
      if IsModifiedClick("CHATLINK") and self.recipe.item > 0 then
        local _, link = GetItemInfo(self.recipe.item)
        if link then ChatEdit_InsertLink(link) end
      end
    end)
  end, function(row, r)
    row.recipe = r
    local qty = CR.ProfTable("targets")[r.spell]
    row.check:SetChecked(qty ~= nil)
    local skill = CR.GetSkill()
    local known = CR.ProfTable("known")[r.spell]
    row.icon:SetTexture(r.item > 0 and GetItemIcon(r.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
    local name = CR.ColorText(r.name, CR.QualityHex(r.q))
    if qty and qty > 1 then name = name .. CR.ColorText(" x" .. qty, "33ccff") end
    if r.stats then name = name .. CR.ColorText("  " .. r.stats, "999999") end
    if known then name = name .. CR.ColorText("  (known)", "40bf40") end
    row.name:SetText(name)
    row.learn:SetText(CR.ColorText(tostring(r.learn), CR.DIFF_COLORS[CR.Difficulty(r, skill)]))
    row.range:SetText(string.format("%d / %d / %d", r.y, r.g, r.x))
    local lvl = CR.ItemMinLevel(r.item)
    local lvlColor = (lvl and lvl > UnitLevel("player")) and "ff8040" or "ffffff"
    row.lvl:SetText(lvl and CR.ColorText(tostring(lvl), lvlColor) or "")
    row.cat:SetText(r.cat .. (r.src == "Trainer" and "" or (" - " .. (r.pattern and "pattern" or CR.FactionText(r.src)))))
  end)
  list:SetPoint("TOPLEFT", 0, -62)
  list:SetPoint("BOTTOMRIGHT", 0, 0)
  list.onResize = function(self)
    local w = self:GetWidth()
    if type(w) ~= "number" then return end
    NAME_W = math.max(330, math.floor(w - 500))
    PlaceHeaders(NAME_W)
    for _, row in ipairs(self.rows) do row.name:SetWidth(NAME_W) end
  end

  local sorted
  function panel:Refresh()
    local prof = CR.professions[CraftRouteCharDB.profession]
    if next(prof.recipes) == nil then
      help:SetText(CR.ColorText(prof.name .. " has no recipes to pick. Switch to Cooking on the Plan tab "
        .. "to choose dishes.", "ff9966"))
    else
      help:SetText(HELP_TEXT)
    end
    if not sorted or sorted.prof ~= prof then
      sorted = { prof = prof }
      for _, r in pairs(prof.recipes) do table.insert(sorted, r) end
      table.sort(sorted, function(a, b)
        if a.learn ~= b.learn then return a.learn < b.learn end
        return a.name < b.name
      end)
    end
    local skill = CR.GetSkill()
    local targets = CR.ProfTable("targets")
    local data = {}
    for _, r in ipairs(sorted) do
      local ok = true
      if filter.selectedOnly and not targets[r.spell] then ok = false end
      if ok and filter.hideGrey and skill >= r.x and not targets[r.spell] then ok = false end
      if ok and not CategoryMatches(filter.group, r.cat) then ok = false end
      if ok and filter.text ~= "" then
        local hay = (r.name .. " " .. (r.stats or "") .. " " .. r.cat .. " " .. (r.pattern or "")):lower()
        ok = hay:find(filter.text, 1, true) ~= nil
      end
      if ok then table.insert(data, r) end
    end
    list.data = data
    list:Refresh()
  end

  return panel
end
