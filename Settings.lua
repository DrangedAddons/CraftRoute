-- CraftRoute's settings: one page in the game's Options (Options > AddOns > CraftRoute), which /cr
-- and the minimap button open too. The windows (the CraftRoute window, now /cr window; the
-- Materials window), the global options (alts' materials, unlearned professions, the minimap button,
-- the look with EllesmereUI), the keybind and the commands.
-- The minimap button: left-click Settings, right-click the Materials window, drag it round the
-- minimap. A named button on the minimap, so EllesmereUI's minimap gathers it like any other.
local _, CR = ...

local ICON = "Interface\\Icons\\Ability_Druid_ChallangingRoar"   -- (the profession window tab's)

---------------------------------------------------------------------------
-- The page
---------------------------------------------------------------------------
local panel = CreateFrame("Frame")
panel.name = "CraftRoute"
panel:Hide()
local category

local built = false
local syncs = {}
local function Build()
  if built then return end
  built = true
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = getMeta and getMeta("CraftRoute", "Version")

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("CraftRoute" .. (version and CR.ColorText("  v" .. version, "888888") or ""))
  local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Profession leveling routes, materials and shopping lists.")

  local y = -70
  local function Heading(text)
    local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 16, y)
    h:SetText(text)
    y = y - 24
  end
  local function Button(text, w, x, fn, tip)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(w, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", fn)
    if tip then
      b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
  end
  local function Check(text, tip, get, set)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", 16, y)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.label:SetText(text)
    cb:SetHitRectInsets(0, -((tonumber(cb.label:GetStringWidth()) or 200) + 8), 0, 0)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    cb:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:SetText(text)
      GameTooltip:AddLine(tip, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", GameTooltip_Hide)
    table.insert(syncs, function() cb:SetChecked(get() and true or false) end)
    y = y - 28
    return cb
  end

  Heading("Windows")
  Button("CraftRoute window", 170, 16, function() CR.SafeCall(CR.ShowWindow) end,
    "The full window: the Plan, the Recipes picker and the Professions tab. (Also /cr window.)")
  Button("Materials window", 170, 196, function() if CR.ToggleAllMaterials then CR.ToggleAllMaterials(true) end end,
    "Every material your professions' routes still need, in one window. (Also /cr all.)")
  y = y - 40

  Heading("General")
  -- (the same setting as every "Alts" tick - kept on while All Materials has another character's guide)
  local alts = Check("Count alts' materials",
    "Ticked: materials on your other characters (bags, bank, mail) count as owned - in the materials lists, "
      .. "the route cost, reagent colours and task steps. Needs Syndicator (with Baganator) to see alts.",
    function() return CraftRouteCharDB and CraftRouteCharDB.includeAlts end,
    function(v)
      if not v and CR.AllMaterialsUsesAlts and CR.AllMaterialsUsesAlts() then
        CR.Print("Alts' materials have to count while All Materials has another character's guide - take its column off (right-click) first.")
        CR.SettingsSync()
        return
      end
      CraftRouteCharDB.includeAlts = v
      if CR.InvalidateLocations then CR.InvalidateLocations() end
      CR.NotifyChanged()
    end)
  Check("Show professions I haven't learned",
    "Ticked, the profession pickers also offer professions this character doesn't have, so you can check "
      .. "their route and costs.",
    function() return CraftRouteCharDB and CraftRouteCharDB.showUnlearned end,
    function(v) CraftRouteCharDB.showUnlearned = v CR.NotifyChanged() end)
  Check("Show minimap button",
    "CraftRoute's button on the minimap: left-click for these settings, right-click for the Materials window.",
    function() return not (CraftRouteDB.minimap and CraftRouteDB.minimap.hide) end,
    function(v)
      CraftRouteDB.minimap = CraftRouteDB.minimap or {}
      CraftRouteDB.minimap.hide = (not v) or nil
      if CR.UpdateMinimapButton then CR.UpdateMinimapButton() end
    end)
  -- the look (EllesmereUI's styles - only with it loaded)
  if CR.HasEllesmere and CR.HasEllesmere() and CR.LookOptions then
    y = y - 4
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 22, y - 4)
    label:SetText("Window look")
    local dd = CR.CreateDropdown(panel, 200, CR.LookOptions, function() return CraftRouteDB.theme or "default" end,
      function(v) CR.SetLook(v) end)
    dd:SetPoint("LEFT", label, "RIGHT", 10, 0)
    table.insert(syncs, function() dd:Sync() end)
    y = y - 34
  end
  y = y - 12

  Heading("Key binding")
  local kb = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  kb:SetPoint("TOPLEFT", 22, y)
  kb:SetWidth(560)
  kb:SetJustifyH("LEFT")
  kb:SetText("A key for CraftRoute's profession window tab: Options > Keybindings > AddOns > CraftRoute.")
  y = y - 34

  Heading("Commands")
  local cmds = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cmds:SetPoint("TOPLEFT", 22, y)
  cmds:SetWidth(560)
  cmds:SetJustifyH("LEFT")
  cmds:SetSpacing(3)
  cmds:SetText(CR.ColorText("/cr", "ffd100") .. "  these settings\n"
    .. CR.ColorText("/cr window", "ffd100") .. "  the CraftRoute window\n"
    .. CR.ColorText("/cr all", "ffd100") .. "  the Materials window\n"
    .. CR.ColorText("/cr recipes", "ffd100") .. "  the recipe picker\n"
    .. CR.ColorText("/cr help", "ffd100") .. "  every command")
end

function CR.SettingsSync()
  for _, fn in ipairs(syncs) do pcall(fn) end
end
panel:SetScript("OnShow", function() Build() CR.SettingsSync() end)

-- in the game's Options (Options > AddOns > CraftRoute)
if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, "CraftRoute")
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

-- /cr and the minimap button: straight to this page
function CR.OpenSettings()
  if InCombatLockdown() then CR.Print("Can't open the settings in combat.") return end
  if Settings and Settings.OpenToCategory and category then
    if SettingsPanel and SettingsPanel:IsShown() and panel:IsVisible() then
      HideUIPanel(SettingsPanel)   -- (open on this page already: /cr again closes it)
      return
    end
    Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)   -- (the old frame needs it twice)
  end
end

---------------------------------------------------------------------------
-- The minimap button
---------------------------------------------------------------------------
local button
local function Angle() return (CraftRouteDB.minimap and CraftRouteDB.minimap.angle) or 215 end
local function PlaceButton()
  local a = math.rad(Angle())
  local r = (Minimap:GetWidth() or 140) / 2 + 5
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function MakeButton()
  if button or not Minimap then return end
  local b = CreateFrame("Button", "CraftRouteMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture(ICON)
  b.icon:SetSize(18, 18)
  b.icon:SetPoint("TOPLEFT", 7, -6)
  b.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  b:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      if CR.ToggleAllMaterials then CR.ToggleAllMaterials() end
    else
      CR.OpenSettings()
    end
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("CraftRoute")
    GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Materials window", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  -- dragged round the minimap's edge (where it stays)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      CraftRouteDB.minimap = CraftRouteDB.minimap or {}
      CraftRouteDB.minimap.angle = math.deg(math.atan2(cy / s - my, cx / s - mx)) % 360
      PlaceButton()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button = b
  PlaceButton()
end

function CR.UpdateMinimapButton()
  MakeButton()
  if not button then return end
  button:SetShown(not (CraftRouteDB.minimap and CraftRouteDB.minimap.hide))
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  CraftRouteDB.minimap = CraftRouteDB.minimap or {}
  CR.UpdateMinimapButton()
end)
