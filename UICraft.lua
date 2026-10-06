-- Craft tab: the one place to live once the route is planned. Shows the recipe the plan says to
-- craft now (big, with its reagents and Create buttons) and a preview of the next one.
-- Crafting goes through the game's own profession API, which needs the profession window open;
-- the tab offers a button to open it.
local _, CR = ...
local GetItemIcon, GetItemCount, GetItemInfo = CR.GetItemIcon, CR.GetItemCount, CR.GetItemInfo

local CRAFT_KINDS = { craft = true, extra = true, target = true }

---------------------------------------------------------------------------
-- Profession window / crafting API (retail-style C_TradeSkillUI, Classic fallback)
---------------------------------------------------------------------------
-- Looked up on use, so it's never stale if the profession API loads after us.
local TS = setmetatable({}, { __index = function(_, k) return C_TradeSkillUI and C_TradeSkillUI[k] end })

-- Is this profession's window open and ready, so recipes can be crafted?
function CR.TradeSkillOpenFor(profName)
  if TS.GetBaseProfessionInfo and TS.IsTradeSkillReady then
    local info = TS.GetBaseProfessionInfo()
    local name = info and (info.professionName or info.parentProfessionName)
    return name == profName and TS.IsTradeSkillReady() and true or false
  end
  if GetTradeSkillLine then return GetTradeSkillLine() == profName end
  return false
end

function CR.OpenTradeSkill(profName)
  if InCombatLockdown() then CR.Print("Can't open professions in combat.") return end
  local s = CR.skill[profName]
  if s and s.skillLine and TS.OpenTradeSkill then
    TS.OpenTradeSkill(s.skillLine)
  else
    CR.Print("Open " .. profName .. " from your spellbook / profession book first.")
  end
end

-- Learned? and how many can be made from what's in your bags right now.
local function RecipeState(prof, r)
  local learned, available
  if TS.GetRecipeInfo and CR.TradeSkillOpenFor(prof.name) then
    local ok, info = pcall(TS.GetRecipeInfo, r.spell)
    if ok and info then learned, available = info.learned, info.numAvailable end
  end
  if learned == nil then learned = CR.ProfTable("known", prof.name)[r.spell] or nil end
  if available == nil then
    available = math.huge
    for _, rg in ipairs(r.reagents) do
      available = math.min(available, math.floor((GetItemCount(rg[1], false) or 0) / rg[2]))
    end
    if available == math.huge then available = 0 end
  end
  return learned, available
end

local function Craft(r, count)
  if InCombatLockdown() then CR.Print("Can't craft in combat.") return end
  if TS.CraftRecipe then
    local ok, err = pcall(TS.CraftRecipe, r.spell, count)
    if not ok then CR.Print("|cffff4040Couldn't craft:|r " .. tostring(err)) end
  elseif DoTradeSkill and GetNumTradeSkills then
    for i = 1, GetNumTradeSkills() do
      local link = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i)
      if link and tonumber(link:match("enchant:(%d+)")) == r.spell then DoTradeSkill(i, count) return end
    end
    CR.Print("Couldn't find " .. r.name .. " in the profession window.")
  end
end

local function IsRepeating()
  return TS.IsRecipeRepeating and TS.IsRecipeRepeating() or false
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function QualityRGB(q)
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

-- An icon with a 2px quality-coloured border; hover shows the item (or recipe) tooltip.
local function IconButton(parent, size)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(size, size)
  b:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 2, -2)
  b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(b.icon)
  hl:SetColorTexture(1, 1, 1, 0.15)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.recipe then
      CR.RecipeTooltip(GameTooltip, self.recipe, self.crafts)
    elseif self.itemID then
      GameTooltip:SetItemByID(self.itemID)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

-- One reagent line: icon, "have/need Name".
local function ReagentRow(parent, iconSize, font)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(240, iconSize + 4)
  row.btn = IconButton(row, iconSize)
  row.btn:SetPoint("LEFT", 0, 0)
  row.text = row:CreateFontString(nil, "OVERLAY", font)
  row.text:SetPoint("LEFT", row.btn, "RIGHT", 8, 0)
  row.text:SetPoint("RIGHT", 0, 0)
  row.text:SetJustifyH("LEFT")
  return row
end

local function FillReagents(box, rows, r, perCraft)
  for i, row in ipairs(rows) do
    local rg = r and r.reagents[i]
    if rg then
      local have = GetItemCount(rg[1], false) or 0
      local need = rg[2] * perCraft
      row.btn.itemID = rg[1]
      row.btn.icon:SetTexture(GetItemIcon(rg[1]))
      local q = select(3, GetItemInfo(rg[1])) or 1
      row.btn:SetBackdropBorderColor(QualityRGB(q))
      local color = have >= need and "40ff40" or "ff6060"
      row.text:SetText(CR.ColorText(string.format("%d/%d", have, need), color) .. "  " .. CR.ItemName(rg[1]))
      row:Show()
    else
      row:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------
