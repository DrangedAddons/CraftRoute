-- Compact profession-frame view.
--
-- This file does not change the /cr window. It adds one button on Blizzard's
-- ProfessionsFrame, beside TrainerSpells, and opens its own view in the frame.
-- Plan and Recipes stay on /cr. This view is only the current craft on the route:
-- the route down the left, the selected recipe and its reagents on the right.
--
-- Profession, goal, and route mode are the same saved settings as /cr. Changing
-- either window updates the other. Hand this file over with the one TOC line.

local _, CR = ...

-- 32 leaves a dark gap around the 26px category bar so the planks stay separate.
local ROW_H = 32
local TAB_ICON = "Interface\\Icons\\Ability_Druid_ChallangingRoar"
local BOOK = "Interface\\Icons\\INV_Misc_Book_09"
local REAGENT_SLOTS = 8
-- Skill bar sits under the native title. Dropdowns, then the list, follow it.
local RANK_DROP_Y = -36
local LIST_TOP = -62
local DIVIDER_TOP = -60

local overlay, entry, list
local AttachPlainCover -- secure cover for Split / Combine buttons; defined with the enchant covers
local installed = false
local installFailed = false
local openedAt = 0

local ui = {
  selectedKey = nil,
  openSteps = {},
  openParts = {}, -- component chains opened under a step's reagents
  keepScroll = false,
  openProf = nil,
  pinned = nil, -- dropdown pick that the profession frame has not switched to yet
}

---------------------------------------------------------------------------
-- Profession frame helpers
---------------------------------------------------------------------------

local function OpenProfessionName()
  local info
  if ProfessionsFrame then
    info = ProfessionsFrame.GetProfessionInfo and ProfessionsFrame:GetProfessionInfo() or ProfessionsFrame.professionInfo
  end
  if type(info) ~= "table" and C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
    info = C_TradeSkillUI.GetBaseProfessionInfo()
  end
  if type(info) ~= "table" then
    if GetTradeSkillLine then
      local name = GetTradeSkillLine()
      if name == "Smelting" then return "Mining" end
      return name ~= "" and name or nil
    end
    return nil
  end
  local name = info.parentProfessionName or info.professionName or info.name
  if name == "Smelting" then return "Mining" end
  return name
end

local function DB()
  return CraftRouteCharDB
end

local function PlanProfession()
  if ui.pinned then
    local prof = CR.professions[ui.pinned]
    if prof and prof.routes then return ui.pinned, prof end
  end
  local db = DB()
  local name = db and db.profession
  local prof = name and CR.professions[name]
  if prof and prof.routes then return name, prof end
  return nil, nil
end

local function ProfessionLabel(name)
  local cur, maxRank, detected = CR.GetSkill(name)
  if detected then return string.format("%s  %d/%d", name, cur, maxRank) end
  return name .. CR.ColorText("  (not learned)", "888888")
end

local function ProfessionOptions()
  local db = DB()
  local learned, other = {}, {}
  for _, name in ipairs(CR.SupportedProfessions()) do
    local _, _, detected = CR.GetSkill(name)
    table.insert(detected and learned or other, { value = name, text = ProfessionLabel(name) })
  end
  local showAll = not db or db.showUnlearned or #learned == 0
  local selected = db and db.profession
  for _, o in ipairs(other) do
    if showAll or o.value == selected then table.insert(learned, o) end
  end
  return learned
end

local function SelectProfession(name)
  local db = DB()
  if not db or not CR.professions[name] then return end
  db.profession = name
  db.profPicked = true
  ui.pinned = name
  ui.selectedKey = nil
  wipe(ui.openSteps)
  wipe(ui.openParts)
  ui.keepScroll = false
  -- (the window itself is opened by the secure cover on the dropdown entry - addon code can't)
  CR.InvalidatePlan()
  if overlay and overlay:IsShown() then overlay:Refresh() end
  CR.NotifyChanged()
end

-- Adopt the profession the frame is showing, when that profession has a route.
-- A dropdown pick of an unlearned profession stays put until the open one changes.
local function SyncOpenProfession()
  local name = OpenProfessionName()
  if not name or name == "" then return end
  if name == ui.openProf then return end
  ui.openProf = name
  local prof = name and CR.professions[name]
  if not (prof and prof.routes) then return end
  ui.pinned = nil
  local db = DB()
  if db and db.profession ~= name then
    db.profession = name
    db.profPicked = true
    ui.selectedKey = nil
    wipe(ui.openSteps)
    wipe(ui.openParts)
    ui.keepScroll = false
    CR.InvalidatePlan()
    CR.NotifyChanged()
  end
end

local function ProfessionOf(recipe)
  if not recipe then return nil end
  for name, prof in pairs(CR.professions) do
    if prof.recipes[recipe.spell] then return name end
  end
end

local function RecipeLearned(profName, recipe)
  if not recipe then return nil end
  if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and CR.TradeSkillOpenFor(profName) then
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipe.spell)
    if ok and info and info.learned ~= nil then return info.learned end
  end
  local known = CR.ProfTable("known", profName)
  if known[recipe.spell] then return true end
  return nil
end

local function CraftsReady(profName, recipe)
  if not recipe then return 0 end
  if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and CR.TradeSkillOpenFor(profName) then
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipe.spell)
    if ok and info and type(info.numAvailable) == "number" then return info.numAvailable end
  end
  local n = math.huge
  for _, rg in ipairs(recipe.reagents or {}) do
    local bags = select(1, CR.BagsAndElsewhere(rg[1]))
    n = math.min(n, math.floor(bags / math.max(1, rg[2])))
  end
  if n == math.huge then return 0 end
  return n
end

local function CraftSpell(spell, count, profName)
  if InCombatLockdown() then CR.Print("Can't craft in combat.") return end
  count = math.max(1, math.floor(count or 1))
  if profName and not CR.TradeSkillOpenFor(profName) then
    CR.OpenTradeSkill(profName)   -- just says how: opening needs a click on an Open button
    return
  end
  if C_TradeSkillUI and C_TradeSkillUI.CraftRecipe then
    local ok, err = pcall(C_TradeSkillUI.CraftRecipe, spell, count)
    if not ok then CR.Print("Couldn't craft: " .. tostring(err)) end
  else
    CR.Print("This client has no CraftRecipe. Use /cr.")
  end
end

local function StepKey(st)
  if st.recipe then return st.kind .. ":" .. st.recipe.spell .. ":" .. (st.from or 0) end
  return (st.kind or "note") .. ":" .. (st.from or 0) .. ":" .. (st.text or "")
end

local function IsOpen(key)
  local forced = ui.openSteps[key]
  if forced ~= nil then return forced end
  return key == ui.selectedKey
end

local function RangeLabel(st)
  local range
  if st.from and st.to and st.to ~= st.from then
    range = st.from .. "-" .. st.to
  elseif st.from and st.from > 0 then
    range = tostring(st.from)
  else
    range = ""
  end
  local count = (st.estimated and "~" or "") .. (st.crafts or 0) .. "x"
  local text = count
  if range ~= "" then text = text .. "  " .. range end
  if st.skill == "Fishing" then return CR.ColorText("Fish ", "4fc3f7") .. CR.ColorText(text, "b0b0b0") end
  if st.skill == "Cooking" then return CR.ColorText("Cook ", "ffb74d") .. CR.ColorText(text, "b0b0b0") end
  return CR.ColorText(text, "b0b0b0")
end

-- Same rule as the Craft tab: the count is what you own (bags, plus bank / alts when bags are
-- short); green = the whole step is in your bags, yellow = at least one craft counting bank /
-- alts, red = not even one.
local function HaveNeed(itemID, per, crafts)
  per = per or 1
  local need = per * math.max(1, crafts or 1)
  local bags, elsewhere = CR.BagsAndElsewhere(itemID)
  local color = CR.ReagentColor(bags, elsewhere, need, per)
  local have = bags >= need and bags or (bags + elsewhere)
  return CR.ColorText(tostring(have), color) .. "/" .. need .. "  " .. CR.ItemName(itemID), bags, need
end

local function Changed()
  ui.keepScroll = false
  CR.InvalidatePlan()
  if overlay and overlay:IsShown() then overlay:Refresh() end
  CR.NotifyChanged()
end

---------------------------------------------------------------------------
-- Left-hand route list
---------------------------------------------------------------------------

-- SetAtlas returns false when the atlas is missing, and throws on some clients.
local function TryAtlas(tex, atlas, useSize)
  if not tex or not atlas or not tex.SetAtlas then return false end
  local ok, result = pcall(tex.SetAtlas, tex, atlas, useSize and true or false)
  return ok and result ~= false
end

local function ResetRow(row)
  row.item = nil
  row.bg:SetColorTexture(0, 0, 0, 0)
  row.sel:Hide()
  row.hover:Hide()
  row.icon:Hide()
  row.barLeft:Hide()
  row.barMid:Hide()
  row.barRight:Hide()
  row.chevron:Hide()
  row.chevron.glow:Hide()
  row.name:SetText("")
  row.name:SetTextColor(1, 1, 1)
  row.right:SetText("")
  row.act:Hide()
  row.act:SetScript("OnClick", nil)
  row.buy:Hide()
  row.buy:SetScript("OnClick", nil)
  row.actMacro = nil
  row.name:ClearAllPoints()
  row.name:SetPoint("LEFT", 8, 0)
  row.name:SetPoint("RIGHT", row.right, "LEFT", -4, 0)
  row:SetScript("OnClick", nil)
  row:SetScript("OnEnter", nil)
end

