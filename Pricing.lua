-- Material prices via Auctionator's public API (Auctionator.API.v1).
-- Vendor prices come from Auctionator's own vendor cache, which it fills whenever you visit a merchant.
local _, CR = ...
local GetItemInfo, GetItemCount, GetItemIcon, IsEquippedItem = CR.GetItemInfo, CR.GetItemCount, CR.GetItemIcon, CR.IsEquippedItem

local CALLER = "CraftRoute"

function CR.HasAuctionator()
  return Auctionator and Auctionator.API and Auctionator.API.v1 and true or false
end

-- Returns unitPrice (copper), source ("vendor" | "ah") or nil if unknown.
-- A plan build asks for the same reagent from auto-fill, forks, and the material list.
-- Remember each answer for a few seconds so those calls share one Auctionator lookup.
local PRICE_TTL = 5
local priceCache = {}
local ahCache = {}

function CR.InvalidatePrices()
  wipe(priceCache)
  wipe(ahCache)
end

function CR.GetUnitPrice(itemID)
  if not itemID then return nil end
  local now = GetTime and GetTime() or 0
  local cached = priceCache[itemID]
  if cached and (now - cached.t) < PRICE_TTL then
    if not cached.ok then return nil end
    return cached.price, cached.src
  end
  local price, src
  if CR.HasAuctionator() then
    local api = Auctionator.API.v1
    local ok, vendor = pcall(api.GetVendorPriceByItemID, CALLER, itemID)
    if ok and vendor and vendor > 0 then
      price, src = vendor, "vendor"
    else
      local ok2, ah = pcall(api.GetAuctionPriceByItemID, CALLER, itemID)
      if ok2 and ah and ah > 0 then price, src = ah, "ah" end
    end
  end
  priceCache[itemID] = { t = now, ok = price ~= nil, price = price, src = src }
  return price, src
end

