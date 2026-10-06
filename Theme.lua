-- Window themes matching EllesmereUI's four looks (only offered when EllesmereUI is loaded).
--   default  - CraftRoute's own look (dark dialog box). Always the fallback.
--   eui      - EllesmereUI Style: flat dark panel, thin border, the user's accent colour, Expressway.
--   forever  - WoW Forever: Blizzard's frame art, which this client draws in Forever's bronze.
--   blizzard - Blizzard Style: the same frame art forced to retail's look via EllesmereUI.StockAtlas.
--   classic  - Classic WoW UI: the vanilla dialog border over the rock background.
-- Everything is reversible at runtime: switching back to "default" restores the original look.
local _, CR = ...

local EUI_FONT_FALLBACK = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.ttf"

CR.THEMES = {
  { key = "default",  text = "CraftRoute default" },
  { key = "auto",     text = "Match EllesmereUI" },
  { key = "eui",      text = "EllesmereUI Style" },
  { key = "forever",  text = "WoW Forever", foreverOnly = true },
  { key = "blizzard", text = "Blizzard Style" },
  { key = "classic",  text = "Classic WoW UI" },
}

function CR.HasEllesmere()
  return type(EllesmereUI) == "table" and EllesmereUI.ELLESMERE_GREEN ~= nil
end

-- The theme to draw: the saved pick, "auto" resolved through EllesmereUI's own active look.
function CR.ActiveTheme()
  if not CR.HasEllesmere() then return "default" end
  local pick = CraftRouteDB and CraftRouteDB.theme or "default"
  if pick == "auto" then
    local ok, look = pcall(EllesmereUI.RenderedLook)
    pick = (ok and type(look) == "string") and look or "default"
  end
  if pick == "forever" and not EllesmereUI.IS_FOREVER then pick = "blizzard" end
  return pick
end

-- Accent colour: EllesmereUI's (user-chosen) accent in its style, Blizzard gold otherwise.
function CR.AccentColor()
  if CR.ActiveTheme() == "eui" then
    local eg = EllesmereUI.ELLESMERE_GREEN
    return eg.r, eg.g, eg.b
  end
  return 1, 0.82, 0
end

function CR.AccentHex()
  local r, g, b = CR.AccentColor()
  return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

---------------------------------------------------------------------------
-- Registries (weak, filled by UI.lua as widgets are created)
---------------------------------------------------------------------------
local borders = setmetatable({}, { __mode = "k" })     -- flat backdrops: lists, dropdowns, buttons
local accentTexts = setmetatable({}, { __mode = "k" }) -- headings drawn in the accent colour
local buttons = setmetatable({}, { __mode = "k" })     -- UIPanelButtonTemplate buttons
local origFonts = setmetatable({}, { __mode = "k" })   -- FontString -> { font, size, flags }

function CR.ThemeRegisterBorder(f) borders[f] = true end
function CR.ThemeRegisterAccentText(fs) accentTexts[fs] = true end
function CR.ThemeRegisterButton(b) buttons[b] = true end

---------------------------------------------------------------------------
-- Window shell
---------------------------------------------------------------------------
local DEFAULT_BACKDROP = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 24,
  insets = { left = 6, right = 6, top = 6, bottom = 6 },
}
local CLASSIC_BACKDROP = {
  bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 256, edgeSize = 24,
  insets = { left = 6, right = 6, top = 6, bottom = 6 },
}
local FLAT_BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
}
CR.DEFAULT_BACKDROP = DEFAULT_BACKDROP

