-- Adds "needed for ..." lines to item tooltips for anything in the current plan.
local _, CR = ...

local MAX_USAGE_LINES = 6

local function Count(have, need)
  local color = have >= need and "40ff40" or "ffffff"
  return string.format("|cff%s%d/%d|r", color, math.min(have, need), need)
end

-- Professions whose plans feed the tooltip: every profession this character has learned, plus
-- the one selected on the Plan tab (so browsing another profession still shows its needs).
-- Cooking and Fishing share the combined guide; it's only shown once.
local function TooltipProfessions()
  local list, seenRoute = {}, {}
  local selected = CraftRouteCharDB.profession
  local function Add(name)
    local route = CR.Route(name)
    if route and not seenRoute[route] then
      seenRoute[route] = true
      table.insert(list, name)
    end
  end
  for _, name in ipairs(CR.SupportedProfessions()) do
    local _, _, detected = CR.GetSkill(name)
    if detected or name == selected then Add(name) end
  end
  return list
end

-- One profession's block: what the item is needed for, have/need for the goal and full route.
local function AddProfessionLines(tooltip, entry, m, f, heading)
  if heading then tooltip:AddLine(heading, 1, 1, 1) end
  if m then
    local shown = 0
    for _, u in ipairs(m.usage or {}) do
      shown = shown + 1
      if shown > MAX_USAGE_LINES then
        tooltip:AddLine(string.format("  ...and %d more", #m.usage - MAX_USAGE_LINES), 0.6, 0.6, 0.6)
        break
      end
      tooltip:AddDoubleLine("  Needed for " .. u.label, u.n, 0.8, 0.8, 0.8, 1, 1, 1)
    end
    local extra = m.crafted > 0 and string.format(" (+%d crafted)", m.crafted) or ""
    local label = entry.route.sequential and ("To finish the " .. entry.route.label .. " guide:")
      or string.format("To reach %s %d (from %d):", entry.plan.prof, entry.goal, entry.cur)
    tooltip:AddDoubleLine(label, Count(m.have + m.crafted, m.need) .. extra, 1, 0.82, 0)
  end
  if f and entry.full ~= entry.plan then
    tooltip:AddDoubleLine(string.format("To complete %s %d-%d:", entry.full.prof, entry.cur, entry.full.goal),
      Count(f.have + f.crafted, f.need), 1, 0.82, 0)
  end
end

function CR.AddTooltipLines(tooltip, itemID)
  if not itemID or not CraftRouteCharDB then return end
  local blocks, price = {}, nil
  for _, name in ipairs(TooltipProfessions()) do
    local entry = CR.GetPlans(name)
    if entry then
      local m, f = entry.plan.byId[itemID], entry.full.byId[itemID]
      if m or f then
        table.insert(blocks, { entry = entry, m = m, f = f, name = name })
        local p = m or f
        if not price and p.price and p.crafted == 0 then price = p end
      end
    end
  end
  if #blocks == 0 then return end

  tooltip:AddLine(" ")
  tooltip:AddLine("|cff33ccffCraftRoute|r")
  for _, b in ipairs(blocks) do
    -- Name each profession when more than one needs the item, or when it's one you haven't learned.
    local _, _, detected = CR.GetSkill(b.name)
    local heading
    if #blocks > 1 or not detected then
      heading = (b.entry.route.sequential and b.entry.route.label or b.name)
        .. (detected and "" or " |cff888888(not learned)|r")
    end
    AddProfessionLines(tooltip, b.entry, b.m, b.f, heading)
  end
  if price then
    local missing = price.missing
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