local function ShowTooltip(row)
  local item = row.item
  if not item then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if item.kind == "reagent" then
    GameTooltip:SetItemByID(item.itemID)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Where you have it:", 1, 0.82, 0)
    CR.AddLocationLines(GameTooltip, item.itemID)
    local info = item.info
    if info then
      GameTooltip:AddLine(" ")
      local what = info.recipe and ((info.smelting and "Smelt it" or "Make it") .. " with " .. info.prof.name)
        or (info.convert.uses > 1 and "Combine 3 lesser into 1 greater" or "Split 1 greater into 3 lesser")
      GameTooltip:AddLine(what .. " - click + to see what from.", 0.2, 1, 0.2, true)
      if info.missing > 0 then
        GameTooltip:AddLine(string.format("%d short: %d %s cover it.", info.missing, info.toMake,
          info.recipe and "crafts" or "uses"), 1, 0.4, 0.4, true)
      end
      if info.recipe and info.learned == false then
        GameTooltip:AddLine("Not learned: " .. CR.FactionText(info.recipe.pattern or info.recipe.src or ""), 1, 0.6, 0.4, true)
      elseif info.recipe and not info.skillOK then
        GameTooltip:AddLine("Needs " .. info.recipe.learn .. " " .. info.prof.name .. " skill.", 1, 0.4, 0.4, true)
      end
    end
  elseif item.kind == "step" and item.step and item.step.recipe then
    CR.RecipeTooltip(GameTooltip, item.step.recipe, item.step.crafts)
    if item.step.note then GameTooltip:AddLine(CR.FactionText(item.step.note), 0.7, 0.7, 0.7, true) end
    if item.step.auto then GameTooltip:AddLine("Filled in past the end of the guide.", 1, 0.6, 0.4, true) end
    GameTooltip:AddLine(item.open and "Click to collapse." or "Click to expand the reagents.", 0.6, 0.6, 0.6)
  elseif item.kind == "option" and item.step then
    local st = item.step
    GameTooltip:SetText(st.letter .. ": " .. st.label)
    GameTooltip:AddLine(st.selected and "Selected for the route." or "Click to use this one.", 0.6, 0.8, 1, true)
  elseif item.kind == "note" then
    GameTooltip:SetText(item.tip or item.text or "")
  else
    GameTooltip:Hide()
    return
  end
  GameTooltip:Show()
end