-- What a crafted item sells for on the AH (Auctionator's price, never a vendor's buy price) - nil
-- if it hasn't been seen there.
function CR.GetAuctionPrice(itemID)
  if not itemID then return nil end
  local now = GetTime and GetTime() or 0
  local cached = ahCache[itemID]
  if cached and (now - cached.t) < PRICE_TTL then
    if not cached.ok then return nil end
    return cached.price
  end
  local price
  if CR.HasAuctionator() then
    local ok, ah = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, CALLER, itemID)
    if ok and ah and ah > 0 then price = ah end
  end
  ahCache[itemID] = { t = now, ok = price ~= nil, price = price }
  return price
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
  -- what goes on it: what's missing, not what vendors sell
  local items = {}
  for _, w in ipairs(wanted) do
    local _, src = CR.GetUnitPrice(w.id)
    if w.missing > 0 and src ~= "vendor" then
      table.insert(items, { id = w.id, name = GetItemInfo(w.id) or w.name, qty = w.missing, on = true })
    end
  end
  if #items == 0 then
    CR.Print("Nothing to buy from the Auction House - you have everything (vendor items excluded).")
    return
  end
  local base = key or listName
  local suggested = string.format("%s (%s)", listName, date("%H:%M"))
  -- the cart: you see what goes on it, can change amounts or drop items, and name it - then it's made
  CR.ShowCart(suggested, items, function(name, chosen)
    local terms = {}
    for _, it in ipairs(chosen) do
      local ok, str = pcall(api.ConvertToSearchString, CALLER,
        { searchString = it.name, isExact = true, categoryKey = "", quantity = it.qty })
      table.insert(terms, ok and str or ('"' .. it.name .. '"'))
    end
    if #terms == 0 then CR.Print("Nothing ticked - no shopping list made.") return end
    local custom = name ~= suggested
    RemovePrevious(base)
    local ok, err = pcall(api.CreateShoppingList, CALLER, name, terms)
    if ok then
      -- remembered so the next one of this kind replaces it - unless you named it yourself
      CraftRouteDB.shoppingLists[base] = (not custom) and name or nil
      CR.Print(string.format("Auctionator shopping list '%s' created with %d item%s.", name, #terms, #terms == 1 and "" or "s"))
    else
      CR.Print("Couldn't create the shopping list: " .. tostring(err))
    end
  end)
end

-- The cart: "This will be added to your shopping list" - the list's name (the suggestion filled in
-- and selected: typing replaces it), then each item with a tick (untick to leave it off), its
-- amount (change it) and what that costs, and the total. Create List (or Enter in the name) makes
-- it from what's ticked; Cancel (or Escape) makes nothing. items: { { id, name, qty, on } }.
local cart
local CART_ROWS, CART_ROW_H = 12, 22
local CART_TOP, CART_FOOT = 36, 110   -- rows start under the title; below them: totals, name, buttons
function CR.ShowCart(suggested, items, onCreate)
  if not cart then
    local f = CreateFrame("Frame", "CraftRouteCart", UIParent, "BackdropTemplate")
    f:SetSize(420, CART_TOP + CART_ROWS * CART_ROW_H + CART_FOOT)
    f:SetPoint("CENTER", 0, 80)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if CR.Backdrop then CR.Backdrop(f, 0.05, 0.05, 0.07, 0.97) end
    f:Hide()
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 14, -12)
    f.title:SetText("This will be added to your shopping list")
    if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(f.title) end
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.nameLabel:SetPoint("BOTTOMLEFT", 14, 50)   -- (just above the buttons)
    f.nameLabel:SetText("List name:")
    f.box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.box:SetHeight(22)
    f.box:SetPoint("LEFT", f.nameLabel, "RIGHT", 10, 0)
    f.box:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    f.box:SetAutoFocus(false)
    f.box:SetMaxLetters(80)

    -- the items
    f.offset = 0
    f.rows = {}
    local function Cost(it)
      local price = CR.GetUnitPrice(it.id)
      return price and price * it.qty or nil
    end
    function f:Totals()
      local n, total = 0, 0
      for _, it in ipairs(self.items) do
        if it.on and it.qty > 0 then
          n = n + 1
          local c = Cost(it)
          if c then total = total + c end
        end
      end
      -- (an item with no price shows "?" in its own row - not repeated here)
      self.summary:SetText(string.format("%d item%s", n, n == 1 and "" or "s"))
      self.total:SetText(CR.FormatMoney(total))
      self.create:SetEnabled(n > 0)
    end
    function f:Fill()
      local items = self.items
      self.offset = math.max(0, math.min(self.offset, #items - CART_ROWS))
      for i = 1, CART_ROWS do
        local r = self.rows[i]
        local it = items[self.offset + i]
        r.it = it   -- (before the amount is set: its change handler writes to this item)
        if it then
          r.tick:SetChecked(it.on)
          r.icon:SetTexture(CR.GetItemIcon and CR.GetItemIcon(it.id) or (GetItemIcon and GetItemIcon(it.id)))
          r.name:SetText(it.name or "?")
          r.name:SetAlpha(it.on and 1 or 0.45)
          if not r.qty:HasFocus() then r.qty:SetText(tostring(it.qty)) end
          local c = Cost(it)
          r.cost:SetText(c and CR.FormatMoney(c) or CR.ColorText("?", "888888"))
          r.cost:SetAlpha(it.on and 1 or 0.45)
          r:Show()
        else
          r:Hide()
        end
      end
      self.more:SetShown(#items > CART_ROWS)
      self.more:SetText(string.format("%d-%d of %d  (scroll)", self.offset + 1,
        math.min(#items, self.offset + CART_ROWS), #items))
      self:Totals()
    end
    for i = 1, CART_ROWS do
      local r = CreateFrame("Frame", nil, f)
      r:SetHeight(CART_ROW_H)
      r:SetPoint("TOPLEFT", 10, -CART_TOP - (i - 1) * CART_ROW_H)
      r:SetPoint("RIGHT", f, "RIGHT", -12, 0)
      r.tick = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
      r.tick:SetSize(20, 20)
      r.tick:SetPoint("LEFT", 0, 0)
      r.tick:SetScript("OnClick", function(self)
        if r.it then r.it.on = self:GetChecked() and true or false end
        f:Fill()
      end)
      r.icon = r:CreateTexture(nil, "ARTWORK")
      r.icon:SetSize(18, 18)
      r.icon:SetPoint("LEFT", r.tick, "RIGHT", 2, 0)
      r.cost = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.cost:SetPoint("RIGHT", 0, 0)
      r.cost:SetWidth(96)
      r.cost:SetJustifyH("RIGHT")
      r.qty = CreateFrame("EditBox", nil, r, "InputBoxTemplate")
      r.qty:SetSize(44, 18)
      r.qty:SetPoint("RIGHT", r.cost, "LEFT", -8, 0)
      r.qty:SetAutoFocus(false)
      r.qty:SetNumeric(true)
      r.qty:SetMaxLetters(5)
      r.qty:SetJustifyH("CENTER")
      -- the amount: kept as it's typed (the cost and total follow)
      r.qty:SetScript("OnTextChanged", function(self)
        local n = tonumber(self:GetText())
        if r.it and n then
          r.it.qty = n
          local price = CR.GetUnitPrice(r.it.id)
          r.cost:SetText(price and CR.FormatMoney(price * n) or CR.ColorText("?", "888888"))
          f:Totals()
        end
      end)
      r.qty:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
      r.qty:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
      r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
      r.name:SetPoint("RIGHT", r.qty, "LEFT", -8, 0)
      r.name:SetJustifyH("LEFT")
      r.name:SetWordWrap(false)
      -- hovering a row: the item's tooltip (CraftRoute's lines with it); the wheel and dragging
      -- still reach the window
      r:EnableMouse(true)
      r:SetScript("OnEnter", function(self)
        if not self.it then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.it.id)
        GameTooltip:Show()
      end)
      r:SetScript("OnLeave", GameTooltip_Hide)
      r:EnableMouseWheel(true)
      r:SetScript("OnMouseWheel", function(_, delta)
        local h = f:GetScript("OnMouseWheel")
        if h then h(f, delta) end
      end)
      r:RegisterForDrag("LeftButton")
      r:SetScript("OnDragStart", function() f:StartMoving() end)
      r:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
      if CR.NoteThemeFonts then CR.NoteThemeFonts(r) end
      f.rows[i] = r
    end
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(self, delta)
      self.offset = self.offset - delta * 3
      self:Fill()
    end)
    f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    -- under the list: how many items (left), the gold total under the cost column (right)
    f.summary = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.total = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.total:SetJustifyH("RIGHT")
    f.totalLine = f:CreateTexture(nil, "ARTWORK")
    f.totalLine:SetHeight(1)
    f.totalLine:SetColorTexture(1, 0.82, 0.35, 0.35)

    local function Done(create)
      local name = strtrim(f.box:GetText() or "")
      if name == "" then name = f.suggested end
      local fn = f.onCreate
      f.onCreate = nil
      local chosen = {}
      for _, it in ipairs(f.items or {}) do
        if it.on and it.qty > 0 then table.insert(chosen, it) end
      end
      f:Hide()
      if create and fn then fn(name, chosen) end
    end
    f.box:SetScript("OnEnterPressed", function() Done(true) end)
    f.box:SetScript("OnEscapePressed", function() Done(false) end)
    local function Btn(text, w, create)
      local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      b:SetSize(w, 22)
      b:SetText(text)
      if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
      b:SetScript("OnClick", function() Done(create) end)
      return b
    end
    Btn("Cancel", 80, false):SetPoint("BOTTOMRIGHT", -14, 12)
    f.create = Btn("Create Shopping List", 170, true)
    f.create:SetPoint("BOTTOM", 0, 12)   -- (centred)
    table.insert(UISpecialFrames, "CraftRouteCart")   -- (Escape closes it)
    f:SetScript("OnHide", function() f.onCreate = nil end)
    cart = f
  end
  local f = cart
  f.suggested, f.onCreate, f.items, f.offset = suggested, onCreate, items, 0
  -- shorter for a short list
  local shown = math.min(#items, CART_ROWS)
  local rowsH = math.max(3, shown) * CART_ROW_H
  f:SetHeight(CART_TOP + rowsH + CART_FOOT)
  -- the totals line, right under the rows: the gold in line with the cost column
  local y = -CART_TOP - rowsH - 4
  f.totalLine:ClearAllPoints()
  f.totalLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, y)
  f.totalLine:SetWidth(96)
  f.total:ClearAllPoints()
  f.total:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, y - 4)
  f.summary:ClearAllPoints()
  f.summary:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 5)
  f.more:ClearAllPoints()
  f.more:SetPoint("TOP", f, "TOP", 0, y - 5)
  f:Show()
  f:Fill()
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, f) end
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
-- them all, so two recipes sharing a reagent don't both count the same stock. Always the recipes'
-- own materials: Medium Leather stays Medium Leather - it's never broken down into the leather or
-- scraps it's made from. e.covered = { [itemID] = n }: what's made for it elsewhere (an earlier
-- route step making a component) - that much isn't bought.
-- What those entries still need to get: { { id, missing, name } }, in the order first met.
function CR.MultiNeeds(entries)
  local used, need, order = {}, {}, {}
  local function Add(id, n)
    local bags, elsewhere = CR.BagsAndElsewhere(id)
    local take = math.max(0, math.min(bags + elsewhere - (used[id] or 0), n))
    used[id] = (used[id] or 0) + take
    local short = n - take
    if short <= 0 then return end
    if not need[id] then table.insert(order, id) end
    need[id] = (need[id] or 0) + short
  end
  for _, e in ipairs(entries) do
    local covered = e.covered or {}
    for _, rg in ipairs(e.recipe.reagents or {}) do
      local n = rg[2] * math.max(1, e.crafts or 1)
      local made = math.min(n, covered[rg[1]] or 0)
      if made > 0 then covered[rg[1]] = covered[rg[1]] - made end
      if n - made > 0 then Add(rg[1], n - made) end
    end
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
  MakeShoppingList(listName, CR.MultiNeeds(entries), key)
end

-- Just one step / recipe. covered: what earlier route steps make of its reagents (not bought).
function CR.CreateStepShoppingList(recipe, crafts, covered)
  CR.CreateMultiShoppingList({ { recipe = recipe, crafts = crafts, covered = covered } },
    string.format("CraftRoute: %s x%d", recipe.name, math.max(1, crafts or 1)), nil, "recipe:" .. tostring(recipe.spell))
end