function CR.CreateCraftPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  local db = function() return CraftRouteCharDB end
  panel.viewOffset = 0   -- browsing ahead with the arrows; 0 = the current craft

  -- Skill bar
  local bar = CreateFrame("StatusBar", nil, panel, "BackdropTemplate")
  bar:SetSize(560, 20)
  bar:SetPoint("TOP", 0, -8)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetMinMaxValues(0, 1)
  CR.Backdrop(bar, 0, 0, 0, 0.6)
  bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bar.text:SetPoint("CENTER")

  -- Profession switcher: the professions this character can actually craft with.
  local profDD = CR.CreateDropdown(panel, 130, function()
    local opts = {}
    for _, n in ipairs(CR.SupportedProfessions()) do
      local _, _, detected = CR.GetSkill(n)
      if detected or n == db().profession then table.insert(opts, { value = n, text = n }) end
    end
    return opts
  end, function() return db().profession end,
  function(v) db().profession = v; db().profPicked = true; panel.viewOffset = 0; CR.NotifyChanged() end)
  profDD:SetPoint("TOPLEFT", 4, -8)

  local stepLine = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  stepLine:SetPoint("TOP", bar, "BOTTOM", 0, -8)
  CR.ThemeRegisterAccentText(stepLine)

  -- browse arrows
  local function Arrow(dir)
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(24, 24)
    local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetDisabledTexture(base .. "Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnClick", function()
      panel.viewOffset = math.max(0, panel.viewOffset + dir)
      panel:Refresh()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(dir < 0 and "Back towards the current craft" or "Look at the next craft in the route")
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
  end
  local prevBtn, nextBtn = Arrow(-1), Arrow(1)

  -- Main recipe (left-centre)
  local main = CreateFrame("Frame", nil, panel)
  main:SetSize(320, 300)
  main:SetPoint("TOP", panel, "TOP", -120, -64)
  local bigIcon = IconButton(main, 64)
  bigIcon:SetPoint("TOP", 0, 0)
  prevBtn:SetPoint("RIGHT", bigIcon, "LEFT", -24, 0)
  nextBtn:SetPoint("LEFT", bigIcon, "RIGHT", 24, 0)
  local name = main:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  name:SetPoint("TOP", bigIcon, "BOTTOM", 0, -10)
  name:SetWidth(320)
  local sub = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOP", name, "BOTTOM", 0, -6)
  sub:SetWidth(320)
  local reagentBox = CreateFrame("Frame", nil, main, "BackdropTemplate")
  reagentBox:SetSize(280, 40)
  reagentBox:SetPoint("TOP", sub, "BOTTOM", 0, -14)
  CR.Backdrop(reagentBox, 0, 0, 0, 0.35)
  local reagentTitle = reagentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  reagentTitle:SetPoint("TOPLEFT", 12, -8)
  reagentTitle:SetText("Reagents:")
  CR.ThemeRegisterAccentText(reagentTitle)
  local reagentRows = {}
  for i = 1, 6 do
    local row = ReagentRow(reagentBox, 36, "GameFontHighlight")
    row:SetPoint("TOPLEFT", 12, -24 - (i - 1) * 42)
    reagentRows[i] = row
  end
  local totalNote = reagentBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  totalNote:SetPoint("BOTTOMRIGHT", -10, 6)

  -- Up next (right)
  local nextFrame = CreateFrame("Frame", nil, panel)
  nextFrame:SetSize(200, 260)
  nextFrame:SetPoint("TOP", panel, "TOP", 250, -110)
  local nextLabel = nextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nextLabel:SetPoint("TOP", 0, 0)
  nextLabel:SetText("Up next")
  CR.ThemeRegisterAccentText(nextLabel)
  local nextIcon = IconButton(nextFrame, 44)
  nextIcon:SetPoint("TOP", nextLabel, "BOTTOM", 0, -8)
  local nextName = nextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nextName:SetPoint("TOP", nextIcon, "BOTTOM", 0, -6)
  nextName:SetWidth(200)
  local nextSub = nextFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  nextSub:SetPoint("TOP", nextName, "BOTTOM", 0, -2)
  local nextBox = CreateFrame("Frame", nil, nextFrame, "BackdropTemplate")
  nextBox:SetSize(170, 30)
  nextBox:SetPoint("TOP", nextSub, "BOTTOM", 0, -8)
  CR.Backdrop(nextBox, 0, 0, 0, 0.35)
  local nextRows = {}
  for i = 1, 6 do
    local row = ReagentRow(nextBox, 22, "GameFontHighlightSmall")
    row:SetSize(150, 26)
    row:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 26)
    nextRows[i] = row
  end

  -- Craft controls (bottom)
  local controls = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  controls:SetSize(470, 44)
  controls:SetPoint("BOTTOM", panel, "BOTTOM", -120, 6)
  CR.Backdrop(controls, 0, 0, 0, 0.45)
  local createAll = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  createAll:SetSize(130, 26)
  createAll:SetPoint("LEFT", 12, 0)
  CR.ThemeRegisterButton(createAll)
  local create = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  create:SetSize(110, 26)
  create:SetPoint("RIGHT", -12, 0)
  CR.ThemeRegisterButton(create)
  local countBox = CreateFrame("EditBox", nil, controls, "InputBoxTemplate")
  countBox:SetSize(40, 20)
  countBox:SetPoint("CENTER", 0, 0)
  countBox:SetAutoFocus(false)
  countBox:SetNumeric(true)
  countBox:SetMaxLetters(3)
  countBox:SetJustifyH("CENTER")
  countBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  countBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  local function Step(dir)
    local b = CreateFrame("Button", nil, controls)
    b:SetSize(22, 22)
    local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnClick", function()
      countBox:SetNumber(math.max(1, (countBox:GetNumber() or 1) + dir))
    end)
    return b
  end
  Step(-1):SetPoint("RIGHT", countBox, "LEFT", -8, 0)
  Step(1):SetPoint("LEFT", countBox, "RIGHT", 4, 0)

  -- Shown instead of the controls while the profession window is closed.
  local openBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  openBtn:SetSize(220, 26)
  openBtn:SetPoint("CENTER")
  CR.ThemeRegisterButton(openBtn)
  local status = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  status:SetPoint("BOTTOM", controls, "TOP", 0, 6)
  status:SetWidth(470)

  local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  empty:SetPoint("CENTER", 0, 20)
  empty:SetWidth(600)

  -- Craft-able steps of the route (current first), following the full route past the goal.
  local function CraftSteps(entry)
    local list = {}
    for _, st in ipairs(entry.full.steps) do
      if CRAFT_KINDS[st.kind] and st.recipe then table.insert(list, st) end
    end
    return list
  end

  local function Describe(st)
    if st.kind == "target" then return "Your target", "33ccff" end
    if st.kind == "extra" then return "For a later step", "aaaaaa" end
    return string.format("Step %d-%d", st.from, st.to), nil
  end

  function panel:Refresh()
    local profName = db().profession
    local entry = CR.GetPlans(profName)
    local cur, maxRank, detected = CR.GetSkill(profName)
    local prof = CR.professions[profName]
    local route = CR.Route(profName)
    local rprof = route and CR.professions[route.recipeProf or profName] or prof

    bar:SetValue((maxRank and maxRank > 0) and (cur / maxRank) or 0)
    local ar, ag, ab = CR.AccentColor()
    bar:SetStatusBarColor(ar * 0.85, ag * 0.85, ab * 0.85)
    bar.text:SetText(detected and string.format("%s %d/%d", profName, cur, maxRank)
      or (profName .. " (not learned)"))

    local steps = entry and CraftSteps(entry) or {}
    if #steps == 0 then
      main:Hide(); nextFrame:Hide(); controls:Hide(); status:SetText(""); prevBtn:Hide(); nextBtn:Hide()
      stepLine:SetText("")
      empty:SetText(route and route.noAutoFill and not next(rprof.recipes)
        and (profName .. " has nothing to craft - see the Plan tab for where to go.")
        or "Nothing left to craft on this route.")
      empty:Show()
      return
    end
    empty:Hide(); main:Show(); controls:Show()
    panel.viewOffset = math.min(panel.viewOffset, #steps - 1)
    local st = steps[1 + panel.viewOffset]
    local nst = steps[2 + panel.viewOffset]
    local r = st.recipe
    prevBtn:SetShown(true); nextBtn:SetShown(true)
    prevBtn:SetEnabled(panel.viewOffset > 0)
    nextBtn:SetEnabled(nst ~= nil)

    -- step line: where this craft sits in the route
    local label, labelColor = Describe(st)
    local diff = CR.Difficulty(r, cur)
    local diffText = ({ orange = "every craft gives a point", yellow = "most crafts give a point",
                        green = "few crafts give a point", grey = "no skill points",
                        red = "needs " .. r.learn .. " skill" })[diff]
    stepLine:SetText((labelColor and CR.ColorText(label, labelColor) or label)
      .. string.format("  ·  %s%d to make", st.estimated and "~" or "", st.crafts)
      .. (panel.viewOffset > 0 and CR.ColorText("  ·  looking ahead", "aaaaaa") or ""))

    bigIcon.recipe, bigIcon.crafts = r, st.crafts
    bigIcon.icon:SetTexture(r.item > 0 and GetItemIcon(r.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
    bigIcon:SetBackdropBorderColor(QualityRGB(r.q))
    name:SetText(r.name)
    name:SetTextColor(QualityRGB(r.q))
    sub:SetText(CR.ColorText(diffText, CR.DIFF_COLORS[diff]) .. (st.note and CR.ColorText("  ·  " .. st.note, "999999") or ""))

    profDD:Sync()
    FillReagents(reagentBox, reagentRows, r, 1)
    reagentBox:SetHeight(32 + #r.reagents * 42)
    if st.crafts > 1 then totalNote:SetText(string.format("per craft  ·  x%d for this step", st.crafts))
    else totalNote:SetText("") end

    -- Up next
    if nst then
      local nr = nst.recipe
      nextFrame:Show()
      nextIcon.recipe, nextIcon.crafts = nr, nst.crafts
      nextIcon.icon:SetTexture(nr.item > 0 and GetItemIcon(nr.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
      nextIcon:SetBackdropBorderColor(QualityRGB(nr.q))
      nextName:SetText(nr.name)
      nextName:SetTextColor(QualityRGB(nr.q))
      local nlabel = Describe(nst)
      nextSub:SetText(string.format("%s  ·  %s%dx", nlabel, nst.estimated and "~" or "", nst.crafts))
      FillReagents(nextBox, nextRows, nr, 1)
      nextBox:SetHeight(12 + #nr.reagents * 26)
    else
      nextFrame:Hide()
    end

    -- Controls
    local open = CR.TradeSkillOpenFor(rprof.name)
    local learned, available = RecipeState(rprof, r)
    local craftable = open and learned ~= false
    createAll:SetShown(open); create:SetShown(open); countBox:SetShown(open)
    for _, child in ipairs({ controls:GetChildren() }) do
      if child ~= openBtn and child ~= createAll and child ~= create and child ~= countBox then child:SetShown(open) end
    end
    openBtn:SetShown(not open)
    openBtn:SetText("Open " .. rprof.name)
    if not detected then
      status:SetText(CR.ColorText("You haven't learned " .. profName .. " on this character.", "ff9966"))
      openBtn:Disable()
    elseif not open then
      status:SetText("The game only lets you craft with the profession window open.")
      openBtn:SetEnabled(not InCombatLockdown())
    elseif learned == false then
      status:SetText(CR.ColorText("You haven't learned " .. r.name .. " yet - " .. CR.FactionText(r.pattern or r.src), "ff9966"))
    elseif available == 0 then
      status:SetText(CR.ColorText("Not enough reagents in your bags.", "ff6060"))
    else
      status:SetText(string.format("You can make %d now.", available))
    end
    createAll:SetText(string.format("Create All [%d]", available or 0))
    createAll:SetEnabled(craftable and (available or 0) > 0)
    if IsRepeating() then
      create:SetText("Stop")
      create:Enable()
    else
      create:SetText("Create")
      create:SetEnabled(craftable and (available or 0) > 0)
    end
    if not countBox:HasFocus() then
      local want = math.max(1, math.min(st.crafts, (available or 0) > 0 and available or st.crafts))
      if panel.lastSpell ~= r.spell then countBox:SetNumber(want) end
    end
    panel.lastSpell = r.spell
    panel.current = r
  end

  createAll:SetScript("OnClick", function()
    local r = panel.current
    if not r then return end
    local _, available = RecipeState(CR.professions[CR.Route(db().profession).recipeProf or db().profession], r)
    if (available or 0) > 0 then Craft(r, available) end
  end)
  create:SetScript("OnClick", function()
    if IsRepeating() and TS.StopRecipeRepeat then TS.StopRecipeRepeat() return end
    local r = panel.current
    if r then Craft(r, math.max(1, countBox:GetNumber() or 1)) end
  end)
  openBtn:SetScript("OnClick", function()
    local route = CR.Route(db().profession)
    CR.OpenTradeSkill(route and route.recipeProf or db().profession)
  end)

  return panel
end

-- Keep the Craft tab live: the profession window opening/closing and crafts finishing.
local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE",
                     "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED",
                     "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    pcall(ev.RegisterEvent, ev, e)
  end
end
ev:SetScript("OnEvent", function(_, event, unit)
  if (event:find("^UNIT_") and unit ~= "player") then return end
  CR.NotifyChanged()
end)