local function ApplyRow(row, item)
  ResetRow(row)
  row.item = item
  row:SetScript("OnEnter", function(self)
    self.hover:Show()
    ShowTooltip(self)
  end)
  row:SetScript("OnLeave", function(self)
    self.hover:Hide()
    GameTooltip_Hide()
  end)

  if item.kind == "note" then
    row.name:SetText(item.text or "")
    -- 0 is falsy, so `gold and 0 or 0.75` cannot produce a gold blue channel.
    if item.gold then
      row.name:SetTextColor(1, 0.82, 0)
    else
      row.name:SetTextColor(0.75, 0.75, 0.75)
    end
    if item.icon then
      row.icon:SetTexture(item.icon)
      row.icon:Show()
      row.icon:ClearAllPoints()
      row.icon:SetPoint("LEFT", 6, 0)
      row.name:ClearAllPoints()
      row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
      row.name:SetPoint("RIGHT", -8, 0)
    end
    return
  end

  if item.kind == "option" then
    local st = item.step
    if st.selected then row.sel:Show() end
    row.name:SetText((st.letter or "") .. "   " .. (st.label or ""))
    row.name:SetTextColor(st.selected and 0.75 or 0.85, st.selected and 1 or 0.78, st.selected and 0.7 or 0.55)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", 18, 0)
    row.name:SetPoint("RIGHT", -8, 0)
    row:SetScript("OnClick", function()
      if st.selected then return end
      CR.ProfTable("choices", st.routeID)[st.choice] = st.option
      ui.selectedKey = nil
      ui.keepScroll = true
      CR.InvalidatePlan()
      if overlay and overlay:IsShown() then overlay:Refresh() end
      CR.NotifyChanged()
    end)
    return
  end

  if item.kind == "reagent" then
    row.icon:SetTexture(CR.GetItemIcon(item.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:Show()
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", 26 + (item.level - 1) * 12, 0)
    row.name:SetText(HaveNeed(item.itemID, item.per, item.crafts))
    local info = item.info
    local toggle = info and (item.short or item.open)
    local rightmost = row.chevron
    if toggle then
      -- + / - opens what it's made from, a level further in
      row.chevron:Show()
      row.chevron.icon:Hide()
      row.chevron.glow:Hide()
      row.chevron.label:Show()
      row.chevron.label:SetText(item.open and "-" or "+")
      row.chevron:SetScript("OnClick", function()
        ui.openParts[item.key] = not item.open or nil
        ui.keepScroll = true
        if overlay then overlay:Refresh() end
      end)
      -- what one click does
      local a = row.act
      a:Show()
      a:Disable()
      if info.recipe then
        if info.learned == false then
          a:SetText("Learn")
        elseif not info.skillOK then
          a:SetText("Skill")
        elseif not info.open then
          a:SetText("Open")
          a:SetEnabled(not InCombatLockdown())
          a:SetScript("OnClick", function() CR.OpenTradeSkill(info.prof.name) end)
          row.actMacro = CR.OpenProfessionMacro(info.prof.name)   -- the secure cover casts it
        else
          local n = info.count or 0
          a:SetText((info.smelting and "Smelt " or "Make ") .. n)
          a:SetEnabled(n > 0 and not InCombatLockdown())
          a:SetScript("OnClick", function() CraftSpell(info.recipe.spell, n, info.prof.name) end)
        end
      else
        a:SetText(info.convert.uses > 1 and "Combine" or "Split")
        a:SetEnabled(info.available > 0 and not InCombatLockdown())
        row.actMacro = info.macro
      end
      rightmost = a
    end
    -- Buy, while a vendor that sells it is open and your bags are short
    if item.short and CR.MerchantSells and CR.MerchantSells(item.itemID) then
      row.buy:Show()
      row.buy:ClearAllPoints()
      row.buy:SetPoint("RIGHT", toggle and rightmost or row, toggle and "LEFT" or "RIGHT", toggle and -2 or -6, 0)
      local need, id = item.need, item.itemID
      row.buy:SetScript("OnClick", function(self)
        CR.OpenBuy(id, need - (CR.BagsAndElsewhere(id)), self, function(i)
          return math.max(0, need - (CR.BagsAndElsewhere(i)))
        end, overlay)
      end)
      rightmost = row.buy
    end
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    if rightmost ~= row.chevron or toggle then
      row.name:SetPoint("RIGHT", rightmost, "LEFT", -4, 0)
    else
      row.name:SetPoint("RIGHT", -8, 0)
    end
    row:SetScript("OnClick", function()
      if IsModifiedClick("CHATLINK") then
        local _, link = CR.GetItemInfo(item.itemID)
        if link then ChatEdit_InsertLink(link) end
      elseif toggle then
        ui.openParts[item.key] = not item.open or nil
        ui.keepScroll = true
        if overlay then overlay:Refresh() end
      end
    end)
    return
  end

  -- Route step. The name sits on the same wood header the professions list uses.
  local st = item.step
  if row.headerReady then
    row.barLeft:Show()
    row.barMid:Show()
    row.barRight:Show()
  end
  if item.selected then row.sel:Show() end
  row.icon:SetTexture(CR.RecipeIcon(st.recipe))
  row.icon:Show()
  row.icon:ClearAllPoints()
  row.icon:SetPoint("LEFT", 8, 0)
  local name = st.recipe.name
  if st.kind == "target" then name = CR.ColorText("Target: ", "33ccff") .. name end
  if st.kind == "extra" then name = CR.ColorText("+ ", "aaaaaa") .. name end
  row.name:SetText(name)
  if item.selected or st.kind ~= "craft" then
    row.name:SetTextColor(1, 1, 1)
  else
    row.name:SetTextColor(1, 0.82, 0)
  end
  row.chevron:Show()
  local chevronAtlas = item.open and "Professions-recipe-header-collapse" or "Professions-recipe-header-expand"
  -- Native draws the glyph once, then the same atlas again with ADD. The base
  -- holds the drop shadow. The ADD copy is what makes the stroke thick and gold.
  local drewChevron = TryAtlas(row.chevron.icon, chevronAtlas, true)
  row.chevron.icon:SetShown(drewChevron)
  row.chevron.label:SetShown(not drewChevron)
  if drewChevron then
    row.chevron.icon:SetVertexColor(1, 1, 1)
    if TryAtlas(row.chevron.glow, chevronAtlas, true) then
      row.chevron.glow:SetVertexColor(1, 1, 1)
      row.chevron.glow:SetAlpha(1)
      row.chevron.glow:Show()
    else
      row.chevron.glow:Hide()
    end
  else
    row.chevron.glow:Hide()
    row.chevron.label:SetText(item.open and "-" or "+")
  end
  row.right:SetText(RangeLabel(st))
  row.name:ClearAllPoints()
  row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
  row.name:SetPoint("RIGHT", row.right, "LEFT", -4, 0)
  row.chevron:SetScript("OnClick", function()
    ui.openSteps[item.key] = not item.open
    ui.keepScroll = true
    if overlay then overlay:Refresh() end
  end)
  row:SetScript("OnClick", function()
    if IsModifiedClick("CHATLINK") and st.recipe.item and st.recipe.item > 0 then
      local _, link = CR.GetItemInfo(st.recipe.item)
      if link then ChatEdit_InsertLink(link) end
      return
    end
    ui.selectedKey = item.key
    ui.openSteps[item.key] = not item.open
    ui.keepScroll = true
    if overlay then overlay:Refresh() end
  end)
end

local function CreateRow(parent)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(ROW_H)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.barLeft = row:CreateTexture(nil, "BACKGROUND")
  row.barLeft:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.barRight = row:CreateTexture(nil, "BACKGROUND")
  row.barRight:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.barMid = row:CreateTexture(nil, "BACKGROUND")
  row.barMid:SetPoint("TOPLEFT", row.barLeft, "TOPRIGHT", 0, 0)
  row.barMid:SetPoint("BOTTOMRIGHT", row.barRight, "BOTTOMLEFT", 0, 0)
  local leftOK = TryAtlas(row.barLeft, "Professions-recipe-header-left", true)
  local rightOK = TryAtlas(row.barRight, "Professions-recipe-header-right", true)
  local midOK = TryAtlas(row.barMid, "Professions-recipe-header-middle", false)
  row.headerReady = leftOK and rightOK and midOK
  -- Leave the caps at the atlas size (14x26). Squashing them cuts off the
  -- top and bottom bevel, and the rows stop reading as separate planks.
  row.barLeft:Hide()
  row.barMid:Hide()
  row.barRight:Hide()
  row.sel = row:CreateTexture(nil, "ARTWORK")
  row.sel:SetAllPoints()
  row.sel:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  row.sel:SetBlendMode("ADD")
  row.sel:Hide()
  row.hover = row:CreateTexture(nil, "HIGHLIGHT")
  row.hover:SetAllPoints()
  row.hover:SetColorTexture(1, 1, 1, 0.06)
  row.hover:Hide()
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(18, 18)
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  row.chevron = CreateFrame("Button", nil, row)
  row.chevron:SetSize(28, 22)
  row.chevron:SetPoint("RIGHT", -6, 1)
  row.chevron.icon = row.chevron:CreateTexture(nil, "ARTWORK")
  row.chevron.icon:SetPoint("CENTER", 0, 0)
  row.chevron.glow = row.chevron:CreateTexture(nil, "OVERLAY")
  row.chevron.glow:SetPoint("CENTER", row.chevron.icon, "CENTER", 0, 0)
  row.chevron.glow:SetBlendMode("ADD")
  row.chevron.glow:Hide()
  row.chevron.label = row.chevron:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.chevron.label:SetPoint("CENTER", 0, 1)
  row.chevron.label:SetTextColor(1, 0.82, 0)
  if row.chevron.label.SetShadowOffset then
    row.chevron.label:SetShadowColor(0, 0, 0, 0.9)
    row.chevron.label:SetShadowOffset(1, -1)
  end
  row.chevron.label:Hide()
  row.chevron:Hide()
  row.act = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.act:SetSize(62, 20)
  row.act:SetPoint("RIGHT", row.chevron, "LEFT", -2, 0)
  row.act:Hide()
  row.buy = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.buy:SetSize(36, 20)
  row.buy:SetText("Buy")
  row.buy:Hide()
  -- essences split / combine by using the item, which needs a secure click
  row.actCover = AttachPlainCover and AttachPlainCover(row.act, function() return row.actMacro or "" end,
    function() return overlay and overlay:IsShown() and row:IsVisible() and row.act:IsShown() and row.actMacro ~= nil end)
  row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.right:SetPoint("RIGHT", row.chevron, "LEFT", -2, 0)
  row.right:SetWidth(78)
  row.right:SetJustifyH("RIGHT")
  row.right:SetWordWrap(false)
  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel", function(_, delta)
    if list and list.Wheel then list:Wheel(delta) end
  end)
  return row
end

local function CreateList(parent)
  local holder = CreateFrame("Frame", nil, parent)
  holder:EnableMouseWheel(true)
  local rows = {}
  local data = {}
  local offset = 0
  local slider = CreateFrame("Slider", nil, holder)
  slider:SetOrientation("VERTICAL")
  slider:SetWidth(12)
  slider:SetPoint("TOPRIGHT", 0, 0)
  slider:SetPoint("BOTTOMRIGHT", 0, 0)
  slider:SetValueStep(1)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  local thumb = slider:GetThumbTexture()
  if thumb then thumb:SetSize(12, 24) end

  local function Visible()
    return math.max(1, math.floor((holder:GetHeight() + 1) / ROW_H))
  end
  local function MaxOffset()
    return math.max(0, #data - Visible())
  end
  local function Paint()
    offset = math.max(0, math.min(offset, MaxOffset()))
    local vis = Visible()
    for i = 1, vis do
      local row = rows[i]
      if not row then
        row = CreateRow(holder)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -14, -(i - 1) * ROW_H)
        rows[i] = row
      end
      local item = data[offset + i]
      row:SetShown(item ~= nil)
      if item then ApplyRow(row, item) end
    end
    for i = vis + 1, #rows do rows[i]:Hide() end
  end
  local function ApplySlider()
    local maxOff = MaxOffset()
    slider.silent = true
    slider:SetMinMaxValues(0, math.max(1, maxOff))
    slider:SetValue(maxOff - offset)
    slider.silent = false
    slider:SetShown(maxOff > 0)
  end
  slider:SetScript("OnValueChanged", function(self, value)
    if self.silent then return end
    offset = math.max(0, MaxOffset() - math.floor(value + 0.5))
    Paint()
  end)
  function holder:Wheel(delta)
    offset = math.max(0, math.min(MaxOffset(), offset - delta))
    Paint()
    ApplySlider()
  end
  holder:SetScript("OnMouseWheel", function(_, delta) holder:Wheel(delta) end)
  holder:SetScript("OnSizeChanged", function()
    Paint()
    ApplySlider()
  end)
  function holder:SetData(items, keep)
    data = items or {}
    if not keep then offset = 0 end
    Paint()
    ApplySlider()
  end
  return holder
end

---------------------------------------------------------------------------
-- What the route still has left to make
---------------------------------------------------------------------------

-- The profession whose recipes count as "its own" for components (the combined guide crafts Cooking).
local function CraftProf(name)
  local route = CR.Route(name)
  return CR.professions[route and route.recipeProf or name]
end

-- A step's reagents, and under any opened one what it's made from, a level further in (up to 8
-- levels: scraps -> Light -> ... -> Rugged Leather). mult: crafts the level above needs.
local function AddReagents(items, reagents, mult, level, prof, keyPrefix, path)
  for _, rg in ipairs(reagents) do
    local id = rg[1]
    local need = rg[2] * mult
    local key = keyPrefix .. ">" .. id
    local info = (level < 8 and not path[id] and CR.ComponentInfo) and CR.ComponentInfo(prof, id, need) or nil
    local bags = CR.BagsAndElsewhere(id)
    local open = info and ui.openParts[key] and true or false
    table.insert(items, {
      kind = "reagent", itemID = id, per = rg[2], crafts = mult, need = need, level = level,
      key = key, info = info, open = open, short = bags < need,
    })
    if open then
      path[id] = true   -- never loop (essences convert both ways)
      AddReagents(items, info.reagents, math.max(1, info.toMake), level + 1, info.prof, key, path)
      path[id] = nil
    end
  end
end

local function BuildItems()
  local name = PlanProfession()
  local openName = OpenProfessionName()
  local openHasRoute = openName and CR.professions[openName] and CR.professions[openName].routes
  if openName and openName ~= "" and not openHasRoute and not ui.pinned then
    return nil, nil, "CraftRoute has no leveling route for " .. openName .. "."
  end
  if not name then return nil, nil, "Open a crafting profession." end
  local entry = CR.GetPlans(name)
  local plan = entry and entry.plan
  if not plan then return nil, nil, "No plan for " .. name .. "." end

  local crafts = {}
  for _, st in ipairs(plan.steps) do
    if st.recipe and (st.kind == "craft" or st.kind == "extra" or st.kind == "target") then
      table.insert(crafts, st)
    end
  end
  local selected
  if ui.selectedKey then
    for _, st in ipairs(crafts) do
      if StepKey(st) == ui.selectedKey then selected = st end
    end
  end
  if not selected then selected = crafts[1] end
  ui.selectedKey = selected and StepKey(selected) or nil

  local items = {}
  for _, st in ipairs(plan.steps) do
    if st.kind == "fork" then
      table.insert(items, { kind = "note", gold = true, text = "Choose one", tip = st.text or "Choose one" })
    elseif st.kind == "option" then
      table.insert(items, { kind = "option", step = st })
    elseif st.kind == "guide" or st.kind == "train" then
      table.insert(items, {
        kind = "note", step = st, gold = st.kind == "train",
        icon = st.kind == "train" and BOOK or nil,
        text = CR.FactionText(st.text or ""),
        tip = CR.FactionText(st.text or ""),
      })
    elseif st.recipe and (st.kind == "craft" or st.kind == "extra" or st.kind == "target") then
      local key = StepKey(st)
      local open = IsOpen(key)
      table.insert(items, {
        kind = "step", step = st, key = key, open = open, selected = key == ui.selectedKey,
      })
      if open then
        AddReagents(items, st.recipe.reagents or {}, st.crafts or 1, 1, CraftProf(name), key, {})
        if not st.recipe.reagents or #st.recipe.reagents == 0 then
          table.insert(items, { kind = "note", text = CR.ColorText("No reagents.", "808080") })
        end
      end
    end
  end
  local ahead = selected and selected ~= crafts[1]
  return items, { profName = name, entry = entry, selected = selected, ahead = ahead }, nil
end

local function CostLines(recipe, crafts)
  local lines = {}
  local one, onePriced, oneGap = 0, false, false
  local missing, missPriced = 0, false
  local unpricedOne, unpricedStep = false, false
  for _, rg in ipairs(recipe.reagents or {}) do
    local per = rg[2] or 0
    local bags = select(1, CR.BagsAndElsewhere(rg[1]))
    local price = CR.GetUnitPrice(rg[1])
    if per > 0 then
      oneGap = true
      if price then
        one = one + price * per
        onePriced = true
      else
        unpricedOne = true
      end
      local short = math.max(0, per * crafts - bags)
      if short > 0 then
        if price then
          missing = missing + price * short
          missPriced = true
        else
          unpricedStep = true
        end
      end
    end
  end
  if onePriced then
    table.insert(lines, CR.ColorText("To Craft:", "ffd100") .. "  " .. CR.FormatMoney(one)
      .. (unpricedOne and CR.ColorText(" +", "808080") or ""))
  elseif oneGap then
    table.insert(lines, CR.ColorText("To Craft:", "ffd100") .. "  " .. CR.ColorText("unknown", "808080"))
  end
  if crafts > 1 then
    -- A short reagent always sets missPriced or unpricedStep, so the other case is fully stocked.
    if missPriced or unpricedStep then
      local value = missPriced and CR.FormatMoney(missing) or CR.ColorText("unknown", "808080")
      table.insert(lines, CR.ColorText("This step:", "ffd100") .. "  " .. value
        .. (unpricedStep and missPriced and CR.ColorText(" +", "808080") or ""))
    else
      table.insert(lines, CR.ColorText("This step:", "ffd100") .. "  " .. CR.ColorText("in your bags", "40ff40"))
    end
  end
  if recipe.item and recipe.item > 0 and onePriced and not unpricedOne then
    local out = CR.GetUnitPrice(recipe.item)
    if out then
      local profit = out * (recipe.makes or 1) - one
      local shown
      if profit < 0 then
        shown = CR.ColorText("-", "ff4040") .. CR.FormatMoney(-profit)
      else
        shown = CR.FormatMoney(profit)
      end
      table.insert(lines, CR.ColorText("Profit:", "ffd100") .. "  " .. shown)
    end
  end
  return table.concat(lines, "\n")
end

-- Secure covers for the enchant target and the Enchant button. The game will not parent a
-- secure button to an addon frame, so each one sits on UIParent and is moved by screen
-- position, the same way /cr covers its Enchant button. The click runs CR.EnchantClick,
-- which casts and, when the item already has an enchant, returns the /click that answers
-- the replace prompt.
local enchantSecure = {}

local function PlaceEnchantCover(b, target)
  local left, bottom, width, height = target:GetLeft(), target:GetBottom(), target:GetWidth(), target:GetHeight()
  if not (left and bottom and width and height) then return false end
  local scale = target:GetEffectiveScale() / UIParent:GetEffectiveScale()
  local x, y = left * scale, bottom * scale
  local key = x .. "," .. y .. "," .. width * scale .. "," .. height * scale
  if b.placed ~= key then
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    b:SetSize(width * scale, height * scale)
    b.placed = key
  end
  return true
end

-- Compact sits hundreds of frame levels above the profession window. A cover in the same
-- strata, even at a higher level, stays underneath that window, so the click reaches the
-- button itself. One strata up is above it. Tooltip stays above the cover.
local COVER_STRATA = {
  BACKGROUND = "LOW",
  LOW = "MEDIUM",
  MEDIUM = "HIGH",
  HIGH = "DIALOG",
  DIALOG = "FULLSCREEN",
  FULLSCREEN = "FULLSCREEN_DIALOG",
  FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
}

local function SyncEnchantSecure()
  if InCombatLockdown() or CR.inCombat then return end
  for _, b in ipairs(enchantSecure) do
    local want = b.wanted and b.wanted()
    local enabled = true
    if b.target.IsEnabled then enabled = b.target:IsEnabled() and true or false end
    local show = want and b.target:IsVisible() and enabled and PlaceEnchantCover(b, b.target)
    b:SetShown(show and true or false)
    if show then
      local strata = b.target:GetFrameStrata()
      b:SetFrameStrata(COVER_STRATA[strata] or strata)
      b:SetFrameLevel(math.min(b.target:GetFrameLevel() + 20, 9999))
    end
  end
end

local combatHide = CreateFrame("Frame")
combatHide:RegisterEvent("PLAYER_REGEN_DISABLED")
combatHide:SetScript("OnEvent", function()
  for _, b in ipairs(enchantSecure) do b:Hide() end
end)

local function AttachEnchantCover(target, onClick)
  local ok, b = pcall(CreateFrame, "Button", nil, UIParent, "SecureActionButtonTemplate")
  if not (ok and b) then return nil end
  b:SetSize(1, 1)
  b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "macro")
  b:SetAttribute("macrotext", "")
  b:Hide()
  b:SetScript("PreClick", function(self, button, down)
    if InCombatLockdown() then return end
    if down or not self.downSeen then
      self.downSeen = down and true or false
      self.answer = onClick(button) or ""
      self:SetAttribute("macrotext", self.answer)
    else
      self.downSeen = false
      local _, yes = CR.VisibleReplacePopup()
      local ours = self.answer ~= "" or (CR.enchantPendingUntil and GetTime() < CR.enchantPendingUntil)
      self:SetAttribute("macrotext", (yes and ours) and ("/click " .. yes) or "")
      if yes and ours then CR.enchantPendingUntil = nil end
      self.answer = nil
    end
  end)
  b:SetScript("OnEnter", function()
    local enter = target:GetScript("OnEnter")
    if enter then enter(target) end
  end)
  b:SetScript("OnLeave", function()
    local leave = target:GetScript("OnLeave")
    if leave then leave(target) end
  end)
  b.target = target
  b.wanted = function()
    return overlay and overlay:IsShown() and overlay.enchant and overlay.enchant:IsShown()
  end
  table.insert(enchantSecure, b)
  return b
