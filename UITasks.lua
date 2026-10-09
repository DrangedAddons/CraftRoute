-- The task card: shown in place of the recipe (Craft tab and the profession-window view) when the
-- route is at a step that isn't a craft - train a rank, buy a book, learn a recipe, buy supplies,
-- fish to a skill. What to do, a checklist the game ticks off, the nearest NPCs with a map pin
-- button each, the cost, and "Mark as done" for anything the game can't confirm.
local _, CR = ...

local TICK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t "
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t "
local MAX_CHECKS, MAX_PLACES = 8, 3

-- Book names, for "Bought ..." lines before the item is cached.
CR.extraNames[16083] = "Expert Fishing - The Bass and You"
CR.extraNames[16072] = "Expert Cookbook"
CR.extraNames[16084] = "Expert First Aid - Under Wraps"

local function Yards(d)
  if d >= 1000 then return string.format("%.1fk yd", d / 1000) end
  return string.format("%d yd", math.floor(d + 0.5))
end

-- width: the card's width (text wraps to it).
function CR.CreateTaskCard(parent, width)
  local card = CreateFrame("Frame", nil, parent)
  card:SetSize(width, 200)
  card:Hide()

  card.icon = card:CreateTexture(nil, "ARTWORK")
  card.icon:SetSize(44, 44)
  card.icon:SetPoint("TOPLEFT", 0, 0)
  card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  card.kind = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  card.kind:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -2)
  CR.ThemeRegisterAccentText(card.kind)
  card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  card.title:SetPoint("TOPLEFT", card.kind, "BOTTOMLEFT", 0, -3)
  card.title:SetJustifyH("LEFT")
  card.title:SetWordWrap(true)

  card.text = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  card.text:SetJustifyH("LEFT")
  card.text:SetJustifyV("TOP")
  card.text:SetWordWrap(true)
  if card.text.SetSpacing then card.text:SetSpacing(2) end

  card.checks = {}
  for i = 1, MAX_CHECKS do
    local fs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    card.checks[i] = fs
  end

  -- skill progress for leveling steps (fishing)
  card.bar = CreateFrame("StatusBar", nil, card, "BackdropTemplate")
  card.bar:SetHeight(14)
  card.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  card.bar:SetMinMaxValues(0, 1)
  CR.Backdrop(card.bar, 0, 0, 0, 0.6)
  card.bar.text = card.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  card.bar.text:SetPoint("CENTER")

  card.whereLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  card.whereLabel:SetText("Where")
  CR.ThemeRegisterAccentText(card.whereLabel)
  card.places = {}
  for i = 1, MAX_PLACES do
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(24)
    row.pin = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.pin:SetSize(46, 20)
    row.pin:SetPoint("LEFT", 0, 0)
    row.pin:SetText("Pin")
    CR.ThemeRegisterButton(row.pin)
    row.pin:SetScript("OnClick", function() if row.place then CR.PinPlace(row.place) end end)
    row.pin:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText("Map pin")
      GameTooltip:AddLine("Puts a pin on your map here and tracks it on screen.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    row.pin:SetScript("OnLeave", GameTooltip_Hide)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.pin, "RIGHT", 8, 0)
    row.text:SetPoint("RIGHT", 0, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    card.places[i] = row
  end
  card.noPlace = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  card.noPlace:SetJustifyH("LEFT")
  card.noPlace:SetWordWrap(true)

  card.cost = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  card.cost:SetJustifyH("LEFT")

  card.done = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
  card.done:SetSize(130, 22)
  card.done:SetText("Mark as done")
  CR.ThemeRegisterButton(card.done)
  card.done:SetScript("OnClick", function()
    if card.task then CR.MarkTaskDone(card.task, not card.task.manual) end
  end)
  card.done:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if card.task and card.task.manual then
      GameTooltip:SetText("Not done yet")
      GameTooltip:AddLine("Puts this step back on the route.", 1, 1, 1, true)
      GameTooltip:Show()
      return
    end
    GameTooltip:SetText("Mark as done")
    GameTooltip:AddLine(card.task and card.task.auto and "The game ticks this off by itself when it's done - "
      .. "use this if it hasn't." or "The game can't tell when this is done - click when you have.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  card.done:SetScript("OnLeave", GameTooltip_Hide)

  local KIND_LABEL = { train = "TRAINING", book = "BOOK", quest = "QUEST", recipe = "LEARN A RECIPE", buy = "SHOPPING",
                       guide = "NEXT STEP" }

  -- Lays the card out top to bottom for this width; returns its height.
  function card:Fill(task, w)
    self.task = task
    w = w or self:GetWidth() or width
    self:SetWidth(w)
    self.icon:SetTexture(task.icon or "Interface\\Icons\\INV_Misc_Note_01")
    self.kind:SetText((KIND_LABEL[task.kind] or "NEXT STEP") .. (task.done and "  -  DONE"
      or (task.waiting and string.format("  -  AT %s %d", (task.skillName or ""):upper(), task.waiting))
      or (task.prep and "  -  GET READY" or "")))
    self.title:SetWidth(w - 54)
    self.title:SetText(task.title or "")
    local y = -math.max(48, 22 + (self.title:GetStringHeight() or 18)) - 10

    self.text:ClearAllPoints()
    self.text:SetPoint("TOPLEFT", 0, y)
    self.text:SetWidth(w)
    self.text:SetText(task.text or "")
    y = y - (self.text:GetStringHeight() or 14) - 12

    for i, fs in ipairs(self.checks) do
      local c = task.checks[i]
      if c then
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 0, y)
        fs:SetWidth(w)
        fs:SetText((c.ok and TICK or CROSS) .. c.text)
        fs:SetTextColor(c.ok and 0.6 or 1, c.ok and 1 or 0.85, c.ok and 0.6 or 0.6)
        fs:Show()
        y = y - (fs:GetStringHeight() or 14) - 4
      else
        fs:Hide()
      end
    end

    if task.progress then
      local p = task.progress
      self.bar:ClearAllPoints()
      self.bar:SetPoint("TOPLEFT", 0, y - 4)
      self.bar:SetWidth(w)
      local span = math.max(1, p.to - p.from)
      self.bar:SetValue(math.max(0, math.min(1, (p.cur - p.from) / span)))
      self.bar:SetStatusBarColor(CR.ProfessionColor(task.skillName))
      self.bar.text:SetText(string.format("%s %d / %d", task.skillName or "", p.cur, p.to))
      self.bar:Show()
      y = y - 26
    else
      self.bar:Hide()
    end

    y = y - 6
    self.whereLabel:ClearAllPoints()
    self.whereLabel:SetPoint("TOPLEFT", 0, y)
    y = y - 20
    local shown = 0
    for i, row in ipairs(self.places) do
      local pl = task.places[i]
      if pl then
        shown = shown + 1
        row.place = pl
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, y)
        row:SetWidth(w)
        local where = pl.dist and (pl.zone .. CR.ColorText("  " .. Yards(pl.dist), "aaaaaa"))
          or (pl.far and (pl.zone .. CR.ColorText("  (another continent)", "aaaaaa")) or pl.zone)
        row.text:SetText(pl.name .. CR.ColorText("  -  ", "888888") .. where)
        row:Show()
        y = y - 26
      else
        row:Hide()
      end
    end
    self.whereLabel:SetShown(true)
    if shown == 0 then
      self.noPlace:ClearAllPoints()
      self.noPlace:SetPoint("TOPLEFT", 0, y)
      self.noPlace:SetWidth(w)
      self.noPlace:SetText(TrainerSpellsProfessionTrainers and "Follow the directions above - no map position known."
        or "Install the TrainerSpells addon to see where trainers and vendors are, with map pins.")
      self.noPlace:Show()
      y = y - (self.noPlace:GetStringHeight() or 14) - 6
    else
      self.noPlace:Hide()
    end

    y = y - 6
    if task.cost and task.cost > 0 then
      self.cost:ClearAllPoints()
      self.cost:SetPoint("TOPLEFT", 0, y)
      self.cost:SetText(CR.ColorText("Cost: ", "ffd100") .. CR.FormatMoney(task.cost))
      self.cost:Show()
      y = y - 22
    else
      self.cost:Hide()
    end

    -- done by the game: nothing to click; ticked by hand: can be undone
    self.done:ClearAllPoints()
    self.done:SetPoint("TOPLEFT", 0, y - 4)
    self.done:SetText(task.manual and "Not done yet" or "Mark as done")
    self.done:SetShown(not task.done or task.manual)
    y = y - 30
    self:SetHeight(-y)
    self:Show()
    return -y
  end

  return card
end