-- Blizzard's frame art as a NineSlice child (created once, shown only for the art themes).
local function NineSlice(frame)
  if frame.crNineSlice ~= nil then return frame.crNineSlice or nil end
  local ok, ns = pcall(function()
    local f = CreateFrame("Frame", nil, frame, "NineSlicePanelTemplate")
    f:SetAllPoints()
    f:SetFrameLevel(frame:GetFrameLevel())
    NineSliceUtil.ApplyLayoutByName(f, "ButtonFrameTemplateNoPortrait")
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetPoint("TOPLEFT", 6, -22)
    bg:SetPoint("BOTTOMRIGHT", -4, 4)
    bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
    bg:SetHorizTile(true)
    bg:SetVertTile(true)
    local shade = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    shade:SetAllPoints(bg)
    shade:SetColorTexture(0, 0, 0, 0.55)
    f.crBg, f.crShade = bg, shade
    return f
  end)
  frame.crNineSlice = ok and ns or false
  return ok and ns or nil
end

-- Blizzard Style on the Forever client: re-point each piece at retail's art.
local function RetailPieces(ns, retail)
  if not (EllesmereUI and EllesmereUI.StockAtlas) then return end
  for _, region in ipairs({ ns:GetRegions() }) do
    if region.GetAtlas then
      local atlas = region.crAtlas or region:GetAtlas()
      if atlas then
        region.crAtlas = atlas
        if retail then pcall(EllesmereUI.StockAtlas, region, atlas, false)
        else region:SetTexCoord(0, 1, 0, 1); region:SetAtlas(atlas, false) end
      end
    end
  end
end

local function ApplyShell(frame, theme)
  local ns = (theme == "forever" or theme == "blizzard") and NineSlice(frame) or frame.crNineSlice
  if ns then
    local show = theme == "forever" or theme == "blizzard"
    ns:SetShown(show)
    ns.crBg:SetShown(show)
    ns.crShade:SetShown(show)
    if show then RetailPieces(ns, theme == "blizzard") end
  end
  frame.crTopBar = frame.crTopBar or frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  frame.crTopBar:Hide()

  if theme == "forever" or theme == "blizzard" then
    if ns then
      frame:SetBackdrop(nil)
    else
      frame:SetBackdrop(DEFAULT_BACKDROP)   -- art unavailable on this client: safe fallback
    end
  elseif theme == "classic" then
    frame:SetBackdrop(CLASSIC_BACKDROP)
  elseif theme == "eui" then
    frame:SetBackdrop(FLAT_BACKDROP)
    local bg = EllesmereUI.DARK_BG or { r = 0.069, g = 0.058, b = 0.047 }
    local bc = EllesmereUI.BORDER_COLOR or { r = 1, g = 1, b = 1, a = 0.05 }
    frame:SetBackdropColor(bg.r, bg.g, bg.b, 0.97)
    frame:SetBackdropBorderColor(bc.r, bc.g, bc.b, math.max(bc.a or 0.05, 0.12))
    -- the house "dark title strip" across the top
    frame.crTopBar:ClearAllPoints()
    frame.crTopBar:SetPoint("TOPLEFT", 1, -1)
    frame.crTopBar:SetPoint("TOPRIGHT", -1, -1)
    frame.crTopBar:SetHeight(40)
    frame.crTopBar:SetColorTexture(0, 0, 0, 0.3)
    frame.crTopBar:Show()
  else
    frame:SetBackdrop(DEFAULT_BACKDROP)
  end
end

---------------------------------------------------------------------------
-- Buttons (tabs, shopping list): flat in EllesmereUI Style, template art otherwise
---------------------------------------------------------------------------
local function TemplatePieces(btn)
  local out = {}
  for _, key in ipairs({ "Left", "Middle", "Right", "LeftSeparator", "RightSeparator" }) do
    if btn[key] then table.insert(out, btn[key]) end
  end
  for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
    local t = btn[getter] and btn[getter](btn)
    if t then table.insert(out, t) end
  end
  return out
end