end

-- Split / Combine: using an item needs a real click, so a secure cover over the row's button
-- runs /use on the press the game acts on (press-down with "cast on key down", else release).
AttachPlainCover = function(target, onClick, wanted)
  if InCombatLockdown() then return nil end
  local ok, b = pcall(CreateFrame, "Button", nil, UIParent, "SecureActionButtonTemplate")
  if not (ok and b) then return nil end
  b:SetSize(1, 1)
  b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "macro")
  b:SetAttribute("macrotext", "")
  b:Hide()
  b:SetScript("PreClick", function(self, button, down)
    if InCombatLockdown() then return end
    local onDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false
    local act = (down and true or false) == (onDown and true or false)
    self:SetAttribute("macrotext", act and (onClick(button) or "") or "")
  end)
  local row = target:GetParent()
  b:SetScript("OnEnter", function()
    local enter = row and row:GetScript("OnEnter")
    if enter then enter(row) end
  end)
  b:SetScript("OnLeave", function()
    local leave = row and row:GetScript("OnLeave")
    if leave then leave(row) end
  end)
  b.target = target
  b.wanted = wanted
  table.insert(enchantSecure, b)
  return b
end

local function FillSchematic(info)
  local frame = overlay
  local st = info and info.selected
  local recipe = st and st.recipe
  frame.icon:SetShown(recipe ~= nil)
  frame.rName:SetShown(recipe ~= nil)
  frame.rSub:SetShown(recipe ~= nil)
  frame.rStructure:SetShown(recipe ~= nil)
  frame.reagentsLabel:SetShown(recipe ~= nil)
  frame.cost:SetShown(recipe ~= nil)
  frame.buttons:SetShown(recipe ~= nil)
  if not recipe then
    for i = 1, REAGENT_SLOTS do frame.reagents[i]:Hide() end
    frame.detailEmpty:SetText(info and info.entry and info.entry.cur >= info.entry.goal
      and ("Goal reached (" .. info.entry.goal .. "). Raise it in the route dropdown.")
      or "Nothing left to craft on this route.")
    frame.detailEmpty:Show()
    if frame.UpdateEnchant then frame:UpdateEnchant(nil) end
    SyncEnchantSecure()
    return
  end
  frame.detailEmpty:Hide()

  local profName = ProfessionOf(recipe) or info.profName
  local cur = CR.GetSkill(info.profName)
  local diff = CR.Difficulty(recipe, cur)
  local diffWord = ({ orange = "orange", yellow = "yellow", green = "green", grey = "grey", red = "too soon" })[diff]
  frame.icon.texture:SetTexture(CR.RecipeIcon(recipe))
  frame.rName:SetText(recipe.name)
  local range
  if st.from and st.to and st.to ~= st.from then range = st.from .. "-" .. st.to
  elseif st.from and st.from > 0 then range = tostring(st.from)
  else range = "" end
  local sub = (st.estimated and "~" or "") .. (st.crafts or 0) .. "x"
  if range ~= "" then sub = range .. "   " .. sub end
  if diffWord then sub = sub .. "   " .. CR.ColorText(diffWord, CR.DIFF_COLORS[diff] or "ffffff") end
  if info.ahead then sub = sub .. CR.ColorText("   looking ahead", "aaaaaa") end
  frame.rSub:SetText(sub)
  local structure = CR.StructureText(recipe)
  frame.rStructure:SetText(structure or "")

  local reagents = recipe.reagents or {}
  local sw = frame.schemW or frame.schematic:GetWidth() or 0
  if sw < 40 then sw = 240 end
  local rowW = math.max(80, sw - 4)
  -- Leave the icon, the cost block, the status line, and the craft buttons clear of each other.
  local schemH = frame.schemH or frame.schematic:GetHeight() or 0
  local cap = REAGENT_SLOTS
  if schemH >= 120 then
    -- Icon, reagent label, cost block, craft buttons, and the enchant target when this recipe needs one.
    local bottom = 130
    if CR.EnchantSlotFor(recipe) then bottom = bottom + 58 end
    local usable = schemH - 100 - bottom
    cap = math.floor(usable / 40)
    if cap < 1 then cap = 1 end
    if cap > REAGENT_SLOTS then cap = REAGENT_SLOTS end
  end
  local shown = math.min(#reagents, cap)
  local anchor = frame.reagentsLabel
  for i = 1, REAGENT_SLOTS do
    local row = frame.reagents[i]
    local rg = reagents[i]
    if i <= shown and rg then
      row:Show()
      row:SetWidth(rowW)
      row.icon:SetTexture(CR.GetItemIcon(rg[1]) or "Interface\\Icons\\INV_Misc_QuestionMark")
      local text, bags, need = HaveNeed(rg[1], rg[2], st.crafts or 1)
      row.text:SetText(text)
      row.itemID = rg[1]
      local canBuy = bags < need and CR.MerchantSells and CR.MerchantSells(rg[1])
      row.buy:SetShown(canBuy and true or false)
      row.text:SetPoint("RIGHT", row, "RIGHT", canBuy and -44 or -4, 0)
      local id, needAll = rg[1], need
      row.buy:SetScript("OnClick", canBuy and function(self)
        CR.OpenBuy(id, needAll - (CR.BagsAndElsewhere(id)), self, function(i)
          return math.max(0, needAll - (CR.BagsAndElsewhere(i)))
        end, overlay)
      end or nil)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -6 or -4)
      anchor = row
    else
      row:Hide()
    end
  end
  if #reagents > shown then
    frame.cost:SetText("+" .. (#reagents - shown) .. " more on the list\n" .. CostLines(recipe, st.crafts or 1))
  else
    frame.cost:SetText(CostLines(recipe, st.crafts or 1))
  end
  frame.cost:ClearAllPoints()
  frame.cost:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
  frame.cost:SetWidth(math.max(40, sw - 8))

  local learned = RecipeLearned(profName, recipe)
  local enchantFits = CR.EnchantSlotFor(recipe)
  local open = CR.TradeSkillOpenFor(profName)
  local ready = CraftsReady(profName, recipe)
  local canCraft = open and learned ~= false and not enchantFits
  local enchantTarget
  if frame.UpdateEnchant then
    enchantTarget = frame:UpdateEnchant(recipe, open and learned ~= false and ready > 0)
  end
  frame.createAll:SetShown(canCraft)
  frame.create:SetShown(open and learned ~= false)
  frame.countBox:SetShown(canCraft)
  frame.prevBtn:SetShown(canCraft)
  frame.nextBtn:SetShown(canCraft)
  frame.openBtn:SetShown(not open)
  frame.createAll:SetText(string.format("Create All [%d]", ready))
  frame.createAll:SetEnabled(ready > 0 and not InCombatLockdown())
  if enchantFits then
    frame.create:SetText("Enchant")
    local answering = CR.VisibleReplacePopup() ~= nil
    frame.create:SetEnabled(((open and learned ~= false and ready > 0 and enchantTarget ~= nil) or answering)
      and not InCombatLockdown())
  else
    frame.create:SetText("Create")
    frame.create:SetEnabled(canCraft and ready > 0 and not InCombatLockdown())
  end
  frame.openBtn:SetText("Open " .. profName)
  frame.openBtn:SetEnabled(not InCombatLockdown())
  if not frame.countBox:HasFocus() and frame.lastSpell ~= recipe.spell then
    local want = math.max(1, math.min(st.crafts or 1, ready > 0 and ready or (st.crafts or 1)))
    frame.countBox:SetText(tostring(want))
  end
  frame.lastSpell = recipe.spell
  frame.current = st
  frame.craftProf = profName

  local _, _, detected = CR.GetSkill(info.profName)
  if not detected then
    frame.status:SetText(CR.ColorText("Not learned on this character.", "ff9966"))
    frame.openBtn:Disable()
  elseif not open then
    frame.status:SetText("Open the profession to craft.")
  elseif learned == false then
    frame.status:SetText(CR.ColorText("Not learned yet. " .. CR.FactionText(recipe.pattern or recipe.src or ""), "ff9966"))
  elseif enchantFits then
    if CR.VisibleReplacePopup() then
      frame.status:SetText(CR.ColorText("Click Enchant (or the target) to replace the enchant.", "ffd100"))
    elseif not enchantTarget then
      frame.status:SetText(CR.ColorText("Select an item to enchant.", "ffd100"))
    else
      frame.status:SetText(string.format("Click the target or Enchant. %d possible now.", ready))
    end
  elseif ready <= 0 then
    frame.status:SetText(CR.ColorText("Not enough reagents in your bags.", "ff6060"))
  else
    frame.status:SetText(string.format("You can make %d now.", ready))
  end
  SyncEnchantSecure()
end

-- A SetTexture that returns false did not load. nil means this client returns nothing on success.
local function TextureLoaded(ok, loaded)
  return ok and loaded ~= false
end

local function UpdateRankBar()
  local bar = overlay and overlay.rankBar
  if not bar then return end
  local name = PlanProfession()
  local cur, maxRank, detected = 0, 0, false
  if name then cur, maxRank, detected = CR.GetSkill(name) end
  if name and detected then
    bar.text:SetText(string.format("%s %d/%d", name, cur or 0, maxRank or 0))
  else
    bar.text:SetText(name or "")
  end
  local ratio = 0
  if detected and maxRank and maxRank > 0 then
    ratio = (cur or 0) / maxRank
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end
  end
  local width = bar:GetWidth() or 0
  if width < 40 then width = 440 end
  -- The wood track is the background. A full-width fill or mask was painting a black rect over it.
  local inner = width - 40
  if inner < 1 then inner = 1 end
  bar.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar.fill:SetTexCoord(0, 1, 0, 1)
  bar.fill:SetVertexColor(0.92, 0.68, 0.28, 0.9)
  if ratio <= 0 then
    bar.fill:Hide()
  else
    bar.fill:Show()
    bar.fill:SetWidth(math.max(1, inner * ratio))
  end
end

local function LayoutHeader()
  if not overlay then return end
  local widgets = { overlay.profDD }
  if overlay.goalDD:IsShown() then table.insert(widgets, 1, overlay.goalDD) end
  if overlay.customBox:IsShown() then table.insert(widgets, 1, overlay.customBox) end
  if overlay.modeDD:IsShown() then table.insert(widgets, 1, overlay.modeDD) end
  local prev
  for i = #widgets, 1, -1 do
    local w = widgets[i]
    w:ClearAllPoints()
    if prev then
      w:SetPoint("RIGHT", prev, "LEFT", -6, 0)
    else
      w:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -8, RANK_DROP_Y)
    end
    prev = w
  end
end

local function LayoutColumns()
  if not overlay then return end
  local w = overlay:GetWidth() or 0
  local leftW = 300
  if w > 0 then leftW = math.max(260, math.min(380, math.floor(w * 0.42))) end
  overlay.divider:ClearAllPoints()
  overlay.divider:SetWidth(1)
  overlay.divider:SetPoint("TOPLEFT", overlay, "TOPLEFT", leftW, DIVIDER_TOP)
  overlay.divider:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", leftW, 8)
  UpdateRankBar()
  if overlay.rName then
    local sw = math.max(40, w - leftW - 20)
    local oh = overlay:GetHeight() or 0
    overlay.schemW = sw
    overlay.schemH = math.max(0, oh + DIVIDER_TOP - 8)
    local nameW = math.max(40, sw - 86)
    overlay.rName:SetWidth(nameW)
    overlay.rSub:SetWidth(nameW)
    overlay.rStructure:SetWidth(nameW)
  end
  if overlay:IsShown() and overlay.info then
    local fitOk, fitErr = pcall(FillSchematic, overlay.info)
    if not fitOk then CR.Print("Compact: " .. tostring(fitErr)) end
  end
end

function CR.RefreshCompact()
  if not overlay or not overlay:IsShown() then return end
  local ok, err = pcall(function()
    SyncOpenProfession()
    local items, info, empty = BuildItems()
    overlay.info = info
    overlay.empty:SetText(empty or "")
    overlay.empty:SetShown(empty ~= nil)
    list:SetShown(empty == nil)
    if empty == nil then list:SetData(items, ui.keepScroll) end
    ui.keepScroll = true

    local name = PlanProfession()
    local route = name and CR.Route(name)
    local sequential = route and route.sequential
    local multi = name and CR.professions[name] and #(CR.professions[name].routeOrder or {}) > 1
    overlay.goalDD:SetShown(not sequential)
    overlay.modeDD:SetShown(multi and true or false)
    overlay.customBox:SetShown(not sequential and DB() and DB().goalMode == "custom")
    LayoutHeader()
    UpdateRankBar()
    if overlay.goalDD:IsShown() then overlay.goalDD:Sync() end
    if overlay.modeDD:IsShown() then overlay.modeDD:Sync() end
    if overlay.profDD then overlay.profDD:Sync() end
    if overlay.customBox:IsShown() and not overlay.customBox:HasFocus() then
      overlay.customBox:SetText(tostring(DB().customGoal or ""))
    end
    FillSchematic(info)
    if CR.RefreshBuyPop then CR.RefreshBuyPop() end
  end)
  if not ok then CR.Print("Compact: " .. tostring(err)) end
end

---------------------------------------------------------------------------
-- Professions frame host
---------------------------------------------------------------------------

local function SetEntryChecked(on)
  if not entry then return end
  if entry.SetChecked then pcall(entry.SetChecked, entry, on and true or false) end
  if entry.glow then entry.glow:SetShown(on) end
end

local function HidePages()
  local frame = ProfessionsFrame
  if not frame then return end
  if frame.Pages then
    for _, page in ipairs(frame.Pages) do page:Hide() end
  else
    if frame.CraftingPage then frame.CraftingPage:Hide() end
    if frame.BookPage then frame.BookPage:Hide() end
  end
end

local function RestorePages()
  local ts = _G.TrainerSpellsProfessionFrame
  if ts and ts:IsShown() then return end
  local frame = ProfessionsFrame
  if not frame then return end
  if frame.BookPage then frame.BookPage:Hide() end
  if frame.CraftingPage then frame.CraftingPage:Show() end
end

local function BottomTab()
  local best, bestTop
  local function Consider(tab)
    if tab and tab.IsShown and tab:IsShown() and tab.GetTop and tab ~= entry then
      local top = tab:GetTop()
      if top and (not bestTop or top < bestTop) then best, bestTop = tab, top end
    end
  end
  if ProfessionsFrame then
    Consider(ProfessionsFrame.ProfessionsOverviewTab)
    if ProfessionsFrame.rightProfessionTabs then
      for _, tab in ipairs(ProfessionsFrame.rightProfessionTabs) do Consider(tab) end
    end
  end
  Consider(_G.TrainerSpellsProfessionsTab)
  for i = 1, 8 do Consider(_G["TrainerSpellsProfessionsViewTab" .. i]) end
  return best
end

local function IsTrainerTab(tab)
  local name = tab and tab.GetName and tab:GetName()
  return type(name) == "string" and name:find("TrainerSpellsProfessions", 1, true) ~= nil
end

local function PositionEntry()
  if not entry or not ProfessionsFrame then return end
  if entry.systemTab and ProfessionsFrame.TabSystem then
    entry:ClearAllPoints()
    local container = _G.TrainerSpellsProfessionsModeTabs
    if container then
      entry:SetPoint("LEFT", container, "RIGHT", 4, 0)
    else
      entry:SetPoint("LEFT", ProfessionsFrame.TabSystem, "RIGHT", 6, 0)
    end
    return
  end
  if not entry.sideTab then return end
  local anchor = BottomTab()
  entry:ClearAllPoints()
  if anchor then
    local gap = IsTrainerTab(anchor) and -6 or -16
    entry:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, gap)
  elseif ProfessionsFrame.ProfessionsOverviewTab then
    entry:SetPoint("TOPLEFT", ProfessionsFrame.ProfessionsOverviewTab, "BOTTOMLEFT", 0, -16)
  else
    entry:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", 2, -70)
  end
