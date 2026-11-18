-- Talking to a trainer or a vendor: skip the chat page and open its training / goods list.
-- Only when that is the NPC's one and only option: no other choice (most trainers also offer
-- chat lines, unlearning, a second service...), and no quests to take or hand in. Hold Shift while
-- talking to see the chat page. Setting: autoGossip (on unless false). When EllesmereUI's "Auto
-- Select Single Gossip" is on, that does the job and this stays out of the way.
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

-- EllesmereUI's QoL "Auto Select Single Gossip" (EllesmereUIDB.autoGossip)
function CR.EllesmereGossip()
  return type(EllesmereUIDB) == "table" and EllesmereUIDB.autoGossip and true or false
end

local picked   -- one pick per conversation (going back to the chat page doesn't loop)

local function OnShow()
  if picked or (CraftRouteCharDB and CraftRouteCharDB.autoGossip == false) or CR.EllesmereGossip() then return end
  if IsShiftKeyDown and IsShiftKeyDown() then return end
  local G = C_GossipInfo
  if not (G and G.GetOptions) then return end
  if G.GetNumAvailableQuests and G.GetNumAvailableQuests() > 0 then return end
  for _, q in ipairs(G.GetActiveQuests and G.GetActiveQuests() or {}) do
    if q.isComplete then return end
  end
  local options = G.GetOptions() or {}
  if #options ~= 1 then return end   -- more than one choice: the player picks
  local hit = options[1]
  local k = Kind(hit)
  if k ~= "trainer" and k ~= "vendor" then return end
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
