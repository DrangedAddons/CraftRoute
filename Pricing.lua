-- Material prices via Auctionator's public API (Auctionator.API.v1).
-- Vendor prices come from Auctionator's own vendor cache, which it fills whenever you visit a merchant.
local _, CR = ...
local GetItemInfo, GetItemCount, GetItemIcon, IsEquippedItem = CR.GetItemInfo, CR.GetItemCount, CR.GetItemIcon, CR.IsEquippedItem

local CALLER = "CraftRoute"

function CR.HasAuctionator()
  return Auctionator and Auctionator.API and Auctionator.API.v1 and true or false
end

-- Returns unitPrice (copper), source ("vendor" | "ah") or nil if unknown.
function CR.GetUnitPrice(itemID)
  if not CR.HasAuctionator() then return nil end
  local api = Auctionator.API.v1
  local ok, vendor = pcall(api.GetVendorPriceByItemID, CALLER, itemID)
  if ok and vendor and vendor > 0 then return vendor, "vendor" end
  local ok2, ah = pcall(api.GetAuctionPriceByItemID, CALLER, itemID)
  if ok2 and ah and ah > 0 then return ah, "ah" end
  return nil
end

-- What a crafted item sells for on the AH (Auctionator's price, never a vendor's buy price) - nil
-- if it hasn't been seen there.
function CR.GetAuctionPrice(itemID)
  if not CR.HasAuctionator() or not itemID then return nil end
  local ok, ah = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, CALLER, itemID)
  if ok and ah and ah > 0 then return ah end
  return nil
end

-- Money with the gold / silver / copper coin icons, like vendors show it: "13 (s) 50 (c)".
-- Units that are zero are left out (but 0 shows as "0 (c)").
local COIN = "|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"
local GOLD, SILVER, COPPER = COIN:format("Gold"), COIN:format("Silver"), COIN:format("Copper")
function CR.FormatMoney(copper)
  if not copper then return "|cff808080?|r" end
  copper = math.floor(copper + 0.5)
  local g, sv, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then table.insert(parts, (BreakUpLargeNumbers and BreakUpLargeNumbers(g) or g) .. GOLD) end
  if sv > 0 then table.insert(parts, sv .. SILVER) end
  if c > 0 or #parts == 0 then table.insert(parts, c .. COPPER) end
  return table.concat(parts, " ")
end

-- Builds an Auctionator shopping list from { id, missing, name } entries: what's short, minus
-- anything a vendor sells (buy those from the vendor). The list is named listName plus the time
-- it was made ("CraftRoute: Leatherworking crafts, 3 recipes (14:32)"), so the one you just made
-- is easy to tell apart; the list CraftRoute made before under the same listName is removed, so
-- they don't pile up (kept per account in CraftRouteDB.shoppingLists).
local function RemovePrevious(base)
  CraftRouteDB.shoppingLists = CraftRouteDB.shoppingLists or {}
  local old = CraftRouteDB.shoppingLists[base]
  CraftRouteDB.shoppingLists[base] = nil
  -- (a list you named yourself is yours: it stays)
  if type(old) ~= "string" then return end
  -- Auctionator's API can't delete a list; its list manager can (guarded: if that ever changes,
  -- the old list just stays)
  local lm = Auctionator.Shopping and Auctionator.Shopping.ListManager
  if lm and lm.GetIndexForName and lm.Delete then
    pcall(function() if lm:GetIndexForName(old) then lm:Delete(old) end end)
  end