end

local function WatchTrainerSpells()
  local ts = _G.TrainerSpellsProfessionFrame
  if not ts or ts.crCompactHook then return end
  ts.crCompactHook = true
  ts:HookScript("OnShow", function()
    if overlay and overlay:IsShown() then
      overlay:Hide()
      SetEntryChecked(false)
    end
  end)
end

local function CloseCompact(restore)
  if not overlay then return end
  overlay:Hide()
  SetEntryChecked(false)
  if restore and not InCombatLockdown() then pcall(RestorePages) end
end

local function ClearOtherChecks()
  local frame = ProfessionsFrame
  if frame and frame.ProfessionsOverviewTab and frame.ProfessionsOverviewTab.SetChecked then
    pcall(frame.ProfessionsOverviewTab.SetChecked, frame.ProfessionsOverviewTab, false)
  end
  if frame and frame.rightProfessionTabs then
    for _, tab in ipairs(frame.rightProfessionTabs) do
      if tab.SetChecked then pcall(tab.SetChecked, tab, false) end
    end
  end
  local main = _G.TrainerSpellsProfessionsTab
  if main and main.SetChecked then pcall(main.SetChecked, main, false) end
  for i = 1, 8 do
    local tab = _G["TrainerSpellsProfessionsViewTab" .. i]
    if tab and tab.SetChecked then pcall(tab.SetChecked, tab, false) end
  end
end

local function OpenCompact()
  if InCombatLockdown() then
    CR.Print("Can't switch the profession window in combat.")
    return
  end
  if not DB() then return end
  WatchTrainerSpells()
  openedAt = GetTime()
  local ts = _G.TrainerSpellsProfessionFrame
  if ts and ts:IsShown() then ts:Hide() end
  ClearOtherChecks()
  pcall(HidePages)
  ui.openProf = nil
  ui.keepScroll = false
  overlay:Show()
  SetEntryChecked(true)
  PositionEntry()
  overlay:Refresh()
end

local function ToggleCompact()
  if overlay and overlay:IsShown() then CloseCompact(true) else OpenCompact() end
end

local function OnNativeTab()
  if GetTime() - openedAt < 0.05 then return end
  if overlay and overlay:IsShown() then CloseCompact(true) end
end

local function TipEntry(tab)
  if tab.crTip then return end
  tab.crTip = true
  tab.tooltipText = "CraftRoute"
  tab:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("CraftRoute")
    GameTooltip:Show()
  end)
  tab:HookScript("OnLeave", GameTooltip_Hide)
