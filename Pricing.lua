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
    table.insert(wanted, { id = m.id, missing = m.need - m.have, name = m.name })
  end
  MakeShoppingList("CraftRoute " .. plan.prof, wanted)
end

-- Just one step: what its crafts need that you don't own anywhere (bags, bank, mail, alts).
function CR.CreateStepShoppingList(recipe, crafts)
  local wanted = {}
  for _, rg in ipairs(recipe.reagents or {}) do
    local bags, elsewhere = CR.BagsAndElsewhere(rg[1])
    table.insert(wanted, { id = rg[1], missing = rg[2] * math.max(1, crafts or 1) - bags - elsewhere,
                           name = CR.ItemName(rg[1]) })
  end
  MakeShoppingList("CraftRoute: " .. recipe.name, wanted)
end
