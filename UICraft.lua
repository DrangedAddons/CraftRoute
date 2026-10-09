-- Craft tab: the one place to live once the route is planned. Shows the recipe the plan says to
-- craft now (big, with its reagents and Create buttons) and a preview of the next one.
-- Crafting goes through the game's own profession API, which needs the profession window open;
-- the tab offers a button to open it.
local _, CR = ...
local GetItemIcon, GetItemCount, GetItemInfo = CR.GetItemIcon, CR.GetItemCount, CR.GetItemInfo

local CRAFT_KINDS = { craft = true, extra = true, target = true }

---------------------------------------------------------------------------
-- Profession window / crafting API (retail-style C_TradeSkillUI, Classic fallback)
---------------------------------------------------------------------------
-- Looked up on use, so it's never stale if the profession API loads after us.
local TS = setmetatable({}, { __index = function(_, k) return C_TradeSkillUI and C_TradeSkillUI[k] end })

-- Is this profession's window open and ready, so recipes can be crafted?
function CR.TradeSkillOpenFor(profName)
  if TS.GetBaseProfessionInfo and TS.IsTradeSkillReady then
    local info = TS.GetBaseProfessionInfo()
    local name = info and (info.professionName or info.parentProfessionName)
    if profName == "Mining" and name == "Smelting" then name = "Mining" end   -- the smelting window
    return name == profName and TS.IsTradeSkillReady() and true or false
  end
  if GetTradeSkillLine then return GetTradeSkillLine() == profName end
  return false
end

-- Opening a profession window. The game only lets a real click do it (OpenTradeSkill is
-- protected - calling it from addon code is blocked), so CraftRoute's Open buttons and its
-- profession pickers are covered by secure buttons that cast the profession as part of your
-- click, like typing /cast Leatherworking. OpenProfessionMacro gives that macro (nil if there's
-- nothing to open: not learned, already open, or no crafting window, like Fishing).
local CAST_NAME = { Mining = "Smelting" }   -- the spell that opens the window, if not the name
function CR.OpenProfessionMacro(profName)
  local route = profName and CR.Route(profName)
  profName = route and route.recipeProf or profName
  if not profName or profName == "Fishing" then return nil end
  local _, _, learned = CR.GetSkill(profName)
  if not learned or CR.TradeSkillOpenFor(profName) then return nil end
  return "/cast " .. (CAST_NAME[profName] or profName)
end

-- Reached only when a click didn't go through a secure cover (e.g. in combat).
function CR.OpenTradeSkill(profName)
  if InCombatLockdown() then CR.Print("Can't open professions in combat.") return end
  CR.Print("Open " .. profName .. " with its Open button or from your profession book.")
end

-- Learned? and how many can be made from what's in your bags right now.
local function RecipeState(prof, r)
  local learned, available
  if TS.GetRecipeInfo and CR.TradeSkillOpenFor(prof.name) then
    local ok, info = pcall(TS.GetRecipeInfo, r.spell)
    if ok and info then learned, available = info.learned, info.numAvailable end
  end
  if learned == nil then learned = CR.ProfTable("known", prof.name)[r.spell] or nil end
  if available == nil then
    available = math.huge
    for _, rg in ipairs(r.reagents) do
      available = math.min(available, math.floor((GetItemCount(rg[1], false) or 0) / rg[2]))
    end
    if available == math.huge then available = 0 end
  end
  return learned, available
end

local function Craft(r, count)
  if InCombatLockdown() then CR.Print("Can't craft in combat.") return end
  if TS.CraftRecipe then
    local ok, err = pcall(TS.CraftRecipe, r.spell, count)
    if not ok then CR.Print("|cffff4040Couldn't craft:|r " .. tostring(err)) end
  elseif DoTradeSkill and GetNumTradeSkills then
    for i = 1, GetNumTradeSkills() do
      local link = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i)
      if link and tonumber(link:match("enchant:(%d+)")) == r.spell then DoTradeSkill(i, count) return end
    end
    CR.Print("Couldn't find " .. r.name .. " in the profession window.")
  end
end

local function IsRepeating()
  return TS.IsRecipeRepeating and TS.IsRecipeRepeating() or false
end

---------------------------------------------------------------------------
-- Enchanting: a target item for "Enchant <slot> - ..." recipes, so you can enchant the same
-- item over and over while levelling.
---------------------------------------------------------------------------
-- Which kinds of gear each enchant goes on (by the part of its name before " - ").
local WEAPONS = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true }
local ENCHANT_SLOTS = {
  ["2H Weapon"] = { INVTYPE_2HWEAPON = true },
  ["Weapon"]    = WEAPONS,
  ["Bracer"]    = { INVTYPE_WRIST = true },
  ["Boots"]     = { INVTYPE_FEET = true },
  ["Gloves"]    = { INVTYPE_HAND = true },
  ["Chest"]     = { INVTYPE_CHEST = true, INVTYPE_ROBE = true },
  ["Cloak"]     = { INVTYPE_CLOAK = true },
  ["Shield"]    = { INVTYPE_SHIELD = true },
  ["Off-Hand"]  = { INVTYPE_HOLDABLE = true },
  ["Necklace"]  = { INVTYPE_NECK = true },
}
-- The gear kinds this recipe enchants (nil if it isn't an item enchant), and its slot word.
function CR.EnchantSlotFor(r)
  local kind = r and r.name:match("^Enchant (.-) %- ")
  return kind and ENCHANT_SLOTS[kind], kind
end

local function EquipLoc(itemID)
  local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not f or not itemID then return nil end
  return select(4, f(itemID))
end

local function HasEnchant(link)
  local e = link and link:match("item:%-?%d+:(%-?%d*)")
  return (tonumber(e) or 0) > 0
end

local function NumBagSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

-- itemID, link, bound? of a bag slot
local function BagItem(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then return nil end
    local bound = info.isBound
    if bound == nil and C_Item and C_Item.IsBound and ItemLocation then
      local ok, b = pcall(C_Item.IsBound, ItemLocation:CreateFromBagAndSlot(bag, slot))
      bound = ok and b or false
    end
    return info.itemID, info.hyperlink or (C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot)), bound
  end
end

-- Gear you could put this enchant on: what you're wearing and what's in your bags (never the
-- bank or alts). Bag items and unenchanted ones first, so your worn gear is the last resort.
-- Unbound items are fine; enchanting one binds it, and the game asks you about that itself.
function CR.EnchantCandidates(fits)
  local list = {}
  if not fits then return list end
  for slot = 1, 19 do
    local id = GetInventoryItemID and GetInventoryItemID("player", slot)
    if id and fits[EquipLoc(id) or ""] then
      local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
      table.insert(list, { equipSlot = slot, itemID = id, link = link, enchanted = HasEnchant(link) })
    end
  end
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, NumBagSlots(bag) do
      local id, link, bound = BagItem(bag, slot)
      if id and fits[EquipLoc(id) or ""] then
        table.insert(list, { bag = bag, slot = slot, itemID = id, link = link, enchanted = HasEnchant(link), unbound = bound == false })
      end
    end
  end
  table.sort(list, function(a, b)
    if (a.equipSlot ~= nil) ~= (b.equipSlot ~= nil) then return a.equipSlot == nil end
    if a.enchanted ~= b.enchanted then return not a.enchanted end
    return (a.bag or 0) * 100 + (a.slot or a.equipSlot) < (b.bag or 0) * 100 + (b.slot or b.equipSlot)
  end)
  return list
end

-- Is the target still where we left it? If it moved, find it again by item.
local function ResolveTarget(t, fits)
  if not t then return nil end
  for _, c in ipairs(CR.EnchantCandidates(fits)) do
    if c.itemID == t.itemID and c.equipSlot == t.equipSlot and c.bag == t.bag and c.slot == t.slot then return c end
  end
  for _, c in ipairs(CR.EnchantCandidates(fits)) do
    if c.itemID == t.itemID then return c end
  end
end

-- "Replace the existing enchant?" - answered Yes for you, for casts you start from the Craft tab.
-- The game ignores an addon pressing the dialog's Yes button, even during your click: only a
-- real click or a macro /click counts. So the target slot and the Enchant button are covered by
-- secure buttons (see SecureEnchantButton) that run "/click StaticPopupNButton1" as part of your
-- click, exactly like the classic enchanting macro:
--   * if the question comes straight back while the enchant is cast, that same click answers it;
--   * if it arrives a moment later, your next click answers it instead of casting again (the
--     status line says so).
-- Binding questions (enchanting an unbound item) are never answered for you.
local REPLACE_PREFIX = type(REPLACE_ENCHANT) == "string" and REPLACE_ENCHANT:match("^(.-)%%s") or nil

local function DialogText(d)
  local fs = d.text or d.Text or (d.GetName and d:GetName() and _G[d:GetName() .. "Text"])
  return fs and fs.GetText and fs:GetText() or nil
end

local function IsReplaceDialog(d)
  local which = d.which
  if type(which) == "string" then
    -- REPLACE_ENCHANT (Classic) or REPLACE_TRADESKILL_ENCHANT (Forever); never TRADE_REPLACE_ENCHANT,
    -- which is about an item in the trade window
    return which:find("^REPLACE_") and which:find("ENCHANT$") and true or false
  end
  local text = DialogText(d)   -- no "which": recognise it by its wording
  return REPLACE_PREFIX and REPLACE_PREFIX ~= "" and text and text:find(REPLACE_PREFIX, 1, true) == 1 or false
end

-- The replace-enchant dialog if one is up, and the name of its Yes button (for /click).
function CR.VisibleReplacePopup()
  for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
    local d = _G["StaticPopup" .. i]
    if d and d:IsShown() and IsReplaceDialog(d) then
      local b = (d.GetButton1 and d:GetButton1()) or d.button1 or (d.ButtonContainer and d.ButtonContainer.Button1)
      local name = (b and b.GetName and b:GetName()) or ("StaticPopup" .. i .. "Button1")
      return d, name
    end
  end
end

-- /cr popup: what dialogs are up (for working out a prompt that isn't being answered).
function CR.DebugPopups()
  local any
  for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
    local d = _G["StaticPopup" .. i]
    if d and d:IsShown() then
      any = true
      CR.Print(string.format("StaticPopup%d: which=%s replace=%s text=%s", i, tostring(d.which),
        tostring(IsReplaceDialog(d)), tostring(DialogText(d))))
    end
  end
  if not any then CR.Print("No dialogs are showing.") end
end

-- Cast the enchant on the target (one cast per click).
local function EnchantTarget(r, t)
  if InCombatLockdown() then CR.Print("Can't enchant in combat.") return end
  CR.enchantPendingUntil = GetTime() + 60
  local loc = ItemLocation and (t.equipSlot and ItemLocation:CreateFromEquipmentSlot(t.equipSlot)
    or ItemLocation:CreateFromBagAndSlot(t.bag, t.slot))
  local cast = false
  if TS.CraftEnchant and loc then cast = pcall(TS.CraftEnchant, r.spell, 1, nil, loc) end
  if not cast then Craft(r, 1) end
  -- Classic-style: the enchant waits for a target - hand it the item.
  if SpellIsTargeting and SpellIsTargeting() then
    if t.equipSlot then
      PickupInventoryItem(t.equipSlot)
    elseif C_Container and C_Container.PickupContainerItem then
      C_Container.PickupContainerItem(t.bag, t.slot)
    elseif PickupContainerItem then
      PickupContainerItem(t.bag, t.slot)
    end
    if CursorHasItem and CursorHasItem() then ClearCursor() end   -- never leave it on the cursor
  end
end

-- One click on the target / Enchant. Returns the macro the secure button then runs: a /click
-- on the replace dialog's Yes button when there's one to answer, else nothing.
local function EnchantClick(r, t, canCast)
  local _, yes = CR.VisibleReplacePopup()
  local ours = CR.enchantPendingUntil and GetTime() < CR.enchantPendingUntil
  if yes and ours then   -- the last cast is waiting on the question: this click answers it
    CR.enchantPendingUntil = nil
    return "/click " .. yes
  end
  if not (r and t and canCast) then return "" end
  EnchantTarget(r, t)
  _, yes = CR.VisibleReplacePopup()   -- asked straight away? answer it in this same click
  if yes then
    CR.enchantPendingUntil = nil
    return "/click " .. yes
  end
  return ""
end

CR.EnchantClick = EnchantClick   -- also used by Compact.lua's covers in the profession window

-- A secure button laid over `target` (the slot, the Enchant button) - only secure code may answer
-- the dialog. It sits on UIParent so CraftRoute's window can still close in combat; it's hidden
-- whenever it isn't wanted, and always when combat starts. onClick(button) returns the macro.
-- The game won't let a secure button be anchored to an addon's frame, so it's placed by screen
-- position instead (anchored to UIParent) and kept lined up as the window moves or resizes.
local secureButtons = {}

-- Put b exactly over target. False if target has no position yet.
local function PlaceOver(b, target)
  local l, btm, w, h = target:GetLeft(), target:GetBottom(), target:GetWidth(), target:GetHeight()
  if not (l and btm and w and h) then return false end
  local scale = target:GetEffectiveScale() / UIParent:GetEffectiveScale()
  local x, y = l * scale, btm * scale
  if b.placed ~= x .. "," .. y .. "," .. w * scale .. "," .. h * scale then
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    b:SetSize(w * scale, h * scale)
    b.placed = x .. "," .. y .. "," .. w * scale .. "," .. h * scale
  end
  return true
end

-- opts.wanted(): show the cover only when this is true (default: while enchanting).
-- opts.plain: the macro is just onClick()'s result, run once per click (down or up, as the game
-- acts) - for
-- using an item (splitting / combining essences); no replace-dialog handling.
local function SecureEnchantButton(target, onClick, opts)
  opts = opts or {}
  local b = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
  b:SetSize(1, 1)
  b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
  -- follow the target while shown (window dragged / resized); never touched in combat
  b:SetScript("OnUpdate", function(self)
    if InCombatLockdown() then return end
    if not target:IsVisible() then self:Hide() return end
    PlaceOver(self, target)
  end)
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "macro")
  b:SetAttribute("macrotext", "")
  b:Hide()
  -- A mouse click reaches this twice (button down, then up), and which of the two runs the
  -- macro depends on the client. So: the first press of a click does the work (casts) and sets
  -- the macro; the second press keeps the /click only if the dialog is still up, i.e. the first
  -- press wasn't the one that ran it. Either way the dialog is answered exactly once.
  b:SetScript("PreClick", function(self, button, down)
    if InCombatLockdown() then return end
    if opts.plain then
      -- run once per click, on the half the game acts on: press-down when "cast on key down"
      -- (ActionButtonUseKeyDown, on by default) is set, else the release
      local onDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false
      local act = (down and true or false) == (onDown and true or false)
      self:SetAttribute("macrotext", act and (onClick(button) or "") or "")
      return
    end
    if down or not self.downSeen then
      self.downSeen = down and true or false
      self.answer = onClick(button) or ""
      self:SetAttribute("macrotext", self.answer)
    else
      -- up: answer the dialog if it's (still) up - including one that arrived while the button
      -- was held, from the cast this click just made
      self.downSeen = false
      local _, yes = CR.VisibleReplacePopup()
      local ours = self.answer ~= "" or (CR.enchantPendingUntil and GetTime() < CR.enchantPendingUntil)
      self:SetAttribute("macrotext", (yes and ours) and ("/click " .. yes) or "")
      if yes and ours then CR.enchantPendingUntil = nil end
      self.answer = nil
    end
  end)
  b:SetScript("OnEnter", function() local f = target:GetScript("OnEnter") if f then f(target) end end)
  b:SetScript("OnLeave", function() local f = target:GetScript("OnLeave") if f then f(target) end end)
  b.target = target
  b.wanted = opts.wanted
  table.insert(secureButtons, b)
  return b