end
-- key: which list this is (a recipe, a profession's crafts, its route...) - the one CraftRoute
-- made before with the same key goes, whatever amounts or time its name had
local function MakeShoppingList(listName, wanted, key)
  if not CR.HasAuctionator() or not Auctionator.API.v1.CreateShoppingList then
    CR.Print("Auctionator isn't loaded.")
    return
  end
  local api = Auctionator.API.v1
  local terms = {}
  for _, w in ipairs(wanted) do
    local _, src = CR.GetUnitPrice(w.id)
    if w.missing > 0 and src ~= "vendor" then
      local name = GetItemInfo(w.id) or w.name
      local ok, str = pcall(api.ConvertToSearchString, CALLER,
        { searchString = name, isExact = true, categoryKey = "", quantity = w.missing })
      table.insert(terms, ok and str or ('"' .. name .. '"'))
    end
  end
  if #terms == 0 then
    CR.Print("Nothing to buy from the Auction House - you have everything (vendor items excluded).")
    return
  end
  local base = key or listName
  local suggested = string.format("%s (%s)", listName, date("%H:%M"))
  -- you name it (the suggestion's filled in); then it's made
  CR.AskListName(suggested, #terms, function(name)
    local custom = name ~= suggested
    RemovePrevious(base)
    local ok, err = pcall(api.CreateShoppingList, CALLER, name, terms)
    if ok then
      -- remembered so the next one of this kind replaces it - unless you named it yourself
      CraftRouteDB.shoppingLists[base] = (not custom) and name or nil
      CR.Print(string.format("Auctionator shopping list '%s' created with %d items.", name, #terms))
    else
      CR.Print("Couldn't create the shopping list: " .. tostring(err))
    end
  end)
end

-- The "name the list" prompt: the suggested name filled in and selected - Enter (or Create) makes
-- it, typing replaces it, Escape (or Cancel) makes nothing.
local namer
function CR.AskListName(suggested, count, onCreate)
  if not namer then
    local f = CreateFrame("Frame", "CraftRouteListName", UIParent, "BackdropTemplate")
    f:SetSize(380, 116)
    f:SetPoint("CENTER", 0, 120)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    if CR.Backdrop then CR.Backdrop(f, 0.05, 0.05, 0.07, 0.97) end
    f:Hide()
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 14, -12)
    if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(f.title) end
    f.box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.box:SetHeight(22)
    f.box:SetPoint("TOPLEFT", 20, -38)
    f.box:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    f.box:SetAutoFocus(false)
    f.box:SetMaxLetters(80)
    local function Done(create)
      local name = strtrim(f.box:GetText() or "")
      if name == "" then name = f.suggested end
      local fn = f.onCreate
      f.onCreate = nil
      f:Hide()
      if create and fn then fn(name) end
    end
    f.box:SetScript("OnEnterPressed", function() Done(true) end)
    f.box:SetScript("OnEscapePressed", function() Done(false) end)
    local function Btn(text, x, create)
      local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      b:SetSize(96, 22)
      b:SetPoint("BOTTOMRIGHT", x, 12)
      b:SetText(text)
      if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
      b:SetScript("OnClick", function() Done(create) end)
      return b
    end
    Btn("Cancel", -14, false)
    Btn("Create", -116, true)
    table.insert(UISpecialFrames, "CraftRouteListName")   -- (Escape closes it)
    f:SetScript("OnHide", function() f.onCreate = nil end)
    namer = f
  end
  local f = namer
  f.suggested, f.onCreate = suggested, onCreate
  f.title:SetText(string.format("Name the shopping list (%d item%s)", count, count == 1 and "" or "s"))
  f:Show()
  f.box:SetText(suggested)
  f.box:SetFocus()
  f.box:HighlightText()
  -- (the click that opened this can still be settling: select it again a moment later)
  C_Timer.After(0, function() if f:IsShown() and f.box:HasFocus() then f.box:HighlightText() end end)
end

-- The whole plan's missing materials.
function CR.CreateShoppingList(plan)
  local wanted = {}
  for _, m in ipairs(plan.materials) do
    -- what's still missing after the crafting the plan does (bolts made from wool aren't bought -
    -- the wool is)
    table.insert(wanted, { id = m.id, missing = m.missing, name = m.name })
  end
  MakeShoppingList("CraftRoute: " .. plan.prof .. (plan.from and plan.goal and string.format(" route %d-%d", plan.from, plan.goal) or " route"),
    wanted, "route:" .. tostring(plan.prof))
end

-- Several recipes' crafts at once - entries { { recipe, crafts } } - into one list: what they need
-- that you don't own (counted as the "Count alts" setting says). What you own is used once across
-- them all, so two recipes sharing a reagent don't both count the same stock. A reagent you make
-- yourself (a bolt of cloth, a cured hide - a recipe of the same profession you can make) isn't
-- bought: what it's made from is, a level further in.
-- What those entries still need to get: { { id, missing, name } }, in the order first met.
-- direct: just the recipes' own materials (Light Leather stays Light Leather - it isn't broken
-- down into the scraps it's made from).
function CR.MultiNeeds(entries, direct)
  local used, need, order = {}, {}, {}
  local function Add(prof, skill, id, n, depth)
    local bags, elsewhere = CR.BagsAndElsewhere(id)
    local take = math.max(0, math.min(bags + elsewhere - (used[id] or 0), n))
    used[id] = (used[id] or 0) + take
    local short = n - take
    if short <= 0 then return end
    local maker = not direct and depth < 3 and prof and prof.byItem[id] and prof.recipes[prof.byItem[id]]
    if maker and (maker.learn or 1) <= skill then
      local times = math.ceil(short / (maker.makes or 1))
      for _, rg in ipairs(maker.reagents or {}) do Add(prof, skill, rg[1], rg[2] * times, depth + 1) end
    else
      if not need[id] then table.insert(order, id) end
      need[id] = (need[id] or 0) + short
    end
  end
  for _, e in ipairs(entries) do
    local recipe = e.recipe
    local prof
    for _, p in pairs(CR.professions) do
      if p.recipes[recipe.spell] == recipe then prof = p break end
    end
    -- a component you can make by the time you make this (its skill isn't above this recipe's)
    local skill = math.max(prof and CR.GetSkill(prof.name) or 0, recipe.learn or 0)
    for _, rg in ipairs(recipe.reagents or {}) do Add(prof, skill, rg[1], rg[2] * math.max(1, e.crafts or 1), 0) end
  end
  local wanted = {}
  for _, id in ipairs(order) do table.insert(wanted, { id = id, missing = need[id], name = CR.ItemName(id) }) end
  return wanted
end

-- What getting those costs: vendor or AH price for each, and how many have no price yet.
function CR.NeedsCost(wanted)
  local total, unpriced = 0, 0
  for _, w in ipairs(wanted) do
    local price = CR.GetUnitPrice(w.id)
    if price then total = total + price * w.missing else unpriced = unpriced + 1 end
  end
  return total, unpriced
end

function CR.CreateMultiShoppingList(entries, listName, direct, key)
  MakeShoppingList(listName, CR.MultiNeeds(entries, direct), key)
end

-- Just one step / recipe.
function CR.CreateStepShoppingList(recipe, crafts)
  CR.CreateMultiShoppingList({ { recipe = recipe, crafts = crafts } },
    string.format("CraftRoute: %s x%d", recipe.name, math.max(1, crafts or 1)), nil, "recipe:" .. tostring(recipe.spell))
end
