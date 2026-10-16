-- CraftRoute's settings: a window of its own (/cr, the minimap button, or the button on its page in
-- Options > AddOns > CraftRoute) - it leaves the profession window open. On it: the Materials
-- window (the CraftRoute window is /cr window), the global options (alts' materials, unlearned professions, the minimap button,
-- the look with EllesmereUI), the CraftRoute key (set right here), the addons that add to it, and
-- the commands.
-- The minimap button: left-click Settings, right-click the Materials window, drag it round the
-- minimap. A named button on the minimap, so EllesmereUI's minimap gathers it like any other.
local _, CR = ...

local ICON = "Interface\\Icons\\Ability_Druid_ChallangingRoar"   -- (the profession window tab's)
local BIND = "CRAFTROUTE_PROFESSION_TAB"   -- (Bindings.xml)

---------------------------------------------------------------------------
-- The page
---------------------------------------------------------------------------
-- the settings: a window of its own (moved by its title, closed by its x or Escape) - it leaves the
-- profession window alone, as the game's Options window doesn't
local win = CreateFrame("Frame", "CraftRouteSettings", UIParent, "BackdropTemplate")
win:SetSize(660, 640)
win:SetPoint("CENTER", 0, 40)
win:SetFrameStrata("DIALOG")
win:SetClampedToScreen(true)
win:SetMovable(true)
win:EnableMouse(true)
win:RegisterForDrag("LeftButton")
win:SetScript("OnDragStart", win.StartMoving)
win:SetScript("OnDragStop", win.StopMovingOrSizing)
win:Hide()
table.insert(UISpecialFrames, "CraftRouteSettings")   -- (Escape closes it)
local winClose = CreateFrame("Button", nil, win, "UIPanelCloseButton")
winClose:SetPoint("TOPRIGHT", -2, -2)
-- and a Close button at the bottom
local closeBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
closeBtn:SetSize(100, 24)
closeBtn:SetPoint("BOTTOMRIGHT", -16, 14)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() win:Hide() end)

-- Options > AddOns > CraftRoute: a button to the window
local panel = CreateFrame("Frame")
panel.name = "CraftRoute"
panel:Hide()
do
  local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", 16, -16)
  t:SetText("CraftRoute")
  local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
  d:SetText("CraftRoute's settings are in a window of their own (also /cr, or the minimap button).")
  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetSize(220, 26)
  b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -14)
  b:SetText("Open CraftRoute Settings")
  b:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
    CR.OpenSettings(true)
  end)
end
local category

