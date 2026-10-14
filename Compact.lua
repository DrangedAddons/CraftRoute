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
local REAGENT_SLOTS = 12
-- Skill bar sits under the native title. Dropdowns, then the list, follow it.
-- Positions follow Blizzard's own recipe page (measured from it), so flicking between the two
-- barely moves anything: the header band with a centred skill bar, the pickers where its search
-- box is, the list where its recipe list starts, the right panel where its schematic is.
-- Measured against Blizzard's own page (its header ends 60 px under the title bar, its skill bar's
-- centre 36 px under it), so nothing jumps when you flick between that page and this view.
local HEADER_H = 48       -- the dark band behind the skill bar
local RANK_BAR_Y = -34    -- skill bar centre
local RANK_DROP_Y = -64   -- the pickers: Blizzard's search / filter line
local LIST_TOP = -92      -- Blizzard's first recipe header
local DIVIDER_TOP = -57   -- right panel top
local LEFT_W = 357        -- Blizzard's recipe-list column
local COST_BAR_H = 22     -- the route cost bar under the list

local overlay, entry, list
local AttachPlainCover -- secure cover for Split / Combine buttons; defined with the enchant covers
local UpdateFavCart    -- the shopping line under your list; defined with the right column
local qtyEd            -- the one amount editor (your crafts' amount buttons open it)
local matPanel, MatSettings, ToggleMatPanel   -- the materials side panel; defined with the right column
local installed = false
local installFailed = false
local openedAt = 0

local ui = {
  selectedKey = nil,
  openSteps = {},
  openParts = {}, -- component chains opened under a step's reagents
  openForks = {}, -- "Choose one" blocks of 3+ options shown in full
  keepScroll = false,
  openProf = nil,
  pinned = nil, -- dropdown pick that the profession frame has not switched to yet
  keepUntil = nil, -- a profession switch started here: stay on this view while it loads
  -- Destinations view
  destSelected = nil, -- recipe (spell) shown on the right
  destSearch = "",
  destSide = nil,     -- the open recipe is in "left" (all recipes) or "right" (your list)
  destQty = {},       -- [spell] = how many to make (the Craft view's quantity box)
  destAnchor = nil,   -- a recipe was just clicked: { spell, side, slot } - keep its row where it was
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
    table.insert(detected and learned or other, { value = name, text = ProfessionLabel(name), short = name })
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
  ui.keepUntil = GetTime() + 2   -- and this view comes back once the new profession has loaded
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

-- Learned / how many you can make / actually crafting live in Core.lua and UICraft.lua
-- (CR.RecipeLearned, CR.CraftsReady, CR.CraftSpell). This view used to keep its own copies,
-- and each one called GetRecipeInfo per recipe.

---------------------------------------------------------------------------
-- Destinations: after the route - the recipes you want to keep handy or aim to make. Picked from
-- every recipe of the profession (left), kept per character and profession (right), each with its
-- cost to make, whether it's learned and where to get it, and the usual crafting panel.
---------------------------------------------------------------------------
local TRUE_MAX = 300   -- the expansion's real cap - not a phase or character-level cap

-- the profession whose recipes are listed (the combined guide's Fishing: Cooking)
local function DestProf(name)
  local route = name and CR.Route(name)
  return (route and route.recipeProf) or name
end

local function DestList(name)
  local db = DB()
  if not db or not name then return {} end
  db.destinations = db.destinations or {}
  db.destinations[name] = db.destinations[name] or {}
  return db.destinations[name]
end

-- The Craft view's filter for this profession (kept per character): ticked mats, skillup,
-- learned, unlearned, and the quality / slot sub-lists. None ticked = everything.
local noDB = {}
local function DestFilters(name)
  local db = DB()
  if not name then return {} end
  if not db then noDB[name] = noDB[name] or {} return noDB[name] end
  db.destFilters = db.destFilters or {}
  db.destFilters[name] = db.destFilters[name] or {}
  return db.destFilters[name]
end

-- The recipe list's order for this profession (kept per character): "level" (learn skill, the
-- default), "profitDesc" or "profitAsc".
local function DestSort(name)
  local db = DB()
  return (db and name and db.destSort and db.destSort[name]) or "level"
end
local function SetDestSort(name, v)
  local db = DB()
  if not db or not name then return end
  db.destSort = db.destSort or {}
  db.destSort[name] = (v ~= "level") and v or nil
end

-- Your list's shopping selection: which recipes are ticked and how many of each (per profession,
-- kept per character). { [spell] = { on = true, qty = n } }
local function DestCart(name)
  local db = DB()
  if not db or not name then return {} end
  db.destCart = db.destCart or {}
  db.destCart[name] = db.destCart[name] or {}
  return db.destCart[name]
end
local function CartEntry(name, spell)
  local c = DestCart(name)
  c[spell] = c[spell] or {}
  return c[spell]
end

local function IsDest(name, spell)
  for _, s in ipairs(DestList(name)) do if s == spell then return true end end
  return false
end

local function ToggleDest(name, spell)
  local l = DestList(name)
  for i, s in ipairs(l) do
    if s == spell then table.remove(l, i) return false end
  end
  table.insert(l, spell)
  return true
end

-- The view you last picked with the Craft / Route buttons, for every profession (kept per
-- character); until you pick one: Route below the true max, Craft at it.
local function ViewFor(name)
  if not name then return "route" end
  local picked = CraftRouteCharDB and CraftRouteCharDB.compactView
  if picked == "dest" or picked == "route" then return picked end
  local cur = CR.GetSkill(DestProf(name))
  return (cur or 0) >= TRUE_MAX and "dest" or "route"
end

-- What one craft's reagents cost to buy (vendor or AH price), and how many of them have no price
-- yet (not seen on the AH) - 0 when all are priced.
local function MakeCost(r)
  local total, unpriced = 0, 0
  for _, rg in ipairs(r.reagents or {}) do
    local p = CR.GetUnitPrice and CR.GetUnitPrice(rg[1])
    if p then total = total + p * rg[2] else unpriced = unpriced + 1 end
  end
  return total, unpriced
end

-- What one craft sells for: its items on the AH less the 5% AH cut, or (never seen on the AH) what
-- a vendor pays for them. nil for enchants (no item) and items with neither price.
local AH_CUT = 0.95
local function SellValue(r)
  if not r.item or r.item <= 0 then return nil end
  local makes = r.makes or 1
  local ah = CR.GetAuctionPrice and CR.GetAuctionPrice(r.item)
  if ah then return math.floor(ah * AH_CUT) * makes, "ah" end
  -- GetItemInfo on a cache miss asks the client to load the item. The profit sort walks
  -- every recipe; skip the ask when the client hasn't seen this item yet.
  local cached = not (C_Item and C_Item.IsItemDataCachedByID) or C_Item.IsItemDataCachedByID(r.item)
  local vendor = cached and GetItemInfo and select(11, GetItemInfo(r.item))
  if type(vendor) == "number" and vendor > 0 then return vendor * makes, "vendor" end
  return nil
end
-- Profit on one craft (sell value less the reagents' cost), how it sells, and how many reagents
-- have no price (their cost isn't in it).
local function Profit(r)
  local v, how = SellValue(r)
  if not v then return nil end
  local cost, unpriced = MakeCost(r)
  return v - cost, how, unpriced
end
-- "+1g 20s" green / "-35s" red
local function ProfitText(p)
  if p >= 0 then return CR.ColorText("+", "40ff40") .. CR.FormatMoney(p) end
  return CR.ColorText("-", "ff4040") .. CR.FormatMoney(-p)
end

-- Show a name in full: if it's wider than its space, the text gets a point or two smaller
-- (down to 8) rather than cut off with "...". The row's normal size comes back in ResetRow.
local function FitName(fs, text)
  local font, size, flags = fs:GetFont()
  if not font or type(size) ~= "number" then fs:SetText(text) return end
  fs.crBaseSize = fs.crBaseSize or size
  size = fs.crBaseSize
  fs:SetFont(font, size, flags)
  fs:SetText(text)
  local room = tonumber(fs:GetWidth()) or 0
  if room <= 0 then   -- not laid out yet: the row's width less the icon, star and expand marker
    local parent = fs:GetParent()
    room = (parent and tonumber(parent:GetWidth()) or 0) - 80
  end
  if room <= 0 then return end
  while size > 8 and (tonumber(fs:GetStringWidth()) or 0) > room do
    size = size - 1
    fs:SetFont(font, size, flags)
  end
end

-- Filter > Slot: the gear slot a recipe makes (or, for an enchant, the slot it enchants), in
-- character-sheet order. Anything that isn't worn is "Other".
local SLOT_GROUPS = {
  { "head", "Head", { "INVTYPE_HEAD" } },
  { "neck", "Neck", { "INVTYPE_NECK" } },
  { "shoulder", "Shoulder", { "INVTYPE_SHOULDER" } },
  { "back", "Back", { "INVTYPE_CLOAK" } },
  { "chest", "Chest", { "INVTYPE_CHEST", "INVTYPE_ROBE" } },
  { "shirt", "Shirt", { "INVTYPE_BODY" } },
  { "tabard", "Tabard", { "INVTYPE_TABARD" } },
  { "wrist", "Wrist", { "INVTYPE_WRIST" } },
  { "hands", "Hands", { "INVTYPE_HAND" } },
  { "waist", "Waist", { "INVTYPE_WAIST" } },
  { "legs", "Legs", { "INVTYPE_LEGS" } },
  { "feet", "Feet", { "INVTYPE_FEET" } },
  { "finger", "Finger", { "INVTYPE_FINGER" } },
  { "trinket", "Trinket", { "INVTYPE_TRINKET" } },
  { "onehand", "One-Hand", { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" } },
  { "twohand", "Two-Hand", { "INVTYPE_2HWEAPON" } },
  { "ranged", "Ranged", { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN" } },
  { "shield", "Shield", { "INVTYPE_SHIELD" } },
  { "offhand", "Held In Off-hand", { "INVTYPE_HOLDABLE" } },
  { "bag", "Bag", { "INVTYPE_BAG", "INVTYPE_QUIVER" } },
  { "ammo", "Ammo", { "INVTYPE_AMMO" } },
  { "other", "Other", {} },
}
local SLOT_OF_INVTYPE = {}
for _, g in ipairs(SLOT_GROUPS) do for _, t in ipairs(g[3]) do SLOT_OF_INVTYPE[t] = g[1] end end
local SLOT_OF_ENCHANT = {
  ["2H Weapon"] = "twohand", ["Weapon"] = "onehand", ["Bracer"] = "wrist", ["Boots"] = "feet",
  ["Gloves"] = "hands", ["Chest"] = "chest", ["Cloak"] = "back", ["Shield"] = "shield",
  ["Off-Hand"] = "offhand", ["Necklace"] = "neck",
}
local function RecipeSlot(r)
  if r._slot then return r._slot end
  local slot
  local _, kind = CR.EnchantSlotFor(r)
  if kind then
    slot = SLOT_OF_ENCHANT[kind] or "other"
  else
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if f and r.item and r.item > 0 then
      local loc = select(4, f(r.item))
      slot = type(loc) == "string" and SLOT_OF_INVTYPE[loc] or "other"
    else
      slot = "other"
    end
  end
  r._slot = slot
  return slot
end

-- Left: every recipe (searched / filtered). Right: your destinations, in the order you added them.
local function BuildDestItems(name)
  local pn = DestProf(name)
  local p = pn and CR.professions[pn]
  if not p then return {}, {}, { profName = pn, dest = true } end
  local q = (ui.destSearch or ""):lower()
  local all, learnedOf = {}, {}
  ui.destPresent = { quality = {}, slot = {} }   -- what this profession has (the sub-lists offer only these)
  for _, r in pairs(p.recipes) do
    ui.destPresent.quality[r.q or 1] = true
    ui.destPresent.slot[RecipeSlot(r)] = true
    local learned = CR.RecipeLearned(pn, r) == true
    learnedOf[r.spell] = learned
    local F, ok = DestFilters(name), q == "" or r.name:lower():find(q, 1, true)
    if ok and (F.learned or F.unlearned) then ok = (F.learned and learned) or (F.unlearned and not learned) end
    if ok and F.mats then ok = CR.CraftsReady(pn, r) > 0 end
    if ok and F.skillup then
      local diff = CR.Difficulty(r, CR.GetSkill(pn))
      ok = diff ~= "grey" and diff ~= "red"
    end
    if ok and F.quality and next(F.quality) then ok = F.quality[r.q or 1] and true or false end
    if ok and F.slot and next(F.slot) then ok = F.slot[RecipeSlot(r)] and true or false end
    if ok then table.insert(all, r) end
  end
  local order = DestSort(name)
  local profitOf = {}
  if order ~= "level" then
    for _, r in ipairs(all) do profitOf[r] = Profit(r) or false end
  end
  table.sort(all, function(a, b)
    if order ~= "level" then
      -- by profit (high or low first); recipes with no price at the end either way
      local pa, pb = profitOf[a], profitOf[b]
      if (pa ~= false) ~= (pb ~= false) then return pa ~= false end
      if pa and pb and pa ~= pb then
        if order == "profitAsc" then return pa < pb end
        return pa > pb
      end
    end
    if (a.learn or 0) ~= (b.learn or 0) then return (a.learn or 0) < (b.learn or 0) end
    return a.name < b.name
  end)
  if ui.destSelected and not p.recipes[ui.destSelected] then ui.destSelected = nil end
  local favs = {}
  for _, spell in ipairs(DestList(name)) do
    local r = p.recipes[spell]
    if r then table.insert(favs, { kind = "destFav", recipe = r, prof = pn, list = name, fav = true, h = 44 }) end
  end
  local left = {}
  for _, r in ipairs(all) do
    table.insert(left, { kind = "dest", recipe = r, prof = pn, list = name, fav = IsDest(name, r.spell),
                         learned = learnedOf[r.spell], selected = ui.destSide == "left" and ui.destSelected == r.spell })
  end
  for _, f in ipairs(favs) do f.selected = ui.destSide == "right" and ui.destSelected == f.recipe.spell end
  local sel = ui.destSelected and p.recipes[ui.destSelected]
  return left, favs, { profName = pn, dest = true,
    selected = sel and { kind = "dest", recipe = sel, spell = sel.spell, crafts = 1 } or nil }
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

-- Craft view: an opened recipe's detail rows form one panel under its row - a faint fill, the
-- selection colour down the left, a thin edge right, and a line under the last row.
local function BoxRow(row, part)
  local b = row.crBox
  if not b then
    b = {}
    b.fill = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    b.fill:SetPoint("TOPLEFT", 1, 0)
    b.fill:SetPoint("BOTTOMRIGHT", -1, 0)
    b.fill:SetColorTexture(0.35, 0.65, 1, 0.07)
    b.bar = row:CreateTexture(nil, "ARTWORK", nil, 2)
    b.bar:SetPoint("TOPLEFT", 1, 0)
    b.bar:SetPoint("BOTTOMLEFT", 1, 0)
    b.bar:SetWidth(3)
    b.bar:SetColorTexture(0.35, 0.65, 1, 1)
    b.right = row:CreateTexture(nil, "ARTWORK", nil, 1)
    b.right:SetPoint("TOPRIGHT", -1, 0)
    b.right:SetPoint("BOTTOMRIGHT", -1, 0)
    b.right:SetWidth(1)
    b.right:SetColorTexture(0.35, 0.65, 1, 0.75)
    b.bottom = row:CreateTexture(nil, "ARTWORK", nil, 1)
    b.bottom:SetPoint("BOTTOMLEFT", 1, 1)
    b.bottom:SetPoint("BOTTOMRIGHT", -1, 1)
    b.bottom:SetHeight(1)
    b.bottom:SetColorTexture(0.35, 0.65, 1, 0.75)
    row.crBox = b
  end
  local on = part ~= nil
  b.fill:SetShown(on)
  b.bar:SetShown(on)
  b.right:SetShown(on)
  b.bottom:SetShown(part == "last")
end

local function ResetRow(row)
  row.item = nil
  row.bg:SetColorTexture(0, 0, 0, 0)
  row.sel:Hide()
  row:ShowSelected(false)
  row.optBg:Hide()
  row.optCapL:Hide()
  row.optCapR:Hide()
  row.radio:Hide()
  row.tick:Hide()
  if row.name.SetShadowOffset then row.name:SetShadowOffset(1, -1) end
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
  if row.crSub then row.crSub:Hide() end
  if row.crSub2 then row.crSub2:Hide() end
  row.right:SetWidth(78)
  row.right:ClearAllPoints()
  row.right:SetPoint("RIGHT", row.chevron, "LEFT", -2, 0)
  row.crEditing = qtyEd and qtyEd:IsShown() and row.crQtyBtn ~= nil and qtyEd.btn == row.crQtyBtn
  for _, w in ipairs({ "crPin", "crQty", "crCreate", "crAll", "crCart", "crRoute", "crPick", "crQtyBtn" }) do
    if row[w] then row[w]:Hide() end
  end
  if row.name.crBaseSize then
    local font, size, flags = row.name:GetFont()
    if font and size ~= row.name.crBaseSize then row.name:SetFont(font, row.name.crBaseSize, flags) end
  end
  if row.crStar then
    row.crStar:Hide()
    row.right:ClearAllPoints()
    row.right:SetPoint("RIGHT", row.chevron, "LEFT", -2, 0)
  end
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
  -- rows in the right-hand list open their tooltip to the left, so it stays over the window
  local inRight = overlay and overlay.favList and row:GetParent() == overlay.favList
  GameTooltip:SetOwner(row, inRight and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
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
    GameTooltip:SetText(st.letter .. ": " .. st.label, 1, 1, 1, 1, true)
    if CR.HasAuctionator() and ((st.cost or 0) > 0 or (st.unpricedN or 0) > 0) then
      GameTooltip:AddLine("Materials to buy: " .. CR.FormatMoney(st.cost or 0)
        .. ((st.unpricedN or 0) > 0 and CR.ColorText(string.format("  (+%d unpriced)", st.unpricedN), "ff9966") or ""),
        1, 1, 1, true)
    end
    GameTooltip:AddLine(st.selected and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t Chosen - this is the path the route follows."
      or "Click to choose this path instead.", st.selected and 0.4 or 1, st.selected and 1 or 0.82, st.selected and 0.4 or 0, true)
  elseif item.kind == "task" then
    GameTooltip:SetText(item.task.title or "", 1, 0.82, 0, 1, true)
    if item.task.text and item.task.text ~= "" then GameTooltip:AddLine(item.task.text, 1, 1, 1, true) end
    GameTooltip:AddLine("Click to see what to do and where.", 0.6, 0.6, 0.6)
  elseif item.kind == "dest" or item.kind == "destFav" then
    CR.RecipeTooltip(GameTooltip, item.recipe, 1)
    GameTooltip:AddLine(item.selected and "Click to close it." or "Click to open it - what it needs, where to get it, and crafting.",
      0.4, 0.8, 1, true)
    GameTooltip:AddLine(item.fav and "The star takes it off your list." or "The star adds it to your list.", 0.6, 0.6, 0.6, true)
  elseif item.kind == "dProfit" then
    GameTooltip:SetText("Profit", 1, 0.82, 0)
    if item.how == "vendor" then
      GameTooltip:AddLine("Not seen on the Auction House, so this is what a vendor pays for it, less what its materials cost.", 1, 1, 1, true)
    elseif item.how == "ah" then
      GameTooltip:AddLine("Its Auction House price less the 5% AH cut, less what its materials cost. Scales with the amount you craft.", 1, 1, 1, true)
    else
      GameTooltip:AddLine("It hasn't been seen on the Auction House and vendors don't buy it.", 1, 1, 1, true)
    end
    if item.unpriced > 0 then
      GameTooltip:AddLine(string.format("%d of its materials have no price yet, so their cost isn't counted.", item.unpriced), 1, 0.6, 0.4, true)
    end
  elseif item.kind == "dInfo" then
    GameTooltip:SetText(item.learned and "Learned" or "Not Learned", item.learned and 0.25 or 1, item.learned and 1 or 0.4, 0.25)
  elseif item.kind == "dPin" then
    GameTooltip:SetText(item.place.name)
    GameTooltip:AddLine("Pin puts it on your map and tracks it on screen.", 1, 1, 1, true)
  elseif item.kind == "toggle" then
    GameTooltip:SetText(item.open and "Show only the chosen option" or "Show every option to choose from", 1, 1, 1)
  elseif item.kind == "note" then
    GameTooltip:SetText(item.tip or item.text or "", 1, 0.82, 0, 1, true)   -- long guide notes wrap
  else
    GameTooltip:Hide()
    return
  end
  GameTooltip:Show()
end

local function ApplyRow(row, item)
  ResetRow(row)
  -- this row's amount was being edited and it now shows something else: finish that edit first
  if row.crEditing and not (item.kind == "destFav" and item.recipe and qtyEd.spell == item.recipe.spell
      and qtyEd.list == item.list) then
    qtyEd:ClearFocus()
  end
  row.item = item
  if item.box or row.crBox then BoxRow(row, item.box) end
  if overlay and overlay.enchant and overlay.enchant:GetParent() == row and item.kind ~= "dEnchant" then
    overlay.enchant:Hide()
  end
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

  if item.kind == "task" then
    local t = item.task
    row:ShowSelected(item.selected and true or false)
    row.icon:SetTexture(t.icon or BOOK)
    row.icon:Show()
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", 6, 0)
    local text
    if t.waiting then
      text = CR.ColorText(string.format("At %d: ", t.waiting), "66aaff") .. (t.title or "")
      if item.selected then row.name:SetTextColor(1, 1, 1) else row.name:SetTextColor(0.7, 0.7, 0.7) end
    elseif t.done then
      text = CR.ColorText("Done: ", "40c040") .. (t.title or "")
      if item.selected then row.name:SetTextColor(1, 1, 1) else row.name:SetTextColor(0.6, 0.6, 0.6) end
    else
      -- a step to do (not a craft): no "To do:" label - its title is orange instead, selected or
      -- not (the selection box already shows which is selected)
      text = t.title or ""
      row.name:SetTextColor(1, 0.6, 0.2)
    end
    -- the title gets the whole line; the skill it's at goes just under it (as the route's steps)
    local from = item.action.from
    local sub = from and from > 0 and tostring(from) or nil
    row.right:SetText("")
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, sub and 6 or 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, sub and 6 or 0)
    FitName(row.name, text)   -- (a title that still doesn't fit gets a point smaller, not cut off)
    if sub then
      if not row.crSub then
        row.crSub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.crSub:SetJustifyH("LEFT")
      end
      row.crSub:ClearAllPoints()
      row.crSub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
      row.crSub:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      row.crSub:SetWordWrap(false)
      row.crSub:SetText(CR.ColorText(sub, "b0b0b0"))
      row.crSub:Show()
    end
    row:SetScript("OnClick", function()
      ui.selectedKey = item.key
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
    end)
    return
  end

  -- Craft view: an opened recipe's details, in rows under it
  if item.kind == "dInfo" then
    -- Add to route / Remove from route: a target the route levels you to and makes (as the main
    -- window's Recipes tab ticks do). A guide followed strictly in order takes no targets.
    if not row.crRoute then
      row.crRoute = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
      row.crRoute:SetSize(118, 20)
      CR.ThemeRegisterButton(row.crRoute)
    end
    local rt = CR.Route and CR.Route(item.list)
    local targets = CR.ProfTable("targets", item.prof)
    local inRoute = targets[item.recipe.spell] ~= nil
    local b = row.crRoute
    b:ClearAllPoints()
    b:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    b:SetText(inRoute and "Remove from route" or "Add to route")
    b:SetEnabled(not (rt and rt.sequential))
    b:SetScript("OnClick", function()
      local t = CR.ProfTable("targets", item.prof)
      t[item.recipe.spell] = (t[item.recipe.spell] == nil) and 1 or nil
      CR.InvalidatePlan()
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
      CR.NotifyChanged()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      if rt and rt.sequential then
        GameTooltip:SetText("This guide is followed in order", 1, 0.82, 0)
        GameTooltip:AddLine("It doesn't take extra recipes as targets.", 1, 1, 1, true)
      else
        GameTooltip:SetText(inRoute and "Remove from route" or "Add to route", 1, 0.82, 0)
        GameTooltip:AddLine(inRoute and "Takes it back off the route's targets."
          or "Makes it a target on the Route: it's crafted at the right point (once you can), "
          .. "and its materials join the route's shopping.", 1, 1, 1, true)
      end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Show()
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", 32, 0)
    row.name:SetPoint("RIGHT", b, "LEFT", -6, 0)
    if item.learned then
      row.name:SetText(CR.ColorText("Learned", "40ff40"))
    else
      row.name:SetText(CR.ColorText("Not Learned", "ff6060") .. CR.ColorText("  learn at " .. (item.recipe.learn or 1), "aaaaaa"))
    end
    return
  end
  -- where it comes from, wrapped (long "Sold by" lists go on as many of these rows as they need)
  if item.kind == "dText" then
    if not row.crSub then
      row.crSub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      row.crSub:SetJustifyH("LEFT")
      if CR.NoteThemeFonts then CR.NoteThemeFonts(row.crSub) end
    end
    row.crSub:ClearAllPoints()
    row.crSub:SetPoint("TOPLEFT", row, "TOPLEFT", 32, -2)
    row.crSub:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 2)
    row.crSub:SetWordWrap(true)
    if row.crSub.SetJustifyV then row.crSub:SetJustifyV("MIDDLE") end
    row.crSub:SetText(item.text)
    row.crSub:Show()
    return
  end
  -- the enchant target slot, moved into this row while the Craft view shows an enchant
  if item.kind == "dEnchant" then
    local e = overlay and overlay.enchant
    if e and e.fits then
      e:SetParent(row)
      e:ClearAllPoints()
      e:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -4)
      e:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      e:SetFrameLevel(row:GetFrameLevel() + 5)
      e:Show()
    end
    return
  end
  if item.kind == "dSpacer" then return end   -- (the target slot is two rows tall)
  -- what it costs to make, just above the crafting row
  if item.kind == "dCost" then
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", 32, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.name:SetText(CR.ColorText(string.format("Cost to make %d:  ", item.qty), "aaaaaa") .. item.cost)
    return
  end
  -- what it makes you selling them (scales with the amount box, like the cost)
  if item.kind == "dProfit" then
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", 32, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    local label = CR.ColorText(string.format("Profit for %d:  ", item.qty), "aaaaaa")
    if item.profit then
      row.name:SetText(label .. ProfitText(item.profit)
        .. (item.how == "vendor" and CR.ColorText("  (vendor)", "aaaaaa") or "")
        .. (item.unpriced > 0 and CR.ColorText("  (cost incomplete)", "ff9966") or ""))
    else
      row.name:SetText(label .. CR.ColorText("no price for it yet", "888888"))
    end
    return
  end
  if item.kind == "dPin" then
    if not row.crPin then
      row.crPin = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
      row.crPin:SetSize(40, 20)
      row.crPin:SetText("Pin")
      CR.ThemeRegisterButton(row.crPin)
    end
    row.crPin:ClearAllPoints()
    row.crPin:SetPoint("LEFT", row, "LEFT", 32, 0)
    row.crPin:SetScript("OnClick", function() if CR.PinPlace then CR.PinPlace(item.place) end end)
    row.crPin:Show()
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.crPin, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.name:SetText(item.place.name .. CR.ColorText("  " .. (item.place.zone or ""), "aaaaaa"))
    return
  end
  if item.kind == "dCraft" then
    local r, prof = item.recipe, item.prof
    if not row.crCreate then
      local function Btn(w, text)
        local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        b:SetSize(w, 20)
        b:SetText(text)
        CR.ThemeRegisterButton(b)
        if CR.NoteThemeFonts then CR.NoteThemeFonts(b) end
        return b
      end
      row.crQty = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
      row.crQty:SetSize(32, 18)
      row.crQty:SetAutoFocus(false)
      row.crQty:SetNumeric(true)
      row.crQty:SetMaxLetters(4)
      row.crQty:SetJustifyH("CENTER")
      if CR.NoteThemeFonts then CR.NoteThemeFonts(row.crQty) end
      row.crCreate = Btn(56, "Create")
      row.crAll = Btn(92, "Create All")
      -- the shopping list: "Shopping list", or a small cart icon when the row is short of room
      row.crCart = Btn(88, "Shopping list")
      row.crCart:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Shopping list")
        GameTooltip:AddLine("Make an Auctionator shopping list of what you need for this many.", 1, 1, 1, true)
        GameTooltip:Show()
      end)
      row.crCart:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    row.crQty:ClearAllPoints()
    row.crQty:SetPoint("LEFT", row, "LEFT", 34, 0)
    row.crCreate:ClearAllPoints()
    row.crCreate:SetPoint("LEFT", row.crQty, "RIGHT", 6, 0)
    row.crAll:ClearAllPoints()
    row.crAll:SetPoint("LEFT", row.crCreate, "RIGHT", 4, 0)
    row.crCart:ClearAllPoints()
    row.crCart:SetPoint("LEFT", row.crAll, "RIGHT", 4, 0)
    if not row.crQty:HasFocus() then row.crQty:SetText(tostring(item.qty)) end
    local function SetQty()
      ui.destQty[r.spell] = math.max(1, tonumber(row.crQty:GetText()) or 1)
      if item.list then CartEntry(item.list, r.spell).qty = ui.destQty[r.spell] end   -- (and your list's)
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
    end
    row.crQty:SetScript("OnEnterPressed", function(self) self:ClearFocus() SetQty() end)
    row.crQty:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.crQty:SetScript("OnEditFocusLost", SetQty)
    local can = item.learned and CR.CraftsReady(prof, r) or 0
    row.crCreate:SetEnabled(item.learned and can > 0 and not InCombatLockdown())
    row.crAll:SetText(string.format("Create All [%d]", can))
    row.crAll:SetEnabled(can > 0 and not InCombatLockdown())
    local isEnchant = CR.EnchantSlotFor(r) and true or false
    row.crCreate:SetScript("OnClick", function()
      CR.CraftSpell(r.spell, math.max(1, tonumber(row.crQty:GetText()) or item.qty), prof)
    end)
    row.crAll:SetScript("OnClick", function()
      local n = CR.CraftsReady(prof, r)
      if n > 0 then
        ui.destQty[r.spell] = n
        CR.CraftSpell(r.spell, n, prof)
      end
    end)
    row.crCart:SetScript("OnClick", function()
      CR.CreateStepShoppingList(r, math.max(1, tonumber(row.crQty:GetText()) or item.qty))
    end)
    row.crCart:SetShown(CR.HasAuctionator() and true or false)
    for _, w in ipairs({ row.crQty, row.crCreate }) do w:Show() end
    row.crAll:SetShown(not isEnchant)   -- enchants go one at a time, onto the target above
    -- the shopping list button: full text if it fits after the other buttons, else the cart icon
    local prev = isEnchant and row.crCreate or row.crAll
    row.crCart:ClearAllPoints()
    row.crCart:SetPoint("LEFT", prev, "RIGHT", 4, 0)
    local function W(f) return tonumber(f and f:GetWidth()) or 0 end
    local used = 34 + W(row.crQty) + 6 + W(row.crCreate) + 4 + (isEnchant and 0 or (W(row.crAll) + 4))
    row.crCart:SetText("Shopping list")
    local fs = row.crCart:GetFontString()
    -- room for it: cart + "Shopping list"; short of room: just the cart
    local textW = tonumber(fs and fs.GetStringWidth and fs:GetStringWidth()) or 70
    local full = math.max(100, textW + 38)
    local fits = W(row) - 8 >= used + full
    row.crCart:SetWidth(fits and full or 26)
    row.crCart:SetText(fits and "Shopping list" or "")
    CR.AddCartIcon(row.crCart, fits)
    -- a batch of it running: how far it's got
    local bs = CR.CraftBatchRunning and CR.CraftBatchRunning(r.spell) and CR.CraftBatchState()
    row.right:ClearAllPoints()
    local last = row.crCart:IsShown() and row.crCart or (row.crAll:IsShown() and row.crAll or row.crCreate)
    row.right:SetPoint("LEFT", last, "RIGHT", 6, 0)
    row.right:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.right:SetWordWrap(false)
    row.right:SetText(bs and CR.ColorText(string.format("%d/%d", bs.current, bs.total), "ffd100") or "")
    return
  end

  if item.kind == "dest" or item.kind == "destFav" then
    local r = item.recipe
    -- opened, or (your list) ticked for the shopping list: the blue selection box
    local ticked = item.kind == "destFav" and (DestCart(item.list)[r.spell] or {}).on
    row:ShowSelected((item.selected or ticked) and true or false)
    if item.selected then row.selEdges[2]:Hide() end   -- open: joins its panel below
    row.icon:SetTexture(CR.RecipeIcon(r))
    row.icon:Show()
    row.icon:ClearAllPoints()
    local fav = item.kind == "destFav"
    row.icon:SetPoint("LEFT", fav and 26 or 6, 0)
    if fav then
      -- your list: tick it for the shopping list, and how many to make
      local entry = CartEntry(item.list, r.spell)
      if not row.crPick then
        row.crPick = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.crPick:SetSize(22, 22)
        row.crPick:SetPoint("LEFT", 3, 0)
        -- the amount: a button showing it; clicking opens the one shared editor over it (an editor in
        -- the list's own rows was hidden and re-shown by every refresh, losing what you typed)
        local b = CreateFrame("Button", nil, row, "BackdropTemplate")
        b:SetSize(34, 18)
        CR.Backdrop(b, 0.02, 0.02, 0.02, 0.9)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("CENTER")
        if CR.NoteThemeFonts then CR.NoteThemeFonts(b.text) end
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.1)
        b:SetScript("OnClick", function(self) if CR.OpenQtyEditor then CR.OpenQtyEditor(self) end end)
        row.crQtyBtn = b
      end
      row.crPick:SetChecked(entry.on and true or false)
      row.crPick:SetScript("OnClick", function(self)
        CartEntry(item.list, r.spell).on = self:GetChecked() and true or nil
        UpdateFavCart()
        ui.keepScroll = true
        if overlay then overlay:Refresh() end
      end)
      row.crPick:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Shopping list")
        GameTooltip:AddLine("Tick it to include it in the shopping list at the bottom, at the amount beside its star.", 1, 1, 1, true)
        GameTooltip:Show()
      end)
      row.crPick:SetScript("OnLeave", GameTooltip_Hide)
      row.crPick:Show()
      local b = row.crQtyBtn
      b.crList, b.crSpell = item.list, r.spell
      b.text:SetText(tostring(entry.qty or 1))
      b.text:SetShown(not (qtyEd and qtyEd:IsShown() and qtyEd.btn == b))
      b:Show()
    end
    local learned = item.learned
    if learned == nil then learned = CR.RecipeLearned(item.prof, r) == true end
    local name = r.name
    local sub, profitLine
    if item.kind == "destFav" then
      local cost, unpriced = MakeCost(r)
      sub = ""
      if CR.HasAuctionator() then
        -- what the amount beside it costs to make; what that makes you sold (as its details show
        -- it) on the line below
        local n = math.max(1, (DestCart(item.list)[r.spell] or {}).qty or 1)
        sub = "costs " .. CR.FormatMoney(cost * n)
        local p = Profit(r)
        profitLine = "profit " .. (p and ProfitText(p * n) or CR.ColorText("no price yet", "888888"))
      end
      local can = learned and CR.CraftsReady(item.prof, r) or 0
      if can > 0 then sub = sub .. CR.ColorText("   " .. can .. " now", "40ff40") end
    else
      -- the level it's learned at, and "Not Learned" if you don't know it yet
      -- (dimmed like the name: the red at 55%)
      sub = tostring(r.learn or 1) .. (learned and "" or ("   " .. CR.ColorText("Not Learned", "8c2323")))
      -- sorted by profit: each one's profit per craft beside it
      if DestSort(item.list) ~= "level" then
        local p = Profit(r)
        sub = sub .. "   " .. (p and ProfitText(p) or CR.ColorText("no price", "666666"))
      end
    end
    row.right:SetText("")
    -- the crafted item's rarity colour; a recipe you don't know yet is the same colour, dimmed
    -- (and says "Not Learned" under the name)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[r.q or 1]
    local qr, qg, qb = c and c.r or 1, c and c.g or 1, c and c.b or 1
    if learned then row.name:SetTextColor(qr, qg, qb) else row.name:SetTextColor(qr * 0.55, qg * 0.55, qb * 0.55) end
    row.right:ClearAllPoints()
    row.right:SetPoint("RIGHT", row.chevron, "LEFT", -24, 0)   -- room for the star
    -- the name, and under it the level (recipe list) or what it costs to make (your list); it
    -- stops short of the star (and the expand marker)
    row.name:ClearAllPoints()
    local stop = fav and -96 or -52   -- (your list: the quantity box too)
    local up = fav and 12 or 6        -- (your list: three lines, so the name sits higher)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, up)
    row.name:SetPoint("RIGHT", row, "RIGHT", stop, up)
    if not row.crSub then
      row.crSub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      row.crSub:SetJustifyH("LEFT")
      if CR.NoteThemeFonts then CR.NoteThemeFonts(row.crSub) end
    end
    row.crSub:ClearAllPoints()
    row.crSub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
    row.crSub:SetPoint("RIGHT", row, "RIGHT", stop, 0)
    row.crSub:SetWordWrap(false)
    row.crSub:SetText(sub)
    row.crSub:Show()
    -- your list: its profit on the third line
    if profitLine then
      if not row.crSub2 then
        row.crSub2 = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.crSub2:SetJustifyH("LEFT")
        row.crSub2:SetWordWrap(false)
        if CR.NoteThemeFonts then CR.NoteThemeFonts(row.crSub2) end
      end
      row.crSub2:ClearAllPoints()
      row.crSub2:SetPoint("TOPLEFT", row.crSub, "BOTTOMLEFT", 0, -2)
      row.crSub2:SetPoint("RIGHT", row, "RIGHT", stop, 0)
      row.crSub2:SetText(profitLine)
      row.crSub2:Show()
    elseif row.crSub2 then
      row.crSub2:Hide()
    end
    FitName(row.name, name)
    -- the star: in your destinations or not
    local star = row.crStar
    if not star then
      star = CreateFrame("Button", nil, row)
      star:SetSize(16, 16)
      local function StarTex(tex)
        if not TryAtlas(tex, "auctionhouse-icon-favorite", false) then
          tex:SetTexture("Interface\\Common\\ReputationStar")
          tex:SetTexCoord(0, 0.5, 0, 0.5)
        end
      end
      star.tex = star:CreateTexture(nil, "ARTWORK")
      star.tex:SetAllPoints()
      StarTex(star.tex)
      -- hover: a soft glow of the star behind it (shown by the game while the mouse is over it)
      star.glow = star:CreateTexture(nil, "HIGHLIGHT")
      star.glow:SetPoint("CENTER")
      star.glow:SetSize(22, 22)
      StarTex(star.glow)
      star.glow:SetBlendMode("ADD")
      star.glow:SetVertexColor(1, 0.85, 0.3)
      star.glow:SetAlpha(0.55)
      -- press: the star sinks a little while the button is held, like a normal button
      star:SetScript("OnMouseDown", function(self)
        self.tex:ClearAllPoints()
        self.tex:SetPoint("TOPLEFT", 2, -2)
        self.tex:SetPoint("BOTTOMRIGHT", -1, 1)
      end)
      star:SetScript("OnMouseUp", function(self)
        self.tex:ClearAllPoints()
        self.tex:SetAllPoints()
      end)
      row.crStar = star
    end
    -- your list (right): the same expand marker the route's steps have, + to open, - when open.
    -- The recipe list (left) has none: a click there adds / removes the recipe.
    row.chevron:Show()
    local atlas = item.selected and "Professions-recipe-header-collapse" or "Professions-recipe-header-expand"
    local drew = TryAtlas(row.chevron.icon, atlas, true)
    row.chevron.icon:SetShown(drew)
    row.chevron.label:SetShown(not drew)
    row.chevron.label:SetText(item.selected and "-" or "+")
    if drew then row.chevron.icon:SetVertexColor(1, 1, 1) end
    row.chevron:SetScript("OnClick", function() row:Click() end)
    star:ClearAllPoints()
    star:SetPoint("RIGHT", row.chevron, "LEFT", -4, 0)
    if fav then
      row.crQtyBtn:ClearAllPoints()
      row.crQtyBtn:SetPoint("RIGHT", star, "LEFT", -10, 0)
    end
    star.tex:SetDesaturated(not item.fav)
    star.tex:SetAlpha(item.fav and 1 or 0.3)
    star:Show()
    star:SetScript("OnClick", function()
      ToggleDest(item.list, r.spell)   -- (only a click on the row opens a recipe)
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
    end)
    star:SetScript("OnEnter", function(self)
      if not item.fav then self.tex:SetAlpha(0.75) end   -- an empty star brightens too (no tooltip)
    end)
    star:SetScript("OnLeave", function(self)
      self.tex:SetAlpha(item.fav and 1 or 0.3)
      self.tex:ClearAllPoints()
      self.tex:SetAllPoints()
    end)
    row:SetScript("OnClick", function()
      if IsModifiedClick("CHATLINK") and r.item and r.item > 0 then
        local _, link = CR.GetItemInfo(r.item)
        if link then ChatEdit_InsertLink(link) end
        return
      end
      -- open it in place (one recipe open at a time, in either column); click again to close
      local side = item.kind == "dest" and "left" or "right"
      if item.selected then
        ui.destSelected, ui.destSide = nil, nil
      else
        ui.destSelected, ui.destSide = r.spell, side
      end
      -- it opens (or closes) where it is: its row stays put and the details expand down
      ui.destAnchor = { spell = r.spell, side = side, slot = row.slot or 1 }
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
    end)
    return
  end

  if item.kind == "toggle" then
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", 26, 0)
    row.name:SetPoint("RIGHT", -8, 0)
    row.name:SetText(item.open and "-  Hide the other options"
      or string.format("+  Show %d more option%s", item.n, item.n == 1 and "" or "s"))
    row.name:SetTextColor(0.6, 0.75, 1)
    row:SetScript("OnClick", function()
      ui.openForks[item.key] = not item.open or nil
      ui.keepScroll = true
      if overlay then overlay:Refresh() end
    end)
    return
  end

  if item.kind == "option" then
    local st = item.step
    local sel = st.selected
    row.optBg:SetVertexColor(sel and 0.15 or 0.4, sel and 0.45 or 0.3, sel and 0.15 or 0.05, sel and 0.35 or 0.22)
    row.optBg:Show()
    for _, cap in ipairs({ row.optCapL, row.optCapR }) do
      cap:SetVertexColor(sel and 0.25 or 0.9, sel and 1 or 0.7, sel and 0.25 or 0.15, 1)
      cap:Show()
    end
    -- radio: UI-RadioButton holds unchecked (left quarter) and checked (second quarter)
    if sel then row.radio:SetTexCoord(0.25, 0.5, 0, 1) else row.radio:SetTexCoord(0, 0.25, 0, 1) end
    row.radio:Show()
    row.tick:SetShown(sel and true or false)
    row.name:SetText((st.letter or "") .. "  " .. (st.label or ""))
    -- light text with a shadow so it reads on either tint
    if sel then row.name:SetTextColor(0.82, 1, 0.82) else row.name:SetTextColor(1, 0.9, 0.62) end
    -- what this path's materials cost to buy (as the main window shows it)
    row.right:ClearAllPoints()
    row.right:SetPoint("RIGHT", row.tick, "LEFT", -6, 0)
    row.right:SetText((CR.HasAuctionator() and (st.cost or 0) > 0) and CR.FormatMoney(st.cost) or "")
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.radio, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
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
          a:SetScript("OnClick", function() CR.CraftSpell(info.recipe.spell, n, info.prof.name) end)
        end
      else
        a:SetText(info.convert.uses > 1 and "Combine" or "Split")
        a:SetEnabled(info.available > 0 and not InCombatLockdown())
        row.actMacro = info.macro
      end
      rightmost = a
    end
    -- bags short: "Buy" while a vendor that sells it is open, "Vendor" when vendors do but none is
    if item.short and CR.SetBuyButton then
      row.buy:ClearAllPoints()
      row.buy:SetPoint("RIGHT", toggle and rightmost or row, toggle and "LEFT" or "RIGHT", toggle and -2 or -6, 0)
      local need, id = item.need, item.itemID
      if CR.SetBuyButton(row.buy, id, function(self)
        CR.OpenBuy(id, need - (CR.BagsAndElsewhere(id)), self, function(i)
          return math.max(0, need - (CR.BagsAndElsewhere(i)))
        end, overlay)
      end) > 0 then rightmost = row.buy end
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
  row:ShowSelected(item.selected and true or false)
  if item.selected and item.open then row.selEdges[2]:Hide() end   -- open: joins its rows below
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
  -- the name gets the whole line; the craft count and skill range ("12x  30-55") go just under it
  row.right:SetText("")
  row.name:ClearAllPoints()
  row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 6)
  row.name:SetPoint("RIGHT", row.chevron, "LEFT", -4, 6)
  FitName(row.name, name)   -- (a name that still doesn't fit gets a point smaller, not cut off)
  if not row.crSub then
    row.crSub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.crSub:SetJustifyH("LEFT")
  end
  row.crSub:ClearAllPoints()
  row.crSub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
  row.crSub:SetPoint("RIGHT", row.chevron, "LEFT", -4, 0)
  row.crSub:SetWordWrap(false)
  row.crSub:SetText(RangeLabel(st))
  row.crSub:Show()
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
  row.sel = row:CreateTexture(nil, "ARTWORK")   -- (kept for compatibility; not shown)
  row.sel:SetAllPoints()
  row.sel:Hide()

  -- "Choose one" options, a compact take on the main window's: a tinted panel (green when
  -- chosen, dark gold when not) with brighter caps at both ends, a radio button, and a tick on
  -- the chosen one in place of the main window's Choose / Selected button.
  row.optBg = row:CreateTexture(nil, "BACKGROUND", nil, 1)
  row.optBg:SetPoint("TOPLEFT", 2, -2)
  row.optBg:SetPoint("BOTTOMRIGHT", -2, 2)
  row.optBg:SetColorTexture(1, 1, 1, 1)
  row.optBg:Hide()
  row.optCapL = row:CreateTexture(nil, "BORDER")
  row.optCapL:SetPoint("TOPLEFT", row.optBg, "TOPLEFT")
  row.optCapL:SetPoint("BOTTOMLEFT", row.optBg, "BOTTOMLEFT")
  row.optCapL:SetWidth(3)
  row.optCapL:SetColorTexture(1, 1, 1, 1)
  row.optCapL:Hide()
  row.optCapR = row:CreateTexture(nil, "BORDER")
  row.optCapR:SetPoint("TOPRIGHT", row.optBg, "TOPRIGHT")
  row.optCapR:SetPoint("BOTTOMRIGHT", row.optBg, "BOTTOMRIGHT")
  row.optCapR:SetWidth(3)
  row.optCapR:SetColorTexture(1, 1, 1, 1)
  row.optCapR:Hide()
  row.radio = row:CreateTexture(nil, "ARTWORK")
  row.radio:SetSize(16, 16)
  row.radio:SetPoint("LEFT", 10, 0)
  row.radio:SetTexture("Interface\\Buttons\\UI-RadioButton")
  row.radio:Hide()
  row.tick = row:CreateTexture(nil, "OVERLAY")
  row.tick:SetSize(14, 14)
  row.tick:SetPoint("RIGHT", -10, 0)
  row.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  row.tick:Hide()

  -- The step you're looking at: a cool blue selection (soft fill, thin outline, bright bar on the
  -- left) - nothing like the green / gold options, so the two never get confused.
  local SEL_R, SEL_G, SEL_B = 0.35, 0.65, 1
  row.selFill = row:CreateTexture(nil, "BACKGROUND", nil, 2)
  row.selFill:SetPoint("TOPLEFT", 1, -1)
  row.selFill:SetPoint("BOTTOMRIGHT", -1, 1)
  row.selFill:SetColorTexture(SEL_R, SEL_G, SEL_B, 0.16)
  row.selFill:Hide()
  row.selBar = row:CreateTexture(nil, "ARTWORK", nil, 2)
  row.selBar:SetPoint("TOPLEFT", row.selFill, "TOPLEFT")
  row.selBar:SetPoint("BOTTOMLEFT", row.selFill, "BOTTOMLEFT")
  row.selBar:SetWidth(3)
  row.selBar:SetColorTexture(SEL_R, SEL_G, SEL_B, 1)
  row.selBar:Hide()
  row.selEdges = {}
  for i, spec in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
                          { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false } }) do
    local e = row:CreateTexture(nil, "ARTWORK", nil, 1)
    e:SetPoint(spec[1], row.selFill, spec[1])
    e:SetPoint(spec[2], row.selFill, spec[2])
    if spec[3] then e:SetHeight(1) else e:SetWidth(1) end
    e:SetColorTexture(SEL_R, SEL_G, SEL_B, 0.75)
    e:Hide()
    row.selEdges[i] = e
  end
  function row:ShowSelected(on)
    self.selFill:SetShown(on)
    self.selBar:SetShown(on)
    for _, e in ipairs(self.selEdges) do e:SetShown(on) end
  end
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
  CR.ThemeRegisterButton(row.act)
  CR.ThemeRegisterButton(row.buy)
  -- essences split / combine by using the item, which needs a secure click
  row.actCover = AttachPlainCover and AttachPlainCover(row.act, function()
      -- "Open" casts another profession: stay on this view while it loads
      if row.actMacro and row.actMacro:find("^/cast") then ui.keepUntil = GetTime() + 2 end
      return row.actMacro or ""
    end,
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
  row:SetScript("OnMouseWheel", function(self, delta)
    -- the list this row belongs to (the route / recipe list, or your list on the right)
    local holder = self:GetParent()
    if holder and holder.Wheel then holder:Wheel(delta) elseif list and list.Wheel then list:Wheel(delta) end
  end)
  if CR.NoteThemeFonts then CR.NoteThemeFonts(row) end
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

  -- an item can ask for a taller row (item.h; your crafts have a third line)
  local function Height(item) return item and item.h or ROW_H end
  local function Room() return (tonumber(holder:GetHeight()) or 0) + 1 end
  -- the furthest it scrolls: the last items just fill the list
  local function MaxOffset()
    local y, room = 0, Room()
    for i = #data, 1, -1 do
      y = y + Height(data[i])
      if y > room then return i end
    end
    return 0
  end
  local function Paint()
    offset = math.max(0, math.min(offset, MaxOffset()))
    local y, room, i = 0, Room(), 0
    while true do
      local item = data[offset + i + 1]
      if not item then break end
      local h = Height(item)
      if y + h > room and i > 0 then break end
      i = i + 1
      local row = rows[i]
      if not row then
        row = CreateRow(holder)
        rows[i] = row
      end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -y)
      row:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -14, -y)
      row:SetHeight(h)
      row.slot = i   -- its place on screen (the Craft view keeps a clicked recipe there)
      row:Show()
      ApplyRow(row, item)
      y = y + h
    end
    for j = i + 1, #rows do rows[j]:Hide() end
  end
  local function ApplySlider()
    local maxOff = MaxOffset()
    slider.silent = true
    -- a vertical slider's minimum is at the top: the thumb sits at the top of the list, and moves
    -- down as you scroll down
    slider:SetMinMaxValues(0, math.max(1, maxOff))
    slider:SetValue(offset)
    slider.silent = false
    slider:SetShown(maxOff > 0)
  end
  slider:SetScript("OnValueChanged", function(self, value)
    if self.silent then return end
    offset = math.max(0, math.min(MaxOffset(), math.floor(value + 0.5)))
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
  function holder:ScrollTo(index)   -- that row at the top (as far as the list goes)
    offset = math.max(0, math.min(MaxOffset(), (index or 1) - 1))
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

  -- what's left to do: crafts, and open tasks (train, book, learn a recipe, fishing) the route
  -- stops at; taskOf[plan step] = its open task
  local actions = CR.ActionSteps(entry, name)
  local taskOf = {}
  local function ActionKey(a) return a.task and ("task:" .. a.task.key) or StepKey(a) end
  for _, a in ipairs(actions) do
    if a.task then taskOf[a.planStep] = a end
  end
  -- finished task steps, and ranks waiting for your skill, stay clickable but don't stop the route
  local doneOf, doneList = {}, {}
  for _, st in ipairs(plan.steps) do
    if (st.kind == "guide" or st.kind == "train") and not taskOf[st] then
      local t = CR.StepTask(st, name)
      if t then
        local a = { task = t, kind = "task", from = st.from, planStep = st }
        doneOf[st] = a
        table.insert(doneList, a)
      end
    end
  end
  local selected
  if ui.selectedKey then
    for _, a in ipairs(actions) do
      if ActionKey(a) == ui.selectedKey then selected = a end
    end
    for _, a in ipairs(doneList) do
      if ActionKey(a) == ui.selectedKey then selected = a end
    end
  end
  if not selected then selected = actions[1] end
  ui.selectedKey = selected and ActionKey(selected) or nil
  local function TaskItem(a)
    return { kind = "task", action = a, task = a.task, key = ActionKey(a), selected = ActionKey(a) == ui.selectedKey }
  end

  -- "Choose one" blocks with more than two options show only the chosen one until opened, with a
  -- "+ Show N more options" row - they took up most of the column.
  local hiddenOpt, toggleAfter = {}, {}
  for i, st in ipairs(plan.steps) do
    if st.kind == "fork" then
      local opts = {}
      for j = i + 1, #plan.steps do
        if plan.steps[j].kind ~= "option" then break end
        table.insert(opts, plan.steps[j])
      end
      if #opts > 2 then
        local key = "fork:" .. tostring(opts[1].choice) .. ":" .. tostring(st.from or 0)
        if ui.openForks[key] then
          toggleAfter[opts[#opts]] = { key = key, open = true }
        else
          local shown = opts[1]
          for _, o in ipairs(opts) do if o.selected then shown = o end end
          for _, o in ipairs(opts) do if o ~= shown then hiddenOpt[o] = true end end
          toggleAfter[shown] = { key = key, n = #opts - 1 }
        end
      end
    end
  end

  local items = {}
  for _, st in ipairs(plan.steps) do
    if st.kind == "fork" then
      table.insert(items, { kind = "note", gold = true, text = "Choose one", tip = st.text or "Choose one" })
    elseif st.kind == "option" then
      if not hiddenOpt[st] then table.insert(items, { kind = "option", step = st }) end
      local tg = toggleAfter[st]
      if tg then table.insert(items, { kind = "toggle", key = tg.key, open = tg.open, n = tg.n }) end
    elseif (st.kind == "guide" or st.kind == "train") and (taskOf[st] or doneOf[st]) then
      table.insert(items, TaskItem(taskOf[st] or doneOf[st]))
    elseif st.kind == "guide" or st.kind == "train" then
      table.insert(items, {
        kind = "note", step = st, gold = st.kind == "train",
        icon = st.kind == "train" and BOOK or nil,
        text = CR.FactionText(st.text or ""),
        tip = CR.FactionText(st.text or ""),
      })
    elseif st.recipe and (st.kind == "craft" or st.kind == "extra" or st.kind == "target") then
      if taskOf[st] then table.insert(items, TaskItem(taskOf[st])) end   -- learn the recipe first
      local key = StepKey(st)
      local open = IsOpen(key)
      local sel = key == ui.selectedKey
      table.insert(items, {
        kind = "step", step = st, key = key, open = open, selected = sel,
      })
      if open then
        local at = #items
        AddReagents(items, st.recipe.reagents or {}, st.crafts or 1, 1, CraftProf(name), key, {})
        if not st.recipe.reagents or #st.recipe.reagents == 0 then
          table.insert(items, { kind = "note", text = CR.ColorText("No reagents.", "808080") })
        end
        -- the selected step: its rows join its header in one blue box (as the Craft view's open recipe)
        if sel then
          for i = at + 1, #items do items[i].box = (i == #items) and "last" or "mid" end
        end
      end
    end
  end
  local ahead = selected and selected ~= actions[1] and not (selected.task and (selected.task.done or selected.task.waiting))
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
  CR.CoverHover(b, target)
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
  CR.CoverHover(b, target, target:GetParent() or target)
  b.target = target
  b.wanted = wanted
  table.insert(enchantSecure, b)
  return b
end

local function FillSchematic(info)
  local frame = overlay
  local st = info and info.selected
  local task = st and st.task
  local recipe = st and not task and st.recipe or nil
  if task then
    if not frame.crTaskCard then
      frame.crTaskCard = CR.CreateTaskScroll(frame.schematic, 300)
      -- starts below the Open CraftRoute button (top right), so its title doesn't run under it
      frame.crTaskCard:SetPoint("TOPLEFT", frame.schematic, "TOPLEFT", 4, (RANK_DROP_Y + 1 - 22 - 8) - DIVIDER_TOP)
      frame.crTaskCard:SetPoint("BOTTOMLEFT", frame.schematic, "BOTTOMLEFT", 4, 8)
    end
    local sw = frame.schemW or frame.schematic:GetWidth() or 0
    if sw < 40 then sw = 300 end
    frame.crTaskCard:Fill(task, math.max(200, math.min(420, sw - 28)))
  elseif frame.crTaskCard then
    frame.crTaskCard:Hide()
  end
  frame.icon:SetShown(recipe ~= nil)
  frame.rName:SetShown(recipe ~= nil)
  frame.rSub:SetShown(recipe ~= nil)
  if not recipe then frame.rBand:Hide() end
  frame.rStructure:SetShown(recipe ~= nil)
  frame.reagentsLabel:SetShown(recipe ~= nil)
  frame.cost:SetShown(recipe ~= nil)
  frame.buttons:SetShown(recipe ~= nil)
  if frame.altsCB then frame.altsCB:SetShown(recipe ~= nil) end
  if not recipe then
    for i = 1, REAGENT_SLOTS do frame.reagents[i]:Hide() end
    if frame.rscroll then frame.rscroll:Hide() end
    if frame.shopBtn then frame.shopBtn:Hide() end
    if task then
      frame.detailEmpty:Hide()
      if frame.status then frame.status:SetText("") end
      if frame.UpdateEnchant then frame:UpdateEnchant(nil) end
      SyncEnchantSecure()
      return
    end
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
  -- the colour band follows the text; "too soon" (can't learn it yet) stays as a word too
  if diff == "red" then sub = sub .. "   " .. CR.ColorText(diffWord, CR.DIFF_COLORS[diff] or "ff4040") end
  if info.ahead then sub = sub .. CR.ColorText("   looking ahead", "aaaaaa") end
  frame.rSub:SetText(sub)
  -- only for a recipe you can craft now (no point before you can learn it), and only in the room
  -- the line has left: narrower if needed, hidden if it wouldn't fit at all
  local textW = tonumber(frame.rSub:GetStringWidth()) or 70
  local room = (tonumber(frame.rSub:GetWidth()) or 180) - textW - 8
  if diff ~= "red" and room >= 40 then
    frame.rBand:SetWidth(math.min(90, room))
    frame.rBand:ClearAllPoints()
    frame.rBand:SetPoint("LEFT", frame.rSub, "LEFT", textW + 8, 0)
    frame.rBand:Fill(recipe, cur)
    frame.rBand:Show()
  else
    frame.rBand:Hide()
  end
  local structure = CR.StructureText(recipe)
  frame.rStructure:SetText(structure or "")

  local reagents = recipe.reagents or {}
  -- Destinations: compact - the icon tucked into the corner, the learned / source lines under it,
  -- reagents straight after, slimmer rows. The route keeps Blizzard's positions.
  local compact = info.dest and true or false
  frame.icon:ClearAllPoints()
  frame.reagentsLabel:ClearAllPoints()
  if compact then
    frame.icon:SetPoint("TOPLEFT", 6, -2)
    frame.icon:SetSize(34, 34)
    frame.icon.texture:SetSize(30, 30)
    if frame.icon.ring then frame.icon.ring:Hide() end
    frame.destInfo:Show()
    frame.reagentsLabel:SetPoint("TOPLEFT", frame.destBottom or frame.destInfo, "BOTTOMLEFT", 0, -4)
  else
    frame.icon:SetSize(54, 54)
    frame.icon.texture:SetSize(46, 46)
    if frame.icon.ring and frame.icon.ring.crWanted then frame.icon.ring:Show() end
    frame.icon:SetPoint("TOPLEFT", 28, -28)
    frame.reagentsLabel:SetPoint("TOPLEFT", frame.schematic, "TOPLEFT", 26, -173)   -- Blizzard's "Reagents:" line
  end
  local rowH = compact and 22 or 42
  -- All reagents, in the scroll area (see its creation): it ends above the enchant target when
  -- this recipe has one, else above the Shopping List button.
  local rscroll, rcontent = frame.rscroll, frame.rcontent
  rscroll:ClearAllPoints()
  rscroll:SetPoint("TOPLEFT", frame.reagentsLabel, "BOTTOMLEFT", 0, -2)
  if CR.EnchantSlotFor(recipe) and frame.enchant then
    rscroll:SetPoint("BOTTOMRIGHT", frame.enchant, "TOPRIGHT", -4, 4)
  else
    rscroll:SetPoint("BOTTOMRIGHT", frame.shopBtn, "TOPRIGHT", -4, 28)   -- clear of "Count alts" too
  end
  local y = -6
  for i = 1, REAGENT_SLOTS do
    local row = frame.reagents[i]
    local rg = reagents[i]
    if rg then
      row:Show()
      row.icon:SetTexture(CR.GetItemIcon(rg[1]) or "Interface\\Icons\\INV_Misc_QuestionMark")
      local text, bags, need = HaveNeed(rg[1], rg[2], st.crafts or 1)
      row.text:SetText(text)
      row.itemID = rg[1]
      -- bags short: "Buy" while a vendor that sells it is open, "Vendor" when vendors do but none is
      local id, needAll = rg[1], need
      local buyW = 0
      if bags < need and CR.SetBuyButton then
        buyW = CR.SetBuyButton(row.buy, id, function(self)
          CR.OpenBuy(id, needAll - (CR.BagsAndElsewhere(id)), self, function(i)
            return math.max(0, needAll - (CR.BagsAndElsewhere(i)))
          end, overlay)
        end)
      else
        row.buy:Hide()
      end
      row.text:SetPoint("RIGHT", row, "RIGHT", buyW > 0 and -(buyW + 4) or -4, 0)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", rcontent, "TOPLEFT", 0, y)
      -- the right edge (and its Buy button) stays inside the column, clear of the scroll bar
      row:SetPoint("RIGHT", rcontent, "RIGHT", -10, 0)
      row:SetHeight(rowH)
      row.icon:SetSize(rowH, rowH)
      y = y - rowH - 4
    else
      row:Hide()
    end
  end
  frame.cost:SetText(CostLines(recipe, st.crafts or 1))
  frame.cost:ClearAllPoints()
  frame.cost:SetPoint("TOPLEFT", rcontent, "TOPLEFT", 0, y - 8)
  frame.cost:SetPoint("RIGHT", rcontent, "RIGHT", -10, 0)
  rcontent:SetHeight(-(y - 8) + (frame.cost:GetStringHeight() or 48) + 6)
  if frame.lastSpell ~= recipe.spell then rscroll:SetVerticalScroll(0) end
  rscroll:Show()
  rscroll:UpdateBar()
  if C_Timer then C_Timer.After(0, function() rscroll:UpdateBar() end) end

  local learned = CR.RecipeLearned(profName, recipe)
  local enchantFits = CR.EnchantSlotFor(recipe)
  local open = CR.TradeSkillOpenFor(profName)
  local ready = CR.CraftsReady(profName, recipe)
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
  -- The quantity follows the step's count (as many as you can make, while crafting the step's
  -- count left) - unless you've typed your own number in, which stays until the recipe changes.
  if not frame.countBox:HasFocus() then
    local running = CR.CraftBatchRunning and CR.CraftBatchRunning(recipe.spell)
    local want = running and (st.crafts or 1)
      or math.max(1, math.min(st.crafts or 1, ready > 0 and ready or (st.crafts or 1)))
    local typed = tonumber(frame.countBox:GetText())
    if frame.lastSpell ~= recipe.spell or running or typed == frame.autoCount then
      frame.countBox:SetText(tostring(want))
      frame.autoCount = want
    end
  end
  frame.lastSpell = recipe.spell
  frame.current = st
  frame.shopBtn:SetShown(CR.HasAuctionator() and true or false)
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

-- The fill covers exactly the frame art's dark track: it starts 4 px in from the top and the
-- sides, and stops 7 px above the bottom (the art's lower bevel), so it never spills past it.
local FILL_INSET_X, FILL_INSET_TOP, FILL_INSET_BOTTOM = 4, 4, 7
local function FillInset(bar)
  local h = bar:GetHeight() or 29
  if h < 15 then h = 29 end
  return FILL_INSET_X, FILL_INSET_TOP, h - FILL_INSET_TOP - FILL_INSET_BOTTOM
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
    ratio = math.max(0, math.min(1, (cur or 0) / maxRank))
  end
  local width = bar:GetWidth() or 0
  if width < 40 then width = 440 end

  -- The fill spans the whole track (the frame's inset on both sides), so a full bar is full:
  -- it used to stop well short of the right end and leave black in the track.
  local left, top, height = FillInset(bar)
  local track = math.max(1, width - 2 * left)
  local fill = bar.fill
  fill:ClearAllPoints()
  fill:SetPoint("TOPLEFT", bar, "TOPLEFT", left, -top)
  fill:SetHeight(height)

  -- the profession's own colour. A Resource & Cast Bars texture replaces the
  -- default status-bar art; None keeps that art. The colour stays either way.
  fill:SetTexture(CR.ResourceBarPath() or "Interface\\TargetingFrame\\UI-StatusBar")
  fill:SetTexCoord(0, math.max(ratio, 0.001), 0, 1)
  local r, g, b = CR.ProfessionColor(name)
  fill:SetVertexColor(r, g, b, 0.95)
  fill:SetShown(ratio > 0)
  fill:SetWidth(math.max(1, track * ratio))
end

-- /cr rankbar: what Blizzard's rank bar is made of (to match its art if this client differs).
function CR.DebugRankBar()
  local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
  local nb = page and (page.RankBar or page.ProfessionRankBar)
  if not nb then CR.Print("No Blizzard rank bar found (open a profession first).") return end
  CR.Print(string.format("RankBar %s  %.0fx%.0f", nb:GetName() or "?", nb:GetWidth() or 0, nb:GetHeight() or 0))
  for key, v in pairs(nb) do
    if type(v) == "table" and v.GetObjectType then
      local kind = v:GetObjectType()
      local extra = ""
      if kind == "Texture" then
        local c = { v:GetTexCoord() }
        extra = string.format(" atlas=%s tex=%s coords=%.3f,%.3f-%.3f,%.3f shown=%s", tostring(v.GetAtlas and v:GetAtlas()),
          tostring(v:GetTexture()), c[1] or 0, c[2] or 0, c[7] or 0, c[8] or 0, tostring(v:IsShown()))
      elseif v.GetRegions then
        for _, r in ipairs({ v:GetRegions() }) do
          if r.GetObjectType and r:GetObjectType() == "Texture" then
            extra = extra .. string.format(" [tex %s atlas=%s %.0fx%.0f]", tostring(r:GetTexture()),
              tostring(r.GetAtlas and r:GetAtlas()), r:GetWidth() or 0, r:GetHeight() or 0)
          end
        end
      end
      CR.Print(string.format("  .%s %s %.0fx%.0f%s", key, kind, v:GetWidth() or 0, v:GetHeight() or 0, extra))
    end
  end
end

-- The pickers sit above the route list, across the left column: profession and goal side by side
-- (with the custom skill box when "Custom skill" is picked), and the route mode (Cooking: alone or
-- with Fishing) on a second line when there is one. The list starts below them.
local function LayoutHeader()
  if not overlay then return end
  local leftW = overlay.leftW or 300
  local x, y, gap = 6, RANK_DROP_Y, 6
  local avail = leftW - x - 4
  local dest = ViewFor(PlanProfession()) == "dest"
  -- Route / Destinations, above the pickers
  if overlay.viewRoute then
    local half = math.floor((avail - gap) / 2)
    -- Craft | Route - the addon's name
    overlay.viewDest:ClearAllPoints()
    overlay.viewDest:SetPoint("TOPLEFT", overlay, "TOPLEFT", x, y + 1)
    overlay.viewDest:SetWidth(half)
    overlay.viewRoute:ClearAllPoints()
    overlay.viewRoute:SetPoint("LEFT", overlay.viewDest, "RIGHT", gap, 0)
    overlay.viewRoute:SetWidth(avail - gap - half)
    if dest then overlay.viewDest:LockHighlight() overlay.viewRoute:UnlockHighlight()
    else overlay.viewRoute:LockHighlight() overlay.viewDest:UnlockHighlight() end
    y = y - 26
  end
  local custom = overlay.customBox:IsShown() and 42 or 0
  local goal = overlay.goalDD:IsShown()
  local profW = goal and math.min(avail - gap - custom - 90, math.max(130, math.floor((avail - gap - custom) / 2))) or avail
  overlay.profDD:ClearAllPoints()
  overlay.profDD:SetPoint("TOPLEFT", overlay, "TOPLEFT", x, y)
  overlay.profDD:SetWidth(profW)
  local prev = overlay.profDD
  if goal then
    overlay.goalDD:ClearAllPoints()
    overlay.goalDD:SetPoint("LEFT", prev, "RIGHT", gap, 0)
    overlay.goalDD:SetWidth(avail - gap - custom - profW)
    prev = overlay.goalDD
  end
  if custom > 0 then
    overlay.customBox:ClearAllPoints()
    overlay.customBox:SetPoint("LEFT", prev, "RIGHT", gap + 4, 0)
  end
  local listTop = LIST_TOP - (overlay.viewRoute and 26 or 0)
  if dest and overlay.destSearch then
    -- search and filter, under the profession picker
    local fw, xw = 112, 22   -- Filter, and its clear X after it
    overlay.destSearch:ClearAllPoints()
    overlay.destSearch:SetPoint("TOPLEFT", overlay, "TOPLEFT", x + 6, y - 26)
    overlay.destSearch:SetWidth(avail - gap - fw - 6)
    overlay.destFilterDD:ClearAllPoints()
    overlay.destFilterDD:SetPoint("TOPLEFT", overlay, "TOPLEFT", x + avail - fw, y - 25)
    overlay.destFilterDD:SetWidth(fw - xw - 2)
    overlay.destFilterClear:ClearAllPoints()
    overlay.destFilterClear:SetPoint("LEFT", overlay.destFilterDD, "RIGHT", 2, 0)
    listTop = listTop - 26
  elseif overlay.modeDD:IsShown() then
    overlay.modeDD:ClearAllPoints()
    overlay.modeDD:SetPoint("TOPLEFT", overlay, "TOPLEFT", x, y - 24)
    overlay.modeDD:SetWidth(avail)
    listTop = listTop - 24
  end
  -- (both views keep the bar under the left list - empty in the Craft view - so the columns line up)
  local listBottom = 8 + COST_BAR_H + 4   -- (the bar under it stays, in both views)
  if list and (overlay.listTop ~= listTop or overlay.listBottom ~= listBottom) then
    overlay.listTop, overlay.listBottom = listTop, listBottom
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", overlay, "TOPLEFT", 6, listTop)
    list:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 6, listBottom)
    list:SetPoint("RIGHT", overlay.divider, "LEFT", -4, 0)
  end
  -- main CraftRoute window button, above the recipe at the right edge
  if overlay.mainBtn then
    overlay.mainBtn:SetText(CR.IsWindowShown and CR.IsWindowShown() and "Close CraftRoute" or "Open CraftRoute")
  end
end

local function LayoutColumns()
  if not overlay then return end
  local w = overlay:GetWidth() or 0
  local leftW = 300
  if w > 0 then leftW = math.max(260, math.min(LEFT_W, math.floor(w * 0.45))) end
  overlay.leftW = leftW
  overlay.divider:ClearAllPoints()
  overlay.divider:SetWidth(1)
  overlay.divider:SetPoint("TOPLEFT", overlay, "TOPLEFT", leftW, DIVIDER_TOP)
  overlay.divider:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", leftW, 8)
  -- the skill bar is centred, about two thirds of the width, as on Blizzard's page
  if w > 0 and overlay.rankBar then overlay.rankBar:SetWidth(math.max(300, math.min(560, math.floor(w * 0.67)))) end
  UpdateRankBar()
  LayoutHeader()
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

-- Destinations on, or off: its widgets, where the recipe panel sits, the cost bar's label.
local function SetDestWidgets(on)
  local f = overlay
  if not f.viewRoute then return end
  for _, w in ipairs({ f.destSearch, f.destFilterDD, f.destFilterClear, f.favHeader, f.favList, f.favAll, f.favCart }) do w:SetShown(on) end
  if not on and qtyEd and qtyEd:IsShown() then qtyEd:ClearFocus() end
  if not on and matPanel then matPanel:Hide() end
  if not on and f.destFilterPop then f.destFilterPop:Hide() end
  f.destInfo:Hide()
  for _, row in ipairs(f.destPins) do row:Hide() end
  if not on then f.favEmpty:Hide() end
  -- the enchant target slot: back in the recipe panel for the route
  if not on and f.enchant and f.enchant:GetParent() ~= f.schematic then
    f.enchant:SetParent(f.schematic)
    f.enchant:ClearAllPoints()
    f.enchant:SetPoint("BOTTOMLEFT", f.status, "TOPLEFT", 0, 4)
    f.enchant:SetPoint("BOTTOMRIGHT", f.status, "TOPRIGHT", 0, 4)
  end
  f.costBar.label:SetText(on and "Make each once" or "Route cost")
  f.schematic:ClearAllPoints()
  f.schematic:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
  if not on then
    f.schematic:SetPoint("TOPLEFT", f.divider, "TOPRIGHT", 12, 0)
    f.schematic:Show()
  end
end

-- The amount editor: one box, opened over the amount button you click. It isn't one of the list's
-- rows, so a refresh never hides it or moves what you type to another recipe. It opens empty
-- (the amount it had shows faintly), so the first key you press is the first digit.
function CR.OpenQtyEditor(btn)
  if not qtyEd then
    local e = CreateFrame("EditBox", nil, overlay, "InputBoxTemplate")
    e:SetAutoFocus(false)
    e:SetNumeric(true)
    e:SetMaxLetters(4)
    e:SetJustifyH("CENTER")
    e:Hide()
    e.hint = e:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    e.hint:SetPoint("CENTER")
    local function Save()
      local n = tonumber(e:GetText())
      if e.spell and n and n >= 1 then
        n = math.min(9999, math.floor(n))
        CartEntry(e.list, e.spell).qty = n
        ui.destQty[e.spell] = n   -- (the opened recipe's cost / profit and Create box follow it)
        return true
      end
    end
    e:SetScript("OnTextChanged", function()
      e.hint:SetShown(e:GetText() == "")
      if e.spell and Save() then
        UpdateFavCart()   -- the totals follow as you type
        -- its row's costs / profit (and, if it's open, its details) follow too - the editor isn't
        -- a list row, so this refresh doesn't disturb your typing
        if overlay then
          ui.keepScroll = true
          overlay:Refresh()
        end
      end
    end)
    e:SetScript("OnEnterPressed", function() e:ClearFocus() end)
    e:SetScript("OnEscapePressed", function() e.cancel = true e:ClearFocus() end)
    e:SetScript("OnEditFocusLost", function()
      if e.spell then
        if e.cancel then
          CartEntry(e.list, e.spell).qty = e.old or nil
          ui.destQty[e.spell] = e.old or nil
        else
          Save()
        end
        local b = e.btn
        if b and b.crSpell == e.spell and b.crList == e.list then
          b.text:SetText(tostring(CartEntry(e.list, e.spell).qty or 1))
          b.text:Show()
        end
      end
      e.cancel, e.spell, e.btn = false, false, false
      e:Hide()
      UpdateFavCart()
      if overlay then ui.keepScroll = true overlay:Refresh() end
    end)
    e.cancel, e.spell, e.btn, e.list, e.old = false, false, false, false, false
    qtyEd = e
  end
  local e = qtyEd
  if e:IsShown() then e:ClearFocus() end   -- (another amount was open: it's kept)
  e.btn, e.list, e.spell = btn, btn.crList, btn.crSpell
  e.old = CartEntry(e.list, e.spell).qty or false
  e.cancel = false
  e:SetFrameLevel(btn:GetFrameLevel() + 20)
  e:ClearAllPoints()
  e:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, 0)
  e:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
  e.hint:SetText(tostring(e.old or 1))   -- (false: never set - 1)
  e:SetText("")
  e.hint:Show()
  btn.text:Hide()
  e:Show()
  e:SetFocus()
end

-- The materials panel: beside the profession window, everything the ticked recipes need at their
-- amounts - all together (Total), or recipe by recipe (By recipe). have / need, as the list counts.
local MAT_ROW = 18
MatSettings = function()
  local db = DB()
  if not db then return {} end
  db.matPanel = db.matPanel or {}
  return db.matPanel
end
local function MatPanel()
  if matPanel then return matPanel end
  local p = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
  p:SetWidth(270)
  CR.Backdrop(p, 0.04, 0.04, 0.05, 0.96)
  p:EnableMouse(true)
  p:EnableMouseWheel(true)
  p:Hide()
  -- top left: tuck it back in (the pop-out button beside the cart does the same)
  p.close = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  p.close:SetSize(20, 20)
  p.close:SetPoint("TOPLEFT", 6, -7)
  p.close:SetText("<")
  CR.ThemeRegisterButton(p.close)
  p.close:SetScript("OnClick", function() ToggleMatPanel(false) end)
  p.close:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Close the materials panel")
    GameTooltip:Show()
  end)
  p.close:SetScript("OnLeave", GameTooltip_Hide)
  p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  p.title:SetPoint("LEFT", p.close, "RIGHT", 6, 0)
  p.title:SetText("Materials")
  CR.ThemeRegisterAccentText(p.title)
  local function ViewBtn(text, view, x)
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetSize(76, 20)
    b:SetPoint("TOPRIGHT", x, -7)
    b:SetText(text)
    CR.ThemeRegisterButton(b)
    b:SetScript("OnClick", function()
      MatSettings().view = view
      p.offset = 0
      p:Refresh()
    end)
    b.view = view
    return b
  end
  p.byRecipe = ViewBtn("By recipe", "recipe", -8)
  p.total = ViewBtn("Total", "total", -88)
  -- vendor items (thread, dyes, flux...): shown unless you untick this
  p.vendor = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
  p.vendor:SetSize(20, 20)
  p.vendor:SetPoint("TOPLEFT", 8, -32)
  p.vendor.label = p.vendor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  p.vendor.label:SetPoint("LEFT", p.vendor, "RIGHT", 2, 0)
  p.vendor.label:SetText("Show vendor items")
  p.vendor:SetHitRectInsets(0, -110, 0, 0)   -- (the label clicks too)
  p.vendor:SetScript("OnClick", function(self)
    MatSettings().hideVendor = (not self:GetChecked()) or nil
    p.offset = 0
    p:Refresh()
  end)
  p.rows = {}
  p.offset = 0
  p.note = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  p.note:SetPoint("TOPLEFT", 10, -62)
  p.note:SetPoint("RIGHT", p, "RIGHT", -10, 0)
  p.note:SetJustifyH("LEFT")
  p.note:SetWordWrap(true)
  p:SetScript("OnMouseWheel", function(self, delta)
    self.offset = math.max(0, (self.offset or 0) - delta)
    self:Refresh()
  end)
  local function Row(i)
    local r = p.rows[i]
    if r then return r end
    r = CreateFrame("Frame", nil, p)
    r:SetHeight(MAT_ROW)
    r:SetPoint("TOPLEFT", 8, -58 - (i - 1) * MAT_ROW)
    r:SetPoint("RIGHT", p, "RIGHT", -8, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(MAT_ROW - 3, MAT_ROW - 3)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.count = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.count:SetPoint("RIGHT", 0, 0)
    r.count:SetJustifyH("RIGHT")
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("RIGHT", r.count, "LEFT", -6, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
      if not self.id then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.id)
      GameTooltip:Show()
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
    p.rows[i] = r
    if CR.NoteThemeFonts then CR.NoteThemeFonts(r) end
    return r
  end
  function p:Refresh()
    if not self:IsShown() then return end
    local view = MatSettings().view == "recipe" and "recipe" or "total"
    for _, b in ipairs({ self.total, self.byRecipe }) do
      if b.LockHighlight then if b.view == view then b:LockHighlight() else b:UnlockHighlight() end end
      CR.ThemeSetButtonActive(b, b.view == view)
    end
    local hideVendor = MatSettings().hideVendor
    self.vendor:SetChecked(not hideVendor)
    local function Skip(id) return hideVendor and CR.IsVendorItem and CR.IsVendorItem(id) end
    local fc = overlay.favCart
    local cart = DestCart(fc.list)
    local lines, totals, order = {}, {}, {}
    for _, it in ipairs(fc.favs or {}) do
      local e = cart[it.recipe.spell]
      if e and e.on then
        local qty = e.qty or 1
        if view == "recipe" then
          table.insert(lines, { header = string.format("%s  x%d", it.recipe.name, qty), recipe = it.recipe })
        end
        for _, rg in ipairs(it.recipe.reagents or {}) do
          local n = rg[2] * qty
          if Skip(rg[1]) then
            -- (a vendor item, hidden)
          elseif view == "recipe" then
            table.insert(lines, { id = rg[1], need = n })
          else
            if not totals[rg[1]] then table.insert(order, rg[1]) end
            totals[rg[1]] = (totals[rg[1]] or 0) + n
          end
        end
      end
    end
    if view == "total" then
      table.sort(order, function(a, b) return CR.ItemName(a) < CR.ItemName(b) end)
      for _, id in ipairs(order) do table.insert(lines, { id = id, need = totals[id] }) end
    end
    self.note:SetText(#lines == 0 and "Tick recipes in Your crafts to see what they need." or "")
    self.note:SetShown(#lines == 0)
    local vis = math.max(1, math.floor(((tonumber(self:GetHeight()) or 300) - 66) / MAT_ROW))
    self.offset = math.max(0, math.min(self.offset or 0, #lines - vis))
    local shown = math.min(vis, #lines - self.offset)
    for i = 1, shown do
      local l, r = lines[self.offset + i], Row(i)
      r.icon:ClearAllPoints()
      if l.header then
        r.id = nil
        r.icon:SetTexture(CR.RecipeIcon(l.recipe))
        r.icon:SetPoint("LEFT", 0, 0)
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
        r.name:SetText(CR.ColorText(l.header, "ffd100"))
        r.count:SetText("")
      else
        r.id = l.id
        r.icon:SetTexture(CR.GetItemIcon(l.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
        r.icon:SetPoint("LEFT", view == "recipe" and 14 or 0, 0)
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
        r.name:SetText(CR.ItemName(l.id))
        local have = CR.HaveCount(l.id)
        r.count:SetText(CR.ColorText(string.format("%d/%d", math.min(have, l.need), l.need), have >= l.need and "40ff40" or "ffd100"))
      end
      r:Show()
    end
    for i = shown + 1, #self.rows do self.rows[i]:Hide() end
    if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, self) end
  end
  p:SetScript("OnShow", function(self) self:Refresh() end)
  matPanel = p
  return p
end
-- open / close it (remembered), against the profession window's right edge
ToggleMatPanel = function(show)
  local p = MatPanel()
  if show == nil then show = not p:IsShown() end
  p:ClearAllPoints()
  local host = ProfessionsFrame or overlay
  -- right against the window, over its side tabs (CraftRoute's too) - close it to get at them
  p:SetPoint("TOPLEFT", host, "TOPRIGHT", 0, 0)
  p:SetPoint("BOTTOMLEFT", host, "BOTTOMRIGHT", 0, 0)
  p:SetFrameStrata(host:GetFrameStrata())
  p:SetFrameLevel(host:GetFrameLevel() + 600)
  p:SetShown(show)
end

-- The shopping line under your list (and the header's select-all tick): how many are ticked, what
-- buying what they still need costs and what they'd make you, at the amounts set. Run on every
-- refresh, and as you type an amount.
function UpdateFavCart()
  local f = overlay
  local fc = f and f.favCart
  if not fc then return end
  local name, favs = fc.list, fc.favs or {}
  local cart, picked = DestCart(name), 0
  for _, it in ipairs(favs) do if cart[it.recipe.spell] and cart[it.recipe.spell].on then picked = picked + 1 end end
  f.favAll:SetChecked(#favs > 0 and picked == #favs)
  f.favAll:SetShown(#favs > 0)
  fc.text:SetText(picked > 0 and string.format("%d selected", picked)
    or CR.ColorText("Tick recipes for a shopping list", "888888"))
  fc.button:SetEnabled(picked > 0 and CR.HasAuctionator() and true or false)
  -- the gold: what the ticked recipes at their amounts still need to buy (what you have taken off)
  -- and the profit: each one's profit per craft (as its details show it) times its amount
  local goldText, profitText = "", ""
  if picked > 0 and CR.HasAuctionator() and CR.MultiNeeds then
    local entries, profit, noPrice = {}, 0, 0
    for _, it in ipairs(favs) do
      local e = cart[it.recipe.spell]
      if e and e.on then
        table.insert(entries, { recipe = it.recipe, crafts = e.qty or 1 })
        local p = Profit(it.recipe)
        if p then profit = profit + p * (e.qty or 1) else noPrice = noPrice + 1 end
      end
    end
    local total, unpriced = CR.NeedsCost(CR.MultiNeeds(entries, true))
    goldText = CR.ColorText("Cost ", "aaaaaa") .. CR.FormatMoney(total)
      .. (unpriced > 0 and CR.ColorText(string.format(" (+%d unpriced)", unpriced), "ff9966") or "")
    profitText = CR.ColorText("Profit ", "aaaaaa") .. ((noPrice < #entries) and ProfitText(profit) or CR.ColorText("no price", "888888"))
      .. ((noPrice > 0 and noPrice < #entries) and CR.ColorText(string.format(" (%d no price)", noPrice), "ff9966") or "")
  end
  fc.gold:SetText(goldText)
  fc.profit:SetText(profitText)
  fc:SetShown(#favs > 0)
  if matPanel and matPanel:IsShown() then matPanel:Refresh() end
end

-- Right column: your destinations at the top (up to 5 rows, then it scrolls), the recipe panel under.
local function LayoutDestRight()
  local f = overlay
  f.schematic:Hide()   -- an opened recipe's details are rows in the list itself
  f.favAll:ClearAllPoints()
  f.favAll:SetPoint("TOPLEFT", f.divider, "TOPRIGHT", 10, -36)
  f.favHeader:ClearAllPoints()
  f.favHeader:SetPoint("LEFT", f.favAll, "RIGHT", 4, 0)   -- under Open CraftRoute
  f.favList:ClearAllPoints()
  f.favList:SetPoint("TOPLEFT", f.divider, "TOPRIGHT", 8, -58)
  f.favList:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8 + COST_BAR_H + 4)   -- (the shopping line under it)
  -- the shopping line: the same height and gaps from the border / divider as the route cost bar
  f.favCart:ClearAllPoints()
  f.favCart:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 8)
  f.favCart:SetPoint("LEFT", f.divider, "RIGHT", 4, 0)
  f.favCart:SetPoint("RIGHT", f, "RIGHT", -6, 0)
  f.favEmpty:ClearAllPoints()
  f.favEmpty:SetPoint("TOPLEFT", f.favList, "TOPLEFT", 8, -8)
  f.favEmpty:SetPoint("RIGHT", f, "RIGHT", -16, 0)
end

-- Your list with the opened recipe's details under it: learned and cost, where to get it (pins),
-- its reagents (Buy / Vendor, make the parts), and a crafting row.
local function ExpandOpen(name, favs)
  local out, at = {}, nil
  for _, f in ipairs(favs) do
    table.insert(out, f)
    if f.selected then
      at = #out
      local r, pn = f.recipe, f.prof
      local learned = CR.RecipeLearned(pn, r) == true
      -- the amount: the one set beside it in your list (or in the Create box), else 1
      local qty = math.max(1, ui.destQty[r.spell] or CartEntry(name, r.spell).qty or 1)
      local cost, unpriced = MakeCost(r)
      local source, places = "", {}
      if not learned and CR.RecipeSource then
        local text, pl, tcost = CR.RecipeSource(pn, r)
        source = (text or "") .. (tcost and ("  " .. CR.FormatMoney(tcost)) or "")
        places = pl or {}
      end
      table.insert(out, { kind = "dInfo", recipe = r, learned = learned, prof = pn, list = name })
      -- the source, split at its commas into rows of up to two lines each
      local cur = ""
      for part in ((source or "") .. ", "):gmatch("(.-), ") do
        local joined = cur == "" and part or (cur .. ", " .. part)
        if #joined > 110 and cur ~= "" then
          table.insert(out, { kind = "dText", text = cur .. "," })
          cur = part
        else
          cur = joined
        end
      end
      if cur ~= "" then table.insert(out, { kind = "dText", text = cur }) end
      for i = 1, math.min(2, #places) do table.insert(out, { kind = "dPin", place = places[i] }) end
      AddReagents(out, r.reagents or {}, qty, 1, CR.professions[pn] or CraftProf(name), "dest:" .. r.spell, {})
      -- reagents with no price yet (not seen on the AH) are left out of the total - say how many
      if CR.EnchantSlotFor(r) then
        -- the enchant target slot (Route's own): pick gear, click it to enchant, replace prompts answered
        table.insert(out, { kind = "dEnchant" })
        table.insert(out, { kind = "dSpacer" })
      end
      table.insert(out, { kind = "dCost", qty = qty,
        cost = CR.HasAuctionator() and (CR.FormatMoney(cost * qty)
          .. (unpriced > 0 and CR.ColorText(string.format("   (+%d unpriced)", unpriced), "ff9966") or "")) or "?" })
      if CR.HasAuctionator() and r.item and r.item > 0 then
        local p, how, pu = Profit(r)
        table.insert(out, { kind = "dProfit", qty = qty, profit = p and p * qty, how = how, unpriced = pu or 0 })
      end
      table.insert(out, { kind = "dCraft", recipe = r, prof = pn, learned = learned, qty = qty, list = name })
      -- they're drawn as one panel joined to the recipe's row, closed off under the crafting row
      for i = at + 1, #out do out[i].box = (i == #out) and "last" or "mid" end
    end
  end
  return out, at
end

-- Under the recipe's name: learned or not, and if not, where it comes from with map pins.
local function FillDestDetail(info)
  local f = overlay
  for _, row in ipairs(f.destPins) do row:Hide() end
  f.destBottom = f.destInfo
  local st = info and info.selected
  if not st then
    f.destInfo:SetText("")
    f.detailEmpty:SetText("Click a recipe on the left to see it here. Its star keeps it in your destinations, above.")
    f.detailEmpty:Show()
    return
  end
  local r = st.recipe
  local learned = CR.RecipeLearned(info.profName, r) == true
  if learned then
    f.destInfo:SetText(CR.ColorText("Learned", "40ff40"))
    return
  end
  local cur = CR.GetSkill(info.profName)
  local text, places, cost = "", {}, nil
  if CR.RecipeSource then text, places, cost = CR.RecipeSource(info.profName, r) end
  f.destInfo:SetText(CR.ColorText("Not Learned", "ff6060")
    .. CR.ColorText(string.format("  -  learn at %d%s", r.learn or 1, (cur or 0) >= (r.learn or 1) and "" or
      string.format(" (you: %d)", cur or 0)), "aaaaaa")
    .. "\n" .. (text or "") .. (cost and ("  " .. CR.FormatMoney(cost)) or ""))
  local anchor = f.destInfo
  for i, pl in ipairs(places or {}) do
    local row = f.destPins[i]
    if not row then break end
    row.place = pl
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    row.text:SetText(pl.name .. CR.ColorText("  " .. (pl.zone or ""), "aaaaaa"))
    row:Show()
    anchor = row
  end
  f.destBottom = anchor
end

local function DestRefresh(name)
  local f = overlay
  SetDestWidgets(true)
  local left, favs, info = BuildDestItems(name)
  f.info = info
  f.empty:SetText("No recipes match.")
  f.empty:SetShown(#left == 0)
  list:SetShown(#left > 0)
  -- the opened recipe is the current one for the enchant target slot (and its click covers) -
  -- settled before the lists draw, so the slot goes into this recipe's row (#7)
  local open
  for _, it in ipairs(favs) do if it.selected then open = it end end
  for _, it in ipairs(left) do if it.selected then open = it end end
  if open then
    f.current = { kind = "dest", recipe = open.recipe, spell = open.recipe.spell, crafts = 1 }
    f.craftProf = open.prof
    local learned = CR.RecipeLearned(open.prof, open.recipe) ~= false
    local canCast = learned and CR.TradeSkillOpenFor(open.prof) and CR.CraftsReady(open.prof, open.recipe) > 0
    if f.UpdateEnchant then f:UpdateEnchant(open.recipe, canCast) end
  elseif f.UpdateEnchant then
    f:UpdateEnchant(nil)
  end
  local leftRows, leftAt = ExpandOpen(name, left)
  -- the clicked recipe's row stays on the same line of the list (rows above it may have closed)
  local function KeepAnchor(holder, rows, side)
    local a = ui.destAnchor
    if not a or a.side ~= side then return end
    for i, it in ipairs(rows) do
      if (it.kind == "dest" or it.kind == "destFav") and it.recipe and it.recipe.spell == a.spell then
        holder:ScrollTo(i - a.slot + 1)
        return
      end
    end
  end
  list:SetData(leftRows, ui.keepScroll)
  KeepAnchor(list, leftRows, "left")
  local rows, openAt = ExpandOpen(name, favs)
  f.favList:SetData(rows, ui.keepScroll)
  KeepAnchor(f.favList, rows, "right")
  ui.destAnchor = nil
  -- the target slot only ever shows inside its recipe's (visible) target row - never left over
  -- where an earlier row was
  local e = f.enchant
  if e and e:IsShown() then
    local host = e:GetParent()
    local hostItem = host and rawget(host, "item")
    if not (hostItem and hostItem.kind == "dEnchant" and host:IsShown()) then e:Hide() end
  end
  f.favEmpty:SetShown(#favs == 0)
  f.favHeader:SetText(string.format("Your crafts (%d)", #favs))
  f.favCart.list, f.favCart.favs = name, favs
  UpdateFavCart()
  ui.keepScroll = true
  f.goalDD:Hide()
  f.modeDD:Hide()
  f.customBox:Hide()
  LayoutHeader()
  LayoutDestRight()
  UpdateRankBar()
  if f.profDD then f.profDD:Sync() end
  if f.altsCB then f.altsCB:Sync() end
  f.destFilterDD:Sync()
  if not f.destSearch:HasFocus() then f.destSearch:SetText(ui.destSearch or "") end
  f.destSearch.hint:SetShown((ui.destSearch or "") == "" and not f.destSearch:HasFocus())
  -- the cost bar: making each destination once (the route's cart isn't for this)
  f.costBar.cart:Hide()
  if f.costBar.popout then f.costBar.popout:Hide() end
  f.costBar.money:ClearAllPoints()
  f.costBar.money:SetPoint("RIGHT", -8, 0)
  if not CR.HasAuctionator() then
    f.costBar.money:SetText("")
    f.costBar.note:SetText(CR.ColorText("Install Auctionator for prices", "ff9966"))
  else
    local total, unpriced = 0, 0
    for _, it in ipairs(favs) do
      local c, u = MakeCost(it.recipe)
      total = total + c
      if u > 0 then unpriced = unpriced + 1 end
    end
    f.costBar.money:SetText(CR.FormatMoney(total))
    f.costBar.note:SetText(unpriced > 0 and CR.ColorText(string.format("(+%d unpriced)", unpriced), "ff9966") or "")
  end
  -- the left bar stays (empty) so both columns line up; the totals are under your crafts
  f.costBar.label:SetText("")
  f.costBar.money:SetText("")
  f.costBar.note:SetText("")
  f.costBar:Show()
  if CR.RefreshBuyPop then CR.RefreshBuyPop() end
end

function CR.RefreshCompact()
  if not overlay or not overlay:IsShown() then return end
  local ok, err = pcall(function()
    SyncOpenProfession()
    local pname = PlanProfession()
    if ViewFor(pname) == "dest" then DestRefresh(pname) return end
    SetDestWidgets(false)
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
    if overlay.altsCB then overlay.altsCB:Sync() end
    if overlay.customBox:IsShown() and not overlay.customBox:HasFocus() then
      overlay.customBox:SetText(tostring(DB().customGoal or ""))
    end
    FillSchematic(info)
    overlay:UpdateRouteCost(info and info.entry and info.entry.plan)
    if CR.RefreshBuyPop then CR.RefreshBuyPop() end
  end)
  if not ok then CR.Print("Compact: " .. tostring(err)) end
  -- rows are rebuilt while the view stays open; reapply after that rebuild
  if overlay and CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, overlay) end
end

---------------------------------------------------------------------------
-- Professions frame host
---------------------------------------------------------------------------

local function SetEntryChecked(on)
  if not entry then return end
  if entry.SetChecked then pcall(entry.SetChecked, entry, on and true or false) end
  if entry.glow then entry.glow:SetShown(on) end
end

-- Is one of Blizzard's own pages (recipes, specializations...) showing?
local function BlizzardPageShown()
  local frame = ProfessionsFrame
  if not frame then return false end
  if frame.Pages then
    for _, page in ipairs(frame.Pages) do
      if page.IsShown and page:IsShown() then return true end
    end
    return false
  end
  return (frame.CraftingPage and frame.CraftingPage:IsShown()) or (frame.BookPage and frame.BookPage:IsShown()) or false
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
  -- Only Blizzard's own tabs. TrainerSpells stacks its tabs under any other addon's side tab
  -- (this one included), so going under theirs as well could make each depend on the other -
  -- the game refuses that ("Cannot anchor to a region dependent on it"). Blizzard's, then
  -- CraftRoute's, then TrainerSpells'.
  return best
end


local HookNativeTabs   -- (defined below)
local function PositionEntry()
  if HookNativeTabs then pcall(HookNativeTabs) end
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
  if anchor and pcall(entry.SetPoint, entry, "TOPLEFT", anchor, "BOTTOMLEFT", 0, -16) then
    -- placed under Blizzard's lowest tab
  elseif ProfessionsFrame.ProfessionsOverviewTab then
    entry:SetPoint("TOPLEFT", ProfessionsFrame.ProfessionsOverviewTab, "BOTTOMLEFT", 0, -16)
  else
    entry:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", 2, -70)
  end
end

local lastNativeClick = 0   -- when one of Blizzard's tabs was last clicked
-- a click on one of Blizzard's tabs is definite: it also ends any "keep this view up while the
-- window loads" spell (the keybind / a profession switch), which would otherwise undo it
local function MarkNativeClick() lastNativeClick = GetTime() ui.keepUntil = nil end
-- the Professions (overview) tab was the one clicked: Blizzard shows its own page - nothing of
-- ours (and not the recipes page) goes back over it
local overviewClickAt = 0
local function OverviewClicked() return GetTime() - overviewClickAt < 0.6 end
local function UserChoseNative() return GetTime() - lastNativeClick < 0.6 end

-- /cr trace: report in chat whatever shows one of Blizzard's pages or hides this view, with where
-- it came from - for tracking down a switch away from CraftRoute's tab you didn't ask for.
local function Trace(what)
  if not CR.compactTrace then return end
  local stack = debugstack and debugstack(3, 4, 0) or ""
  stack = stack:gsub("Interface/AddOns/", ""):gsub("\n", " | ")
  CR.Print(string.format("|cffffd100trace|r %.2f %s  <- %s", GetTime(), what, stack:sub(1, 300)))
end
function CR.ToggleCompactTrace()
  CR.compactTrace = not CR.compactTrace
  CR.Print("Profession view trace " .. (CR.compactTrace and "on - craft, then copy the trace lines" or "off") .. ".")
end

-- This view only goes away on purpose: your click (one of Blizzard's tabs, TrainerSpells' tabs,
-- CraftRoute's own tab) or the window closing. Anything else that hides it - the window
-- refreshing after a craft, another addon - puts it straight back.
local deliberate = false
local function HideOverlay(why)
  if not overlay then return end
  Trace("view closed: " .. why)
  deliberate = true
  overlay:Hide()
  deliberate = false
end

local function WatchTrainerSpells()
  local ts = _G.TrainerSpellsProfessionFrame
  if not ts or ts.crCompactHook then return end
  ts.crCompactHook = true
  ts:HookScript("OnShow", function(self)
    if not (overlay and overlay:IsShown()) then return end
    if UserChoseNative() then
      HideOverlay("TrainerSpells tab clicked")
      SetEntryChecked(false)
    elseif not InCombatLockdown() then
      Trace("TrainerSpells' frame shown without a click - hidden again")
      self:Hide()
    end
  end)
end

local function CloseCompact(restore)
  if not overlay then return end
  HideOverlay(restore and "your click" or "Blizzard tab clicked")
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

-- Blizzard's own page background on this tab: the large background / border textures of its
-- crafting page (a few levels down: the page, its recipe list and recipe panels - not rows,
-- buttons or icons), copied - same art, crop, colour and alpha, so an EllesmereUI skin carries
-- over - to the same place on this tab. Done as the tab opens, before Blizzard's page is hidden,
-- and again for each profession (its art changes). /cr bg lists what was copied.
local mirrored, mirrorLog = {}, {}
local function MirrorBlizzardBackground()
  for _, t in ipairs(mirrored) do t:Hide() end
  wipe(mirrorLog)
  local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
  local ol, ot = overlay and overlay:GetLeft(), overlay and overlay:GetTop()
  if not (page and ol and ot) then return 0 end
  local os = overlay:GetEffectiveScale()
  local n = 0
  local function Visit(f, depth)
    if depth > 3 then return end
    for _, r in ipairs({ f:GetRegions() }) do
      if r.GetObjectType and r:GetObjectType() == "Texture" and r:IsShown() then
        local layer = r:GetDrawLayer()
        local l, t, w, h = r:GetLeft(), r:GetTop(), r:GetWidth(), r:GetHeight()
        local atlas = r.GetAtlas and r:GetAtlas()
        local file = not atlas and r:GetTexture()
        if (layer == "BACKGROUND" or layer == "BORDER") and l and t and w and h and w * h >= 4000 and (atlas or file) then
          n = n + 1
          local c = mirrored[n]
          if not c then
            c = overlay:CreateTexture(nil, "BACKGROUND")
            mirrored[n] = c
          end
          -- stacked as Blizzard stacks them: deeper frames and BORDER over BACKGROUND (all under
          -- this tab's own art)
          c:SetDrawLayer("BACKGROUND", math.min(-1, -8 + depth * 2 + (layer == "BORDER" and 1 or 0)))
          if atlas then c:SetAtlas(atlas) else c:SetTexture(file) end
          pcall(function()
            c:SetTexCoord(r:GetTexCoord())
            c:SetVertexColor(r:GetVertexColor())
            c:SetBlendMode(r:GetBlendMode())
            c:SetDesaturated(r:IsDesaturated())
            if r.GetHorizTile then c:SetHorizTile(r:GetHorizTile()) c:SetVertTile(r:GetVertTile()) end
          end)
          c:SetAlpha(r:GetAlpha())
          local rs = r:GetEffectiveScale()
          c:ClearAllPoints()
          c:SetPoint("TOPLEFT", overlay, "TOPLEFT", (l * rs - ol * os) / os, (t * rs - ot * os) / os)
          c:SetSize(w * rs / os, h * rs / os)
          c:Show()
          table.insert(mirrorLog, string.format("%s %s  %dx%d  alpha %.2f  (%s)", layer, tostring(atlas or file),
            w, h, r:GetAlpha(), tostring(r.GetDebugName and r:GetDebugName() or depth)))
        end
      end
    end
    for _, ch in ipairs({ f:GetChildren() }) do
      if ch:IsShown() and not (ch.IsObjectType and (ch:IsObjectType("Button") or ch:IsObjectType("EditBox"))) then
        Visit(ch, depth + 1)
      end
    end
  end
  pcall(Visit, page, 0)
  -- with Blizzard's own header art copied, this tab's stand-in band steps aside
  if overlay.headerBand then
    overlay.headerBand:SetShown(n == 0)
    overlay.headerLine:SetShown(n == 0)
  end
  return n
end
function CR.DebugBackground()
  CR.Print(string.format("Background: %d of Blizzard's textures copied onto this tab.", #mirrorLog))
  for _, line in ipairs(mirrorLog) do CR.Print("  " .. line) end
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
  pcall(MirrorBlizzardBackground)   -- (before its page is hidden: its art's still laid out)
  pcall(HidePages)
  ui.openProf = nil
  ui.keepScroll = false
  overlay:Show()
  SetEntryChecked(true)
  PositionEntry()
  overlay:Refresh()
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, overlay) end   -- EllesmereUI global font, if loaded
end

local function ToggleCompact()
  if overlay and overlay:IsShown() then CloseCompact(true) else OpenCompact() end
end

-- The keybind (Keybind.lua). It opens the profession window when it has to - then this view
-- should come up once it has. With the window already open: shows this view, or closes the
-- window when this view is what's showing.
function CR.KeybindWillOpen() ui.keepUntil = GetTime() + 2 end
function CR.KeybindToggleView()
  if not (ProfessionsFrame and ProfessionsFrame:IsShown()) then return false end
  if overlay and overlay:IsShown() then
    if C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then C_TradeSkillUI.CloseTradeSkill() else HideUIPanel(ProfessionsFrame) end
  else
    OpenCompact()
  end
  return true
end

-- A profession switch started from this view (dropdown, Open): Blizzard's window flips back to its
-- own recipes page as the new profession loads. This view isn't closed meanwhile, and the page
-- Blizzard shows is hidden again straight away, in the same frame - before anything is drawn, so
-- it never flashes up. ReopenSoon (a few retries over the next half second) is only the backup.
local function Keeping() return ui.keepUntil and GetTime() < ui.keepUntil end
local function KeepNow()
  if not Keeping() or InCombatLockdown() or not (ProfessionsFrame and ProfessionsFrame:IsShown()) then return end
  pcall(HidePages)
  if overlay and not overlay:IsShown() then OpenCompact() end
end
local function ReopenSoon()
  if not Keeping() then return end
  for _, delay in ipairs({ 0, 0.1, 0.3, 0.6 }) do
    C_Timer.After(delay, function()
      if not Keeping() or InCombatLockdown() or not (ProfessionsFrame and ProfessionsFrame:IsShown()) then return end
      if overlay and overlay:IsShown() then pcall(HidePages) else OpenCompact() end
    end)
  end
end

-- Only a click on one of Blizzard's tabs means "show Blizzard's page". The window also brings
-- its recipes page back by itself (a craft finishing refreshes it) - then this view stays and
-- that page is hidden again.
local function HookTab(tab)
  if not tab or tab == entry or tab.crClickHooked or not tab.HookScript then return end
  tab.crClickHooked = true
  pcall(tab.HookScript, tab, "OnClick", MarkNativeClick)
  pcall(tab.HookScript, tab, "OnMouseDown", MarkNativeClick)
end
function HookNativeTabs()
  local frame = ProfessionsFrame
  if frame then
    HookTab(frame.ProfessionsOverviewTab)
    -- Blizzard's Professions (overview) tab: clicking it from this view always goes to Blizzard's
    -- page - this view closes (without bringing the recipes page back over it)
    local ov = frame.ProfessionsOverviewTab
    if ov and ov.HookScript and not ov.crOverviewHooked then
      ov.crOverviewHooked = true
      pcall(ov.HookScript, ov, "OnMouseDown", function() overviewClickAt = GetTime() MarkNativeClick() end)
      -- the Professions page is the window's BookPage (as TrainerSpells switches to it): show it
      -- outright, so one click always lands there - even when Blizzard thinks it's already the
      -- selected tab (it was only covered by this view) and so does nothing itself
      local function ShowOverview()
        if InCombatLockdown() then return end
        ui.keepUntil = nil
        if overlay and overlay:IsShown() then CloseCompact(false) end
        if frame.CraftingPage then frame.CraftingPage:Hide() end
        if frame.BookPage then frame.BookPage:Show() end
        if ov.SetChecked then pcall(ov.SetChecked, ov, true) end
        if CR.RefreshBook then CR.SafeCall(CR.RefreshBook) end
      end
      pcall(ov.HookScript, ov, "OnMouseUp", function(self, button)
        if button and button ~= "LeftButton" then return end
        if self.IsMouseOver and not self:IsMouseOver() then return end   -- released elsewhere: no click
        overviewClickAt = GetTime()
        MarkNativeClick()
        ShowOverview()
        C_Timer.After(0, ShowOverview)   -- and once more after anything else this click set off
      end)
    end
    for _, tab in ipairs(frame.rightProfessionTabs or {}) do HookTab(tab) end
    local sys = frame.TabSystem
    if sys then
      for _, tab in ipairs(sys.tabs or {}) do HookTab(tab) end
      for _, tab in ipairs({ sys:GetChildren() }) do HookTab(tab) end
    end
  end
  HookTab(_G.TrainerSpellsProfessionsTab)
  for i = 1, 8 do HookTab(_G["TrainerSpellsProfessionsViewTab" .. i]) end
end

local function OnNativeTab()
  if Keeping() then KeepNow() ReopenSoon() return end
  if GetTime() - openedAt < 0.05 then return end
  if overlay and overlay:IsShown() then
    if UserChoseNative() then CloseCompact(not OverviewClicked()) else pcall(HidePages) end
  end
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

  -- opens / closes the main CraftRoute window (Plan, Recipes and the full Craft tab)
  frame.mainBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.mainBtn:SetSize(130, 22)
  frame.mainBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, RANK_DROP_Y + 1)
  frame.mainBtn:SetText("Open CraftRoute")
  CR.ThemeRegisterButton(frame.mainBtn)
  -- only this character's materials, or alts' too (the same setting as the main window's)
  frame.altsCB = CR.CreateAltsCheck(frame, "Count alts")
  -- (placed above the Shopping List button once that exists, below)
  -- CraftRoute's version, small, just left of the button
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = getMeta and getMeta("CraftRoute", "Version")
  if version then
    frame.version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.version:SetPoint("RIGHT", frame.mainBtn, "LEFT", -6, 0)
    frame.version:SetText("v" .. version)
  end
  frame.mainBtn:SetScript("OnClick", function(self)
    CR.SafeCall(CR.ToggleWindow)
    self:SetText(CR.IsWindowShown() and "Close CraftRoute" or "Open CraftRoute")
  end)
  frame.mainBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("CraftRoute window")
    GameTooltip:AddLine("Opens the full CraftRoute window: the Plan, the Recipes picker and the Craft tab. "
      .. "Same settings as here. (Also /cr.)", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.mainBtn:SetScript("OnLeave", GameTooltip_Hide)

  frame.rankBar = CreateFrame("Frame", nil, frame)
  frame.rankBar:SetPoint("CENTER", frame, "TOP", 0, RANK_BAR_Y)
  frame.rankBar:SetWidth(540)
  -- the header band behind it, like the top of Blizzard's page
  frame.headerBand = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  frame.headerBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
  frame.headerBand:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
  frame.headerBand:SetHeight(HEADER_H)
  frame.headerBand:SetColorTexture(0, 0, 0, 0.35)
  frame.headerLine = frame:CreateTexture(nil, "BORDER")
  frame.headerLine:SetPoint("TOPLEFT", frame.headerBand, "BOTTOMLEFT", 0, 0)
  frame.headerLine:SetPoint("TOPRIGHT", frame.headerBand, "BOTTOMRIGHT", 0, 0)
  frame.headerLine:SetHeight(1)
  frame.headerLine:SetColorTexture(1, 0.82, 0.35, 0.15)
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
  frame.rankBar.fill:SetPoint("TOPLEFT", frame.rankBar, "TOPLEFT", 9, -8)   -- placed by UpdateRankBar
  frame.rankBar.fill:SetHeight(13)
  frame.rankBar.fill:SetWidth(1)
  frame.rankBar.fill:Hide()
  local rankText = CreateFrame("Frame", nil, frame.rankBar)
  rankText:SetAllPoints()
  rankText:SetFrameLevel(frame.rankBar:GetFrameLevel() + 4)
  frame.rankBar.text = rankText:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  -- centred on the dark track (which sits high in the frame art), not on the whole frame
  frame.rankBar.text:SetPoint("CENTER", rankText, "TOP", 0, -(FILL_INSET_TOP + (29 - FILL_INSET_TOP - FILL_INSET_BOTTOM) / 2))
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
  list:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 8 + COST_BAR_H + 4)
  list:SetPoint("RIGHT", frame.divider, "LEFT", -4, 0)
  -- What the rest of the route costs: everything still to buy (Auctionator prices), under the list.
  local costBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  costBar:SetHeight(COST_BAR_H)
  costBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 8)
  costBar:SetPoint("RIGHT", frame.divider, "LEFT", -4, 0)
  CR.Backdrop(costBar, 0, 0, 0, 0.55)
  costBar.label = costBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  costBar.label:SetPoint("LEFT", 8, 0)
  costBar.label:SetText("Route cost")
  CR.ThemeRegisterAccentText(costBar.label)
  -- the route's Auctionator shopping list (what the main window's button makes), Route view only
  costBar.cart = CreateFrame("Button", nil, costBar, "UIPanelButtonTemplate")
  costBar.cart:SetSize(24, 18)
  costBar.cart:SetPoint("RIGHT", -4, 0)
  costBar.cart:SetText("")
  CR.ThemeRegisterButton(costBar.cart)
  CR.AddCartIcon(costBar.cart, false)
  costBar.cart:SetScript("OnClick", function()
    if costBar.plan then CR.CreateShoppingList(costBar.plan) end
  end)
  costBar.cart:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Route shopping list")
    GameTooltip:AddLine("Makes an Auctionator shopping list of everything the route still needs to buy.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  costBar.cart:SetScript("OnLeave", GameTooltip_Hide)
  costBar.cart:Hide()
  -- pop the materials tracker out (a small window of its own you can pin anywhere)
  costBar.popout = CreateFrame("Button", nil, costBar, "UIPanelButtonTemplate")
  costBar.popout:SetSize(24, 18)
  costBar.popout:SetPoint("RIGHT", -4, 0)
  costBar.popout:SetText("")
  CR.ThemeRegisterButton(costBar.popout)
  CR.AddPopoutIcon(costBar.popout)
  costBar.popout:SetScript("OnClick", function()
    if CR.ToggleTracker then CR.ToggleTracker(nil, PlanProfession()) end
  end)
  costBar.popout:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Pop out the materials")
    GameTooltip:AddLine("A small window of the route's materials you can pin anywhere on screen - it stays "
      .. "up with this window closed.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  costBar.popout:SetScript("OnLeave", GameTooltip_Hide)
  costBar.popout:Hide()
  costBar.money = costBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  costBar.money:SetPoint("RIGHT", -8, 0)
  costBar.money:SetJustifyH("RIGHT")
  costBar.note = costBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  costBar.note:SetPoint("LEFT", costBar.label, "RIGHT", 6, 0)
  costBar.note:SetPoint("RIGHT", costBar.money, "LEFT", -6, 0)
  costBar.note:SetJustifyH("LEFT")
  costBar.note:SetWordWrap(false)
  frame.costBar = costBar

  -- Route / Destinations
  local function ViewButton(text, view, tip)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetHeight(22)
    b:SetText(text)
    CR.ThemeRegisterButton(b)
    b:SetScript("OnClick", function()
      local n = PlanProfession()
      if not n then return end
      if CraftRouteCharDB then CraftRouteCharDB.compactView = view end
      ui.keepScroll = false
      frame:Refresh()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(text)
      GameTooltip:AddLine(tip, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
  end
  frame.viewRoute = ViewButton("Route", "route", "The leveling route: the step you're on and what's next.")
  frame.viewDest = ViewButton("Craft", "dest", "Your recipes, after the route: pick the ones you want handy or "
    .. "aim to make - what they cost, whether you know them, where to get them, and crafting. Opens here once a "
    .. "profession is at " .. TRUE_MAX .. ".")

  frame.destSearch = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  frame.destSearch:SetHeight(20)
  frame.destSearch:SetAutoFocus(false)
  frame.destSearch.hint = frame.destSearch:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.destSearch.hint:SetPoint("LEFT", 2, 0)
  frame.destSearch.hint:SetText("Search recipes")
  frame.destSearch:SetScript("OnTextChanged", function(self, user)
    if not user then return end
    ui.destSearch = self:GetText()
    ui.keepScroll = false
    frame:Refresh()
  end)
  frame.destSearch:SetScript("OnEditFocusGained", function(self) self.hint:Hide() end)
  frame.destSearch:SetScript("OnEditFocusLost", function(self) self.hint:SetShown(self:GetText() == "") end)
  frame.destSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  frame.destSearch:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  -- Filter: tickboxes (none ticked = every recipe; each ticked one narrows the list)
  frame.destFilterDD = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.destFilterDD:SetSize(112, 22)
  frame.destFilterDD:SetText("Filter")
  CR.ThemeRegisterButton(frame.destFilterDD)
  local pop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  pop:SetFrameStrata("DIALOG")
  pop:SetSize(160, 7 * 22 + 18)
  pop:SetPoint("TOPRIGHT", frame.destFilterDD, "BOTTOMRIGHT", 0, -2)
  CR.Backdrop(pop, 0.05, 0.05, 0.07, 0.97)
  pop:EnableMouse(true)
  pop:Hide()
  frame.destFilterPop = pop
  local FILTERS = { { "mats", "Has materials" }, { "skillup", "Has skill-ups" },
                    { "learned", "Learned" }, { "unlearned", "Not Learned" } }
  pop.boxes = {}
  for i, spec in ipairs(FILTERS) do
    local cb = CreateFrame("CheckButton", nil, pop, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 22)
    cb:SetHitRectInsets(0, -122, 0, 0)   -- the whole line toggles it, not just the box
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label:SetText(spec[2])
    cb:SetScript("OnClick", function(self)
      DestFilters(PlanProfession())[spec[1]] = self:GetChecked() and true or nil
      ui.keepScroll = false
      frame:Refresh()
    end)
    cb.key = spec[1]
    cb:SetScript("OnEnter", function() if pop.sub then pop.sub:Hide() end end)
    pop.boxes[i] = cb
  end

  -- Quality > / Slot > : a side list of tickboxes (several ticked = any of them)
  local function QualityName(q)
    local n = _G["ITEM_QUALITY" .. q .. "_DESC"] or ({ [0] = "Poor", "Common", "Uncommon", "Rare", "Epic",
      "Legendary", "Artifact", "Heirloom" })[q] or ("Quality " .. q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    return (c and c.r) and CR.ColorText(n, string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)) or n
  end
  local SORTS = { { "level", "Level (default)" }, { "profitDesc", "Profit: high to low" },
                  { "profitAsc", "Profit: low to high" } }
  local SUBS = {
    { key = "sort", label = "Sort", radio = true, options = function() return SORTS end },
    { key = "quality", label = "Quality", options = function()
        local out, have = {}, ui.destPresent and ui.destPresent.quality or {}
        for q = 0, 7 do if have[q] then table.insert(out, { q, QualityName(q) }) end end
        return out
      end },
    { key = "slot", label = "Slot", options = function()
        local out, have = {}, ui.destPresent and ui.destPresent.slot or {}
        for _, g in ipairs(SLOT_GROUPS) do if have[g[1]] then table.insert(out, { g[1], g[2] }) end end
        return out
      end },
  }
  local sub = CreateFrame("Frame", nil, pop, "BackdropTemplate")
  sub:SetFrameStrata("DIALOG")
  sub:SetFrameLevel(pop:GetFrameLevel() + 10)
  CR.Backdrop(sub, 0.05, 0.05, 0.07, 0.97)
  sub:EnableMouse(true)
  sub:Hide()
  sub.boxes = {}
  pop.sub = sub
  local function OpenSub(spec, anchor)
    local opts = spec.options()
    sub.spec, sub.anchor = spec, anchor
    sub:ClearAllPoints()
    sub:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 6)
    sub:SetSize(150, math.max(1, #opts) * 22 + 12)
    local chosen = spec.radio and { [DestSort(PlanProfession())] = true } or DestFilters(PlanProfession())[spec.key] or {}
    for i, o in ipairs(opts) do
      local cb = sub.boxes[i]
      if not cb then
        cb = CreateFrame("CheckButton", nil, sub, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 22)
        cb:SetHitRectInsets(0, -112, 0, 0)   -- the whole line toggles it, not just the box
        cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb:SetScript("OnClick", function(self)
          if sub.spec.radio then
            -- pick one: this order (ticking the ticked one again goes back to the default)
            local cur = DestSort(PlanProfession())
            SetDestSort(PlanProfession(), (cur == self.value) and "level" or self.value)
            OpenSub(sub.spec, sub.anchor)
            ui.keepScroll = false
            frame:Refresh()
            return
          end
          local key = sub.spec.key
          local F = DestFilters(PlanProfession())
          local set = F[key] or {}
          set[self.value] = self:GetChecked() and true or nil
          F[key] = next(set) and set or nil
          ui.keepScroll = false
          frame:Refresh()
        end)
        sub.boxes[i] = cb
      end
      cb.value = o[1]
      cb.label:SetText(o[2])
      cb:SetChecked(chosen[o[1]] and true or false)
      cb:Show()
    end
    for i = #opts + 1, #sub.boxes do sub.boxes[i]:Hide() end
    sub:Show()
  end
  pop.subRows = {}
  for i, spec in ipairs(SUBS) do
    local b = CreateFrame("Button", nil, pop)
    b:SetSize(148, 22)
    b:SetPoint("TOPLEFT", 6, -12 - (#FILTERS + i - 1) * 22)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("LEFT", 4, 0)
    b.arrow = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.arrow:SetPoint("RIGHT", -4, 0)
    b.arrow:SetText(">")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    b:SetScript("OnEnter", function(self) OpenSub(spec, self) end)
    b:SetScript("OnClick", function(self)
      if sub:IsShown() and sub.spec == spec then sub:Hide() else OpenSub(spec, self) end
    end)
    b.spec = spec
    pop.subRows[i] = b
  end
  -- a thin line between the tickboxes and the sub-lists
  local line = pop:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(1, 1, 1, 0.12)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", 10, -9 - #FILTERS * 22)
  line:SetPoint("TOPRIGHT", -10, -9 - #FILTERS * 22)

  frame.destFilterDD:SetScript("OnClick", function()
    pop:SetShown(not pop:IsShown())
    if not pop:IsShown() then sub:Hide() end
  end)
  -- a click anywhere else (not on the list, its side list or the Filter button) closes it: the
  -- game's "mouse pressed anywhere" event while it's open
  local function ClickedOutside()
    -- (Frame:IsMouseOver - Forever has no global MouseIsOver)
    local over = pop:IsMouseOver() or (sub:IsShown() and sub:IsMouseOver()) or frame.destFilterDD:IsMouseOver()
    if not over then
      sub:Hide()
      pop:Hide()
    end
  end
  pop:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
  pop:SetScript("OnHide", function(self)
    pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN")
    sub:Hide()
  end)
  pop:SetScript("OnEvent", function(self, event)
    if event == "GLOBAL_MOUSE_DOWN" and self:IsShown() then ClickedOutside() end
  end)
  -- X: clear every filter for this profession, and put the sort back to Level
  frame.destFilterClear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.destFilterClear:SetSize(22, 22)
  frame.destFilterClear:SetText("X")
  CR.ThemeRegisterButton(frame.destFilterClear)
  frame.destFilterClear:SetScript("OnClick", function()
    local F = DestFilters(PlanProfession())
    for k in pairs(F) do F[k] = nil end
    SetDestSort(PlanProfession(), "level")
    sub:Hide()
    ui.keepScroll = false
    frame:Refresh()
  end)
  frame.destFilterClear:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Clear filters and sort")
    GameTooltip:Show()
  end)
  frame.destFilterClear:SetScript("OnLeave", GameTooltip_Hide)
  frame.destFilterClear:Hide()
  function frame.destFilterDD:Sync()
    local n, F = 0, DestFilters(PlanProfession())
    for _, cb in ipairs(pop.boxes) do
      cb:SetChecked(F[cb.key] and true or false)
      if F[cb.key] then n = n + 1 end
    end
    for _, b in ipairs(pop.subRows) do
      if b.spec.radio then
        -- the sort isn't a filter: its row just says which order is on
        local cur = DestSort(PlanProfession())
        local tag = cur == "profitDesc" and "profit, high first" or cur == "profitAsc" and "profit, low first" or nil
        b.label:SetText(tag and (b.spec.label .. CR.ColorText(" (" .. tag .. ")", "aaaaaa")) or b.spec.label)
      else
        local set, k = F[b.spec.key], 0
        if set then for _ in pairs(set) do k = k + 1 end end
        n = n + k
        b.label:SetText(k > 0 and string.format("%s (%d)", b.spec.label, k) or b.spec.label)
      end
    end
    self:SetText(n > 0 and string.format("Filter (%d)", n) or "Filter")
    frame.destFilterClear:SetEnabled(n > 0 or DestSort(PlanProfession()) ~= "level")
  end
  frame:HookScript("OnHide", function() pop:Hide() sub:Hide() end)

  -- right column: your destinations
  frame.favHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  CR.ThemeRegisterAccentText(frame.favHeader)
  frame.favList = CreateList(frame)
  frame.favEmpty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.favEmpty:SetJustifyH("LEFT")
  frame.favEmpty:SetWordWrap(true)
  frame.favEmpty:SetText("Click recipes on the left to add them here.")
  -- tick all / none of your list for the shopping list
  frame.favAll = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.favAll:SetSize(22, 22)
  frame.favAll:SetScript("OnClick", function(self)
    local name = PlanProfession()
    local on = self:GetChecked() and true or nil
    for _, spell in ipairs(DestList(name)) do CartEntry(name, spell).on = on end
    ui.keepScroll = true
    frame:Refresh()
  end)
  frame.favAll:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Select all / none")
    GameTooltip:AddLine("For the shopping list at the bottom.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.favAll:SetScript("OnLeave", GameTooltip_Hide)
  -- along the bottom: one Auctionator shopping list for every ticked recipe at its amount
  local fc = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  fc:SetHeight(COST_BAR_H)
  CR.Backdrop(fc, 0, 0, 0, 0.55)
  fc.button = CreateFrame("Button", nil, fc, "UIPanelButtonTemplate")
  fc.button:SetSize(24, 18)
  fc.button:SetPoint("RIGHT", -30, 0)   -- (the materials pop-out is to its right)
  fc.button:SetText("")
  CR.ThemeRegisterButton(fc.button)
  CR.AddCartIcon(fc.button, false)
  -- right to left: the cart, what selling what they make would earn, what buying it all costs
  fc.profit = fc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fc.profit:SetPoint("RIGHT", fc.button, "LEFT", -8, 0)
  fc.profit:SetJustifyH("RIGHT")
  fc.gold = fc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fc.gold:SetPoint("RIGHT", fc.profit, "LEFT", -14, 0)
  fc.gold:SetJustifyH("RIGHT")
  fc.text = fc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fc.text:SetPoint("LEFT", 8, 0)
  fc.text:SetPoint("RIGHT", fc.gold, "LEFT", -10, 0)
  fc.text:SetJustifyH("LEFT")
  fc.text:SetWordWrap(false)
  fc.text:SetJustifyH("RIGHT")
  fc.button:SetScript("OnClick", function()
    local name = fc.list
    local cart = DestCart(name)
    local entries = {}
    for _, it in ipairs(fc.favs or {}) do
      local e = cart[it.recipe.spell]
      if e and e.on then table.insert(entries, { recipe = it.recipe, crafts = e.qty or 1 }) end
    end
    if #entries == 0 then return end
    CR.CreateMultiShoppingList(entries, string.format("CraftRoute: %s crafts, %d recipe%s", tostring(name), #entries,
      #entries == 1 and "" or "s"), true, "crafts:" .. tostring(name))
  end)
  fc.button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Shopping list for the selected")
    GameTooltip:AddLine("Cost: what buying what they still need costs. Profit: what they'd make sold on the AH (less "
      .. "the 5% cut), minus what their materials cost, at the amounts set.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine("One Auctionator shopping list with everything the ticked recipes need, at the amounts "
      .. "you set - their own materials, less what you have (counted once across them all). Vendor items "
      .. "are left off.", 1, 1, 1, true)
    if not CR.HasAuctionator() then GameTooltip:AddLine("Needs Auctionator.", 1, 0.5, 0.3, true) end
    GameTooltip:Show()
  end)
  fc.button:SetScript("OnLeave", GameTooltip_Hide)
  -- beside the cart: pop out the materials panel
  fc.mats = CreateFrame("Button", nil, fc, "UIPanelButtonTemplate")
  fc.mats:SetSize(24, 18)
  fc.mats:SetPoint("RIGHT", fc, "RIGHT", -4, 0)
  fc.mats:SetText("")
  CR.ThemeRegisterButton(fc.mats)
  CR.AddPopoutIcon(fc.mats)
  fc.mats:SetScript("OnClick", function() ToggleMatPanel() end)
  fc.mats:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Materials for the selected")
    GameTooltip:AddLine("Opens a panel beside this window: every material the ticked recipes need at their amounts - "
      .. "all together, or recipe by recipe.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  fc.mats:SetScript("OnLeave", GameTooltip_Hide)
  frame.favCart = fc
  for _, w in ipairs({ frame.viewRoute, frame.viewDest }) do w:Show() end
  for _, w in ipairs({ frame.destSearch, frame.destFilterDD, frame.favHeader, frame.favList, frame.favEmpty, frame.favAll, frame.favCart }) do w:Hide() end
  function frame:UpdateRouteCost(plan)
    costBar.plan = plan
    if not plan then costBar:Hide() return end
    costBar:Show()
    -- the cart sits at the right end, the gold just before it
    -- right end: pop-out, then the cart (with Auctionator), then the gold
    local cart = CR.HasAuctionator() and true or false
    costBar.popout:Show()
    costBar.cart:ClearAllPoints()
    costBar.cart:SetPoint("RIGHT", costBar.popout, "LEFT", -2, 0)
    costBar.cart:SetShown(cart)
    costBar.money:ClearAllPoints()
    costBar.money:SetPoint("RIGHT", cart and costBar.cart or costBar.popout, "LEFT", -6, 0)
    if not CR.HasAuctionator() then
      costBar.money:SetText("")
      costBar.note:SetText(CR.ColorText("Install Auctionator for prices", "ff9966"))
      return
    end
    costBar.money:SetText(CR.FormatMoney(plan.missingCost or 0))
    costBar.note:SetText(plan.unpriced > 0 and CR.ColorText(string.format("(+%d unpriced)", plan.unpriced), "ff9966") or "")
  end

  frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.empty:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -24)
  frame.empty:SetWidth(240)
  frame.empty:SetJustifyH("LEFT")
  frame.empty:Hide()

  local schematic = CreateFrame("Frame", nil, frame)
  schematic:SetPoint("TOPLEFT", frame.divider, "TOPRIGHT", 12, 0)
  schematic:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
  frame.schematic = schematic

  -- The recipe icon is drawn here (round, masked) rather than from Blizzard's
  -- CircularGiantItemButtonTemplate: after a client update that template brought its own square
  -- slot and highlight pieces, which showed as stray boxes over the icon.
  local icon
  do
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
  end
  frame.icon = icon
  frame.icon:SetSize(54, 54)
  frame.icon:SetPoint("TOPLEFT", 28, -28)
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
    ring.crWanted = true   -- (Destinations' compact panel hides it)
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
  frame.rName:SetPoint("BOTTOMLEFT", frame.icon, "RIGHT", 16, 6)   -- level with the icon's upper half
  frame.rName:SetWidth(180)
  frame.rName:SetJustifyH("LEFT")
  frame.rName:SetWordWrap(false)
  frame.rName:SetTextColor(1, 1, 1)
  frame.rSub = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.rSub:SetPoint("TOPLEFT", frame.rName, "BOTTOMLEFT", 0, -2)
  frame.rSub:SetWidth(180)
  frame.rSub:SetJustifyH("LEFT")
  frame.rSub:SetWordWrap(false)

  -- skill-up colours, compact: the recipe's orange / yellow / green / grey ranges with a white
  -- marker at your skill (the Craft tab's band, small), right after the step and count
  local BAND_W = 90
  local band = CreateFrame("Frame", nil, schematic, "BackdropTemplate")
  band:SetSize(BAND_W, 8)
  CR.Backdrop(band, 0, 0, 0, 0.6)
  band.crOwnBorder = true
  band:SetBackdropBorderColor(0, 0, 0, 1)
  band.segs = {}
  for i, key in ipairs({ "orange", "yellow", "green", "grey" }) do
    local t = band:CreateTexture(nil, "ARTWORK")
    t.crBand = key
    t:SetHeight(6)
    band.segs[i] = t
  end
  band.marker = band:CreateTexture(nil, "OVERLAY")
  band.marker:SetSize(2, 12)
  band.marker:SetColorTexture(1, 1, 1, 1)
  function band:Fill(r, skill)
    local lo, hi = r.learn or 1, (r.x or 1) + 10   -- from learn to a little past grey
    if hi <= lo then hi = lo + 1 end
    local w = tonumber(self:GetWidth()) or BAND_W
    local inner = w - 2
    if inner < 1 then inner = 1 end
    local function X(v) return math.max(0, math.min(1, (v - lo) / (hi - lo))) * inner + 1 end
    local edges = { lo, r.y, r.g, r.x, hi }
    local path = CR.ResourceBarPath()
    for i, t in ipairs(self.segs) do
      local a, b = X(math.max(lo, edges[i])), X(math.max(lo, edges[i + 1]))
      t:ClearAllPoints()
      t:SetPoint("LEFT", self, "LEFT", a, 0)
      t:SetWidth(math.max(0.01, b - a))
      t:SetShown(b - a > 0.5)
      CR.PaintSkillSegment(t, CR.DIFF_COLORS[t.crBand], path, (a - 1) / inner, (b - 1) / inner)
    end
    self:SetBackdropBorderColor(0, 0, 0, 1)
    self.marker:ClearAllPoints()
    self.marker:SetPoint("CENTER", self, "LEFT", X(skill), 0)
    self.r, self.skill = r, skill
  end
  band:EnableMouse(true)
  band:SetScript("OnEnter", function(self)
    if not self.r then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Skill-up colours")
    -- condensed (GitHub #9): the four thresholds in their colours, and your skill on the right
    local dash = "|cff808080 - |r"
    GameTooltip:AddDoubleLine(string.format("|cffff8040%d|r%s|cffffff00%d|r%s|cff40bf40%d|r%s|cff9d9d9d%d|r",
      self.r.learn or 1, dash, self.r.y, dash, self.r.g, dash, self.r.x),
      "|cffffd100you:|r " .. CR.SkillLevelText(self.r, self.skill), 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  band:SetScript("OnLeave", GameTooltip_Hide)
  band:Hide()
  frame.rBand = band
  frame.rStructure = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.rStructure:SetPoint("TOPLEFT", frame.rSub, "BOTTOMLEFT", 0, -1)
  frame.rStructure:SetWidth(180)
  frame.rStructure:SetJustifyH("LEFT")
  frame.rStructure:SetWordWrap(false)

  -- Destinations: learned or not, where to get it, map pins (FillDestDetail)
  frame.destInfo = schematic:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.destInfo:SetPoint("TOPLEFT", frame.icon, "BOTTOMLEFT", 0, -4)
  frame.destInfo:SetPoint("RIGHT", schematic, "RIGHT", -8, 0)
  frame.destInfo:SetJustifyH("LEFT")
  frame.destInfo:SetWordWrap(true)
  frame.destInfo:Hide()
  frame.destPins = {}
  for i = 1, 3 do
    local row = CreateFrame("Frame", nil, schematic)
    row:SetSize(240, 20)
    row.pin = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.pin:SetSize(40, 18)
    row.pin:SetPoint("LEFT", 0, 0)
    row.pin:SetText("Pin")
    CR.ThemeRegisterButton(row.pin)
    row.pin:SetScript("OnClick", function() if row.place and CR.PinPlace then CR.PinPlace(row.place) end end)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.pin, "RIGHT", 6, 0)
    row.text:SetJustifyH("LEFT")
    row:Hide()
    frame.destPins[i] = row
  end

  frame.reagentsLabel = schematic:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.reagentsLabel:SetPoint("TOPLEFT", schematic, "TOPLEFT", 26, -173)   -- Blizzard's "Reagents:" line

  -- Every reagent always shows: the reagents and the cost lines under them sit in a scroll area
  -- from the label down to the Shopping List button (or the enchant target), with a slim bar on
  -- the right when they're taller than that. Its bottom is set in FillSchematic.
  local rscroll = CreateFrame("ScrollFrame", nil, schematic)
  rscroll:SetPoint("TOPLEFT", frame.reagentsLabel, "BOTTOMLEFT", 0, -2)
  local rcontent = CreateFrame("Frame", nil, rscroll)
  rcontent:SetSize(240, 40)
  rscroll:SetScrollChild(rcontent)
  local rtrack = CreateFrame("Frame", nil, rscroll, "BackdropTemplate")
  rtrack:SetWidth(5)
  rtrack:SetPoint("TOPRIGHT", rscroll, "TOPRIGHT", 0, 0)
  rtrack:SetPoint("BOTTOMRIGHT", rscroll, "BOTTOMRIGHT", 0, 0)
  CR.Backdrop(rtrack, 0.1, 0.1, 0.1, 0.8)
  rtrack.crOwnBorder = true
  local rthumb = rtrack:CreateTexture(nil, "OVERLAY")
  rthumb:SetColorTexture(0.6, 0.6, 0.6, 0.9)
  rthumb:SetWidth(5)
  local function RMax() return math.max(0, (rcontent:GetHeight() or 0) - (rscroll:GetHeight() or 0)) end
  function rscroll:UpdateBar()
    local max = RMax()
    if (self:GetVerticalScroll() or 0) > max then self:SetVerticalScroll(max) end
    rtrack:SetShown(max > 0)
    if max <= 0 then return end
    local vis, total = self:GetHeight() or 1, rcontent:GetHeight() or 1
    local h = math.max(16, vis * vis / total)
    rthumb:SetHeight(h)
    rthumb:ClearAllPoints()
    rthumb:SetPoint("TOP", rtrack, "TOP", 0, -(vis - h) * ((self:GetVerticalScroll() or 0) / max))
  end
  rscroll:EnableMouseWheel(true)
  rscroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, math.min(RMax(), (self:GetVerticalScroll() or 0) - delta * 46)))
    self:UpdateBar()
  end)
  rscroll:SetScript("OnSizeChanged", function(self, w)
    if w and w > 0 then rcontent:SetWidth(w) end
    self:UpdateBar()
  end)
  frame.rscroll, frame.rcontent = rscroll, rcontent
  frame.reagentsLabel:SetText("Reagents:")
  frame.reagents = {}
  for i = 1, REAGENT_SLOTS do
    local row = CreateFrame("Button", nil, rcontent)
    row:SetSize(280, 42)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(42, 42)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.buy = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.buy:SetSize(40, 20)
    row.buy:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.buy:SetText("Buy")
    row.buy:Hide()
    CR.ThemeRegisterButton(row.buy)
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

  frame.cost = rcontent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
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
  frame.status:SetPoint("BOTTOMRIGHT", schematic, "BOTTOMRIGHT", -150, 30)   -- clear of the shopping list button
  frame.status:SetJustifyH("LEFT")
  frame.status:SetWordWrap(false)

  -- Crafting progress for a batch started here (Create All / Create / a typed amount): fills over
  -- the whole batch, "Crafting Minor Mana Oil 3/50". In the status line's place while it runs and
  -- for a few seconds after (OnUpdate below).
  local batchBar = CreateFrame("StatusBar", nil, schematic, "BackdropTemplate")
  batchBar:SetPoint("BOTTOMLEFT", frame.buttons, "TOPLEFT", 0, 6)
  batchBar:SetPoint("BOTTOMRIGHT", schematic, "BOTTOMRIGHT", -150, 30)
  batchBar:SetHeight(18)
  batchBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  batchBar:SetMinMaxValues(0, 1)
  CR.Backdrop(batchBar, 0, 0, 0, 0.6)
  batchBar.text = batchBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  batchBar.text:SetPoint("CENTER")
  batchBar:Hide()
  frame.batchBar = batchBar
  -- time left for the whole batch, just above the bar
  batchBar.eta = schematic:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  batchBar.eta:SetPoint("BOTTOMLEFT", batchBar, "TOPLEFT", 0, 3)
  batchBar.eta:SetJustifyH("LEFT")

  frame.create = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.create:SetSize(96, 22)
  frame.create:SetPoint("RIGHT", 0, 0)
  frame.create:SetText("Create")
  CR.ThemeRegisterButton(frame.create)
  frame.nextBtn = CreateFrame("Button", nil, frame.buttons)
  frame.nextBtn:SetSize(20, 20)
  frame.nextBtn:SetPoint("RIGHT", frame.create, "LEFT", -52, 0)
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
  -- Auctionator shopping list for just this step, above Create
  frame.shopBtn = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.shopBtn:SetSize(130, 22)   -- cart + "Shopping List"
  frame.shopBtn:SetPoint("BOTTOMRIGHT", frame.buttons, "TOPRIGHT", 0, 6)
  frame.altsCB:SetPoint("BOTTOMLEFT", frame.shopBtn, "TOPLEFT", 0, 4)   -- "Count alts", just above it
  frame.shopBtn:SetText("Shopping List")
  CR.ThemeRegisterButton(frame.shopBtn)
  CR.AddCartIcon(frame.shopBtn)
  frame.shopBtn:SetScript("OnClick", function()
    local st = frame.current
    if st and st.recipe then CR.CreateStepShoppingList(st.recipe, st.crafts) end
  end)
  frame.shopBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Auctionator shopping list")
    GameTooltip:AddLine("Makes a list of what this step still needs - everything its crafts use that you "
      .. "don't have anywhere (bags, bank, mail, alts). Vendor items are left off: buy those from a vendor.", 1, 1, 1, true)
    if not CR.HasAuctionator() then GameTooltip:AddLine("Needs Auctionator.", 1, 0.5, 0.3, true) end
    GameTooltip:Show()
  end)
  frame.shopBtn:SetScript("OnLeave", GameTooltip_Hide)

  frame.createAll = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.createAll:SetSize(130, 22)
  frame.createAll:SetPoint("LEFT", frame.buttons, "LEFT", -7, 0)
  frame.createAll:SetText("Create All [0]")
  CR.ThemeRegisterButton(frame.createAll)
  frame.openBtn = CreateFrame("Button", nil, frame.buttons, "UIPanelButtonTemplate")
  frame.openBtn:SetSize(160, 22)
  frame.openBtn:SetPoint("RIGHT", 0, 0)
  frame.openBtn:SetText("Open")
  frame.openBtn:Hide()
  CR.ThemeRegisterButton(frame.openBtn)

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
    if cand.trade and GetTradeTargetItemLink then return GetTradeTargetItemLink(cand.tradeSlot) or cand.link end
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
      enchant.target = { equipSlot = cand.equipSlot, bag = cand.bag, slot = cand.slot, itemID = cand.itemID,
                       trade = cand.trade, tradeSlot = cand.tradeSlot }
      flyout:Hide()
      GameTooltip_Hide()
      if overlay then overlay:Refresh() end
    end)
    flyout.rows[i] = row
    if CR.NoteThemeFonts then CR.NoteThemeFonts(row) end
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
    -- trading: the trade window's item is the target (it's the only one offered)
    if not found and CR.tradeOpen then found = CR.EnchantCandidates(fits)[1] end
    enchant.target = found and {
      equipSlot = found.equipSlot, bag = found.bag, slot = found.slot, itemID = found.itemID,
      trade = found.trade, tradeSlot = found.tradeSlot,
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
      if found.trade then name = name .. CR.ColorText(" (in the trade)", "aaaaaa") end
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
    enchant.target = { equipSlot = cand.equipSlot, bag = cand.bag, slot = cand.slot, itemID = cand.itemID,
                       trade = cand.trade, tradeSlot = cand.tradeSlot }
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

  -- hovering opens the pick list; no tooltip (it would cover the list)
  enchant.slot:SetScript("OnEnter", function() ShowFlyout() end)
  enchant.slot:SetScript("OnLeave", GameTooltip_Hide)
  enchant.slot:SetScript("OnClick", SlotClick)
  enchant.slotCover = AttachEnchantCover(enchant.slot, SlotClick)
  enchant.castCover = AttachEnchantCover(frame.create, EnchantButtonClick)

  frame.create:SetScript("OnClick", function()
    local st = frame.current
    if not st or not st.recipe or CR.RecipeLearned(frame.craftProf, st.recipe) == false then return end
    if CR.EnchantSlotFor(st.recipe) then
      -- The secure cover takes this click when it is the top frame, and that is what
      -- answers the replace prompt. This runs only when the click reaches the button.
      EnchantButtonClick()
      return
    end
    CR.CraftSpell(st.recipe.spell, tonumber(frame.countBox:GetText()) or 1, frame.craftProf)
  end)
  frame.createAll:SetScript("OnClick", function()
    local st = frame.current
    if not st or not st.recipe or CR.RecipeLearned(frame.craftProf, st.recipe) == false then return end
    if CR.EnchantSlotFor(st.recipe) then return end
    local n = CR.CraftsReady(frame.craftProf, st.recipe)
    if n > 0 then
      frame.countBox:SetText(tostring(n))   -- the quantity box shows what was just queued
      CR.CraftSpell(st.recipe.spell, n, frame.craftProf)
    end
  end)
  frame.openBtn:SetScript("OnClick", function()
    if frame.craftProf then CR.OpenTradeSkill(frame.craftProf) end
  end)
  -- the click opens the profession by casting it (only a secure click may)
  AttachPlainCover(frame.openBtn, function()
      local macro = CR.OpenProfessionMacro(frame.craftProf)
      if macro then ui.keepUntil = GetTime() + 2 end   -- stay on this view while it loads
      return macro or ""
    end,
    function() return frame:IsShown() and frame.openBtn:IsShown() and CR.OpenProfessionMacro(frame.craftProf) ~= nil end)

  -- The batch bar, the Blizzard-page check, and the enchant covers used to run every frame.
  -- GetLeft/GetBottom inside the cover sync forces a layout. 0.1s is enough for the bar.
  -- The label, structure text, and profession sync stay on the slower tick.
  local watch, slow = 0, 0
  frame:SetScript("OnUpdate", function(_, elapsed)
    elapsed = elapsed or 0
    watch = watch + elapsed
    slow = slow + elapsed
    if watch < 0.1 then return end
    watch = 0
    local bs = CR.CraftBatchState and CR.CraftBatchState()
    if bs and frame.icon:IsShown() then
      frame.batchBar:Show()
      frame.status:Hide()
      frame.batchBar:SetValue(bs.frac)
      if bs.stopped then frame.batchBar:SetStatusBarColor(0.9, 0.15, 0.15)
      elseif bs.finished then frame.batchBar:SetStatusBarColor(0.2, 0.9, 0.2)
      else frame.batchBar:SetStatusBarColor(1, 0.7, 0) end
      frame.batchBar.text:SetText(CR.CraftBatchText(bs))
      local left, togo
      if CR.CraftBatchTimeLeft then left, togo = CR.CraftBatchTimeLeft() end
      if left then
        frame.batchBar.eta:SetText(string.format("About %s left  (%d to go)", CR.FormatDuration(left), togo))
        frame.batchBar.eta:Show()
      else
        frame.batchBar.eta:Hide()
      end
    elseif frame.batchBar:IsShown() then
      frame.batchBar.eta:Hide()
      frame.batchBar:Hide()
      frame.status:Show()
    end
    -- One of Blizzard's own pages is showing - you went to one of its tabs. This view steps
    -- aside even if that tab change wasn't seen (a client update changed how the window switches
    -- tabs, and this view stayed up, empty, over Blizzard's page). Not while a profession switch
    -- from this view is loading, when Blizzard briefly shows its recipes page.
    if not Keeping() and GetTime() - openedAt > 0.3 and BlizzardPageShown() then
      if UserChoseNative() then
        CloseCompact(false)
        return
      end
      pcall(HidePages)   -- not your choice (a craft finished, the list refreshed): stay here
    end
    SyncEnchantSecure()
    if slow < 0.4 then return end
    slow = 0
    -- the main window can be closed from its own X: keep the button's label right
    frame.mainBtn:SetText(CR.IsWindowShown() and "Close CraftRoute" or "Open CraftRoute")
    -- "Anvil required" turns green as you walk up to one
    local sel = frame.info and frame.info.selected
    if sel and sel.recipe and not sel.task and frame.rStructure:IsShown() then
      frame.rStructure:SetText(CR.StructureText(sel.recipe) or "")
    end
    local before = ui.openProf
    SyncOpenProfession()
    if ui.openProf ~= before then
      pcall(MirrorBlizzardBackground)   -- (another profession: its own art)
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
  frame:SetScript("OnMouseWheel", function(self, delta)
    -- anywhere over a column scrolls that column: right of the divider, your list (Craft view)
    local target = list
    local fav = self.favList
    if fav and fav:IsShown() and self.divider and self.divider:GetLeft() then
      local x = GetCursorPosition() / (self:GetEffectiveScale() or 1)
      if x > self.divider:GetLeft() then target = fav end
    end
    if target and target.Wheel then target:Wheel(delta) end
  end)

  function frame:Refresh()
    CR.RefreshCompact()
  end
  overlay = frame
  CR.compactFrame = frame
  frame:HookScript("OnHide", function()
    if deliberate then return end
    Trace("view hidden by something else")
    C_Timer.After(0, function()
      if overlay:IsShown() or InCombatLockdown() or UserChoseNative() then return end
      if not (ProfessionsFrame and ProfessionsFrame:IsShown()) then return end   -- the window closed
      Trace("view put back")
      OpenCompact()
    end)
  end)
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
    KeepNow()
    ReopenSoon()
    C_Timer.After(0, PositionEntry)
    C_Timer.After(0.2, PositionEntry)
    WatchTrainerSpells()
  end)
  ProfessionsFrame:HookScript("OnHide", function()
    -- the materials panel doesn't come back by itself: open it again when you want it
    if matPanel then matPanel:Hide() end
    if Keeping() then return end   -- switching profession from this view: it stays open
    local wasOpen = overlay and overlay:IsShown()
    if wasOpen then
      HideOverlay("window closed")
      SetEntryChecked(false)
    end
    if wasOpen and not InCombatLockdown() then pcall(RestorePages) end
  end)
  -- Blizzard's own pages: one shown while a switch from this view is loading is hidden again in
  -- the same frame (only then - normal tab clicks behave as Blizzard intends).
  local pages = ProfessionsFrame.Pages or { ProfessionsFrame.CraftingPage, ProfessionsFrame.BookPage }
  for _, page in pairs(pages) do
    if type(page) == "table" and page.HookScript then
      page:HookScript("OnShow", function(self)
        if not (overlay and overlay:IsShown()) or InCombatLockdown() then return end
        if Keeping() or not UserChoseNative() then
          Trace("Blizzard page shown without a tab click - hidden again")
          self:Hide()
        end
      end)
    end
  end
  WatchTrainerSpells()
  CR.OnChange(function()
    if overlay and overlay:IsShown() then
      overlay:Refresh()
    end
  end)
end

-- /cr view: what the profession-window view and Blizzard's window are showing right now
-- (for tracking down something drawn where it shouldn't be).
function CR.DebugCompactView()
  local P = CR.Print
  local function n(v) return tonumber(v) or 0 end
  if not overlay then P("CraftRoute view not built (open a profession first).") return end
  P(string.format("view shown=%s visible=%s alpha=%.2f level=%d strata=%s | Keeping=%s | BlizzardPageShown=%s",
    tostring(overlay:IsShown()), tostring(overlay:IsVisible()), n(overlay:GetAlpha()), n(overlay:GetFrameLevel()),
    tostring(overlay:GetFrameStrata()), tostring(Keeping()), tostring(BlizzardPageShown())))
  local f = ProfessionsFrame
  if f then
    P(string.format("ProfessionsFrame: Pages=%s CraftingPage=%s(%s) BookPage=%s(%s)",
      f.Pages and #f.Pages or "nil", tostring(f.CraftingPage ~= nil), tostring(f.CraftingPage and f.CraftingPage:IsShown()),
      tostring(f.BookPage ~= nil), tostring(f.BookPage and f.BookPage:IsShown())))
    for key, v in pairs(f) do
      if type(v) == "table" and v.IsShown and v.GetObjectType and v:GetObjectType() == "Frame" and v:IsShown()
        and type(key) == "string" and key:find("Page") then
        P("  shown page-like child: ." .. key)
      end
    end
  end
  local icon = overlay.icon
  if icon then
    P(string.format("recipe icon: shown=%s visible=%s %.0fx%.0f", tostring(icon:IsShown()), tostring(icon:IsVisible()),
      n(icon:GetWidth()), n(icon:GetHeight())))
    for _, r in ipairs({ icon:GetRegions() }) do
      local t = r.GetObjectType and r:GetObjectType()
      P(string.format("  region %s shown=%s %.0fx%.0f tex=%s atlas=%s layer=%s", tostring(t), tostring(r:IsShown()),
        n(r:GetWidth()), n(r:GetHeight()), tostring(r.GetTexture and r:GetTexture()),
        tostring(r.GetAtlas and r:GetAtlas()), tostring(r.GetDrawLayer and r:GetDrawLayer())))
    end
    for _, c in ipairs({ icon:GetChildren() }) do
      P(string.format("  child %s %s shown=%s %.0fx%.0f", tostring(c:GetObjectType()), tostring(c:GetName()),
        tostring(c:IsShown()), n(c:GetWidth()), n(c:GetHeight())))
    end
  end
end

-- /cr probe: every frame of the profession window under the mouse - where it hangs, its size and
-- what it draws - to identify something drawn there (hover it, then type the command).
function CR.ProbeUnderMouse()
  local P = CR.Print
  local root = ProfessionsFrame
  if not root then P("Open a profession first.") return end
  local function n(v) return tonumber(v) or 0 end
  local function KeyIn(parent, child)
    for k, v in pairs(parent) do if v == child and type(k) == "string" then return k end end
  end
  local found = 0
  local function Walk(f, path, depth)
    if depth > 6 then return end
    for _, c in ipairs({ f:GetChildren() }) do
      local name = c.GetName and c:GetName()
      local key = KeyIn(f, c) or (type(name) == "string" and name) or (tostring(c):gsub("table: ", ""))
      local cpath = path .. "." .. key
      if c:IsVisible() and c.IsMouseOver and c:IsMouseOver() and not cpath:find("CraftRoute") then
        found = found + 1
        local textures = {}
        for _, r in ipairs({ c:GetRegions() }) do
          if r.GetObjectType and r:GetObjectType() == "Texture" and r:IsShown() then
            table.insert(textures, string.format("%s/%s %.0fx%.0f", tostring(r:GetTexture()),
              tostring(r.GetAtlas and r:GetAtlas()), n(r:GetWidth()), n(r:GetHeight())))
          end
        end
        P(string.format("%s  [%s%s] level=%d %.0fx%.0f  %s", cpath, tostring(c:GetObjectType()),
          type(name) == "string" and (" " .. name) or "", n(c:GetFrameLevel()), n(c:GetWidth()), n(c:GetHeight()),
          #textures > 0 and ("tex: " .. table.concat(textures, ", ")) or ""))
      end
      Walk(c, cpath, depth + 1)
    end
  end
  Walk(root, "ProfessionsFrame", 0)
  if found == 0 then P("Nothing of the profession window (outside CraftRoute) is under the mouse.") end
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
  ReopenSoon()
end)
if ProfessionsFrame then Install() end
