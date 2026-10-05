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

function CR.FormatMoney(copper)
  if not copper then return "|cff808080?|r" end
  copper = math.floor(copper + 0.5)
  if GetCoinTextureString then return GetCoinTextureString(copper) end
  return string.format("%dg %ds %dc", copper / 10000, (copper / 100) % 100, copper % 100)
end

-- Builds (or replaces) an Auctionator shopping list with the missing AH-bought materials.
function CR.CreateShoppingList(plan)
  if not CR.HasAuctionator() or not Auctionator.API.v1.CreateShoppingList then
    CR.Print("Auctionator isn't loaded.")
    return
  end
  local api = Auctionator.API.v1
  local terms = {}
  for _, m in ipairs(plan.materials) do
    local missing = m.need - m.have
    local _, src = CR.GetUnitPrice(m.id)
    if missing > 0 and src ~= "vendor" then
      local name = GetItemInfo(m.id) or m.name
      local ok, str = pcall(api.ConvertToSearchString, CALLER,
        { searchString = name, isExact = true, categoryKey = "", quantity = missing })
      table.insert(terms, ok and str or ('"' .. name .. '"'))
    end
  end
  if #terms == 0 then
    CR.Print("Nothing to buy from the Auction House - you have everything (vendor items excluded).")
    return
  end
  local listName = "CraftRoute " .. plan.prof
  local ok, err = pcall(api.CreateShoppingList, CALLER, listName, terms)
  if ok then
    CR.Print(string.format("Auctionator shopping list '%s' created with %d items.", listName, #terms))
  else
    CR.Print("Couldn't create the shopping list: " .. tostring(err))
  end
end