end

-- Show each secure button only while its target is visible and it's wanted - by default while
-- enchanting (out of combat).
local lastEnchanting = false
local function SyncSecureButtons(enchanting)
  if enchanting ~= nil then lastEnchanting = enchanting end
  if InCombatLockdown() or CR.inCombat then return end
  for _, b in ipairs(secureButtons) do
    local want
    if b.wanted then want = b.wanted() else want = lastEnchanting end
    local show = want and b.target:IsVisible() and b.target:IsEnabled() ~= false and PlaceOver(b, b.target)
    if show then
      b:SetFrameStrata(b.target:GetFrameStrata())
      b:SetFrameLevel(b.target:GetFrameLevel() + 5)
    end
    b:SetShown(show and true or false)
  end
end

-- For other windows' covers (the dropdown menus): show / place them now.
function CR.SyncSecureCovers() SyncSecureButtons() end
-- A secure cover over `target` that runs onClick()'s macro once per click (see SecureEnchantButton).
function CR.SecureCover(target, onClick, wanted)
  return SecureEnchantButton(target, onClick, { plain = true, wanted = wanted })
end

function CR.HideSecureEnchantButtons()
  if InCombatLockdown() then return end
  for _, b in ipairs(secureButtons) do b:Hide() end
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function QualityRGB(q)
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

-- An icon with a 2px quality-coloured border; hover shows the item (or recipe) tooltip.
local function IconButton(parent, size)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(size, size)
  b:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 2, -2)
  b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(b.icon)
  hl:SetColorTexture(1, 1, 1, 0.15)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.recipe then
      CR.RecipeTooltip(GameTooltip, self.recipe, self.crafts)
    elseif self.itemID then
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Where you have it:", 1, 0.82, 0)
      CR.AddLocationLines(GameTooltip, self.itemID)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

-- One reagent line: icon, "have/need Name", and (when you can make the reagent yourself) a
-- +/- toggle. Clicking the line or the toggle opens it up to show how to make it.
local function ReagentRow(parent, iconSize, font)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(240, iconSize + 4)
  row.btn = IconButton(row, iconSize)
  row.btn:SetPoint("LEFT", 0, 0)
  row.hl = row:CreateTexture(nil, "BACKGROUND")
  row.hl:SetAllPoints()
  row.hl:SetColorTexture(1, 1, 1, 0.08)
  row.hl:Hide()
  row.make = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.make:SetSize(22, 20)
  row.make:SetPoint("RIGHT", -2, 0)
  row.make:SetText("+")
  row.make:Hide()
  CR.ThemeRegisterButton(row.make)
  row.buy = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.buy:SetSize(42, 20)
  row.buy:SetText("Buy")
  row.buy:Hide()
  CR.ThemeRegisterButton(row.buy)
  row.text = row:CreateFontString(nil, "OVERLAY", font)
  row.text:SetPoint("LEFT", row.btn, "RIGHT", 8, 0)
  row.text:SetPoint("RIGHT", 0, 0)
  row.text:SetJustifyH("LEFT")
  local function Click() if row.onMake then row.onMake() end end
  row:SetScript("OnClick", Click)
  row.make:SetScript("OnClick", Click)
  row:SetScript("OnEnter", function(self)
    if not self.onMake then return end
    self.hl:Show()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(CR.ItemName(self.btn.itemID), 1, 0.82, 0)
    GameTooltip:AddLine(self.expanded and "Click to hide how to make it."
      or "You can make this yourself - click to show its components and craft it here.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function(self) self.hl:Hide() GameTooltip_Hide() end)
  return row
end

-- A scrolling area inside a reagent box: rows go on `content`; Fit() caps the visible height
-- and shows a slim scroll bar (mouse wheel or drag) when they don't all fit.
local function ScrollArea(box, left, top, width)
  local sf = CreateFrame("ScrollFrame", nil, box)
  sf:SetPoint("TOPLEFT", left, top)
  sf:SetSize(width, 40)
  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(width, 40)
  sf:SetScrollChild(content)
  local track = CreateFrame("Frame", nil, box, "BackdropTemplate")
  track:SetWidth(5)
  track:SetPoint("TOPRIGHT", box, "TOPRIGHT", -3, top)
  track:SetPoint("BOTTOM", sf, "BOTTOM", 0, 0)
  CR.Backdrop(track, 0.1, 0.1, 0.1, 0.8)
  track.crOwnBorder = true
  local thumb = track:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0.6, 0.6, 0.6, 0.9)
  thumb:SetWidth(5)
  sf.contentH, sf.visibleH = 40, 40
  local function MaxScroll() return math.max(0, sf.contentH - sf.visibleH) end
  function sf:UpdateThumb()
    local max = MaxScroll()
    track:SetShown(max > 0)
    if max <= 0 then return end
    local th = self.visibleH
    local h = math.max(12, th * self.visibleH / self.contentH)
    thumb:SetHeight(h)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -(th - h) * (self:GetVerticalScroll() / max))
  end
  function sf:ScrollTo(v)
    self:SetVerticalScroll(math.max(0, math.min(MaxScroll(), v)))
    self:UpdateThumb()
  end
  -- contentH: everything; maxH: the most to show. Returns the height shown.
  function sf:Fit(contentH, maxH)
    self.contentH = contentH
    self.visibleH = math.max(1, math.min(contentH, maxH))
    content:SetHeight(contentH)
    self:SetHeight(self.visibleH)
    self:ScrollTo(self:GetVerticalScroll() or 0)
    return self.visibleH
  end
  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function(self, delta) self:ScrollTo((self:GetVerticalScroll() or 0) - delta * 30) end)
  local function FromCursor()
    local _, y = GetCursorPosition()
    y = y / track:GetEffectiveScale()
    local frac = (track:GetTop() - y) / track:GetHeight()
    sf:ScrollTo(frac * MaxScroll())
  end
  track:EnableMouse(true)
  track:SetScript("OnMouseDown", function(self) FromCursor() self:SetScript("OnUpdate", FromCursor) end)
  track:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
  track:Hide()
  return sf, content
end

-- How tall a reagent box may be: down to just above the cast bar (keeping `reserve` free for
-- the text under it), at least `minH`. Before layout has happened, `fallback`.
local function RoomBelow(box, floorFrame, reserve, minH, fallback)
  local top, bottom = box:GetTop(), floorFrame:GetTop()
  if type(top) ~= "number" or type(bottom) ~= "number" or top <= bottom then return fallback end
  return math.max(minH, top - bottom - reserve)
end

-- How many of an item are in your bags (craftable now) and how many are elsewhere: your bank,
-- mailbox, or alts (via Syndicator) - you have them, they're just not on hand.
function CR.BagsAndElsewhere(itemID)
  local bags = GetItemCount(itemID, false) or 0
  local _, total = CR.GetLocations(itemID)
  return bags, math.max(0, (total or 0) - bags)
end

-- Colour for "have/need" (need = the whole step, perCraft = one craft):
-- green = the whole step is in your bags; yellow = not the whole step, but at least one craft
-- (counting the bank / mail / alts); red = not even one craft anywhere.
function CR.ReagentColor(bags, elsewhere, need, perCraft)
  if bags >= need then return "40ff40" end
  if bags + elsewhere >= (perCraft or need) then return "ffd100" end
  return "ff6060"
end

-- Components you can make yourself without a trade skill recipe: enchanting essences combine
-- (3 lesser -> 1 greater) and split (1 greater -> 3 lesser) by using the item.
-- [wanted item] = { use = item to use, uses = how many it takes, makes = how many you get }
local CONVERSIONS = {}
for _, pair in ipairs({ { 10938, 10939 }, { 10998, 11082 }, { 11134, 11135 },
                        { 11174, 11175 }, { 16202, 16203 } }) do
  local lesser, greater = pair[1], pair[2]
  CONVERSIONS[greater] = { use = lesser, uses = 3, makes = 1 }
  CONVERSIONS[lesser] = { use = greater, uses = 1, makes = 3 }
