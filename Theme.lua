-- Window themes matching EllesmereUI's four looks (only offered when EllesmereUI is loaded).
--   default  - CraftRoute's own look (dark dialog box). Always the fallback.
--   eui      - EllesmereUI Style: flat dark panel, thin border, the user's accent colour.
--   forever  - WoW Forever: Blizzard's frame art, which this client draws in Forever's bronze.
--   blizzard - Blizzard Style: the same frame art forced to retail's look via EllesmereUI.StockAtlas.
--   classic  - Classic WoW UI: the vanilla dialog border over the rock background.
-- Everything is reversible at runtime: switching back to "default" restores the original frame.
-- The typeface follows EllesmereUI's global font for as long as that addon is loaded.
local _, CR = ...

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
local origFonts = setmetatable({}, { __mode = "k" })   -- FontString/EditBox -> { font, size, flags }

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
-- Fonts: EllesmereUI's global font on /cr and Compact whenever it is loaded,
-- whichever CraftRoute look is selected. GetFontPath() with no addon key is
-- the global face; outline and shadow come from the same setting. A /reload
-- picks up a font change. With EllesmereUI absent, the faces these widgets
-- were created with are put back. Each widget keeps the size it was created
-- at, so Compact's rank number stays on the Number12 size.
-- (From a fix contributed against 0.28.13 - CraftRoute used to force Expressway.)
---------------------------------------------------------------------------
local fontApplied = setmetatable({}, { __mode = "k" })   -- FontString/EditBox -> "path|flags|shadow" it has
local fontEpoch = 0   -- bumped when a widget is created after the last full walk

local function EachFontString(root, fn, depth)
  depth = depth or 0
  if depth > 12 or not root.GetRegions then return end
  -- EditBox text is the box itself, not a FontString region.
  if root.GetObjectType and root:GetObjectType() == "EditBox" then fn(root) end
  for _, region in ipairs({ root:GetRegions() }) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then fn(region) end
  end
  if root.GetChildren then
    for _, child in ipairs({ root:GetChildren() }) do EachFontString(child, fn, depth + 1) end
  end
end

-- Global Settings > Textures > Resource & Cast Bars > Bar Texture.
-- The same key the resource bars use for health, power and class bars:
-- _ERB_AceDB.profile.general.barTexture. "none" has no file (those bars draw
-- white). This returns nil then, and the skill bar stays flat colour.
function CR.ResourceBarPath()
  if not CR.HasEllesmere() or type(EllesmereUI.ResolveTexturePath) ~= "function" then return nil end
  local db = _G._ERB_AceDB
  local general = db and db.profile and db.profile.general
  local key = general and general.barTexture
  if type(key) ~= "string" or key == "" or key == "none" then return nil end
  local lookup = _G._ERB_BarTextures
  if not lookup and type(EllesmereUI.BuildBarTextureTables) == "function" then
    local ok, built = pcall(EllesmereUI.BuildBarTextureTables, true)
    if ok then lookup = built end
  end
  local ok, path = pcall(EllesmereUI.ResolveTexturePath, lookup, key, nil)
  if not ok or type(path) ~= "string" or path == "" then return nil end
  return path
end

-- One segment of the skill-up bar. path nil: flat colour. Otherwise the
-- Resource & Cast Bars texture, cropped to this segment's slice of the bar
-- and tinted with the band colour. u0/u1 are 0..1 across the inner width.
function CR.PaintSkillSegment(tex, hex, path, u0, u1)
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  if path then
    tex:SetTexture(path)
    tex:SetTexCoord(u0, u1, 0, 1)
    tex:SetVertexColor(r, g, b, 0.9)
  else
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetColorTexture(r, g, b, 0.9)
  end
end

-- nil path: EllesmereUI is not loaded, or its getter failed. Callers restore.
local function EllesmereFont()
  if not CR.HasEllesmere() or type(EllesmereUI.GetFontPath) ~= "function" then return nil end
  local ok, path = pcall(EllesmereUI.GetFontPath)
  if not ok or type(path) ~= "string" or path == "" then return nil end
  local flags = ""
  if type(EllesmereUI.GetFontOutlineFlag) == "function" then
    local okf, flag = pcall(EllesmereUI.GetFontOutlineFlag)
    if okf and type(flag) == "string" then flags = flag end
  end
  local shadow = false
  if type(EllesmereUI.GetFontUseShadow) == "function" then
    local oks, use = pcall(EllesmereUI.GetFontUseShadow)
    shadow = oks and use and true or false
  end
  return path, flags, shadow
end