local built = false
local syncs = {}
local function Build()
  if built then return end
  built = true
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = getMeta and getMeta("CraftRoute", "Version")

  local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("CraftRoute" .. (version and CR.ColorText("  v" .. version, "888888") or ""))
  local sub = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Profession leveling routes, materials and shopping lists.")

  local y = -70
  local function Heading(text)
    local h = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 16, y)
    h:SetText(text)
    y = y - 24
  end
  local function Button(text, w, x, fn, tip)
    local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
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
    local cb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
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
  Button("Materials window", 170, 16, function(self) if CR.ToggleAllMaterials then CR.ToggleAllMaterials(true, self) end end,
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
      if CR.SyncAltsChecks then CR.SyncAltsChecks() end
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
    local label = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 22, y - 4)
    label:SetText("Window look")
    local dd = CR.CreateDropdown(win, 200, CR.LookOptions, function() return CraftRouteDB.theme or "default" end,
      function(v) CR.SetLook(v) end)
    dd:SetPoint("LEFT", label, "RIGHT", 10, 0)
    table.insert(syncs, function() dd:Sync() end)
    y = y - 34
  end
  y = y - 12

  Heading("Key binding")
  -- the CraftRoute key (the same binding as in Options > Keybindings > AddOns): click, then press it
  local kbLabel = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  kbLabel:SetPoint("TOPLEFT", 22, y - 5)
  kbLabel:SetText("Profession tab")
  local kb = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  kb:SetSize(180, 24)
  kb:SetPoint("LEFT", kbLabel, "RIGHT", 12, 0)
  kb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local hint = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("LEFT", kb, "RIGHT", 10, 0)
  local capturing = false
  local function Show()
    local key = GetBindingKey and GetBindingKey(BIND)
    if capturing then
      kb:SetText(CR.ColorText("Press a key...", "ffd100"))
      hint:SetText("Escape cancels")
    else
      kb:SetText(key and (GetBindingText and GetBindingText(key) or key) or CR.ColorText("Not bound", "888888"))
      hint:SetText("Click to set, right-click to clear")
    end
  end
  -- (keys only while it's waiting for one - otherwise every key, Escape too, goes on as usual)
  local function Listen(on)
    kb:EnableKeyboard(on)
    if not InCombatLockdown() and kb.SetPropagateKeyboardInput then pcall(kb.SetPropagateKeyboardInput, kb, not on) end
  end
  local function Stop()
    capturing = false
    Listen(false)
    Show()
  end
  local function Save()
    if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
  end
  kb:SetScript("OnClick", function(_, mouse)
    if InCombatLockdown() then CR.Print("Can't change key bindings in combat.") return end
    if mouse == "RightButton" then
      -- cleared: every key it had
      for _, k in ipairs({ GetBindingKey(BIND) }) do SetBinding(k) end
      Save()
      Stop()
      return
    end
    capturing = not capturing
    Listen(capturing)
    Show()
  end)
  kb:SetScript("OnKeyDown", function(self, key)
    if not capturing then
      if not InCombatLockdown() then pcall(self.SetPropagateKeyboardInput, self, true) end
      return
    end
    if key == "ESCAPE" then Stop() return end
    -- a modifier on its own isn't the key - wait for the rest
    if key:match("^[LR]?SHIFT$") or key:match("^[LR]?CTRL$") or key:match("^[LR]?ALT$") or key:match("^[LR]?META$") then return end
    local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "")
      .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    -- the old key goes; the new one is this binding's (taken from whatever had it)
    for _, k in ipairs({ GetBindingKey(BIND) }) do SetBinding(k) end
    SetBinding(combo, BIND)
    Save()
    Stop()
  end)
  kb:SetScript("OnHide", Stop)
  Listen(false)
  table.insert(syncs, Show)
  y = y - 40

  -- what else to install for everything CraftRoute can do (each shown installed or not)
  Heading("Recommended addons")
  local function Loaded(name)
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return isLoaded and isLoaded(name) and true or false
  end
  -- three columns: the addon, installed or not, what it adds (wrapped in its own column)
  local NAME_W, STATUS_W, DESC_W = 110, 100, 400
  for _, a in ipairs({
    { "Auctionator", "Auction House prices - costs, profit and the route cost - and the shopping lists." },
    { "Syndicator", "Counts your alts' bags, bank and mail (Count alts' materials). Comes with Baganator." },
    { "TrainerSpells", "Live recipe data, and where trainers and vendors are, with map pins." },
    { "EllesmereUI", "The matching window looks, have/need counts on its loot feed, its movers and minimap." },
    { "Questie", "Pins the nearest vendor for a reagent's Vendor button. QuestieDB comes with it." },
  }) do
    local name = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", 22, y)
    name:SetWidth(NAME_W)
    name:SetJustifyH("LEFT")
    name:SetText(a[1])
    local status = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("TOPLEFT", 22 + NAME_W, y)
    status:SetWidth(STATUS_W)
    status:SetJustifyH("LEFT")
    local desc = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", 22 + NAME_W + STATUS_W, y)
    desc:SetWidth(DESC_W)
    desc:SetJustifyH("LEFT")
    desc:SetJustifyV("TOP")
    desc:SetWordWrap(true)
    desc:SetTextColor(0.8, 0.8, 0.8)
    desc:SetText(a[2])
    table.insert(syncs, function()
      local ok = Loaded(a[1])
      status:SetText(ok and CR.ColorText("installed", "40ff40") or CR.ColorText("not installed", "ff6060"))
    end)
    -- (the row is as tall as its description)
    y = y - math.max(18, (tonumber(desc:GetStringHeight()) or 14)) - 8
  end
  y = y - 16

  Heading("Commands")
  local cmds = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cmds:SetPoint("TOPLEFT", 22, y)
  cmds:SetWidth(560)
  cmds:SetJustifyH("LEFT")
  cmds:SetSpacing(3)
  cmds:SetText(CR.ColorText("/cr", "ffd100") .. "  these settings\n"
    .. CR.ColorText("/cr window", "ffd100") .. "  the CraftRoute window\n"
    .. CR.ColorText("/cr all", "ffd100") .. "  the Materials window\n"
    .. CR.ColorText("/cr recipes", "ffd100") .. "  the recipe picker\n"
    .. CR.ColorText("/cr help", "ffd100") .. "  every command")
  -- (the window's height: down to the end of the commands)
  win.contentH = -y + math.max(80, tonumber(cmds:GetStringHeight()) or 80) + 24 + 36   -- (+ the Close button)
end

function CR.SettingsSync()
  if win.contentH then win:SetHeight(win.contentH) end
  for _, fn in ipairs(syncs) do pcall(fn) end
end
win:SetScript("OnShow", function()
  Build()
  if CR.Backdrop and not win.crBackdrop then
    CR.Backdrop(win, 0.05, 0.05, 0.07, 0.97)
    win.crBackdrop = true
  end
  CR.SettingsSync()
end)

-- in the game's Options (Options > AddOns > CraftRoute)
if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, "CraftRoute")
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

-- /cr and the minimap button: straight to this page
-- /cr, the minimap button, the Options page's button: the settings window (show: true opens it,
-- else it toggles)
function CR.OpenSettings(show)
  if show == nil then show = not win:IsShown() end
  win:SetShown(show)
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
  b:SetScript("OnClick", function(self, mouse)
    if mouse == "RightButton" then
      if CR.ToggleAllMaterials then CR.ToggleAllMaterials(nil, self) end
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