end

local function CreateEntryButton()
  local parent = ProfessionsFrame
  local side = parent.ProfessionsOverviewTab and parent.rightProfessionTabs
  if side then
    local ok, tab = pcall(CreateFrame, "Frame", "CraftRouteProfessionsTab", parent, "LargeSideTabButtonTemplate")
    if ok and tab and tab.Icon then
      tab.sideTab = true
      tab:SetFrameLevel(parent:GetFrameLevel() + 420)
      tab:EnableMouse(true)
      tab.tooltipText = "CraftRoute"
      tab.Icon:SetTexture(TAB_ICON)
      tab.Icon:SetSize(30, 30)
      tab.Icon:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
      if tab.SetFillToInterior then tab:SetFillToInterior(true) end
      if tab.SetChecked then tab:SetChecked(false) end
      if tab.SetCustomOnMouseUpHandler then
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
          if button == "LeftButton" and upInside and not InCombatLockdown() then ToggleCompact() end
        end)
      else
        tab:SetScript("OnMouseUp", function(_, button)
          if button == "LeftButton" then ToggleCompact() end
        end)
      end
      tab:Show()
      TipEntry(tab)
      return tab
    end
  end

  if parent.TabSystem then
    local ok, tab = pcall(CreateFrame, "Button", "CraftRouteProfessionsTab", parent, "TabSystemButtonTemplate")
    if ok and tab and tab.Init then
      tab.systemTab = true
      tab:Init(1101, nil, TAB_ICON)
      if tab.SetTooltipText then pcall(tab.SetTooltipText, tab, "CraftRoute") end
      tab:SetFrameLevel(parent.TabSystem:GetFrameLevel() + 20)
      tab:SetScript("OnClick", function()
        if not InCombatLockdown() then ToggleCompact() end
      end)
      tab:Show()
      TipEntry(tab)
      return tab
    end
  end

  local tab = CreateFrame("Button", "CraftRouteProfessionsTab", parent)
  tab.sideTab = true
  tab:SetSize(32, 32)
  tab:SetFrameLevel(parent:GetFrameLevel() + 420)
  tab:SetNormalTexture(TAB_ICON)
  local nt = tab:GetNormalTexture()
  if nt then nt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
  tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  tab.glow = tab:CreateTexture(nil, "OVERLAY")
  tab.glow:SetAllPoints()
  tab.glow:SetColorTexture(1, 0.82, 0.2, 0.35)
  tab.glow:Hide()
  tab:SetScript("OnClick", ToggleCompact)
  TipEntry(tab)
  return tab
end