local function ApplyButton(btn, theme)
  local flat = theme == "eui"
  for _, t in ipairs(TemplatePieces(btn)) do t:SetAlpha(flat and 0 or 1) end
  if flat and not btn.crFlat then
    local f = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    f:SetAllPoints()
    f:SetFrameLevel(math.max(0, btn:GetFrameLevel() - 1))
    f:SetBackdrop(FLAT_BACKDROP)
    local line = f:CreateTexture(nil, "OVERLAY")
    line:SetPoint("BOTTOMLEFT", 1, 1)
    line:SetPoint("BOTTOMRIGHT", -1, 1)
    line:SetHeight(2)
    f.crLine = line
    btn.crFlat = f
  end
  if btn.crFlat then
    btn.crFlat:SetShown(flat)
    if flat then
      local r, g, b = CR.AccentColor()
      btn.crFlat:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
      btn.crFlat:SetBackdropBorderColor(1, 1, 1, 0.1)
      btn.crFlat.crLine:SetColorTexture(r, g, b, 1)
      btn.crFlat.crLine:SetShown(btn.crActive == true)
    end
  end
end

-- Tabs call this when selected/unselected, so the accent underline follows.
function CR.ThemeSetButtonActive(btn, active)
  btn.crActive = active
  if btn.crFlat and btn.crFlat.crLine then btn.crFlat.crLine:SetShown(active and CR.ActiveTheme() == "eui") end
end

---------------------------------------------------------------------------
-- Fonts: EllesmereUI's font in its style, the original fonts otherwise
---------------------------------------------------------------------------
local function EachFontString(root, fn, depth)
  depth = depth or 0
  if depth > 12 then return end
  for _, region in ipairs({ root:GetRegions() }) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then fn(region) end
  end
  for _, child in ipairs({ root:GetChildren() }) do EachFontString(child, fn, depth + 1) end
end

function CR.ApplyThemeFonts(root)
  if not root then return end
  local theme = CR.ActiveTheme()
  local euiFont = theme == "eui" and (EllesmereUI.EXPRESSWAY or EUI_FONT_FALLBACK) or nil
  EachFontString(root, function(fs)
    local font, size, flags = fs:GetFont()
    if not font then return end
    if euiFont then
      if not origFonts[fs] then origFonts[fs] = { font, size, flags } end
      if font ~= euiFont then fs:SetFont(euiFont, origFonts[fs][2], origFonts[fs][3]) end
    elseif origFonts[fs] then
      local o = origFonts[fs]
      fs:SetFont(o[1], o[2], o[3])
      origFonts[fs] = nil
    end
  end)
end

---------------------------------------------------------------------------
-- Apply everything
---------------------------------------------------------------------------
local BORDER_BY_THEME = {
  default  = { 0.3, 0.3, 0.3, 0.9 },
  eui      = { 1, 1, 1, 0.08 },
  forever  = { 0.55, 0.42, 0.22, 0.9 },
  blizzard = { 0.6, 0.5, 0.25, 0.9 },
  classic  = { 0.45, 0.45, 0.45, 0.9 },
}

function CR.ThemeBorderColor()
  local c = BORDER_BY_THEME[CR.ActiveTheme()] or BORDER_BY_THEME.default
  return c[1], c[2], c[3], c[4]
end

function CR.ApplyTheme(frame)
  if not frame then return end
  local theme = CR.ActiveTheme()
  local ok, err = pcall(function()
    ApplyShell(frame, theme)
    local r, g, b, a = CR.ThemeBorderColor()
    for f in pairs(borders) do
      if f.SetBackdropBorderColor and not f.crOwnBorder then f:SetBackdropBorderColor(r, g, b, a) end
    end
    local ar, ag, ab = CR.AccentColor()
    for fs in pairs(accentTexts) do fs:SetTextColor(ar, ag, ab) end
    for btn in pairs(buttons) do ApplyButton(btn, theme) end
    if frame.crTitle then
      if theme == "eui" then frame.crTitle:SetTextColor(1, 1, 1) else frame.crTitle:SetTextColor(1, 0.82, 0) end
    end
    CR.ApplyThemeFonts(frame)
  end)
  if not ok then
    -- Never leave the window broken: fall back to the default look and say why.
    pcall(ApplyShell, frame, "default")
    CR.Print("|cffff4040theme error, using the default look:|r " .. tostring(err))
  end
end
