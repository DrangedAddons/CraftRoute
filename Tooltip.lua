-- Adds "needed for ..." lines to item tooltips for what the All Materials window tracks.
local _, CR = ...

local MAX_USAGE_LINES = 6

local function Count(have, need)
  local color = have >= need and "40ff40" or "ffffff"
  return string.format("|cff%s%d/%d|r", color, math.min(have, need), need)
end

-- The All Materials window's columns that need this item (your professions on it, the other
-- characters' you've added - each to the guide picked there): a block each - what it's needed
-- for, and have/need to that column's goal - then, with more than one, the total together.
function CR.AddTooltipLines(tooltip, itemID)
  if not itemID or not CraftRouteCharDB then return end
  local cols = CR.AllMaterialsColumns and CR.AllMaterialsColumns()
  if not cols then return end
  local blocks = {}
  for _, c in ipairs(cols) do
    local m = c.plan.byId and c.plan.byId[itemID]
    if m and (m.need or 0) > 0 then table.insert(blocks, { col = c, m = m }) end
  end
  if #blocks == 0 then return end

  tooltip:AddLine(" ")
  tooltip:AddLine("|cff33ccffCraftRoute|r")
  local need, have, crafted, price = 0, 0, 0, nil
  for _, b in ipairs(blocks) do
    local c, m = b.col, b.m
    -- named when there's more than one, or it's another character's
    local heading
    if #blocks > 1 or c.char then
      heading = c.char and (c.charName .. "'s " .. c.prof) or ((c.route and c.route.sequential) and c.route.label or c.prof)
    end
    if heading then tooltip:AddLine(heading, 1, 1, 1) end
    local shown = 0
    for _, u in ipairs(m.usage or {}) do
      shown = shown + 1
      if shown > MAX_USAGE_LINES then
        tooltip:AddLine(string.format("  ...and %d more", #m.usage - MAX_USAGE_LINES), 0.6, 0.6, 0.6)
        break
      end
      tooltip:AddDoubleLine("  Needed for " .. CR.TipShort(u.label), u.n, 0.8, 0.8, 0.8, 1, 1, 1)
    end
    local extra = (m.crafted or 0) > 0 and string.format(" (+%d crafted)", m.crafted) or ""
    tooltip:AddDoubleLine(string.format("To reach %s %d (from %d):", c.prof, c.goal or 0, c.cur or 0),
      Count((m.have or 0) + (m.crafted or 0), m.need) .. extra, 1, 0.82, 0)
    need = need + m.need
    have = math.max(have, m.have or 0)   -- (the same stock for each)
    crafted = crafted + (m.crafted or 0)
    if not price and m.price and (m.crafted or 0) == 0 then price = m end
  end
  if #blocks > 1 then
    tooltip:AddDoubleLine("Together:", Count(have + crafted, need), 1, 0.82, 0)
  end
  if price then
    local missing = math.max(0, need - have - crafted)
    tooltip:AddDoubleLine(price.priceSrc == "vendor" and "  Vendor price" or "  AH price (Auctionator)",
      CR.FormatMoney(price.price) .. (missing > 0 and ("  |cffaaaaaa(buy " .. missing .. ": "
        .. CR.FormatMoney(price.price * missing) .. ")|r") or ""),
      0.8, 0.8, 0.8, 1, 1, 1)
  end
  tooltip:Show()
end

local function ItemIDFromTooltip(tooltip)
  local _, link = tooltip:GetItem()
  return link and tonumber(link:match("item:(%d+)"))
end

-- Tooltip errors are reported once, not on every hover.
local reported = false
local function SafeAdd(tooltip, id)
  local ok, err = pcall(CR.AddTooltipLines, tooltip, id)
  if not ok and not reported then
    reported = true
    CR.Print("|cffff4040tooltip error:|r " .. tostring(err))
  end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    SafeAdd(tooltip, data and data.id or ItemIDFromTooltip(tooltip))
  end)
else
  for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    pcall(tt.HookScript, tt, "OnTooltipSetItem", function(self)
      SafeAdd(self, ItemIDFromTooltip(self))
    end)
  end
end