local function BuildOverlay()
  local parent = ProfessionsFrame
  local frame = CreateFrame("Frame", "CraftRouteCompactFrame", parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -22)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
  frame:SetFrameStrata(parent:GetFrameStrata())
  frame:SetFrameLevel(parent:GetFrameLevel() + 320)
  frame:EnableMouse(true)
  frame:Hide()
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0)

  frame.divider = frame:CreateTexture(nil, "BORDER")
  frame.divider:SetColorTexture(1, 0.82, 0.35, 0.18)

  frame.profDD = CR.CreateDropdown(frame, 200, ProfessionOptions,
    function() return DB() and DB().profession or "" end, SelectProfession, CR.OpenProfessionMacro)
  frame.goalDD = CR.CreateDropdown(frame, 168, CR.GoalOptions,
    function() return DB() and DB().goalMode or "next" end,
    function(v)
      local db = DB()
      if not db then return end
      db.goalMode = v
      Changed()
    end)
  frame.customBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  frame.customBox:SetSize(36, 18)
  frame.customBox:SetAutoFocus(false)
  frame.customBox:SetNumeric(true)
  frame.customBox:SetMaxLetters(3)
  frame.customBox:SetScript("OnEnterPressed", function(self)
    local db = DB()
    if not db then self:ClearFocus() return end
    db.customGoal = tonumber(self:GetText()) or 225
    db.goalMode = "custom"
    self:ClearFocus()
    Changed()
  end)
  frame.customBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  frame.modeDD = CR.CreateDropdown(frame, 130, function()
    local _, prof = PlanProfession()
    local opts = {}
    for _, mode in ipairs(prof and prof.routeOrder or {}) do
      table.insert(opts, { value = mode, text = prof.routes[mode].label })
    end
    return opts
  end, function()
    local pname = PlanProfession()
    local route = pname and CR.Route(pname)
    return route and route.mode or "solo"
  end, function(v)
    local db = DB()
    local pname = PlanProfession()
    if not db or not pname then return end
    db.routeMode = db.routeMode or {}
    db.routeMode[pname] = v
    Changed()
  end)

  frame.rankBar = CreateFrame("Frame", nil, frame)
  frame.rankBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -2)
  frame.rankBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -2)
  -- Atlas is 451x29. Matching the height keeps the wood from being squashed.
  frame.rankBar:SetHeight(29)
  frame.rankBar.bg = frame.rankBar:CreateTexture(nil, "BACKGROUND")
  frame.rankBar.bg:SetAllPoints()
  if TryAtlas(frame.rankBar.bg, "Professions-skillbar-bg", false) then
    frame.rankBar.bg:SetVertexColor(1, 1, 1, 1)
  else
    frame.rankBar.bg:SetColorTexture(0.22, 0.16, 0.08, 0.9)
  end
  frame.rankBar.fill = frame.rankBar:CreateTexture(nil, "ARTWORK")
  frame.rankBar.fill:SetPoint("LEFT", frame.rankBar, "LEFT", 12, -1)
  frame.rankBar.fill:SetHeight(12)
  frame.rankBar.fill:SetWidth(1)
  frame.rankBar.fill:Hide()
  local rankText = CreateFrame("Frame", nil, frame.rankBar)
  rankText:SetAllPoints()
  rankText:SetFrameLevel(frame.rankBar:GetFrameLevel() + 4)
  frame.rankBar.text = rankText:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.rankBar.text:SetPoint("CENTER", rankText, "CENTER", 0, -1)
  frame.rankBar.text:SetJustifyH("CENTER")
  if frame.rankBar.text.SetFontObject then
    pcall(frame.rankBar.text.SetFontObject, frame.rankBar.text, "Number12FontOutline")
  end
  frame.rankBar.arrow = CreateFrame("Button", nil, frame.rankBar)
  frame.rankBar.arrow:SetSize(20, 20)
  frame.rankBar.arrow:SetPoint("RIGHT", frame.rankBar, "RIGHT", -4, -1)
  frame.rankBar.arrow.tex = frame.rankBar.arrow:CreateTexture(nil, "OVERLAY")
  frame.rankBar.arrow.tex:SetPoint("CENTER", 1, -1)
  local arrowOK = TryAtlas(frame.rankBar.arrow.tex, "common-dropdown-classic-a-buttonDown", true)
  if not arrowOK then arrowOK = TryAtlas(frame.rankBar.arrow.tex, "common-dropdown-a-button", true) end
  frame.rankBar.arrow:SetShown(arrowOK)
  frame.rankBar.arrow:SetScript("OnClick", function()
    if frame.profDD then frame.profDD:Click() end
  end)

  list = CreateList(frame)
  list:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, LIST_TOP)
  list:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 8)
  list:SetPoint("RIGHT", frame.divider, "LEFT", -4, 0)
  frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.empty:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -24)
  frame.empty:SetWidth(240)
  frame.empty:SetJustifyH("LEFT")
  frame.empty:Hide()

  local schematic = CreateFrame("Frame", nil, frame)
  schematic:SetPoint("TOPLEFT", frame.divider, "TOPRIGHT", 12, 0)
  schematic:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
  frame.schematic = schematic

  local iconOk, icon = pcall(CreateFrame, "Button", nil, schematic, "CircularGiantItemButtonTemplate")
  if not (iconOk and icon and icon.Icon) then
    icon = CreateFrame("Frame", nil, schematic)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetSize(46, 46)
    icon.texture:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if icon.CreateMaskTexture and icon.texture.AddMaskTexture then
      pcall(function()
        local mask = icon:CreateMaskTexture()
        mask:SetPoint("TOPLEFT", icon.texture, "TOPLEFT", 1, -1)
        mask:SetPoint("BOTTOMRIGHT", icon.texture, "BOTTOMRIGHT", -1, 1)
        local path = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        local called, loaded = pcall(mask.SetTexture, mask, path, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        if not TextureLoaded(called, loaded) then error("no portrait mask") end
        icon.texture:AddMaskTexture(mask)
      end)
    end
  else
    icon.texture = icon.Icon
  end
  frame.icon = icon
  frame.icon:SetSize(54, 54)
  frame.icon:SetPoint("TOPLEFT", 0, -2)
  -- CircularGiant's IconBorder is this atlas at 68px: a thin ring around the
  -- 46px circle. The recrafting frame is the thick square the schematic had.
  local ring = icon.IconBorder
  if not ring then
    ring = frame.icon:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)
  end
  frame.icon.ring = ring
  ring:ClearAllPoints()
  ring:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)
  if TryAtlas(ring, "auctionhouse-itemicon-border-white", false) then
    ring:SetSize(68, 68)
    ring:SetVertexColor(0.62, 0.40, 0.16)
    ring:Show()
  else
    ring:Hide()
  end
  frame.icon:EnableMouse(true)
  frame.icon:SetScript("OnEnter", function(self)
    local info = frame.info
    local st = info and info.selected
    if not st or not st.recipe then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    CR.RecipeTooltip(GameTooltip, st.recipe, st.crafts)
    if st.note then GameTooltip:AddLine(CR.FactionText(st.note), 0.7, 0.7, 0.7, true) end
    GameTooltip:Show()
  end)
  frame.icon:SetScript("OnLeave", GameTooltip_Hide)

  frame.rName = schematic:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.rName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 16, -2)
  frame.rName:SetWidth(180)
  frame.rName:SetJustifyH("LEFT")
  frame.rName:SetWordWrap(false)
  frame.rName:SetTextColor(1, 1, 1)
  frame.rSub = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.rSub:SetPoint("TOPLEFT", frame.rName, "BOTTOMLEFT", 0, -2)
  frame.rSub:SetWidth(180)
  frame.rSub:SetJustifyH("LEFT")
  frame.rSub:SetWordWrap(false)
  frame.rStructure = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.rStructure:SetPoint("TOPLEFT", frame.rSub, "BOTTOMLEFT", 0, -1)
  frame.rStructure:SetWidth(180)
  frame.rStructure:SetJustifyH("LEFT")
  frame.rStructure:SetWordWrap(false)

  frame.reagentsLabel = schematic:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.reagentsLabel:SetPoint("TOPLEFT", frame.icon, "BOTTOMLEFT", 0, -16)
  frame.reagentsLabel:SetText("Reagents:")
  frame.reagents = {}
  for i = 1, REAGENT_SLOTS do
    local row = CreateFrame("Button", nil, schematic)
    row:SetSize(280, 36)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(36, 36)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.buy = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.buy:SetSize(40, 20)
    row.buy:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.buy:SetText("Buy")
    row.buy:Hide()
    row:SetScript("OnEnter", function(self)
      if not self.itemID then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Where you have it:", 1, 0.82, 0)
      CR.AddLocationLines(GameTooltip, self.itemID)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
      if IsModifiedClick("CHATLINK") and self.itemID then
        local _, link = CR.GetItemInfo(self.itemID)
        if link then ChatEdit_InsertLink(link) end
      elseif self.itemID and ui.selectedKey then
        -- open this reagent's chain in the route list
        ui.openSteps[ui.selectedKey] = true
        local key = ui.selectedKey .. ">" .. self.itemID
        ui.openParts[key] = not ui.openParts[key] or nil
        ui.keepScroll = true
        if overlay then overlay:Refresh() end
      end
    end)
    row:Hide()
    frame.reagents[i] = row
  end

  frame.cost = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.cost:SetJustifyH("LEFT")
  frame.cost:SetJustifyV("TOP")
  frame.cost:SetWordWrap(true)
  if frame.cost.SetSpacing then frame.cost:SetSpacing(3) end

  frame.detailEmpty = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.detailEmpty:SetPoint("TOPLEFT", schematic, "TOPLEFT", 0, -8)
  frame.detailEmpty:SetPoint("TOPRIGHT", schematic, "TOPRIGHT", -8, -8)
  frame.detailEmpty:SetJustifyH("LEFT")
  frame.detailEmpty:SetWordWrap(true)
  frame.detailEmpty:Hide()

  frame.buttons = CreateFrame("Frame", nil, schematic)
  frame.buttons:SetPoint("BOTTOMLEFT", schematic, "BOTTOMLEFT", 0, 0)
  frame.buttons:SetPoint("BOTTOMRIGHT", schematic, "BOTTOMRIGHT", 0, 0)
  frame.buttons:SetHeight(24)
  frame.status = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.status:SetPoint("BOTTOMLEFT", frame.buttons, "TOPLEFT", 0, 6)
  frame.status:SetPoint("BOTTOMRIGHT", schematic, "BOTTOMRIGHT", -4, 30)
  frame.status:SetJustifyH("LEFT")
  frame.status:SetWordWrap(false)

  frame.create = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.create:SetSize(88, 22)
  frame.create:SetPoint("RIGHT", 0, 0)
  frame.create:SetText("Create")
  frame.nextBtn = CreateFrame("Button", nil, frame.buttons)
  frame.nextBtn:SetSize(20, 20)
  frame.nextBtn:SetPoint("RIGHT", frame.create, "LEFT", -8, 0)
  frame.nextBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  frame.nextBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
  frame.nextBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  frame.countBox = CreateFrame("EditBox", nil, frame.buttons, "InputBoxTemplate")
  frame.countBox:SetSize(36, 18)
  frame.countBox:SetPoint("RIGHT", frame.nextBtn, "LEFT", -2, 0)
  frame.countBox:SetAutoFocus(false)
  frame.countBox:SetNumeric(true)
  frame.countBox:SetMaxLetters(4)
  frame.countBox:SetJustifyH("CENTER")
  frame.countBox:SetText("1")
  frame.countBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  frame.countBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  frame.prevBtn = CreateFrame("Button", nil, frame.buttons)
  frame.prevBtn:SetSize(20, 20)
  frame.prevBtn:SetPoint("RIGHT", frame.countBox, "LEFT", -2, 0)
  frame.prevBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
  frame.prevBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
  frame.prevBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  frame.prevBtn:SetScript("OnClick", function()
    frame.countBox:SetText(tostring(math.max(1, (tonumber(frame.countBox:GetText()) or 1) - 1)))
  end)
  frame.nextBtn:SetScript("OnClick", function()
    frame.countBox:SetText(tostring(math.min(9999, (tonumber(frame.countBox:GetText()) or 1) + 1)))
  end)
  frame.createAll = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.createAll:SetSize(130, 22)
  frame.createAll:SetPoint("RIGHT", frame.prevBtn, "LEFT", -12, 0)
  frame.createAll:SetText("Create All [0]")
  frame.openBtn = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.openBtn:SetSize(160, 22)
  frame.openBtn:SetPoint("RIGHT", 0, 0)
  frame.openBtn:SetText("Open")
  frame.openBtn:Hide()

  local enchant = CreateFrame("Frame", nil, schematic)
  enchant:SetHeight(54)
  enchant:SetPoint("BOTTOMLEFT", frame.status, "TOPLEFT", 0, 4)
  enchant:SetPoint("BOTTOMRIGHT", frame.status, "TOPRIGHT", 0, 4)
  enchant:Hide()
  frame.enchant = enchant
  enchant.label = enchant:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  enchant.label:SetPoint("TOPLEFT", enchant, "TOPLEFT", 0, 0)
  enchant.label:SetText("Optional Target:")
  enchant.slot = CreateFrame("Button", nil, enchant, "BackdropTemplate")
  enchant.slot:SetSize(36, 36)
  enchant.slot:SetPoint("TOPLEFT", enchant.label, "BOTTOMLEFT", 0, -4)
  enchant.slot:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  enchant.slot:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
  enchant.slot:SetBackdropBorderColor(0.45, 0.36, 0.16, 1)
  enchant.slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  enchant.slot.icon = enchant.slot:CreateTexture(nil, "ARTWORK")
  enchant.slot.icon:SetPoint("TOPLEFT", 3, -3)
  enchant.slot.icon:SetPoint("BOTTOMRIGHT", -3, 3)
  enchant.slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  enchant.slot.icon:Hide()
  enchant.slot.plus = enchant.slot:CreateTexture(nil, "OVERLAY")
  enchant.slot.plus:SetPoint("CENTER", 0, 0)
  if TryAtlas(enchant.slot.plus, "Professions-Slot-Plus", false) then
    enchant.slot.plus:SetSize(16, 16)
  else
    enchant.slot.plus:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    enchant.slot.plus:SetSize(18, 18)
  end
  enchant.slot.plus:SetVertexColor(0.15, 0.95, 0.25)
  local slotHl = enchant.slot:CreateTexture(nil, "HIGHLIGHT")
  slotHl:SetAllPoints(enchant.slot.icon)
  slotHl:SetColorTexture(1, 1, 1, 0.12)
  enchant.text = enchant:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  enchant.text:SetPoint("LEFT", enchant.slot, "RIGHT", 10, 0)
  enchant.text:SetWidth(180)
  enchant.text:SetJustifyH("LEFT")
  enchant.text:SetWordWrap(false)
  enchant.text:SetText("Select Item to Enchant")

  local flyout = CreateFrame("Frame", nil, enchant, "BackdropTemplate")
  flyout:SetPoint("BOTTOMLEFT", enchant.slot, "TOPLEFT", 0, 4)
  flyout:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  flyout:SetBackdropColor(0.05, 0.04, 0.03, 0.96)
  flyout:SetBackdropBorderColor(0.45, 0.36, 0.16, 1)
  flyout:SetFrameLevel(enchant.slot:GetFrameLevel() + 12)
  flyout:EnableMouse(true)
  flyout:Hide()
  enchant.flyout = flyout
  flyout.empty = flyout:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  flyout.empty:SetPoint("LEFT", 8, 0)
  flyout.rows = {}

  local function ItemQualityColor(itemID)
    local _, _, quality = CR.GetItemInfo(itemID)
    local color = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b end
    return 0.45, 0.36, 0.16
  end
  local function CandidateLink(cand)
    if cand.equipSlot and GetInventoryItemLink then
      return GetInventoryItemLink("player", cand.equipSlot)
    end
    if cand.bag and C_Container and C_Container.GetContainerItemLink then
      return C_Container.GetContainerItemLink(cand.bag, cand.slot)
    end
    return cand.link
  end
  local function ResolveEnchantTarget(target, fits)
    if not target or not fits then return nil end
    local list = CR.EnchantCandidates(fits)
    for _, cand in ipairs(list) do
      if cand.itemID == target.itemID and cand.equipSlot == target.equipSlot
        and cand.bag == target.bag and cand.slot == target.slot then
        return cand
      end
    end
    for _, cand in ipairs(list) do
      if cand.itemID == target.itemID then return cand end
    end
  end
  local function CursorEnchantTarget(fits)
    if not (fits and CursorHasItem and CursorHasItem() and GetCursorInfo) then return nil end
    local cursorType, itemID = GetCursorInfo()
    if cursorType ~= "item" or not itemID then return nil end
    local bag, slot, equipSlot
    if C_Cursor and C_Cursor.GetCursorItem then
      local called, loc = pcall(C_Cursor.GetCursorItem)
      if called and type(loc) == "table" and loc.HasAnyLocation and loc:HasAnyLocation() then
        if loc.IsBagAndSlot and loc:IsBagAndSlot() then
          local got, b, s = pcall(loc.GetBagAndSlot, loc)
          if got then bag, slot = b, s end
        elseif loc.IsEquipmentSlot and loc:IsEquipmentSlot() then
          local got, s = pcall(loc.GetEquipmentSlot, loc)
          if got then equipSlot = s end
        end
      end
    end
    local function Take(cand)
      return { equipSlot = cand.equipSlot, bag = cand.bag, slot = cand.slot, itemID = cand.itemID }
    end
    local list = CR.EnchantCandidates(fits)
    for _, cand in ipairs(list) do
      if cand.itemID == itemID
        and (not bag or cand.bag == bag) and (not slot or cand.slot == slot)
        and (not equipSlot or cand.equipSlot == equipSlot) then
        return Take(cand)
      end
    end
    for _, cand in ipairs(list) do
      if cand.itemID == itemID then return Take(cand) end
    end
  end
  local function FlyRow(i)
    local row = flyout.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, flyout)
    row:SetHeight(24)
    row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 24)
    row:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * 24)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.82, 0.2, 0.15)
    row:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      local link = CandidateLink(self.cand)
      if link then GameTooltip:SetHyperlink(link) else GameTooltip:SetItemByID(self.cand.itemID) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(self.cand.equipSlot and "You're wearing this" or "In your bags", 0.8, 0.8, 0.8)
      if self.cand.enchanted then
        GameTooltip:AddLine("Already enchanted. It will be replaced without asking.", 1, 0.4, 0.4, true)
      end
      if self.cand.unbound then
        GameTooltip:AddLine("Not soulbound yet. Enchanting it binds it to you (the game asks first).", 1, 0.82, 0, true)
      end
      GameTooltip:AddLine("Click to make it the target.", 0.2, 1, 0.2)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
      local cand = self.cand
      enchant.target = { equipSlot = cand.equipSlot, bag = cand.bag, slot = cand.slot, itemID = cand.itemID }
      flyout:Hide()
      GameTooltip_Hide()
      if overlay then overlay:Refresh() end
    end)
    flyout.rows[i] = row
    return row
  end
  local function ShowFlyout()
    local list = CR.EnchantCandidates(enchant.fits)
    local n = math.min(#list, 8)
    for i = 1, n do
      local row, cand = FlyRow(i), list[i]
      row.cand = cand
      row.icon:SetTexture(CR.GetItemIcon(cand.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
      local name = CR.ItemName(cand.itemID)
      if cand.equipSlot then name = name .. CR.ColorText(" (worn)", "aaaaaa") end
      row.name:SetText(name)
      row:Show()
    end
    for i = n + 1, #flyout.rows do flyout.rows[i]:Hide() end
    local width = math.max(160, (frame.schemW or 220) - 8)
    flyout:SetWidth(width)
    if n == 0 then
      flyout.empty:SetText(string.format("No %s you're wearing or carrying.", (enchant.kind or "item"):lower()))
      flyout.empty:Show()
      flyout:SetHeight(28)
    else
      flyout.empty:Hide()
      flyout:SetHeight(8 + n * 24)
    end
    flyout:Show()
  end
  flyout:SetScript("OnShow", function(self) self.awayFor = 0 end)
  flyout:SetScript("OnUpdate", function(self, elapsed)
    local function Over(widget)
      if not widget or not widget.IsMouseOver then return false end
      local ok, over = pcall(widget.IsMouseOver, widget, 12, -12, -12, 12)
      return ok and over or false
    end
    local overSlot = Over(enchant.slot)
    local overList = Over(self)
    if overSlot or overList then
      self.awayFor = 0
    else
      self.awayFor = (self.awayFor or 0) + (elapsed or 0)
      if self.awayFor > 0.6 then self:Hide() end
    end
  end)

  function frame:UpdateEnchant(recipe, canCast)
    local fits, kind = CR.EnchantSlotFor(recipe)
    enchant.fits, enchant.kind = fits, kind
    enchant.slot.canCast = canCast and true or false
    enchant:SetShown(fits and true or false)
    if not fits then
      flyout:Hide()
      return nil
    end
    local found = ResolveEnchantTarget(enchant.target, fits)
    enchant.target = found and {
      equipSlot = found.equipSlot, bag = found.bag, slot = found.slot, itemID = found.itemID,
    } or nil
    local sw = frame.schemW or frame.schematic:GetWidth() or 220
    enchant.text:SetWidth(math.max(40, sw - 56))
    if found then
      enchant.slot.icon:SetTexture(CR.GetItemIcon(found.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
      enchant.slot.icon:SetDesaturated(not canCast)
      enchant.slot.icon:Show()
      enchant.slot.plus:Hide()
      enchant.slot:SetBackdropBorderColor(ItemQualityColor(found.itemID))
      local name = CR.ItemName(found.itemID)
      if found.equipSlot then name = name .. CR.ColorText(" (worn)", "aaaaaa") end
      enchant.text:SetText(name)
      enchant.text:SetTextColor(1, 1, 1)
    else
      enchant.slot.icon:Hide()
      enchant.slot.plus:Show()
      enchant.slot:SetBackdropBorderColor(0.45, 0.36, 0.16, 1)
      enchant.text:SetText("Select Item to Enchant")
      enchant.text:SetTextColor(0.9, 0.9, 0.9)
    end
    if flyout:IsShown() then ShowFlyout() end
    return enchant.target
  end

  local function RememberTarget(cand)
    enchant.target = { equipSlot = cand.equipSlot, bag = cand.bag, slot = cand.slot, itemID = cand.itemID }
    flyout:Hide()
    if overlay then overlay:Refresh() end
  end
  local function SlotClick(button)
    if button == "RightButton" then
      enchant.target = nil
      flyout:Hide()
      if overlay then overlay:Refresh() end
      return ""
    end
    if CursorHasItem and CursorHasItem() then
      local dropped = CursorEnchantTarget(enchant.fits)
      if dropped then
        if ClearCursor then ClearCursor() end
        RememberTarget(dropped)
      end
      return ""
    end
    if not enchant.target then
      ShowFlyout()
      return ""
    end
    local st = frame.current
    if not st or not st.recipe then return "" end
    return CR.EnchantClick(st.recipe, enchant.target, enchant.slot.canCast)
  end
  local function EnchantButtonClick()
    local st = frame.current
    if not st or not st.recipe or not enchant.target then return "" end
    return CR.EnchantClick(st.recipe, enchant.target, true)
  end

  enchant.slot:SetScript("OnEnter", function(self)
    ShowFlyout()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local target = enchant.target
    if target then
      local link = CandidateLink(target)
      if link then GameTooltip:SetHyperlink(link) else GameTooltip:SetItemByID(target.itemID) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Left-click: enchant it.", 0.2, 1, 0.2, true)
      GameTooltip:AddLine("An existing enchant is replaced without asking.", 1, 0.4, 0.4, true)
      GameTooltip:AddLine("Right-click: clear the target.", 0.8, 0.8, 0.8)
    else
      GameTooltip:SetText("Optional Target")
      GameTooltip:AddLine("Pick gear you're wearing or carrying that this enchant fits. "
        .. "You can also drop an item onto the slot.", 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  enchant.slot:SetScript("OnLeave", GameTooltip_Hide)
  enchant.slot:SetScript("OnClick", SlotClick)
  enchant.slotCover = AttachEnchantCover(enchant.slot, SlotClick)
  enchant.castCover = AttachEnchantCover(frame.create, EnchantButtonClick)

  frame.create:SetScript("OnClick", function()
    local st = frame.current
    if not st or not st.recipe or RecipeLearned(frame.craftProf, st.recipe) == false then return end
    if CR.EnchantSlotFor(st.recipe) then
      -- The secure cover takes this click when it is the top frame, and that is what
      -- answers the replace prompt. This runs only when the click reaches the button.
      EnchantButtonClick()
      return
    end
    CraftSpell(st.recipe.spell, tonumber(frame.countBox:GetText()) or 1, frame.craftProf)
  end)
  frame.createAll:SetScript("OnClick", function()
    local st = frame.current
    if not st or not st.recipe or RecipeLearned(frame.craftProf, st.recipe) == false then return end
    if CR.EnchantSlotFor(st.recipe) then return end
    local n = CraftsReady(frame.craftProf, st.recipe)
    if n > 0 then CraftSpell(st.recipe.spell, n, frame.craftProf) end
  end)
  frame.openBtn:SetScript("OnClick", function()
    if frame.craftProf then CR.OpenTradeSkill(frame.craftProf) end
  end)
  -- the click opens the profession by casting it (only a secure click may)
  AttachPlainCover(frame.openBtn, function() return CR.OpenProfessionMacro(frame.craftProf) or "" end,
    function() return frame:IsShown() and frame.openBtn:IsShown() and CR.OpenProfessionMacro(frame.craftProf) ~= nil end)

  local watch = 0
  frame:SetScript("OnUpdate", function(_, elapsed)
    SyncEnchantSecure()
    watch = watch + elapsed
    if watch < 0.4 then return end
    watch = 0
    local before = ui.openProf
    SyncOpenProfession()
    if ui.openProf ~= before then
      ui.keepScroll = false
      frame:Refresh()
    end
  end)
  frame:SetScript("OnShow", function() PositionEntry() end)
  frame:HookScript("OnHide", function()
    if frame.enchant and frame.enchant.flyout then frame.enchant.flyout:Hide() end
    if CR.HideBuyPop then CR.HideBuyPop(frame) end
    SyncEnchantSecure()
  end)
  frame:SetScript("OnSizeChanged", LayoutColumns)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    if list and list.Wheel then list:Wheel(delta) end
  end)

  function frame:Refresh()
    CR.RefreshCompact()
  end
  overlay = frame
  LayoutColumns()
  LayoutHeader()
end

local function Install()
  if installed or installFailed or not ProfessionsFrame or not DB() then return end
  local ok, err = pcall(function()
    entry = CreateEntryButton()
    BuildOverlay()
    PositionEntry()
  end)
  if not ok then
    installFailed = true
    if _G.CraftRouteProfessionsTab then
      _G.CraftRouteProfessionsTab:Hide()
      _G.CraftRouteProfessionsTab:EnableMouse(false)
    end
    if _G.CraftRouteCompactFrame then _G.CraftRouteCompactFrame:Hide() end
    CR.Print("Compact failed to install: " .. tostring(err))
    return
  end
  installed = true

  if ProfessionsFrame.RefreshRightTabs then
    hooksecurefunc(ProfessionsFrame, "RefreshRightTabs", PositionEntry)
  end
  if ProfessionsFrame.RightTabSelected then
    hooksecurefunc(ProfessionsFrame, "RightTabSelected", OnNativeTab)
  end
  if ProfessionsFrame.SetTab then
    hooksecurefunc(ProfessionsFrame, "SetTab", OnNativeTab)
  end
  ProfessionsFrame:HookScript("OnShow", function()
    C_Timer.After(0, PositionEntry)
    C_Timer.After(0.2, PositionEntry)
    WatchTrainerSpells()
  end)
  ProfessionsFrame:HookScript("OnHide", function()
    local wasOpen = overlay and overlay:IsShown()
    if wasOpen then
      overlay:Hide()
      SetEntryChecked(false)
    end
    if wasOpen and not InCombatLockdown() then pcall(RestorePages) end
  end)
  WatchTrainerSpells()
  CR.OnChange(function()
    if overlay and overlay:IsShown() then
      overlay:Refresh()
    end
  end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addonName)
  if addonName == "Blizzard_Professions" or ProfessionsFrame then
    Install()
  end
end)
local trade = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "PLAYER_LOGIN" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    pcall(trade.RegisterEvent, trade, e)
  end
end
trade:SetScript("OnEvent", function()
  Install()
  WatchTrainerSpells()
  PositionEntry()
end)
if ProfessionsFrame then Install() end