local function ApplyOneFont(obj, path, flags, shadow, key)
  -- the profession view refreshes after every craft and bag change: only touch a string whose
  -- font isn't already the right one
  if path and fontApplied[obj] == key then return end
  local font, size, curFlags = obj:GetFont()
  if not font or not size or size <= 0 then return end
  if path then
    if not origFonts[obj] then origFonts[obj] = { font, size, curFlags } end
    local useSize = origFonts[obj][2]
    -- Shadow only renders from a FontObject, and it has to be primed before SetFont.
    if EllesmereUI.PrimeFontShadow then pcall(EllesmereUI.PrimeFontShadow, obj, shadow) end
    if pcall(obj.SetFont, obj, path, useSize, flags or "") then
      fontApplied[obj] = key
    elseif origFonts[obj] then
      local o = origFonts[obj]
      pcall(obj.SetFont, obj, o[1], o[2], o[3])
    end
  elseif origFonts[obj] then
    local o = origFonts[obj]
    pcall(obj.SetFont, obj, o[1], o[2], o[3])
    origFonts[obj], fontApplied[obj] = nil, nil
  end
end

-- A new row or lazy font string. Styles that widget now, and makes the next
-- ApplyThemeFonts on a parent walk once so anything created beside it is caught.
function CR.NoteThemeFonts(obj)
  fontEpoch = fontEpoch + 1
  if not obj then return end
  local path, flags, shadow = EllesmereFont()
  local key = path and (path .. "|" .. (flags or "") .. "|" .. tostring(shadow)) or nil
  local kind = obj.GetObjectType and obj:GetObjectType()
  if kind == "FontString" or kind == "EditBox" then
    ApplyOneFont(obj, path, flags, shadow, key)
  else
    EachFontString(obj, function(fs) ApplyOneFont(fs, path, flags, shadow, key) end)
  end
end

function CR.ApplyThemeFonts(root)
  if not root then return end
  local path, flags, shadow = EllesmereFont()
  local key = path and (path .. "|" .. (flags or "") .. "|" .. tostring(shadow)) or nil
  -- Refresh runs after every craft. Skip the tree walk when nothing new was created
  -- and the face is unchanged. NoteThemeFonts bumps fontEpoch for a new widget.
  if root.crFontKey == key and root.crFontEpoch == fontEpoch then return end
  EachFontString(root, function(obj) ApplyOneFont(obj, path, flags, shadow, key) end)
  root.crFontKey = key
  root.crFontEpoch = fontEpoch
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

-- Buttons made later (the profession-window view, rows created as lists grow) are styled as soon
-- as they're registered, not only at the next theme change.
function CR.ThemeRegisterButton(b)
  buttons[b] = true
  pcall(ApplyButton, b, CR.ActiveTheme())
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
    if CR.compactFrame then CR.ApplyThemeFonts(CR.compactFrame) end   -- the profession-window view
  end)
  if not ok then
    -- Never leave the window broken: fall back to the default look and say why.
    pcall(ApplyShell, frame, "default")
    CR.Print("|cffff4040theme error, using the default look:|r " .. tostring(err))
  end
end

-- The little shopping cart picture for a shopping list button. With text: the cart sits just
-- left of the (nudged right) label; withText false: the cart alone, centred. The button's width
-- is the caller's (leave ~20px for the cart).
function CR.SetCartTexture(tex)
  local ok = false
  if tex.SetAtlas then
    for _, atlas in ipairs({ "Perks-ShoppingCart", "perks-shoppingcart" }) do
      local good, res = pcall(tex.SetAtlas, tex, atlas, false)
      if good and res ~= false then ok = true break end
    end
  end
  if not ok then tex:SetTexture("Interface\\CURSOR\\Buy") end
end
-- A "pop out" icon drawn on a button: a page (an outline open at its top-right corner) with an
-- arrow leaving that corner - like an "open in a new window" icon.
function CR.AddPopoutIcon(b)
  local icon = CreateFrame("Frame", nil, b)
  icon:SetSize(14, 14)
  icon:SetPoint("CENTER", 0, 0)
  local function Line(w, h)
    local t = icon:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(0.95, 0.85, 0.55, 1)
    t:SetSize(w, h)
    return t
  end
  -- the page: left, bottom, and the parts of the top and right that the arrow leaves free
  Line(1.5, 11):SetPoint("BOTTOMLEFT", 0, 0)
  Line(11, 1.5):SetPoint("BOTTOMLEFT", 0, 0)
  Line(5, 1.5):SetPoint("BOTTOMLEFT", 0, 9.5)
  Line(1.5, 5):SetPoint("BOTTOMLEFT", 9.5, 0)
  -- the arrow: a shaft from the page's middle up to the top-right, and its head
  local shaft = Line(9, 1.5)
  shaft:SetPoint("CENTER", icon, "BOTTOMLEFT", 9, 9)
  shaft:SetRotation(math.rad(45))
  local h1 = Line(5, 1.5)
  h1:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, -0.5)
  local h2 = Line(1.5, 5)
  h2:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -0.5, 0)
  b.popoutIcon = icon
  return icon
end

function CR.AddCartIcon(b, withText)
  local icon = rawget(b, "cartIcon")
  if not icon then
    icon = b:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16, 16)
    CR.SetCartTexture(icon)
    b.cartIcon = icon
  end
  local fs = b:GetFontString()
  icon:ClearAllPoints()
  if withText ~= false and fs then
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", b, "CENTER", 10, 0)
    icon:SetPoint("RIGHT", fs, "LEFT", -3, 0)
  else
    icon:SetPoint("CENTER")
  end
  icon:Show()
end
