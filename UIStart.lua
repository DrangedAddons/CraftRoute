-- The start page: shown when this character hasn't learned any profession CraftRoute covers.
-- Pick a profession from the list and it shows the nearest trainers who teach it (map pins, from
-- TrainerSpells' trainer data), and - for the ones CraftRoute has a route for - a button to the
-- leveling route.
local _, CR = ...

local GROUPS = {
  { title = "Crafting", list = {
    { "Alchemy", "Interface\\Icons\\Trade_Alchemy", "Potions, elixirs and flasks. Pairs with Herbalism." },
    { "Blacksmithing", "Interface\\Icons\\Trade_BlackSmithing", "Mail and plate armour, weapons, sharpening stones. Pairs with Mining." },
    { "Enchanting", "Interface\\Icons\\Trade_Engraving", "Enchants gear; its materials come from disenchanting green items." },
    { "Engineering", "Interface\\Icons\\Trade_Engineering", "Gadgets, guns, ammo and explosives. Pairs with Mining." },
    { "Leatherworking", "Interface\\Icons\\Trade_LeatherWorking", "Leather and mail armour, armour kits. Pairs with Skinning." },
    { "Tailoring", "Interface\\Icons\\Trade_Tailoring", "Cloth armour and bags, from the cloth monsters drop." },
  }},
  { title = "Gathering", list = {
    { "Herbalism", "Interface\\Icons\\Trade_Herbalism", "Pick herbs - for Alchemy, or to sell." },
    { "Mining", "Interface\\Icons\\Trade_Mining", "Mine ore and stone - for Blacksmithing and Engineering, or to sell." },
    { "Skinning", "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", "Skin beasts for leather - for Leatherworking, or to sell." },
  }},
  { title = "Secondary (any character can learn all three)", list = {
    { "Cooking", "Interface\\Icons\\INV_Misc_Food_15", "Food that restores health and gives buffs." },
    { "First Aid", "Interface\\Icons\\Spell_Holy_SealOfSacrifice", "Bandages from cloth - healing for any class." },
    { "Fishing", "Interface\\Icons\\Trade_Fishing", "Catch fish for Cooking. Needs a fishing pole." },
  }},
}

local ROW_H = 24

local function HasRoute(name)
  local p = CR.professions[name]
  return p and p.routes and true or false
end

-- Any profession at all on this character - gathering ones (Herbalism, Skinning) too, which
-- CraftRoute has no route for. Asks the game directly, so it's never fooled by a skill list that
-- hasn't been read yet.
function CR.LearnedProfessionNames()
  local names = {}
  if GetProfessions and GetProfessionInfo then
    for _, index in pairs({ GetProfessions() }) do
      local name = index and GetProfessionInfo(index)
      if name then table.insert(names, name) end
    end
  end
  for name in pairs(CR.skill or {}) do
    local seen = false
    for _, n in ipairs(names) do if n == name then seen = true end end
    if not seen then table.insert(names, name) end
  end
  return names
end
function CR.HasAnyProfession()
  return #CR.LearnedProfessionNames() > 0
end

-- opts.listW: the profession list's width (narrower in the professions book)
function CR.CreateStartPanel(parent, opts)
  opts = opts or {}
  local panel = CreateFrame("Frame", nil, parent)
  local selected = "Alchemy"

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 4, -4)
  title:SetText("Pick a profession")
  CR.ThemeRegisterAccentText(title)
  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  intro:SetPoint("RIGHT", panel, "RIGHT", -4, 0)
  intro:SetJustifyH("LEFT")
  intro:SetWordWrap(true)
  intro:SetText("This character hasn't learned a profession yet. Pick one to see the nearest trainers "
    .. "who teach it, and pin one on your map. You can learn two main professions (crafting or "
    .. "gathering) and all three secondary ones.")

  -- left: the professions, by group
  local list = CreateFrame("Frame", nil, panel)
  list:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -12)
  list:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
  list:SetWidth(opts.listW or 240)
  CR.Backdrop(list, 0, 0, 0, 0.35)

  local buttons = {}
  local y = -6
  for _, g in ipairs(GROUPS) do
    local h = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetPoint("TOPLEFT", 8, y)
    h:SetPoint("RIGHT", list, "RIGHT", -8, 0)
    h:SetJustifyH("LEFT")
    h:SetText(g.title)
    CR.ThemeRegisterAccentText(h)
    y = y - 16
    for _, spec in ipairs(g.list) do
      local b = CreateFrame("Button", nil, list)
      b:SetHeight(ROW_H)
      b:SetPoint("TOPLEFT", 4, y)
      b:SetPoint("RIGHT", list, "RIGHT", -4, 0)
      b.icon = b:CreateTexture(nil, "ARTWORK")
      b.icon:SetSize(20, 20)
      b.icon:SetPoint("LEFT", 4, 0)
      b.icon:SetTexture(spec[2])
      b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
      b.text:SetText(spec[1])
      b.sel = b:CreateTexture(nil, "BACKGROUND")
      b.sel:SetAllPoints()
      b.sel:SetColorTexture(1, 0.82, 0, 0.18)
      local hl = b:CreateTexture(nil, "HIGHLIGHT")
      hl:SetAllPoints()
      hl:SetColorTexture(1, 1, 1, 0.08)
      b.spec = spec
      b:SetScript("OnClick", function()
        selected = spec[1]
        panel:Refresh()
      end)
      table.insert(buttons, b)
      y = y - ROW_H
    end
    y = y - 8
  end

  -- right: the picked profession - what it is, its nearest trainers, the route
  local info = CreateFrame("Frame", nil, panel)
  info:SetPoint("TOPLEFT", list, "TOPRIGHT", 12, 0)
  info:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
  CR.Backdrop(info, 0, 0, 0, 0.35)

  info.icon = info:CreateTexture(nil, "ARTWORK")
  info.icon:SetSize(36, 36)
  info.icon:SetPoint("TOPLEFT", 12, -12)
  info.name = info:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  info.name:SetPoint("TOPLEFT", info.icon, "TOPRIGHT", 10, -2)
  info.desc = info:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  info.desc:SetPoint("TOPLEFT", info.name, "BOTTOMLEFT", 0, -4)
  info.desc:SetPoint("RIGHT", info, "RIGHT", -12, 0)
  info.desc:SetJustifyH("LEFT")
  info.desc:SetWordWrap(true)

  info.trainHead = info:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  info.trainHead:SetPoint("TOPLEFT", info.icon, "BOTTOMLEFT", 0, -22)
  info.trainHead:SetText("Nearest trainers")
  CR.ThemeRegisterAccentText(info.trainHead)
  info.note = info:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  info.note:SetPoint("TOPLEFT", info.trainHead, "BOTTOMLEFT", 0, -6)
  info.note:SetPoint("RIGHT", info, "RIGHT", -12, 0)
  info.note:SetJustifyH("LEFT")
  info.note:SetWordWrap(true)

  info.rows = {}
  for i = 1, 3 do
    local r = CreateFrame("Frame", nil, info)
    r:SetHeight(26)
    r:SetPoint("TOPLEFT", info.trainHead, "BOTTOMLEFT", 0, -6 - (i - 1) * 28)
    r:SetPoint("RIGHT", info, "RIGHT", -12, 0)
    r.pin = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
    r.pin:SetSize(44, 22)
    r.pin:SetPoint("LEFT", 0, 0)
    r.pin:SetText("Pin")
    CR.ThemeRegisterButton(r.pin)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetPoint("LEFT", r.pin, "RIGHT", 8, 0)
    r.text:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    info.rows[i] = r
  end

  info.route = CreateFrame("Button", nil, info, "UIPanelButtonTemplate")
  info.route:SetSize(opts.listW and 190 or 200, 24)
  info.route:SetPoint("BOTTOMLEFT", 12, 12)
  info.route:SetText("Show me the leveling route")
  CR.ThemeRegisterButton(info.route)
  info.route:SetScript("OnClick", function()
    local db = CraftRouteCharDB
    db.profession = selected
    db.profPicked = true
    if CR.InvalidatePlan then CR.InvalidatePlan() end
    CR.NotifyChanged()
    CR.ShowWindow("plan")
  end)
  info.routeNote = info:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  info.routeNote:SetPoint("BOTTOMLEFT", info.route, "TOPLEFT", 0, 6)
  info.routeNote:SetPoint("RIGHT", info, "RIGHT", -12, 0)
  info.routeNote:SetJustifyH("LEFT")
  info.routeNote:SetWordWrap(true)

  function panel:Refresh()
    local spec
    for _, b in ipairs(buttons) do
      b.sel:SetShown(b.spec[1] == selected)
      if b.spec[1] == selected then spec = b.spec end
    end
    if not spec then return end
    info.icon:SetTexture(spec[2])
    info.name:SetText(spec[1])
    info.desc:SetText(spec[3])

    -- trainers who teach it from the start (Apprentice), nearest first
    local near = CR.NearestTrainers and CR.NearestTrainers(spec[1], 1, 3) or {}
    for i, r in ipairs(info.rows) do
      local t = near[i]
      if t then
        local where = t.zone or ""
        if t.dist then
          where = where .. string.format("  (%d yards)", math.floor(t.dist / 10 + 0.5) * 10)
        elseif t.far then
          where = where .. "  (another continent)"
        end
        r.text:SetText(t.name .. CR.ColorText("  " .. where, "aaaaaa"))
        r.pin:SetScript("OnClick", function() CR.PinPlace(t) end)
        r:Show()
      else
        r:Hide()
      end
    end
    if #near > 0 then
      info.note:SetText("")
      info.note:Hide()
    else
      info.note:SetText(type(TrainerSpellsProfessionTrainers) == "table"
        and "No trainer for your faction found in the data. Ask a city guard - they mark trainers on your map."
        or "Install the TrainerSpells addon to see trainers here with map pins. Until then, ask a city guard - they mark trainers on your map.")
      info.note:Show()
    end

    local route = HasRoute(spec[1])
    info.route:SetShown(route)
    info.routeNote:SetText(route and "CraftRoute has a leveling route for it - see the steps and what to buy before you start."
      or "CraftRoute doesn't have a leveling route for gathering professions - level it by gathering as you quest.")
  end

  panel:SetScript("OnShow", function(self) self:Refresh() end)
  return panel
