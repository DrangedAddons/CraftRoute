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

-- Builds (or replaces) an Auctionator shopping list called listName from { id, missing, name }
-- entries: what's short, minus anything a vendor sells (buy those from the vendor).
local function MakeShoppingList(listName, wanted)
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
  local ok, err = pcall(api.CreateShoppingList, CALLER, listName, terms)
  if ok then
    CR.Print(string.format("Auctionator shopping list '%s' created with %d items.", listName, #terms))
  else
    CR.Print("Couldn't create the shopping list: " .. tostring(err))
  end
end

-- The whole plan's missing materials.
function CR.CreateShoppingList(plan)
  local wanted = {}
  for _, m in ipairs(plan.materials) do
    -- what's still missing after the crafting the plan does (bolts made from wool aren't bought -
    -- the wool is)
    table.insert(wanted, { id = m.id, missing = m.missing, name = m.name })
  end
  MakeShoppingList("CraftRoute " .. plan.prof, wanted)
end

-- Just one step: what its crafts need that you don't own (counted as the "Count alts" setting
-- says). A reagent you make yourself (a bolt of cloth, a cured hide - a recipe of the same
-- profession you can make) isn't bought: what it's made from is, a level further in.
function CR.CreateStepShoppingList(recipe, crafts)
  local prof
  for _, p in pairs(CR.professions) do
    if p.recipes[recipe.spell] == recipe then prof = p break end
  end
  -- a component you can make by the time you're on this step (its skill isn't above the step's)
  local skill = math.max(prof and CR.GetSkill(prof.name) or 0, recipe.learn or 0)
  local need, order = {}, {}
  local function Add(id, n, depth)
    local bags, elsewhere = CR.BagsAndElsewhere(id)
    local short = n - bags - elsewhere
    if short <= 0 then return end
    local maker = depth < 3 and prof and prof.byItem[id] and prof.recipes[prof.byItem[id]]
    if maker and (maker.learn or 1) <= skill then
      local times = math.ceil(short / (maker.makes or 1))
      for _, rg in ipairs(maker.reagents or {}) do Add(rg[1], rg[2] * times, depth + 1) end
    else
      if not need[id] then table.insert(order, id) end
      need[id] = (need[id] or 0) + short
    end
  end
  for _, rg in ipairs(recipe.reagents or {}) do Add(rg[1], rg[2] * math.max(1, crafts or 1), 0) end
  local wanted = {}
  for _, id in ipairs(order) do table.insert(wanted, { id = id, missing = need[id], name = CR.ItemName(id) }) end
  MakeShoppingList("CraftRoute: " .. recipe.name, wanted)
end