end

-- How this profession can make an item: a recipe, or an item-use conversion. nil if it can't.
-- How this character can make an item, from any profession it has:
--   1. the current profession's own recipe;
--   2. another crafting profession this character has learned (a blacksmith with Leatherworking
--      makes Thick Leather from Heavy; with Mining, smelts bars - only bars, from Mining);
--   3. enchanting essences, which combine / split by using the item.
-- how.prof is set when the recipe belongs to another profession (its window has to be open to
-- craft it). nil if the character can't make it at all.
local function OtherMaker(itemID, current)
  local best
  for name, p in pairs(CR.professions) do
    local spell = name ~= current and p.byItem[itemID]
    local r = spell and p.recipes[spell]
    if r and (name ~= "Mining" or r.cat == "Smelted Bars") then
      local skill, _, learned = CR.GetSkill(name)
      if learned then
        -- prefer one you have the skill for, then the lowest recipe
        local ok = (skill or 0) >= (r.learn or 1)
        if not best or (ok and not best.ok) or (ok == best.ok and (r.learn or 1) < (best.recipe.learn or 1)) then
          best = { recipe = r, prof = p, ok = ok }
        end
      end
    end
  end
  return best
end

function CR.ComponentMaker(prof, itemID)
  local spell = prof and prof.byItem[itemID]
  if spell and prof.recipes[spell] then return { recipe = prof.recipes[spell] } end
  local other = OtherMaker(itemID, prof and prof.name)
  if other then return { recipe = other.recipe, prof = other.prof } end
  if CONVERSIONS[itemID] then return { convert = CONVERSIONS[itemID] } end
end

---------------------------------------------------------------------------
-- Vendor: when a merchant window is open, reagents it sells get a Buy button.
---------------------------------------------------------------------------
local merchantOpen, merchantIndex = false, {}   -- [itemID] = merchant slot

-- price (for one purchase), how many one purchase gives, how many are left (-1 = unlimited)
local function MerchantSlotInfo(i)
  if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
    local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
    if ok and info then return info.price, info.stackCount, info.numAvailable, info.hasExtendedCost end
  end
  if GetMerchantItemInfo then
    local _, _, price, quantity, numAvailable, _, _, extendedCost = GetMerchantItemInfo(i)
    return price, quantity, numAvailable, extendedCost
  end
end

local function ScanMerchant()
  wipe(merchantIndex)
  if not merchantOpen or not GetMerchantNumItems or not GetMerchantItemID then return end
  for i = 1, GetMerchantNumItems() do
    local id = GetMerchantItemID(i)
    local price, _, _, extended = MerchantSlotInfo(i)
    if id and price and price > 0 and not extended then merchantIndex[id] = i end   -- gold only
  end
end

function CR.MerchantSells(itemID) return merchantOpen and merchantIndex[itemID] or nil end

-- What buying `count` would actually get you: purchases, items, cost (capped by stock and gold).
local function BuyPlan(itemID, count)
  local i = merchantIndex[itemID]
  if not i or count <= 0 then return 0, 0, 0 end
  local price, batch, avail = MerchantSlotInfo(i)
  batch = math.max(1, batch or 1)
  local purchases = math.ceil(count / batch)
  if avail and avail >= 0 then purchases = math.min(purchases, avail) end
  if price and price > 0 then purchases = math.min(purchases, math.floor((GetMoney and GetMoney() or 0) / price)) end
  return purchases, purchases * batch, purchases * (price or 0)
end

local function BuyFromMerchant(itemID, count)
  local i = merchantIndex[itemID]
  local purchases = BuyPlan(itemID, count)
  if not i or purchases <= 0 then return end
  local _, batch = MerchantSlotInfo(i)
  if (batch or 1) > 1 then
    for _ = 1, purchases do BuyMerchantItem(i) end   -- sold in bundles: one call per bundle
  else
    local maxStack = math.max(1, GetMerchantItemMaxStack and GetMerchantItemMaxStack(i) or 1)
    local left = purchases
    while left > 0 do
      local n = math.min(left, maxStack)
      BuyMerchantItem(i, n)
      left = left - n
    end
  end
end

-- opts.perCraft: colour by one craft rather than the step total (the current recipe).
-- opts.onBuy(itemID, short, button): offer "Buy" for reagents the open vendor sells.
-- opts.prof + opts.onMake(itemID): offer the +/- toggle for reagents you're short of in your
-- bags and can make yourself; opts.expanded is the one that's open.
local function FillReagents(box, rows, r, crafts, opts)
  opts = opts or {}
  for i, row in ipairs(rows) do
    local rg = r and r.reagents[i]
    if rg then
      local bags, elsewhere = CR.BagsAndElsewhere(rg[1])
      local need = rg[2] * crafts
      row.btn.itemID = rg[1]
      row.btn.icon:SetTexture(GetItemIcon(rg[1]))
      local q = select(3, GetItemInfo(rg[1])) or 1
      row.btn:SetBackdropBorderColor(QualityRGB(q))
      local color = CR.ReagentColor(bags, elsewhere, need, opts.perCraft and rg[2] or nil)
      local have = bags >= need and bags or (bags + elsewhere)
      row.text:SetText(CR.ColorText(string.format("%d/%d", have, need), color) .. "  " .. CR.ItemName(rg[1]))
      local id = rg[1]
      local open = opts.expanded == id
      local short = bags < (opts.needMult and rg[2] * opts.needMult or need)
      local canMake = opts.onMake and (short or open) and not (opts.exclude and opts.exclude[id])
        and CR.ComponentMaker(opts.prof, id)
      row.onMake = canMake and function() opts.onMake(id) end or nil
      row.expanded = open
      row.make:SetText(open and "-" or "+")
      row.make:SetShown(canMake and true or false)
      -- "Buy" when the open vendor sells it and your bags are short
      local canBuy = opts.onBuy and bags < need and CR.MerchantSells(id)
      row.buy:ClearAllPoints()
      row.buy:SetPoint("RIGHT", canMake and -28 or -2, 0)
      row.buy:SetShown(canBuy and true or false)
      row.buy:SetScript("OnClick", canBuy and function(self) opts.onBuy(id, need - bags, self) end or nil)
      row.text:SetPoint("RIGHT", -((canMake and 28 or 0) + (canBuy and 46 or 0)), 0)
      row:Show()
    else
      row.onMake = nil
      row:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- Buy popup (shared by the Craft tab and the profession-window view): opened from a reagent's
-- Buy button while a vendor is open - buy one, the amount still needed in your bags, or any
-- amount. It sits on UIParent so it shows over whichever window opened it.
---------------------------------------------------------------------------
local buyPop, bp
local function UpdateBuyPop()
  local id = buyPop and buyPop.itemID
  if not id or not CR.MerchantSells(id) then if buyPop then buyPop:Hide() end return end
  local price, batch = MerchantSlotInfo(merchantIndex[id])
  bp.title:SetText("Buy " .. CR.ItemName(id))
  bp.price:SetText(CR.FormatMoney(price or 0) .. ((batch or 1) > 1 and string.format(" per %d", batch) or " each"))
  local _, items, needCost = BuyPlan(id, buyPop.need)
  bp.need:SetText(items > 0 and string.format("Buy needed (%d)", items) or "Buy needed")
  bp.need:SetEnabled(items > 0)
  bp.needCost:SetText(items > 0 and CR.FormatMoney(needCost)
    or CR.ColorText(buyPop.need > 0 and "Can't afford" or "Nothing needed", buyPop.need > 0 and "ff6060" or "40ff40"))
  bp.one:SetEnabled((BuyPlan(id, 1)) > 0)
  local n = math.max(1, bp.box:GetNumber() or 1)
  local _, boxItems, boxCost = BuyPlan(id, n)
  bp.buy:SetText("Buy " .. boxItems)
  bp.buy:SetEnabled(boxItems > 0)
  bp.total:SetText(boxItems > 0 and ("Total: " .. CR.FormatMoney(boxCost)) or CR.ColorText("Can't afford", "ff6060"))
end

