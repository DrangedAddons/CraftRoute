-- Talking to a trainer or a vendor: skip the chat page and open its training / goods list.
-- Picks the NPC's one trainer or vendor option when nothing else needs a choice: no quests to
-- take or hand in, and no other service (inn, flight, bank, unlearn...). Plain chat options are
-- passed over. Hold Shift while talking to see the chat page. Setting: autoGossip (on unless false).
local _, CR = ...

-- Gossip icons (fileIDs) and the older type names
local TRAINER_ICON, VENDOR_ICON, CHAT_ICON = 132058, 132060, 132053
local SERVICE = { trainer = "trainer", vendor = "vendor", gossip = "chat" }

local function Kind(o)
  if o.type and SERVICE[o.type] then return SERVICE[o.type] end
  if o.icon == TRAINER_ICON then return "trainer" end
  if o.icon == VENDOR_ICON then return "vendor" end
  if o.icon == CHAT_ICON or o.icon == nil then return "chat" end
  return "other"
end

local picked   -- one pick per conversation (going back to the chat page doesn't loop)

local function OnShow()
  if picked or (CraftRouteCharDB and CraftRouteCharDB.autoGossip == false) then return end
  if IsShiftKeyDown and IsShiftKeyDown() then return end
  local G = C_GossipInfo
  if not (G and G.GetOptions) then return end
  if G.GetNumAvailableQuests and G.GetNumAvailableQuests() > 0 then return end
  for _, q in ipairs(G.GetActiveQuests and G.GetActiveQuests() or {}) do
    if q.isComplete then return end
  end
  local hit
  for _, o in ipairs(G.GetOptions() or {}) do
    local k = Kind(o)
    if k == "trainer" or k == "vendor" then
      if hit then return end   -- both, or two of them: let the player choose
      hit = o
    elseif k ~= "chat" then
      return                   -- an inn, flight path, bank, unlearn...: the player chooses
    end
  end
  if not hit then return end
  if hit.status and Enum and Enum.GossipOptionStatus and hit.status ~= Enum.GossipOptionStatus.Available then return end
  picked = true
  if hit.gossipOptionID and G.SelectOption then
    G.SelectOption(hit.gossipOptionID)
  elseif hit.orderIndex and G.SelectOptionByIndex then
    G.SelectOptionByIndex(hit.orderIndex)
  end
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "GOSSIP_SHOW", "GOSSIP_CLOSED" }) do pcall(f.RegisterEvent, f, e) end
f:SetScript("OnEvent", function(_, event)
  if event == "GOSSIP_CLOSED" then picked = nil return end
  CR.SafeCall(OnShow)
end)