end

---------------------------------------------------------------------------
-- The professions book (K / the Professions micro button): with no profession learned it's
-- empty, so CraftRoute's tab sits on its side and opens the start page over it - shown straight
-- away when the book opens for a character with nothing learned.
---------------------------------------------------------------------------
local TAB_ICON = "Interface\\Icons\\Ability_Druid_ChallangingRoar"
local book   -- { tab, page } once built

local function BuildBook()
  local parent = ProfessionsBookFrame
  if book or not parent then return book end
  book = {}
  local page = CreateFrame("Frame", "CraftRouteBookPage", parent, "BackdropTemplate")
  page:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -24)
  page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
  page:SetFrameLevel(parent:GetFrameLevel() + 300)
  CR.Backdrop(page, 0.05, 0.05, 0.07, 0.98)
  page:EnableMouse(true)
  page:Hide()
  page:SetScript("OnShow", function() if book and book.start then book.start:Refresh() end end)
  local start = CR.CreateStartPanel(page, { listW = 190 })
  start:SetPoint("TOPLEFT", 10, -8)
  start:SetPoint("BOTTOMRIGHT", -10, 8)
  book.page, book.start = page, start
  if CR.ApplyTheme then pcall(CR.ApplyTheme, page) end

  -- the side tab, like the one on the crafting window
  local tab = CreateFrame("Button", "CraftRouteBookTab", parent)
  tab:SetSize(36, 36)
  tab:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -40)
  tab:SetFrameLevel(parent:GetFrameLevel() + 320)
  tab.bg = tab:CreateTexture(nil, "BACKGROUND")
  tab.bg:SetPoint("TOPLEFT", -2, 2)
  tab.bg:SetPoint("BOTTOMRIGHT", 2, -2)
  tab.bg:SetColorTexture(0, 0, 0, 0.8)
  tab:SetNormalTexture(TAB_ICON)
  local nt = tab:GetNormalTexture()
  if nt then nt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
  tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  tab.glow = tab:CreateTexture(nil, "OVERLAY")
  tab.glow:SetAllPoints()
  tab.glow:SetColorTexture(1, 0.82, 0.2, 0.3)
  tab.glow:Hide()
  tab:SetScript("OnClick", function()
    page:SetShown(not page:IsShown())
    tab.glow:SetShown(page:IsShown())
  end)
  tab:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("CraftRoute")
    GameTooltip:AddLine("Pick a profession and find its nearest trainer.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  tab:SetScript("OnLeave", GameTooltip_Hide)
  book.tab = tab

  -- opening the book: with nothing learned, the tab is there and its page shows straight away;
  -- once something's learned the book is Blizzard's own again
  parent:HookScript("OnShow", function()
    local none = not CR.HasAnyProfession()
    tab:SetShown(none)
    page:SetShown(none)
    tab.glow:SetShown(none)
  end)
  parent:HookScript("OnHide", function() page:Hide() end)
  return book
end

local function TryBuild()
  if ProfessionsBookFrame then CR.SafeCall(BuildBook) end
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("ADDON_LOADED")
watch:RegisterEvent("PLAYER_LOGIN")
watch:SetScript("OnEvent", function(_, event, name)
  if event == "PLAYER_LOGIN" or name == "Blizzard_ProfessionsBook" then TryBuild() end
end)

-- The keybind with no profession learned: open the professions book on CraftRoute's page (or
-- close it, if it's already showing). True if it could.
function CR.OpenBookStart()
  if not ProfessionsBookFrame then
    if ProfessionsBook_LoadUI then pcall(ProfessionsBook_LoadUI)
    elseif C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, "Blizzard_ProfessionsBook")
    elseif LoadAddOn then pcall(LoadAddOn, "Blizzard_ProfessionsBook") end
  end
  TryBuild()
  local f = ProfessionsBookFrame
  if not f then return false end
  if f:IsShown() then
    if book and not book.page:IsShown() then
      book.page:Show()
      book.tab:Show()
      book.tab.glow:Show()
    elseif HideUIPanel then
      HideUIPanel(f)
    else
      f:Hide()
    end
    return true
  end
  if ToggleProfessionsBook then
    ToggleProfessionsBook()
  elseif ProfessionMicroButton and ProfessionMicroButton.Click then
    ProfessionMicroButton:Click()
  elseif ShowUIPanel then
    ShowUIPanel(f)
  else
    f:Show()
  end
  return f:IsShown()
end