local function BuildBuyPop()
  buyPop = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  buyPop:SetSize(236, 150)
  buyPop:SetFrameStrata("DIALOG")
  CR.Backdrop(buyPop, 0.04, 0.04, 0.06, 0.97)
  CR.ThemeRegisterBorder(buyPop)
  buyPop:EnableMouse(true)
  buyPop:Hide()
  bp = {}
  bp.title = buyPop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  bp.title:SetPoint("TOPLEFT", 10, -10)
  bp.title:SetPoint("RIGHT", -10, 0)
  bp.title:SetJustifyH("LEFT")
  CR.ThemeRegisterAccentText(bp.title)
  bp.price = buyPop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bp.price:SetPoint("TOPLEFT", bp.title, "BOTTOMLEFT", 0, -3)
  local function PopButton(w, text)
    local b = CreateFrame("Button", nil, buyPop, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    if text then b:SetText(text) end
    CR.ThemeRegisterButton(b)
    return b
  end
  bp.one = PopButton(64, "Buy 1")
  bp.one:SetPoint("TOPLEFT", 10, -60)
  bp.need = PopButton(144)
  bp.need:SetPoint("LEFT", bp.one, "RIGHT", 8, 0)
  bp.needCost = buyPop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- what "Buy needed" costs
  bp.needCost:SetPoint("BOTTOM", bp.need, "TOP", 0, 3)
  bp.box = CreateFrame("EditBox", nil, buyPop, "InputBoxTemplate")
  bp.box:SetSize(44, 20)
  bp.box:SetPoint("TOPLEFT", 40, -94)
  bp.box:SetAutoFocus(false)
  bp.box:SetNumeric(true)
  bp.box:SetMaxLetters(4)
  bp.box:SetJustifyH("CENTER")
  local function BpStep(dir)
    local b = CreateFrame("Button", nil, buyPop)
    b:SetSize(22, 22)
    local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnClick", function() bp.box:SetNumber(math.max(1, (bp.box:GetNumber() or 1) + dir)) end)
    return b
  end
  BpStep(-1):SetPoint("RIGHT", bp.box, "LEFT", -6, 0)
  BpStep(1):SetPoint("LEFT", bp.box, "RIGHT", 2, 0)
  bp.buy = PopButton(92)
  bp.buy:SetPoint("LEFT", bp.box, "RIGHT", 30, 0)
  bp.cancel = PopButton(80, "Cancel")
  bp.cancel:SetPoint("BOTTOMRIGHT", -10, 8)
  bp.total = buyPop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bp.total:SetPoint("BOTTOMLEFT", 10, 13)
  bp.box:SetScript("OnTextChanged", UpdateBuyPop)
  bp.box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  bp.box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  bp.one:SetScript("OnClick", function() BuyFromMerchant(buyPop.itemID, 1) end)
  bp.need:SetScript("OnClick", function() BuyFromMerchant(buyPop.itemID, buyPop.need) buyPop:Hide() end)
  bp.buy:SetScript("OnClick", function() BuyFromMerchant(buyPop.itemID, math.max(1, bp.box:GetNumber() or 1)) buyPop:Hide() end)
  bp.cancel:SetScript("OnClick", function() buyPop:Hide() end)
end

-- Open the buy box for itemID next to `anchor`. short: how many more you need in your bags.
-- needFn(itemID) recomputes that as bags change (nil = the recipe moved on: close).
-- owner: who opened it, so closing that window closes the box (CR.HideBuyPop(owner)).
function CR.OpenBuy(itemID, short, anchor, needFn, owner)
  if not buyPop then BuildBuyPop() end
  if buyPop:IsShown() and buyPop.itemID == itemID then buyPop:Hide() return end
  buyPop.itemID, buyPop.need, buyPop.needFn, buyPop.owner = itemID, short, needFn, owner
  buyPop:ClearAllPoints()
  buyPop:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
  bp.box:SetNumber(1)   -- "Buy needed" covers the usual case; a stray click here buys just one
  buyPop:Show()
  UpdateBuyPop()
end

-- Keep the open buy box in step with your bags (and close it if its item no longer applies).
function CR.RefreshBuyPop()
  if not (buyPop and buyPop:IsShown()) then return end
  if buyPop.needFn then
    local need = buyPop.needFn(buyPop.itemID)
    if not need then buyPop:Hide() return end
    buyPop.need = need
  end
  UpdateBuyPop()
end

function CR.HideBuyPop(owner)
  if buyPop and (owner == nil or buyPop.owner == owner) then buyPop:Hide() end
end

---------------------------------------------------------------------------
-- Components, for views outside the Craft tab (the profession-window view): how this
-- character makes itemID when `need` of it is wanted, and what one click would do.
---------------------------------------------------------------------------
CR.RecipeState = function(prof, r) return RecipeState(prof, r) end
CR.CraftRecipe = function(r, count) return Craft(r, count) end

function CR.ComponentInfo(prof, itemID, need)
  local how = CR.ComponentMaker(prof, itemID)
  if not how then return nil end
  local mprof = how.prof or prof
  local bags, elsewhere = CR.BagsAndElsewhere(itemID)
  local missing = math.max(0, need - bags - elsewhere)
  local shortBags = math.max(0, need - bags)
  local makes = how.recipe and how.recipe.makes or how.convert.makes
  local info = {
    how = how, prof = mprof, recipe = how.recipe, convert = how.convert,
    missing = missing, shortBags = shortBags, smelting = mprof.name == "Mining",
    toMake = math.ceil((missing > 0 and missing or shortBags) / makes),
  }
  if how.recipe then
    local learned, available = RecipeState(mprof, how.recipe)
    info.learned, info.available = learned, available or 0
    info.skillOK = not how.recipe.learn or (CR.GetSkill(mprof.name) or 0) >= how.recipe.learn
    info.open = CR.TradeSkillOpenFor(mprof.name)
    info.count = math.min(info.toMake, info.available)
    info.reagents = how.recipe.reagents
  else
    local c = how.convert
    info.available = math.floor((GetItemCount(c.use, false) or 0) / c.uses)
    info.macro = info.available > 0 and ("/use item:" .. c.use) or nil
    info.reagents = { { c.use, c.uses } }
  end
  return info
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------
function CR.CreateCraftPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  local db = function() return CraftRouteCharDB end
  panel.viewOffset = 0   -- browsing ahead with the arrows; 0 = the current craft

  -- Layout: the craft area fills the left (everything centred in it, so it follows the window
  -- size), the compact route runs down the right. In the craft area: a row of three recipes -
  -- the current one and the next two, their reagent boxes level - with the step bar under the
  -- skill bar at the top and the craft controls at the bottom.
  local LEFT_W, ROUTE_W = 684, 290
  local MAIN_X, NEXT_X, AFTER_X = -170, 85, 272   -- column centres, relative to the craft area's centre
  local leftArea = CreateFrame("Frame", nil, panel)
  leftArea:SetPoint("TOPLEFT")
  leftArea:SetPoint("BOTTOMLEFT")
  leftArea:SetPoint("RIGHT", panel, "RIGHT", -(ROUTE_W + 10), 0)

  -- Skill bar
  local bar = CreateFrame("StatusBar", nil, panel, "BackdropTemplate")
  bar:SetHeight(20)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetMinMaxValues(0, 1)
  CR.Backdrop(bar, 0, 0, 0, 0.6)
  bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bar.text:SetPoint("CENTER")

  -- Profession switcher: the professions this character can actually craft with.
  local profDD = CR.CreateDropdown(panel, 130, function()
    local opts = {}
    for _, n in ipairs(CR.SupportedProfessions()) do
      local _, _, detected = CR.GetSkill(n)
      if detected or db().showUnlearned or n == db().profession then
        table.insert(opts, { value = n, text = detected and n or CR.ColorText(n, "808080") })
      end
    end
    return opts
  end, function() return db().profession end,
  function(v)
    db().profession = v; db().profPicked = true; panel.viewOffset = 0
    panel:AutoOpen(true)
    CR.NotifyChanged()
  end, CR.OpenProfessionMacro)
  profDD:SetPoint("TOPLEFT", 4, -8)

  -- Same setting as the Plan tab's tickbox: list professions this character hasn't learned.
  local unlearnedCB = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  unlearnedCB:SetSize(20, 20)
  unlearnedCB:SetPoint("TOPLEFT", profDD, "BOTTOMLEFT", -2, -4)
  unlearnedCB.label = unlearnedCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  unlearnedCB.label:SetPoint("LEFT", unlearnedCB, "RIGHT", 2, 0)
  unlearnedCB.label:SetText("Show unlearned")
  unlearnedCB:SetScript("OnClick", function(self)
    db().showUnlearned = self:GetChecked() and true or false
    CR.NotifyChanged()
  end)
  unlearnedCB:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Show professions I haven't learned")
    GameTooltip:AddLine("Ticked, the profession list also offers professions this character doesn't have "
      .. "(greyed out), so you can look through their route. Untick to list only your own professions.", 1, 1, 1, true)
    GameTooltip:AddLine("Shared with the Plan tab's tickbox.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
  end)
  unlearnedCB:SetScript("OnLeave", GameTooltip_Hide)
  bar:SetPoint("LEFT", profDD, "RIGHT", 12, 0)
  bar:SetPoint("RIGHT", leftArea, "RIGHT", -10, 0)

  -- Step progress: how far through the current guide step you are (fills as you skill up).
  -- Placed under the recipe row in Refresh, below whichever reagent box ends lowest.
  local stepBar = CreateFrame("StatusBar", nil, panel, "BackdropTemplate")
  stepBar:SetHeight(16)
  stepBar:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -6)
  stepBar:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -6)
  stepBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  stepBar:SetMinMaxValues(0, 1)
  CR.Backdrop(stepBar, 0, 0, 0, 0.6)
  local stepLine = stepBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  stepLine:SetPoint("CENTER")

  -- browse arrows
  local function Arrow(dir)
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(24, 24)
    local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetDisabledTexture(base .. "Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnClick", function()
      panel.viewOffset = math.max(0, panel.viewOffset + dir)
      panel:Refresh()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(dir < 0 and "Back towards the current craft" or "Look at the next craft in the route")
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
  end
  local prevBtn, nextBtn = Arrow(-1), Arrow(1)

  -- Main recipe (left-centre)
  local main = CreateFrame("Frame", nil, panel)
  main:SetSize(320, 300)
  main:SetPoint("TOP", leftArea, "TOP", MAIN_X, -92)
  local bigIcon = IconButton(main, 80)
  bigIcon:SetPoint("TOP", 0, 0)
  prevBtn:SetPoint("RIGHT", bigIcon, "LEFT", -24, 0)
  nextBtn:SetPoint("LEFT", bigIcon, "RIGHT", 24, 0)
  -- "Tanning Rack required" - special crafting stations, in the gap above the icon
  local structureText = main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  structureText:SetPoint("BOTTOM", bigIcon, "TOP", 0, 8)
  local name = main:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  name:SetPoint("TOP", bigIcon, "BOTTOM", 0, -10)
  name:SetWidth(320)
  local sub = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOP", name, "BOTTOM", 0, -6)
  sub:SetWidth(320)

  -- Skill-up colour band: the recipe's orange / yellow / green / grey ranges with a marker at
  -- your skill, so you can see how long it keeps giving points.
  local BAND_W = 260
  local band = CreateFrame("Frame", nil, main, "BackdropTemplate")
  band:SetSize(BAND_W, 10)
  band:SetPoint("TOP", sub, "BOTTOM", 0, -8)
  CR.Backdrop(band, 0, 0, 0, 0.6)
  band.crOwnBorder = true
  band:SetBackdropBorderColor(0, 0, 0, 1)
  band.segs = {}
  for i, key in ipairs({ "orange", "yellow", "green", "grey" }) do
    local t = band:CreateTexture(nil, "ARTWORK")
    local hex = CR.DIFF_COLORS[key]
    t:SetColorTexture(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
      tonumber(hex:sub(5, 6), 16) / 255, 0.9)
    t:SetHeight(8)
    band.segs[i] = t
  end
  band.marker = band:CreateTexture(nil, "OVERLAY")
  band.marker:SetSize(3, 16)
  band.marker:SetColorTexture(1, 1, 1, 1)
  local bandText = main:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bandText:SetPoint("TOP", band, "BOTTOM", 0, -4)
  bandText:SetWidth(300)
  local function FillBand(r, skill)
    -- scale: from learn skill to a little past grey
    local lo, hi = r.learn or 1, (r.x or 1) + 10
    if hi <= lo then hi = lo + 1 end
    local function X(v) return math.max(0, math.min(1, (v - lo) / (hi - lo))) * (BAND_W - 2) + 1 end
    local edges = { lo, r.y, r.g, r.x, hi }
    for i, t in ipairs(band.segs) do
      local a, b = X(math.max(lo, edges[i])), X(math.max(lo, edges[i + 1]))
      t:ClearAllPoints()
      t:SetPoint("LEFT", band, "LEFT", a, 0)
      t:SetWidth(math.max(0.01, b - a))
      t:SetShown(b - a > 0.5)
    end
    band.marker:ClearAllPoints()
    band.marker:SetPoint("CENTER", band, "LEFT", X(skill), 0)
    bandText:SetText(string.format("|cffff8040%d|r learn  ·  |cffffff00%d|r yellow  ·  |cff40bf40%d|r green  ·  |cff808080%d|r grey  ·  you: |cffffffff%d|r",
      r.learn or 1, r.y, r.g, r.x, skill))
  end

  local reagentBox = CreateFrame("Frame", nil, main, "BackdropTemplate")
  reagentBox:SetSize(300, 40)
  reagentBox:SetPoint("TOP", bandText, "BOTTOM", 0, -10)
  CR.Backdrop(reagentBox, 0, 0, 0, 0.35)
  local reagentTitle = reagentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  reagentTitle:SetPoint("TOPLEFT", 12, -8)
  reagentTitle:SetText("Reagents:")
  CR.ThemeRegisterAccentText(reagentTitle)
  -- "Crafts ready: 1/16" - how many of this step your bags can make right now
  local readyText = reagentBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  readyText:SetPoint("TOPRIGHT", -12, -8)
  local reagentScroll, reagentContent = ScrollArea(reagentBox, 0, -24, 292)
  local reagentRows = {}
  for i = 1, 8 do
    local row = ReagentRow(reagentContent, 36, "GameFontHighlight")
    row:SetSize(276, 40)
    row:SetPoint("TOPLEFT", 12, -(i - 1) * 40)
    reagentRows[i] = row
  end
  local totalNote = reagentBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  totalNote:SetPoint("BOTTOMRIGHT", -10, 6)

  -- Inline component maker: click a reagent you can make yourself (Medium Leather from Light
  -- Leather, Bolts of Cloth, Handfuls of Bolts, essences...) and its line opens up to show what
  -- it's made from, with a Make button that starts crafting it straight away. A component in
  -- there that you can make too has its own +, so the chain opens as deep as it goes (Rugged
  -- Leather <- Thick <- Heavy <- Medium <- Light <- scraps), one section per level, each a step
  -- further in.
  local MAX_LEVELS, LEVEL_INDENT = 8, 8
  local expands = {}
  local function NewExpand(level)
    local ex = CreateFrame("Frame", nil, reagentContent, "BackdropTemplate")
    ex:SetWidth(264 - (level - 1) * LEVEL_INDENT)
    CR.Backdrop(ex, 0, 0, 0, 0.5)
    ex:Hide()
    ex.title = ex:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ex.title:SetPoint("TOPLEFT", 8, -5)
    ex.title:SetPoint("RIGHT", -8, 0)
    ex.title:SetJustifyH("LEFT")
    ex.title:SetWordWrap(false)
    CR.ThemeRegisterAccentText(ex.title)
    ex.rows = {}
    for i = 1, 4 do
      local row = ReagentRow(ex, 28, "GameFontHighlightSmall")
      row:SetSize(ex:GetWidth() - 92, 32)
      row:SetPoint("TOPLEFT", 8, -18 - (i - 1) * 32)
      ex.rows[i] = row
    end
    ex.info = ex:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ex.info:SetPoint("BOTTOMLEFT", 8, 6)
    ex.info:SetPoint("RIGHT", -8, 0)
    ex.info:SetJustifyH("LEFT")
    ex.make = CreateFrame("Button", nil, ex, "UIPanelButtonTemplate")
    ex.make:SetSize(76, 22)
    ex.make:SetPoint("TOPRIGHT", -8, -23)
    CR.ThemeRegisterButton(ex.make)
    ex.make:SetScript("OnClick", function(self)
      if self.openProf then CR.OpenTradeSkill(self.openProf)
      elseif self.recipe and (self.count or 0) > 0 then Craft(self.recipe, self.count) end
    end)
    -- secure cover: uses the item for Split / Combine (essences), or casts the profession for
    -- Open - only a real click may do either
    SecureEnchantButton(ex.make, function() return ex.convertMacro or ex.openMacro or "" end, {
      plain = true,
      wanted = function() return ex:IsVisible() and (ex.convertMacro or ex.openMacro) ~= nil end,
    })
    return ex
  end
  for level = 1, MAX_LEVELS do expands[level] = NewExpand(level) end

  -- The open chain: path[1] is the opened reagent, path[2] the component opened inside it...
  panel.expandPath = {}
  -- Open (or close) `id` at `level`; anything opened below that level closes.
  local function ToggleExpand(level, id)
    local path = panel.expandPath
    local wasOpen = path[level] == id
    for i = #path, level, -1 do path[i] = nil end
    if not wasOpen then path[level] = id end
    panel:Refresh()
  end

  -- Buy (the shared buy box, below): short = how many more this step needs in your bags
  local function OpenBuy(itemID, short, button)
    CR.OpenBuy(itemID, short, button, function(id)
      -- keep "Buy needed" in step with your bags; close if the recipe moved on
      for _, rg in ipairs(panel.current and panel.current.reagents or {}) do
        if rg[1] == id then
          return math.max(0, rg[2] * (panel.currentCrafts or 1) - (GetItemCount(rg[1], false) or 0))
        end
      end
    end, panel)
  end
  panel.UpdateBuyPop = CR.RefreshBuyPop

  -- Fills the section for itemID at `level` (the level above needs `need` of it); returns its
  -- height (0 if it can't be made), how many crafts / uses cover the shortfall, and the recipe.
  local function FillExpand(level, prof, itemID, need)
    local ex = expands[level]
    local how = CR.ComponentMaker(prof, itemID)
    if not how then return 0 end
    prof = how.prof or prof   -- made by another of your professions (Leatherworking, Mining...)
    local smelting = prof.name == "Mining"
    local bags, elsewhere = CR.BagsAndElsewhere(itemID)
    local missing = math.max(0, need - bags - elsewhere)   -- not anywhere: has to be made
    local shortBags = math.max(0, need - bags)              -- not on you
    local makes = how.recipe and how.recipe.makes or how.convert.makes
    local toMake = math.ceil((missing > 0 and missing or shortBags) / makes)
    local shortText = missing > 0 and CR.ColorText(missing .. " short", "ff6060")
      or (shortBags > 0 and CR.ColorText(shortBags .. " not on you", "ffd100"))
      or CR.ColorText("enough", "40ff40")
    ex.title:SetText(string.format("%s %s from:",
      smelting and "Smelt" or how.recipe and "Make" or (how.convert.uses > 1 and "Combine" or "Split"),
      CR.ItemName(itemID) .. ((how.prof and not smelting) and (" (" .. prof.name .. ")") or "")))
    -- the components, as have / per craft; ones you can make yourself open the next level
    local exclude = {}
    for i = 1, level do exclude[panel.expandPath[i]] = true end   -- never loop (essences go both ways)
    FillReagents(ex, ex.rows, how.recipe or { reagents = { { how.convert.use, how.convert.uses } } }, 1, {
      perCraft = true, prof = prof, needMult = math.max(1, toMake), exclude = exclude,
      expanded = panel.expandPath[level + 1],
      onMake = level < MAX_LEVELS and function(id) ToggleExpand(level + 1, id) end or nil,
    })
    local m, info = ex.make, nil
    m.recipe, m.count, m.openProf = nil, nil, nil
    ex.convertMacro, ex.openMacro = nil, nil
    if how.recipe then
      local r = how.recipe
      local learned, available = RecipeState(prof, r)
      available = available or 0
      m:Show()
      m:SetText("Make")
      m:Disable()
      if learned == false then
        info = CR.ColorText("Not learned - " .. CR.FactionText(r.pattern or r.src), "ff9966")
      elseif r.learn and (CR.GetSkill(prof.name) or 0) < r.learn then
        info = CR.ColorText("Needs " .. r.learn .. " skill", "ff6060")
      elseif not CR.TradeSkillOpenFor(prof.name) then
        m:SetText("Open")
        m:SetEnabled(not InCombatLockdown())
        m.openProf = prof.name
        ex.openMacro = CR.OpenProfessionMacro(prof.name)
        info = (smelting and "Open Mining (Smelting) to smelt" or ("Open " .. prof.name .. " to craft")) .. "  ·  " .. shortText
      else
        local n = math.min(toMake, available)
        m.recipe, m.count = r, n
        if n > 0 then m:SetText((smelting and "Smelt " or "Make ") .. n) end
        m:SetEnabled(n > 0 and not IsRepeating())
        info = string.format("Can make %s now  ·  %s", CR.ColorText(tostring(available), available > 0 and "40ff40" or "ff6060"), shortText)
        if r.makes > 1 then info = info .. "  ·  " .. r.makes .. " per craft" end
      end
    else
      -- essences combine / split by using the item; the secure cover over this button does the
      -- /use (only a real click may use an item)
      local c = how.convert
      local can = math.floor((GetItemCount(c.use, false) or 0) / c.uses)
      m:Show()
      m:SetText(c.uses > 1 and "Combine" or "Split")
      m:SetEnabled(can > 0 and not InCombatLockdown())
      ex.convertMacro = can > 0 and ("/use item:" .. c.use) or nil
      info = string.format("%s  ·  can do %s now  ·  %s",
        c.uses > 1 and string.format("Each click: %d into 1", c.uses) or string.format("Each click: 1 into %d", c.makes),
        CR.ColorText(tostring(can), can > 0 and "40ff40" or "ff6060"), shortText)
    end
    ex.info:SetText(info)
    local nRows = how.recipe and #how.recipe.reagents or 1
    local h = 18 + nRows * 32 + 18
    ex:SetHeight(h)
    return h, toMake, how.recipe or { reagents = { { how.convert.use, how.convert.uses } } }
  end

  -- What the whole step needs that your bags don't have yet, and what buying it costs.
  local stepNeed = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  stepNeed:SetPoint("TOP", reagentBox, "BOTTOM", 0, -8)
  stepNeed:SetWidth(300)
  stepNeed:SetJustifyH("CENTER")

  -- Previews of the next two crafts, beside the current one: "Up next" and "After that".
  -- Each reagent box's top is level with the current recipe's reagent box; the icon, name and
  -- labels stack upwards from it.
  local function Preview(title, iconSize, x)
    local p = CreateFrame("Frame", nil, panel)
    p:SetAllPoints(leftArea)
    p.box = CreateFrame("Frame", nil, p, "BackdropTemplate")
    p.box:SetSize(180, 30)
    p.box:SetPoint("TOP", reagentBox, "TOP", x - MAIN_X, 0)
    CR.Backdrop(p.box, 0, 0, 0, 0.35)
    p.sub = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.sub:SetPoint("BOTTOM", p.box, "TOP", 0, 6)
    p.name = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    p.name:SetPoint("BOTTOM", p.sub, "TOP", 0, 2)
    p.name:SetWidth(176)
    p.iconBtn = IconButton(p, iconSize)
    p.iconBtn:SetPoint("BOTTOM", p.name, "TOP", 0, 4)
    p.label = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.label:SetPoint("BOTTOM", p.iconBtn, "TOP", 0, 6)
    p.label:SetText(title)
    CR.ThemeRegisterAccentText(p.label)
    p.scroll, p.content = ScrollArea(p.box, 0, -6, 172)
    p.rows = {}
    for i = 1, 8 do
      local row = ReagentRow(p.content, 26, "GameFontHighlightSmall")
      row:SetSize(162, 30)
      row:SetPoint("TOPLEFT", 8, -(i - 1) * 30)
      p.rows[i] = row
    end
    return p
  end
  local nextFrame = Preview("Up next", 54, NEXT_X)
  local afterFrame = Preview("After that", 44, AFTER_X)

  -- Craft controls (bottom)
  local controls = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  controls:SetSize(400, 40)
  controls:SetPoint("BOTTOM", leftArea, "BOTTOM", 0, 6)   -- centred at the bottom of the craft area
  CR.Backdrop(controls, 0, 0, 0, 0.45)
  local createAll = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  createAll:SetSize(130, 24)
  createAll:SetPoint("LEFT", 10, 0)
  CR.ThemeRegisterButton(createAll)
  local create = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  create:SetSize(110, 24)
  create:SetPoint("RIGHT", -10, 0)
  CR.ThemeRegisterButton(create)
  local countBox = CreateFrame("EditBox", nil, controls, "InputBoxTemplate")
  countBox:SetSize(40, 20)
  countBox:SetPoint("CENTER", 8, 0)
  countBox:SetAutoFocus(false)
  countBox:SetNumeric(true)
  countBox:SetMaxLetters(3)
  countBox:SetJustifyH("CENTER")
  countBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  countBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  local function Step(dir)
    local b = CreateFrame("Button", nil, controls)
    b:SetSize(22, 22)
    local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    b:SetScript("OnClick", function()
      countBox:SetNumber(math.max(1, (countBox:GetNumber() or 1) + dir))
    end)
    return b
  end
  Step(-1):SetPoint("RIGHT", countBox, "LEFT", -8, 0)
  Step(1):SetPoint("LEFT", countBox, "RIGHT", 4, 0)

  -- Shown instead of the controls while the profession window is closed.
  local openBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
  openBtn:SetSize(220, 24)
  openBtn:SetPoint("CENTER")
  CR.ThemeRegisterButton(openBtn)
  local status = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  status:SetPoint("BOTTOM", controls, "TOP", 0, 6)
  status:SetWidth(400)

  -- Crafting cast bar (above the status line): the profession cast in progress, Blizzard
  -- cast-bar style. Dimmed and empty between crafts so the space stays steady.
  local cast = CreateFrame("StatusBar", nil, panel, "BackdropTemplate")
  cast:SetSize(480, 22)
  cast:SetPoint("BOTTOM", status, "TOP", 12, 26)
  cast:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  cast:SetMinMaxValues(0, 1)
  cast:SetValue(0)
  CR.Backdrop(cast, 0, 0, 0, 0.6)
  cast.icon = cast:CreateTexture(nil, "ARTWORK")
  cast.icon:SetSize(24, 24)
  cast.icon:SetPoint("RIGHT", cast, "LEFT", -6, 0)
  cast.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  cast.spark = cast:CreateTexture(nil, "OVERLAY")
  cast.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
  cast.spark:SetBlendMode("ADD")
  cast.spark:SetSize(24, 44)
  cast.text = cast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cast.text:SetPoint("CENTER")

  -- Enchanting target (bottom centre, above the cast bar): only for "Enchant <slot> - ..."
  -- recipes. Hover to pick from matching gear you're wearing or carrying; click to enchant it.
  local ench = {}   -- target = { equipSlot | bag, slot, itemID }; fits / kind of the current enchant
  panel.crEnch = ench
  local enchantArea = CreateFrame("Frame", nil, panel)
  enchantArea:SetSize(480, 64)
  enchantArea:SetPoint("BOTTOM", cast, "TOP", -12, 14)
  enchantArea:Hide()
  local eSlot = CreateFrame("Button", nil, enchantArea, "BackdropTemplate")
  eSlot:SetSize(56, 56)
  eSlot:SetPoint("CENTER", -40, 0)
  eSlot:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
  eSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  eSlot.icon = eSlot:CreateTexture(nil, "ARTWORK")
  eSlot.icon:SetPoint("TOPLEFT", 2, -2)
  eSlot.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  eSlot.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local eHl = eSlot:CreateTexture(nil, "HIGHLIGHT")
  eHl:SetAllPoints(eSlot.icon)
  eHl:SetColorTexture(1, 1, 1, 0.15)
  local eLabel = enchantArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  eLabel:SetPoint("BOTTOMRIGHT", eSlot, "LEFT", -10, 2)
  eLabel:SetJustifyH("RIGHT")
  eLabel:SetText("Enchant target")
  CR.ThemeRegisterAccentText(eLabel)
  local eName = enchantArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  eName:SetPoint("TOPRIGHT", eSlot, "LEFT", -10, -2)
  eName:SetWidth(170)
  eName:SetJustifyH("RIGHT")
  eName:SetWordWrap(false)

  -- the pick list, to the right of the slot while you hover
  local flyout = CreateFrame("Frame", nil, enchantArea, "BackdropTemplate")
  flyout:SetPoint("LEFT", eSlot, "RIGHT", 6, 0)
  flyout:SetHeight(52)
  CR.Backdrop(flyout, 0.04, 0.04, 0.06, 0.95)
  flyout:SetFrameLevel(eSlot:GetFrameLevel() + 5)
  flyout:Hide()
  local flyEmpty = flyout:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  flyEmpty:SetPoint("LEFT", 10, 0)
  flyout.buttons = {}
  local function FlyButton(i)
    local b = flyout.buttons[i]
    if b then return b end
    b = IconButton(flyout, 42)
    b:SetPoint("LEFT", 5 + (i - 1) * 46, 0)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      if self.cand.link then GameTooltip:SetHyperlink(self.cand.link) else GameTooltip:SetItemByID(self.cand.itemID) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(self.cand.equipSlot and "You're wearing this" or "In your bags", 0.8, 0.8, 0.8)
      if self.cand.enchanted then
        GameTooltip:AddLine("Already enchanted - it will be replaced without asking.", 1, 0.4, 0.4, true)
      end
      if self.cand.unbound then
        GameTooltip:AddLine("Not soulbound yet - enchanting it binds it to you (the game asks first).", 1, 0.82, 0, true)
      end
      GameTooltip:AddLine("Click to make it the target.", 0.2, 1, 0.2)
      GameTooltip:Show()
    end)
    b:SetScript("OnClick", function(self)
      local c = self.cand
      ench.target = { equipSlot = c.equipSlot, bag = c.bag, slot = c.slot, itemID = c.itemID }
      flyout:Hide()
      GameTooltip_Hide()
      panel:Refresh()
    end)
    flyout.buttons[i] = b
    return b
  end
  local function ShowFlyout()
    local list = CR.EnchantCandidates(ench.fits)
    local n = math.min(#list, 10)
    for i = 1, n do
      local b, c = FlyButton(i), list[i]
      b.cand = c
      b.icon:SetTexture(GetItemIcon(c.itemID))
      b:SetBackdropBorderColor(QualityRGB(select(3, GetItemInfo(c.itemID)) or 1))
      b:Show()
    end
    for i = n + 1, #flyout.buttons do flyout.buttons[i]:Hide() end
    if n == 0 then
      flyEmpty:SetText(string.format("No %s you're wearing or in your bags.",
        (ench.kind or "item"):lower()))
      flyEmpty:Show()
      flyout:SetWidth(flyEmpty:GetStringWidth() + 20)
    else
      flyEmpty:Hide()
      flyout:SetWidth(10 + n * 46)
    end
    flyout:Show()
  end
  -- Hide once the mouse has been away from both the slot and the list for a moment: a margin
  -- around them covers the gap between, and the delay forgives a wobbly mouse.
  -- (Frame method - Forever has no global MouseIsOver.)
  flyout:SetScript("OnShow", function(self) self.awayFor = 0 end)
  flyout:SetScript("OnUpdate", function(self, elapsed)
    if self:IsMouseOver(12, -12, -12, 12) or eSlot:IsMouseOver(12, -12, -12, 12) then
      self.awayFor = 0
    else
      self.awayFor = (self.awayFor or 0) + (elapsed or 0)
      if self.awayFor > 0.6 then self:Hide() end
    end
  end)
  eSlot:SetScript("OnEnter", function(self)
    ShowFlyout()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local t = ench.target
    if t then
      local link = t.equipSlot and GetInventoryItemLink("player", t.equipSlot)
        or (C_Container and C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(t.bag, t.slot))
      if link then GameTooltip:SetHyperlink(link) else GameTooltip:SetItemByID(t.itemID) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Left-click: enchant it with " .. (panel.current and panel.current.name or "this enchant"), 0.2, 1, 0.2, true)
      GameTooltip:AddLine("Its current enchant is replaced without asking.", 1, 0.4, 0.4, true)
      GameTooltip:AddLine("Right-click: clear the target", 0.8, 0.8, 0.8)
    else
      GameTooltip:SetText("Enchant target")
      GameTooltip:AddLine("Pick something to enchant from the list beside this slot: gear you're wearing, "
        .. "or gear in your bags that this enchant fits.", 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  eSlot:SetScript("OnLeave", GameTooltip_Hide)
  eSlot:SetScript("OnClick", function(self, button)
    if button == "RightButton" then ench.target = nil panel:Refresh() return end
    if not ench.target then ShowFlyout() end
  end)
  -- the secure cover that actually enchants (and answers the replace question)
  SecureEnchantButton(eSlot, function(button)
    if button == "RightButton" then ench.target = nil panel:Refresh() return "" end
    if not ench.target then ShowFlyout() return "" end
    return EnchantClick(panel.current, ench.target, not eSlot.blocked)
  end)

  -- Called from Refresh. fits: the gear kinds this recipe enchants (nil = not an enchant).
  function panel:UpdateEnchant(r, fits, kind, canCraft)
    ench.fits, ench.kind = fits, kind
    enchantArea:SetShown(fits and true or false)
    if not fits then flyout:Hide() return end
    local t = ResolveTarget(ench.target, fits)
    ench.target = t and { equipSlot = t.equipSlot, bag = t.bag, slot = t.slot, itemID = t.itemID } or nil
    if t then
      eSlot.icon:SetTexture(GetItemIcon(t.itemID))
      eSlot.icon:SetDesaturated(not canCraft)
      eSlot:SetBackdropBorderColor(QualityRGB(select(3, GetItemInfo(t.itemID)) or 1))
      eName:SetText(CR.ItemName(t.itemID) .. (t.equipSlot and CR.ColorText(" (worn)", "aaaaaa") or ""))
    else
      eSlot.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
      eSlot.icon:SetDesaturated(false)
      eSlot:SetBackdropBorderColor(0.4, 0.4, 0.4)
      eName:SetText(CR.ColorText("Hover to choose a " .. kind:lower(), "aaaaaa"))
    end
    eSlot.blocked = not canCraft
    if flyout:IsShown() then ShowFlyout() end
    return t
  end

  local function CastIdle()
    cast:SetScript("OnUpdate", nil)
    cast.casting = nil
    cast:SetValue(0)
    cast:SetAlpha(0.55)
    cast.spark:Hide()
    cast.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    cast.icon:SetDesaturated(true)
    cast.text:SetText(CR.ColorText("Not crafting", "999999"))
  end

  -- Called on spell-cast events; only profession casts are shown.
  function panel:UpdateCast(event)
    if event == "UNIT_SPELLCAST_SUCCEEDED" and cast.casting then
      cast.casting = nil
      cast:SetScript("OnUpdate", nil)
      cast:SetValue(1)
      cast:SetStatusBarColor(0.2, 0.9, 0.2)
      cast.spark:Hide()
      C_Timer.After(0.6, function() if not cast.casting then self:UpdateCast() end end)
      return
    elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") and cast.casting then
      cast.casting = nil
      cast:SetScript("OnUpdate", nil)
      cast:SetStatusBarColor(0.9, 0.15, 0.15)
      cast.spark:Hide()
      cast.text:SetText("Interrupted")
      C_Timer.After(1, function() if not cast.casting then self:UpdateCast() end end)
      return
    end
    local name, _, texture, startMS, endMS, isTradeSkill = UnitCastingInfo("player")
    if not (name and isTradeSkill and startMS and endMS and endMS > startMS) then
      CastIdle()
      return
    end
    cast.casting = true
    cast:SetAlpha(1)
    cast:SetStatusBarColor(1, 0.7, 0)
    cast.icon:SetTexture(texture)
    cast.icon:SetDesaturated(false)
    cast.spark:Show()
    local left = TS.GetRemainingRecasts and TS.GetRemainingRecasts() or 0
    cast.text:SetText("Crafting " .. name .. (left and left > 0 and string.format("  ·  %d left", left) or ""))
    local start, dur = startMS / 1000, (endMS - startMS) / 1000
    cast:SetScript("OnUpdate", function(bar)
      local v = math.max(0, math.min(1, (GetTime() - start) / dur))
      bar:SetValue(v)
      bar.spark:ClearAllPoints()
      bar.spark:SetPoint("CENTER", bar, "LEFT", v * bar:GetWidth(), 0)
    end)
  end
  CastIdle()

  local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  empty:SetPoint("TOP", leftArea, "TOP", 0, -160)
  empty:SetWidth(560)

  -- A step that isn't a craft (train a rank, buy a book, learn a recipe, go fishing) stops the
  -- route: this card takes the recipe's place until the game (or "Mark as done") ticks it off.
  local TASK_W = 320
  local taskCard = CR.CreateTaskCard(panel, TASK_W)
  taskCard:SetPoint("TOP", leftArea, "TOP", MAIN_X, -64)

  -- Compact route (right): the upcoming steps, current one highlighted. Click a craft to view it.
  local routeTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  routeTitle:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -ROUTE_W + 50, -10)
  routeTitle:SetText("Route")
  CR.ThemeRegisterAccentText(routeTitle)
  local routeGoal = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  routeGoal:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -12)
  -- The goal, the same setting as the Plan tab's Goal dropdown: change it in either place.
  local goalDD = CR.CreateDropdown(panel, 180, CR.GoalOptions,
    function() return db().goalMode end,
    function(v) db().goalMode = v; panel.viewOffset = 0; CR.NotifyChanged() end)
  goalDD:SetPoint("LEFT", routeTitle, "RIGHT", 10, 0)
  local goalBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  goalBox:SetSize(34, 20)
  goalBox:SetPoint("LEFT", goalDD, "RIGHT", 10, 0)
  goalBox:SetAutoFocus(false)
  goalBox:SetNumeric(true)
  goalBox:SetMaxLetters(3)
  goalBox:SetScript("OnEnterPressed", function(self)
    db().customGoal = tonumber(self:GetText()) or 225
    db().goalMode = "custom"
    self:ClearFocus()
    CR.NotifyChanged()
  end)
  goalBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local routeList = CR.CreateList("CraftRouteCraftRouteList", panel, ROUTE_W, 400, function(row)
    row.range = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.range:SetPoint("LEFT", 2, 0)
    row.range:SetWidth(52)
    row.range:SetJustifyH("LEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 56, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", -2, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.mark = row:CreateTexture(nil, "BACKGROUND")
    row.mark:SetAllPoints()
    row.mark:SetColorTexture(1, 1, 1, 1)
    row.mark:Hide()
    row:SetScript("OnClick", function(self)
      if self.craftIndex then
        panel.viewOffset = self.craftIndex - 1
        panel:Refresh()
      end
    end)
    row:SetScript("OnEnter", function(self)
      local st = self.step
      if not st then return end
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      if st.recipe then
        CR.RecipeTooltip(GameTooltip, st.recipe, st.crafts)
        GameTooltip:AddLine("Click to view it in the craft panel", 0.6, 0.8, 1)
      else
        GameTooltip:SetText(st.text or "", 1, 1, 1, 1, true)
      end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
  end, function(row, line)
    local st = line.step
    row.step, row.craftIndex = st, line.craftIndex
    row.range:SetText(st.from and st.to and st.to > st.from and string.format("%d-%d", st.from, st.to)
      or (st.from and st.from > 0 and tostring(st.from) or ""))
    if st.recipe then
      row.icon:SetTexture(CR.RecipeIcon(st.recipe))
      row.icon:Show()
      local name = CR.ColorText(st.recipe.name, CR.QualityHex(st.recipe.q))
      local prefix = st.kind == "extra" and CR.ColorText("+ ", "aaaaaa") or (st.kind == "target" and CR.ColorText("Target: ", "33ccff") or "")
      row.text:SetText(prefix .. (st.estimated and "~" or "") .. st.crafts .. "x " .. name)
    else
      row.icon:SetTexture(st.kind == "train" and "Interface\\Icons\\INV_Misc_Book_09" or "Interface\\Icons\\Trade_Fishing")
      row.icon:Show()
      row.text:SetText(CR.ColorText(st.text or "", st.kind == "train" and "ffd100" or "cccccc"))
    end
    -- the craft on view gets an accent tint; the current one a fainter one
    local r, g, b = CR.AccentColor()
    if line.craftIndex and line.craftIndex == panel.viewOffset + 1 then
      row.mark:SetVertexColor(r, g, b, 0.25); row.mark:Show()
    elseif line.craftIndex == 1 then
      row.mark:SetVertexColor(r, g, b, 0.1); row.mark:Show()
    else
      row.mark:Hide()
    end
  end)
  routeList:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -28)

  -- Bottom third of the column: the plan's materials, compact, with the cost of what's missing.
  local costBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  costBar:SetSize(ROUTE_W, 22)
  costBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 6)
  CR.Backdrop(costBar, 0, 0, 0, 0.55)
  local costText = costBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  costText:SetPoint("LEFT", 8, 0)
  costText:SetPoint("RIGHT", -8, 0)
  costText:SetJustifyH("LEFT")
  costText:SetWordWrap(false)
  local craftMats = CR.CreateList("CraftRouteCraftMatsList", panel, ROUTE_W, 160,
    function(row) CR.CreateMaterialRow(row, 64, 62) end, CR.UpdateMaterialRow)
  craftMats:SetPoint("BOTTOMRIGHT", costBar, "TOPRIGHT", 0, 2)
  local matsTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  matsTitle:SetPoint("BOTTOMLEFT", craftMats, "TOPLEFT", 4, 4)
  matsTitle:SetText("Materials")
  CR.ThemeRegisterAccentText(matsTitle)
  local matsHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  matsHdr:SetPoint("BOTTOMRIGHT", craftMats, "TOPRIGHT", -4, 5)
  matsHdr:SetText("have / need     cost")
  routeList:SetPoint("BOTTOMRIGHT", craftMats, "TOPRIGHT", 0, 22)
  -- a third of the column, following the window size
  local function SizeColumn()
    local h = panel:GetHeight()
    if type(h) == "number" and h > 0 then
      craftMats:SetHeight(math.max(80, math.floor((h - 28 - 6 - 24 - 22) / 3)))
    end
  end
  panel:HookScript("OnSizeChanged", SizeColumn)
  SizeColumn()

  -- The profession window can't be opened by addon code (only by a click), so there's no
  -- automatic opening: the Open button and the profession picker do it on your click.
  function panel:AutoOpen() end
  panel:SetScript("OnHide", function(self) self.autoOpened = nil; CR.HideBuyPop(panel); CR.HideSecureEnchantButtons() end)

  -- What's left to do (current first), up to the goal picked on either tab: crafts, and the
  -- tasks between them ({ task = ... }).
  local function CraftSteps(entry)
    return CR.ActionSteps(entry, db().profession)
  end

  local function Describe(st)
    if st.kind == "target" then return "Your target", "33ccff" end
    if st.kind == "extra" then return "For a later step", "aaaaaa" end
    return string.format("Step %d-%d", st.from, st.to), nil
  end

  function panel:Refresh()
    local profName = db().profession
    unlearnedCB:SetChecked(db().showUnlearned)
    local entry = CR.GetPlans(profName)
    local cur, maxRank, detected = CR.GetSkill(profName)
    local prof = CR.professions[profName]
    local route = CR.Route(profName)
    local rprof = route and CR.professions[route.recipeProf or profName] or prof

    bar:SetValue((maxRank and maxRank > 0) and (cur / maxRank) or 0)
    bar:SetStatusBarColor(CR.ProfessionColor(profName))   -- the profession's own colour
    bar.text:SetText(detected and string.format("%s %d/%d", profName, cur, maxRank)
      or (profName .. " (not learned)"))

    local steps = entry and CraftSteps(entry) or {}

    -- compact route: everything ahead except the "choose ONE" blocks (the chosen path's steps show)
    -- each line clicks to its place in `steps` (a craft whose recipe must be learned first goes
    -- to the "learn it" task)
    local indexOf = {}
    for i, a in ipairs(steps) do
      local key = a.task and a.planStep or a
      if not indexOf[key] then indexOf[key] = i end
    end
    local lines = {}
    for _, s in ipairs(entry and entry.plan.steps or {}) do
      if s.kind ~= "fork" and s.kind ~= "option" then
        table.insert(lines, { step = s, craftIndex = indexOf[s] })
      end
    end
    routeList.data = lines
    -- keep the viewed craft in sight
    local viewLine
    for i, l in ipairs(lines) do if l.craftIndex == panel.viewOffset + 1 then viewLine = i end end
    if viewLine and (viewLine <= routeList.offset or viewLine > routeList.offset + 20) then
      routeList.offset = math.max(0, viewLine - 3)
    end
    routeList:Refresh()
    -- goal picker (single-skill routes); the combined guide just follows the whole guide
    local seq = route and route.sequential
    goalDD:SetShown(not seq)
    goalBox:SetShown(not seq and db().goalMode == "custom")
    if not seq then
      goalDD:Sync()
      if not goalBox:HasFocus() then goalBox:SetText(tostring(db().customGoal or "")) end
    end
    routeGoal:SetShown(seq and true or false)
    routeGoal:SetText(entry and string.format("to %d (%s)", entry.goal, entry.route and entry.route.label or "") or "")
    craftMats.data = entry and entry.plan.materials or {}
    craftMats:Refresh()
    costText:SetText(entry and CR.MissingCostText(entry.plan, true) or "")

    -- Up next / After that
    local function FillPreview(p, ps, floor)
      if not ps then p:Hide() return end
      local pr = ps.recipe
      p:Show()
      p.iconBtn.recipe, p.iconBtn.crafts = pr, ps.crafts
      p.iconBtn.icon:SetTexture(CR.RecipeIcon(pr))
      p.iconBtn:SetBackdropBorderColor(QualityRGB(pr.q))
      p.name:SetText(pr.name)
      p.name:SetTextColor(QualityRGB(pr.q))
      local structure = CR.StructureText(pr)
      p.sub:SetText(string.format("%s  ·  %s%dx", (Describe(ps)), ps.estimated and "~" or "", ps.crafts)
        .. (structure and ("\n" .. structure) or ""))
      FillReagents(p.box, p.rows, pr, ps.crafts, { perCraft = true })   -- same colour rule as the current recipe
      if p.lastSpell ~= pr.spell then p.scroll:ScrollTo(0) end
      p.lastSpell = pr.spell
      p.box:SetHeight(12 + p.scroll:Fit(#pr.reagents * 30, RoomBelow(p.box, floor, 12 + 16, 90, 150)))
    end

    if #steps == 0 then
      taskCard:Hide()
      main:Hide(); nextFrame:Hide(); afterFrame:Hide(); controls:Hide(); enchantArea:Hide(); CR.HideSecureEnchantButtons(); status:SetText(""); prevBtn:Hide(); nextBtn:Hide()
      stepLine:SetText("")
      stepBar:SetValue(0)
      empty:SetText(route and route.noAutoFill and not next(rprof.recipes)
        and (profName .. " has nothing to craft - see the Plan tab for where to go.")
        or (entry and cur >= entry.goal and entry.goal < (route.maxSkill or 300))
        and string.format("Goal reached (%d). Pick a higher goal next to Route to keep going.", entry.goal)
        or "Nothing left to craft on this route.")
      empty:Show()
      return
    end
    empty:Hide(); main:Show(); controls:Show()
    panel.viewOffset = math.min(panel.viewOffset, #steps - 1)
    local st = steps[1 + panel.viewOffset]
    prevBtn:SetShown(true); nextBtn:SetShown(true)
    prevBtn:SetEnabled(panel.viewOffset > 0)
    nextBtn:SetEnabled(steps[2 + panel.viewOffset] ~= nil)
    -- the next two crafts after this one, for the previews (tasks aren't previewed)
    local ahead = {}
    for i = 2 + panel.viewOffset, #steps do
      if not steps[i].task then table.insert(ahead, steps[i]) end
      if #ahead == 2 then break end
    end

    if st.task then
      local t = st.task
      main:Hide(); controls:Hide(); enchantArea:Hide(); CR.HideSecureEnchantButtons(); CR.HideBuyPop(panel)
      status:SetText("")
      if t.progress then
        local p = t.progress
        stepBar:SetValue(math.max(0, math.min(1, (p.cur - p.from) / math.max(1, p.to - p.from))))
      else
        stepBar:SetValue(0)
      end
      stepBar:SetStatusBarColor(0.25, 0.6, 1)
      stepLine:SetText(CR.ColorText("Before you carry on: " .. (t.title or ""), "ffd100")
        .. (panel.viewOffset > 0 and CR.ColorText("  ·  looking ahead", "aaaaaa") or ""))
      taskCard:Fill(t, TASK_W)
      FillPreview(nextFrame, ahead[1], cast)
      FillPreview(afterFrame, ahead[2], cast)
      profDD:Sync()
      panel.lastSpell, panel.current = nil, nil
      SyncSecureButtons(false)
      return
    end
    taskCard:Hide()

    local r = st.recipe
    local enchantFits, enchantKind = CR.EnchantSlotFor(r)
    -- the reagent boxes stop above the enchant target when it's showing, else above the cast bar
    local floor = enchantFits and enchantArea or cast

    -- step line: where this craft sits in the route
    local label, labelColor = Describe(st)
    local diff = CR.Difficulty(r, cur)
    local diffText = ({ orange = "every craft gives a point", yellow = "most crafts give a point",
                        green = "few crafts give a point", grey = "no skill points",
                        red = "needs " .. r.learn .. " skill" })[diff]
    -- step progress: how far through this guide step (e.g. 130-150 at 141), and what's left
    local sFrom, sTo = st.stepFrom or st.from, st.stepTo or st.to
    local inStep = st.kind == "craft" and sTo and sFrom and sTo > sFrom
    stepBar:SetValue(inStep and math.max(0, math.min(1, (cur - sFrom) / (sTo - sFrom))) or 0)
    stepBar:SetStatusBarColor(0.25, 0.6, 1)
    local progress
    if inStep and cur >= sFrom then
      progress = string.format("Step %d-%d  ·  %d points to go  ·  %s%d crafts left", sFrom, sTo,
        math.max(0, sTo - cur), "~", st.crafts)   -- remaining crafts are always an estimate
    elseif inStep then
      progress = string.format("Step %d-%d  ·  starts in %d points  ·  %s%d to make", sFrom, sTo,
        sFrom - cur, st.estimated and "~" or "", st.crafts)
    else
      progress = (labelColor and CR.ColorText(label, labelColor) or label)
        .. string.format("  ·  %s%d to make", st.estimated and "~" or "", st.crafts)
    end
    stepLine:SetText(progress .. (panel.viewOffset > 0 and CR.ColorText("  ·  looking ahead", "aaaaaa") or ""))

    bigIcon.recipe, bigIcon.crafts = r, st.crafts
    bigIcon.icon:SetTexture(CR.RecipeIcon(r))
    bigIcon:SetBackdropBorderColor(QualityRGB(r.q))
    name:SetText(r.name)
    name:SetTextColor(QualityRGB(r.q))
    sub:SetText(CR.ColorText(diffText, CR.DIFF_COLORS[diff]) .. (st.note and CR.ColorText("  ·  " .. st.note, "999999") or ""))
    FillBand(r, cur)
    structureText:SetText(CR.StructureText(r) or "")

    profDD:Sync()
    -- counts are totals for the whole step; colours say whether you can make any at all
    local path = panel.expandPath
    if panel.lastSpell ~= r.spell then wipe(path) end
    FillReagents(reagentBox, reagentRows, r, st.crafts, { perCraft = true, prof = rprof, expanded = path[1],
      onBuy = OpenBuy,
      onMake = function(id) ToggleExpand(1, id) end })
    local y, extra = 0, 0
    for _, ex in ipairs(expands) do ex:Hide() end
    for i, row in ipairs(reagentRows) do
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 12, y)
      y = y - 40
      local rg = r.reagents[i]
      if rg and rg[1] == path[1] then
        -- the open chain, one section per level under this reagent, each a step further in
        local need, parent = rg[2] * st.crafts, nil
        for level = 1, #path do
          if level > 1 then
            -- how many of this component the level above needs for its crafts
            need = nil
            for _, prg in ipairs(parent.recipe.reagents) do
              if prg[1] == path[level] then need = prg[2] * math.max(1, parent.toMake) end
            end
          end
          local h, toMake, recipe = 0, 0, nil
          if need then h, toMake, recipe = FillExpand(level, rprof, path[level], need) end
          if h == 0 then   -- no longer makeable / not part of the level above: close from here
            for j = #path, level, -1 do path[j] = nil end
            break
          end
          local ex = expands[level]
          ex:ClearAllPoints()
          ex:SetPoint("TOPLEFT", 24 + (level - 1) * LEVEL_INDENT, y + 2)
          ex:Show()
          y, extra = y - h - 4, extra + h + 4
          parent = { recipe = recipe, toMake = toMake }
        end
      end
    end
    -- Crafts ready: green = your bags can make some now (that many); yellow = none from your
    -- bags but some counting the bank / mail / alts (that many); red = none anywhere.
    local _, readyNow = RecipeState(rprof, r)
    readyNow = readyNow or 0
    local anywhere = math.huge
    for _, rg in ipairs(r.reagents) do
      local bags, elsewhere = CR.BagsAndElsewhere(rg[1])
      anywhere = math.min(anywhere, math.floor((bags + elsewhere) / rg[2]))
    end
    if anywhere == math.huge then anywhere = 0 end
    -- green = the whole step from your bags; yellow = some (from bags, else counting bank /
    -- alts); red = none anywhere
    local readyN, readyColor = 0, "ff6060"
    if readyNow >= st.crafts then readyN, readyColor = readyNow, "40ff40"
    elseif readyNow > 0 then readyN, readyColor = readyNow, "ffd100"
    elseif anywhere > 0 then readyN, readyColor = anywhere, "ffd100" end
    readyText:SetText("Crafts ready: " .. CR.ColorText(string.format("%d/%d", math.min(readyN, st.crafts), st.crafts), readyColor))
    -- cap the box at the room above the cast bar; scroll the rest
    if panel.lastSpell ~= r.spell then reagentScroll:ScrollTo(0) end
    local shown = reagentScroll:Fit(#r.reagents * 40 + extra, RoomBelow(reagentBox, floor, 32 + 44, 120, 200))
    reagentBox:SetHeight(32 + shown)
    if st.crafts > 1 then totalNote:SetText(string.format("for all %d crafts", st.crafts))
    else totalNote:SetText("") end

    -- the whole step: what to fetch from the bank / alts, and what's truly missing (with cost)
    local fetch, short, cost, unpriced = {}, {}, 0, false
    for _, rg in ipairs(r.reagents) do
      local bags, elsewhere = CR.BagsAndElsewhere(rg[1])
      local need = rg[2] * st.crafts
      if bags < need then
        local fromElsewhere = math.min(elsewhere, need - bags)
        if fromElsewhere > 0 then table.insert(fetch, fromElsewhere .. " " .. CR.ItemName(rg[1])) end
        local missing = need - bags - fromElsewhere
        if missing > 0 then
          table.insert(short, missing .. " " .. CR.ItemName(rg[1]))
          local price = CR.GetUnitPrice(rg[1])
          if price then cost = cost + price * missing else unpriced = true end
        end
      end
    end
    local lines = {}
    if #fetch > 0 then
      table.insert(lines, CR.ColorText("Fetch from bank/alts: " .. table.concat(fetch, ", "), "ffd100"))
    end
    if #short > 0 then
      table.insert(lines, string.format("For all %d you still need: %s", st.crafts, table.concat(short, ", "))
        .. (cost > 0 and ("  ·  " .. CR.FormatMoney(cost) .. (unpriced and "+" or "")) or ""))
    end
    if #lines == 0 then
      lines[1] = CR.ColorText(string.format("Everything for all %d is in your bags.", st.crafts), "40ff40")
    elseif #short == 0 then
      table.insert(lines, CR.ColorText(string.format("You have everything for all %d.", st.crafts), "40ff40"))
    end
    stepNeed:SetText(table.concat(lines, "\n"))

    FillPreview(nextFrame, ahead[1], floor)
    FillPreview(afterFrame, ahead[2], floor)

    -- Controls
    local open = CR.TradeSkillOpenFor(rprof.name)
    local learned, available = RecipeState(rprof, r)
    local craftable = open and learned ~= false
    createAll:SetShown(open); create:SetShown(open); countBox:SetShown(open)
    for _, child in ipairs({ controls:GetChildren() }) do
      if child ~= openBtn and child ~= createAll and child ~= create and child ~= countBox then child:SetShown(open) end
    end
    openBtn:SetShown(not open)
    openBtn:SetText("Open " .. rprof.name)
    if not detected then
      status:SetText(CR.ColorText("You haven't learned " .. profName .. " on this character.", "ff9966"))
      openBtn:Disable()
    elseif not open then
      status:SetText("The profession window is closed - crafting needs it open.")
      openBtn:SetEnabled(not InCombatLockdown())
    elseif learned == false then
      status:SetText(CR.ColorText("You haven't learned " .. r.name .. " yet - " .. CR.FactionText(r.pattern or r.src), "ff9966"))
    elseif available == 0 then
      status:SetText(CR.ColorText("Not enough reagents in your bags.", "ff6060"))
    else
      status:SetText(string.format("You can make %d now.", available))
    end
    local target = panel:UpdateEnchant(r, enchantFits, enchantKind, craftable and (available or 0) > 0)
    if enchantFits and open and learned ~= false and (available or 0) > 0 then
      status:SetText(CR.VisibleReplacePopup() and CR.ColorText("Click Enchant (or the target) to replace the enchant.", "ffd100")
        or target and string.format("Click the target (or Enchant) for each cast - %d possible now.", available)
        or CR.ColorText("Hover the enchant target slot to pick what to enchant.", "ffd100"))
    end
    createAll:SetText(string.format("Create All [%d]", available or 0))
    createAll:SetEnabled(craftable and (available or 0) > 0)
    if IsRepeating() then
      create:SetText("Stop")
      create:Enable()
    elseif enchantFits then
      -- one cast per click, onto the target
      create:SetText("Enchant")
      create:SetEnabled((craftable and (available or 0) > 0 and target ~= nil) or CR.VisibleReplacePopup() ~= nil)
      createAll:Disable()
    else
      create:SetText("Create")
      create:SetEnabled(craftable and (available or 0) > 0)
    end
    if not countBox:HasFocus() then
      local want = math.max(1, math.min(st.crafts, (available or 0) > 0 and available or st.crafts))
      if panel.lastSpell ~= r.spell then countBox:SetNumber(want) end
    end
    panel.lastSpell = r.spell
    panel.currentCrafts = st.crafts
    panel.current = r
    panel.UpdateBuyPop()
    SyncSecureButtons(enchantFits and true or false)
  end

  createAll:SetScript("OnClick", function()
    local r = panel.current
    if not r then return end
    local _, available = RecipeState(CR.professions[CR.Route(db().profession).recipeProf or db().profession], r)
    if (available or 0) > 0 then Craft(r, available) end
  end)
  create:SetScript("OnClick", function()
    if IsRepeating() and TS.StopRecipeRepeat then TS.StopRecipeRepeat() return end
    local r = panel.current
    if r and CR.EnchantSlotFor(r) then return end   -- enchants go through the secure cover below
    if r then Craft(r, math.max(1, countBox:GetNumber() or 1)) end
  end)
  SecureEnchantButton(create, function()
    return EnchantClick(panel.current, ench.target, true)
  end)
  openBtn:SetScript("OnClick", function()
    local route = CR.Route(db().profession)
    CR.OpenTradeSkill(route and route.recipeProf or db().profession)
  end)
  SecureEnchantButton(openBtn, function() return CR.OpenProfessionMacro(db().profession) or "" end, {
    plain = true,
    wanted = function() return openBtn:IsVisible() and CR.OpenProfessionMacro(db().profession) ~= nil end,
  })

  CR.craftPanel = panel
  return panel
end

-- Keep the Craft tab live: the profession window opening/closing, casts and crafts finishing.
local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE",
                     "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED",
                     "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
                     "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                     "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE",
                     "REPLACE_ENCHANT", "PLAYER_EQUIPMENT_CHANGED" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    pcall(ev.RegisterEvent, ev, e)
  end
end
ev:SetScript("OnEvent", function(_, event, unit)
  if (event:find("^UNIT_") and unit ~= "player") then return end
  -- combat: hide the secure covers now (the last moment they can be), keep them hidden until it ends
  if event == "PLAYER_REGEN_DISABLED" then CR.HideSecureEnchantButtons(); CR.inCombat = true end
  if event == "PLAYER_REGEN_ENABLED" then CR.inCombat = false end
  if event == "REPLACE_ENCHANT" then
    if C_Timer then C_Timer.After(0, CR.NotifyChanged) end   -- status line: "click to replace"
    return
  end
  if event:find("^MERCHANT_") then
    if event == "MERCHANT_SHOW" then merchantOpen = true elseif event == "MERCHANT_CLOSED" then merchantOpen = false end
    ScanMerchant()
    CR.RefreshBuyPop()
  end
  if event:find("^UNIT_SPELLCAST") and CR.craftPanel then
    CR.SafeCall(CR.craftPanel.UpdateCast, CR.craftPanel, event)
    if event == "UNIT_SPELLCAST_START" then return end   -- nothing else changes until it finishes
  end
  CR.NotifyChanged()
end)
