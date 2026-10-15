-- All materials: one window over every profession you're leveling - each material any of their
-- routes still needs down the left, a column per profession (what that route needs of it), and the
-- total on the right (what you have of what they need together). Professions are the ones you've
-- learned whose route uses materials; an item hidden in a profession's own tracker is left out of
-- that profession's column. Open with the main window's "All" button or /cr all.
-- Like the trackers: size panel (width of the names, scale, height - shorter scrolls) and a corner
-- grip for the height, Ctrl+wheel scales; the Alts tick; above the materials, vendor items shown
-- or not, and the order - Route order (by the first column's route, then the next column's...),
-- Milestones (split by
-- rank band - 1-75, 75-150, 150-225, 225-300 - each band with what the routes use in it, what you
-- have counting towards the earliest bands first; each band's line has what reaching it still
-- costs) or A-Z. (No shopping carts here.)
-- Click a profession's icon to pick which guide it tracks: its route's own goal, or to 75 / 150 /
-- 225 / 300 (Settings().goals[profession]) - its goal shows under the icon in its rank's colour
-- (Apprentice white, Journeyman green, Expert blue, Artisan purple); picked here: a gold border. Right-click an icon to take that profession off
-- (Settings().removed), drag it to move its column (Settings().order), double-click it for that
-- profession's own tracker; the + after the icons adds a removed one back.
-- Every profession you've learned has a column (secondary ones too), even with nothing to track.
-- The + also adds another character's profession (each character's professions are recorded when
-- it logs in: CraftRouteDB.characters) - its column is planned from that character's skill, to the
-- guide picked on its icon like any other; its name sits over the icon. Settings().alts = keys
-- "alt:<Name-Realm>:<profession>".
-- Kept per character (CraftRouteCharDB.trackerAll).
local _, CR = ...

local ROW_H, HEAD_H, BAND_H, MAX_ROWS = 20, 58, 18, 25
local ICON_H = 34   -- a profession's heading: its icon, its goal under it (at the header's bottom)
local COL_W, TOTAL_W, MIN_NAME, MAX_NAME = 44, 74, 100, 320
local MIN_S, MAX_S, MIN_H, MAX_H = 0.6, 2, 120, 900
local BANDS = { { 1, 75 }, { 75, 150 }, { 150, 225 }, { 225, 300 } }
-- the title bar (Edit: nothing behind it yet - kept for what comes)
local editing = false
local function Top() return 28 end

local frame, rows, cols, offset = nil, {}, {}, 0
local charLabels, colTints, headTints = {}, {}, {}   -- names over a character's columns, the columns' tints (list / header)
CR.AllMaterialsNames = function() return charLabels, colTints end   -- (tests)
local sizePanel, sizePanelSync

local function Settings()
  local db = CraftRouteCharDB
  if not db then return {} end
  db.trackerAll = db.trackerAll or {}
  return db.trackerAll
end
local function Scale() return Settings().scale or 1 end

-- this character's professions, kept account-wide so its alts can add them here
local function MyKey()
  local name, realm = UnitName and UnitName("player"), GetRealmName and GetRealmName()
  return name and (name .. "-" .. (realm or "")) or nil
end
local function Characters()
  CraftRouteDB.characters = CraftRouteDB.characters or {}
  return CraftRouteDB.characters
end
local function RecordCharacter()
  local key = MyKey()
  if not (key and CraftRouteDB) then return end
  -- (UnitClass's second value: the class's file name, MAGE - what the class colours go by)
  local class = UnitClass and select(2, UnitClass("player"))
  local c = Characters()[key] or {}
  c.name, c.class = UnitName("player"), class or c.class
  c.profs = {}
  for prof, sk in pairs(CR.skill or {}) do
    c.profs[prof] = { rank = sk.rank or 0, maxRank = sk.maxRank or 0 }
  end
  Characters()[key] = c
end
-- a character's class (MAGE...): CraftRoute's own record, made when that character logs in. Else
-- Syndicator's - only for exactly the same character (its full name and realm), never a guess by
-- name - and kept, once found
local function CharClass(key, c)
  if c and c.class then return c.class end
  local api = Syndicator and Syndicator.API
  local get = api and api.GetByCharacterFullName
  if get and key then
    local name, realm = key:match("^(.-)%-(.*)$")
    local function Found(class) if class and c then c.class = class end return class end
    for _, full in ipairs({ key, name and realm and (name .. "-" .. realm:gsub("[%s%-]", "")) or key }) do
      local ok, data = pcall(get, full)
      local class = ok and type(data) == "table" and data.details and data.details.className
      if class then return Found(class) end
    end
  end
end
local function ClassHex(class)
  local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  return cc and cc.colorStr and cc.colorStr:sub(3) or "ffffff"
end

-- an alt's route goal: its current rank's cap, or (at the cap already) the next milestone
local function AltRouteGoal(col)
  local cur, cap = col.cur or 0, col.maxRank or 0
  if cap > cur then return cap end
  for _, g in ipairs({ 75, 150, 225, 300 }) do if g > cur then return g end end
  return 300
end

-- a column: your own profession (its key is the profession), or an alt's ("alt:Name-Realm:prof");
-- nil when it isn't there (not learned, taken off, or the alt has no record of it)
local function Column(key)
  local char, prof = key:match("^alt:(.+):([^:]+)$")
  if char then
    local c = Characters()[char]
    local sk = c and c.profs and c.profs[prof]
    if not (sk and CR.Route and CR.Route(prof)) then return nil end
    return { key = key, prof = prof, char = char, charName = c.name or char, class = CharClass(char, c),
             cur = sk.rank, maxRank = sk.maxRank }
  end
  local cur, maxRank, detected = CR.GetSkill(key)
  local removed = Settings().removed
  if not detected or (removed and removed[key]) then return nil end
  return { key = key, prof = key, cur = cur, maxRank = maxRank }
end

-- an item hidden in that profession's own tracker
local function HiddenIn(prof, id)
  local t = CraftRouteCharDB and CraftRouteCharDB.tracker
  return t and t.hidden and t.hidden[prof] and t.hidden[prof][id] and true or false
end

local function BandOf(at)
  for i, b in ipairs(BANDS) do if at < b[2] then return i end end
  return #BANDS
end

-- a profession's plan: the route's own (CraftRoute's goal), or one built to the goal picked here -
-- those are kept until something changes (bags, skills, the routes: plans wiped)
local plans = {}
local function PlanFor(col)
  local goals = Settings().goals
  local goal = goals and goals[col.key]
  local picked = goal ~= nil
  if not goal then
    -- yours: CraftRoute's own plan; an alt's: to its current rank's cap (its own record - your
    -- character's rank says nothing about it), or at that cap the next milestone
    if not col.char then return CR.GetPlans and CR.GetPlans(col.prof) end
    goal = AltRouteGoal(col)
  end
  local key = col.key .. ":" .. goal .. (picked and ":p" or "")
  if plans[key] then return plans[key] end
  local cur = col.cur or 0
  local e = { cur = cur, goal = goal, picked = picked or nil,
              plan = (goal > cur) and CR.BuildPlan(col.prof, cur, goal) or { materials = {}, steps = {} } }
  plans[key] = e
  return e
end

-- professions taken off this window, and the columns' order
local function Removed()
  local st = Settings()
  st.removed = st.removed or {}
  return st.removed
end
local preview   -- while a column is dragged: the order it would leave (shown live)
local dragCol   -- the column heading being dragged
local function AltKeys()
  local st = Settings()
  st.alts = st.alts or {}
  return st.alts
end
local function Ordered()
  local list = CR.SupportedProfessions()
  for _, k in ipairs(AltKeys()) do table.insert(list, k) end
  local pos = {}
  for i, name in ipairs(preview or Settings().order or {}) do pos[name] = i end
  local natural = {}
  for i, name in ipairs(list) do natural[name] = i end
  table.sort(list, function(a, b)
    local pa, pb = pos[a] or (1000 + natural[a]), pos[b] or (1000 + natural[b])
    return pa < pb
  end)
  return list
end

-- profs = { { name, cur, goal } }; items = { { id, name, per = { [prof] = n }, need, have, price,
-- crafted, first, band = { [i] = { per = { [prof] = n }, need, first } } } }
local function Gather()
  local profs, byId, items = {}, {}, {}
  local hideVendor = Settings().hideVendor
  for _, name in ipairs(Ordered()) do
    local col = Column(name)
    local e = col and PlanFor(col)
    local mats = e and e.plan and e.plan.materials
    local any = false
    -- the order this column's route uses its materials (each step's reagents, what a step has you buy)
    local pos, n = {}, 0
    local function Seen(id) n = n + 1 if id and not pos[id] then pos[id] = n end end
    for _, st in ipairs(e and e.plan and e.plan.steps or {}) do
      if st.recipe then for _, rg in ipairs(st.recipe.reagents or {}) do Seen(rg[1]) end end
      for _, x in ipairs(st.items or {}) do Seen(x[1]) end
      for _, x in ipairs(st.has or {}) do Seen(x[1]) end
    end
    for _, m in ipairs(mats or {}) do
      if (m.need or 0) > 0 and not (not col.char and HiddenIn(name, m.id)) and not (hideVendor and CR.IsVendorItem and CR.IsVendorItem(m.id)) then
        any = true
        local it = byId[m.id]
        if not it then
          it = { id = m.id, name = m.name or CR.ItemName(m.id), per = {}, need = 0, have = 0, crafted = 0,
                 price = m.price, first = math.huge, band = {}, order = {} }
          byId[m.id] = it
          table.insert(items, it)
        end
        it.per[name] = (it.per[name] or 0) + m.need
        it.need = it.need + m.need
        it.have = math.max(it.have, m.have or 0)   -- (what you have is the same stock for each)
        it.crafted = it.crafted + (m.crafted or 0)
        it.price = it.price or m.price
        -- (where it comes in this column's route; never seen in its steps: after the rest)
        it.order[name] = pos[m.id] or (100000 + (m.usage and m.usage[1] and m.usage[1].at or 0))
        -- by band: where in the route each use is (a use with no skill: where you are now)
        local uses = m.usage
        if not uses or #uses == 0 then uses = { { n = m.need, at = e.cur or 1 } } end
        for _, u in ipairs(uses) do
          local at = u.at or e.cur or 1
          local b = it.band[BandOf(at)]
          if not b then b = { per = {}, need = 0, first = math.huge } it.band[BandOf(at)] = b end
          b.per[name] = (b.per[name] or 0) + (u.n or 0)
          b.need = b.need + (u.n or 0)
          b.first = math.min(b.first, at)
          it.first = math.min(it.first, at)
        end
      end
    end
    -- every learned one gets its column, even with nothing to track (finished, or a guide that uses
    -- no materials) - so you see it's taken into account
    if e then
      table.insert(profs, { name = name, prof = col.prof, char = col.char, charName = col.charName, class = col.class,
                            label = col.char and (col.charName .. "'s " .. col.prof) or col.prof,
                            cur = e.cur, goal = e.goal, picked = e.picked, empty = not any })
    end
  end
  return profs, items
end

-- what's still to buy of these lines: the materials, the cost, how many unpriced
-- (what a route makes itself isn't bought)
local function ToBuy(lines, label)
  local mats, cost, unpriced = {}, 0, 0
  for _, l in ipairs(lines) do
    local missing = l.need - l.have
    if l.it and missing > 0 and l.it.crafted == 0 then
      table.insert(mats, { id = l.it.id, missing = missing, name = l.it.name })
      if l.it.price then cost = cost + l.it.price * missing else unpriced = unpriced + 1 end
    end
  end
  return { prof = label, materials = mats }, cost, unpriced
end

-- route order across the columns: by the first column's route (where it uses each material), then
-- what only the second uses, by its route, and so on - so whichever profession is in the first
-- column leads (drag another there and the list follows)
local function RouteKey(it, profs)
  for j, p in ipairs(profs) do
    local o = it.order[p.name]
    if o then return j, o end
  end
  return #profs + 1, it.first
end
local function RouteBefore(a, b, profs)
  local ja, oa = RouteKey(a, profs)
  local jb, ob = RouteKey(b, profs)
  if ja ~= jb then return ja < jb end
  if oa ~= ob then return oa < ob end
  return (a.name or "") < (b.name or "")
end

-- the lines to show: { head = "1-75" } and { it = item, per, need, have } in display order
local function Lines(items, profs)
  local out = {}
  local function Line(it, per, need, have)
    return { it = it, per = per, need = need, have = have }
  end
  local sort = Settings().sort
  if sort ~= "milestone" then
    -- one list: still-needed first, then by where the routes first use it (route order) or by name
    local list = {}
    for _, it in ipairs(items) do table.insert(list, Line(it, it.per, it.need, it.have)) end
    table.sort(list, function(a, b)
      local da, db = a.have >= a.need, b.have >= b.need
      if da ~= db then return not da end
      if sort ~= "name" then return RouteBefore(a.it, b.it, profs) end
      return (a.it.name or "") < (b.it.name or "")
    end)
    return list
  end
  -- milestones: split by band; what you have fills the earliest band first
  local left = {}
  for _, it in ipairs(items) do left[it] = it.have end
  for i, band in ipairs(BANDS) do
    local list = {}
    for _, it in ipairs(items) do
      local b = it.band[i]
      if b and b.need > 0 then
        local have = math.min(b.need, left[it])
        left[it] = left[it] - have
        local l = Line(it, b.per, b.need, have)
        l.first = b.first
        table.insert(list, l)
      end
    end
    if #list > 0 then
      table.sort(list, function(a, b) return RouteBefore(a.it, b.it, profs) end)
      -- the milestone's line: what reaching it still costs, and its own shopping list
      local label = string.format("%d-%d", band[1], band[2])
      local _, cost, unpriced = ToBuy(list, "All Materials " .. label)
      -- (the milestone's line closes its materials: below them)
      for _, l in ipairs(list) do table.insert(out, l) end
      table.insert(out, { head = label, cost = cost, unpriced = unpriced })
    end
  end
  return out
end

local function SavePos()
  local l, t = frame:GetLeft(), frame:GetTop()
  if l and t then Settings().pos = { "TOPLEFT", "BOTTOMLEFT", l, t } end
end

local function Place()
  frame:ClearAllPoints()
  frame:SetFrameStrata(CR.PopoutStrata and CR.PopoutStrata() or "HIGH")
  local p = Settings().pos
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120) end
end

local function StartDrag() frame:StartMoving() end
local function StopDrag()
  frame:StopMovingOrSizing()
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, false) end
  SavePos()
end

-- the wheel over anything in the window (rows, headings, the +) does what it does over the window:
-- scroll, or with Ctrl held scale
local function PassWheel(w)
  w:EnableMouseWheel(true)
  w:SetScript("OnMouseWheel", function(_, delta)
    local h = frame and frame:GetScript("OnMouseWheel")
    if h then h(frame, delta) end
  end)
end

local function Cell(parent, justify, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetJustifyH(justify)
  fs:SetWordWrap(false)
  return fs
end

local function Row(i)
  local r = rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, frame)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ROW_H - 4, ROW_H - 4)
  r.icon:SetPoint("LEFT", 0, 0)
  r.name = Cell(r, "LEFT")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
  r.head = Cell(r, "LEFT", "GameFontNormalSmall")
  r.head:SetPoint("LEFT", 0, -1)
  r.line = r:CreateTexture(nil, "ARTWORK")
  r.line:SetHeight(1)
  r.line:SetColorTexture(1, 0.82, 0.35, 0.25)
  r.line:SetPoint("LEFT", r.head, "RIGHT", 6, 0)
  r.line:SetPoint("RIGHT", 0, -1)
  r.bandCost = Cell(r, "RIGHT")
  r.bandCost:SetPoint("RIGHT", 0, 0)   -- (a milestone's cost, at the line's end)
  r.bandCost:Hide()
  r.cells = {}
  r.total = Cell(r, "RIGHT")
  -- under the + : an empty slot's "-" (what's added there will fill it)
  r.spare = Cell(r, "CENTER")
  r.spare:SetWidth(20)
  r.spare:SetText(CR.ColorText("-", "555555"))
  r.hl = r:CreateTexture(nil, "HIGHLIGHT")
  r.hl:SetAllPoints()
  r.hl:SetColorTexture(1, 1, 1, 0.06)
  r:SetScript("OnEnter", function(self)
    local l = self.l
    if not (l and l.it) then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetItemByID(l.it.id)
    for _, p in ipairs(frame.profs or {}) do
      local n = l.per[p.name]
      if n then GameTooltip:AddDoubleLine(p.label or p.name, tostring(n), 0.8, 0.8, 0.8, 1, 1, 1) end
    end
    GameTooltip:AddLine(string.format("Together %d - you have %d%s.", l.it.need, l.it.have,
      l.it.crafted > 0 and string.format(", %d made on the way", l.it.crafted) or ""), 0.4, 0.8, 1, true)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:RegisterForDrag("LeftButton")
  r:SetScript("OnDragStart", StartDrag)
  r:SetScript("OnDragStop", StopDrag)
  PassWheel(r)
  rows[i] = r
  if CR.NoteThemeFonts then CR.NoteThemeFonts(r) end
  return r
end

-- a profession's column heading: its icon and the goal it's tracking to; click it to pick which
-- guide it tracks (the route's own goal, or 75 / 150 / 225 / 300)
local Refresh
local GOAL_OPTS = { 75, 150, 225, 300 }
-- a goal's colour, by the rank it's in: Apprentice (to 75) white, Journeyman (150) green, Expert
-- (225) blue, Artisan (300) purple
local RANKS = { { 75, "Apprentice", "ffffff" }, { 150, "Journeyman", "1eff00" }, { 225, "Expert", "3d9cff" },
                { 300, "Artisan", "b46dff" } }
local function RankOf(goal)
  for _, r in ipairs(RANKS) do if goal <= r[1] then return r end end
  return RANKS[#RANKS]
end
local dragged = {}   -- [column] = just dragged (its release isn't a click)
local function Col(name)
  local c = cols[name]
  if c then return c end
  c = CR.CreateDropdown(frame, COL_W, function()
    local p = c and c.p
    local route
    if p and p.char then
      local col = Column(p.name)
      route = col and AltRouteGoal(col)
    else
      local e = p and CR.GetPlans and CR.GetPlans(p.prof or p.name)
      route = e and e.goal
    end
    local opts = { { value = "route", text = "Route goal" .. (route and string.format(" (%d)", route) or ""), radio = true } }
    for _, g in ipairs(GOAL_OPTS) do
      table.insert(opts, { value = g, text = string.format("%s to %d", p and (p.label or p.name) or "", g), radio = true })
    end
    return opts
  end, function()
    local goals = Settings().goals
    return c and c.p and goals and goals[c.p.name] or "route"
  end, function(v)
    local p = c.p
    if not p then return end
    local st = Settings()
    st.goals = st.goals or {}
    st.goals[p.name] = (v ~= "route") and v or nil
    offset = 0
    Refresh()
  end)
  c:SetSize(COL_W, ICON_H)
  -- (the box itself: just the icon and the goal - no frame, no text, no arrow)
  if c.SetBackdropColor then c:SetBackdropColor(0, 0, 0, 0) end
  if c.SetBackdropBorderColor then c:SetBackdropBorderColor(0, 0, 0, 0) end
  c.text:SetAlpha(0)
  for _, r in ipairs({ c:GetRegions() }) do
    if r ~= c.text and r.GetText and r:GetText() == "v" then r:Hide() end
  end
  c.icon = c:CreateTexture(nil, "ARTWORK")
  c.icon:SetSize(18, 18)
  c.icon:SetPoint("TOP", 0, -2)
  c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  -- picked here (not the route's own goal): a gold border round the icon
  c.picked = {}
  for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -1 },
                       { "TOPLEFT", "BOTTOMLEFT", -1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 } }) do
    local t = c:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(1, 0.82, 0, 1)
    t:SetPoint(e[1], c.icon, e[1], e[3] ~= 0 and e[3] or 0, e[4] ~= 0 and e[4] or 0)
    t:SetPoint(e[2], c.icon, e[2], e[3] ~= 0 and e[3] or 0, e[4] ~= 0 and e[4] or 0)
    if e[3] ~= 0 then t:SetWidth(1) else t:SetHeight(1) end
    table.insert(c.picked, t)
  end
  c.goal = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  c.goal:SetPoint("TOP", c.icon, "BOTTOM", 0, -1)   -- (stacked under the icon)
  -- an alt's column: its name over the icon, in its class colour
  c.char = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  c.char:SetPoint("BOTTOM", c.icon, "TOP", 0, 2)
  c.char:SetWidth(COL_W)
  c.char:SetWordWrap(false)
  c:SetScript("OnEnter", function(self)
    local p = self.p
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(p.label or p.name)
    if p.char then GameTooltip:AddLine(string.format("%s's skill: %d", p.charName, p.cur or 0), 0.8, 0.8, 0.8) end
    if p.cur and p.goal then
      local rank = RankOf(p.goal)
      GameTooltip:AddLine(string.format("To %d - %s", p.goal, CR.ColorText(rank[2], rank[3])), 1, 1, 1)
      GameTooltip:AddLine(p.picked and "Picked here (gold border) - pick \"Route goal\" to follow the route again."
        or "Following the route's own goal.", 0.8, 0.8, 0.8, true)
    end
    if p.empty then
      GameTooltip:AddLine("Nothing to track - its guide is done, or uses no materials.", 0.4, 0.8, 1, true)
    end
    GameTooltip:AddLine("Click to pick which guide this column tracks: the route's own goal, or to 75 / 150 / 225 / 300.",
      0.6, 0.6, 0.6, true)
    GameTooltip:Show()
  end)
  c:SetScript("OnLeave", GameTooltip_Hide)
  -- left: the guide menu (a second click straight after makes it a double-click: that profession's
  -- own tracker instead); right: off this window; drag: move the column
  local openMenu = c:GetScript("OnClick")
  local pending
  c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  c:SetScript("OnClick", function(self, button)
    local p = self.p
    if not p then return end
    if dragged[self] then dragged[self] = nil return end
    if button == "RightButton" then
      GameTooltip_Hide()
      if p.char then
        -- an alt's column: gone (the + adds it again)
        local alts = AltKeys()
        for j = #alts, 1, -1 do if alts[j] == p.name then table.remove(alts, j) end end
        if Settings().goals then Settings().goals[p.name] = nil end
      else
        Removed()[p.name] = true
      end
      Refresh()
      return
    end
    -- the second click of a double-click: the menu the first one opened closes again, and that
    -- profession's own tracker opens
    if pending then
      pending = nil
      if self.menu then self.menu:Hide() end
      if CR.ToggleTracker and not p.char then CR.ToggleTracker(true, p.name) end   -- (an alt's has none)
      return
    end
    -- a click: the guide menu straight away (no waiting to see if a second click comes)
    openMenu(self)
    local token = {}
    pending = token
    C_Timer.After(0.3, function() if pending == token then pending = nil end end)
  end)
  c:RegisterForDrag("LeftButton")
  -- dragged: it follows the cursor along the headings, and as it passes a column the columns (and
  -- their numbers) shift over to make room - the order you'll get, live; released, it stays
  local function Slot()
    local x = GetCursorPosition() / frame:GetEffectiveScale()
    local first = frame.colsLeft and frame:GetLeft() and (frame:GetLeft() + frame.colsLeft)
    local n = #(frame.profs or {})
    if not first or n == 0 then return nil end
    return math.max(1, math.min(n, math.floor((x - first) / COL_W) + 1))
  end
  -- the dragged column into the slot under the cursor (the others shift over)
  local function MoveTo(self)
    if not preview then return end
    local to = Slot()
    local from
    for j, n in ipairs(preview) do if n == self.p.name then from = j end end
    if to and from and to ~= from then
      table.remove(preview, from)
      table.insert(preview, to, self.p.name)
      Refresh()
    else
      Refresh(true)   -- (just the dragged heading under the cursor)
    end
  end
  c:SetScript("OnDragStart", function(self)
    pending = nil
    dragged[self] = true
    if self.menu then self.menu:Hide() end
    GameTooltip_Hide()
    dragCol = self
    preview = {}
    for _, q in ipairs(frame.profs or {}) do table.insert(preview, q.name) end
    self:SetFrameLevel(frame:GetFrameLevel() + 20)
    self:SetScript("OnUpdate", MoveTo)
    Refresh()
  end)
  c:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    MoveTo(self)   -- (where it's let go)
    self:SetFrameLevel(frame:GetFrameLevel() + 2)
    dragCol = nil
    C_Timer.After(0, function() dragged[self] = nil end)   -- (a release that isn't a click)
    -- the order it was dropped in: these columns, then the rest as they were
    if preview then
      local seen, order = {}, {}
      for _, n in ipairs(preview) do seen[n] = true table.insert(order, n) end
      preview = nil
      for _, n in ipairs(Ordered()) do if not seen[n] then table.insert(order, n) end end
      Settings().order = order
    end
    Refresh()
  end)
  PassWheel(c)
  cols[name] = c
  return c
end

-- the + after the headings: put back a profession taken off, or add another character's - pick
-- the character, then (a second menu) which of its professions
local addBtn
local ForceAlts
-- another character's guide here: their materials (bags, bank, mail) have to count - "Count alts'
-- materials" is switched on, and stays on while any alt column is here (CR.AllMaterialsUsesAlts)
function CR.AllMaterialsUsesAlts()
  local st = CraftRouteCharDB and CraftRouteCharDB.trackerAll
  return st and st.alts and #st.alts > 0 or false
end
function ForceAlts()
  if CR.AllMaterialsUsesAlts() and CraftRouteCharDB and not CraftRouteCharDB.includeAlts then
    CraftRouteCharDB.includeAlts = true
    if CR.InvalidateLocations then CR.InvalidateLocations() end
    CR.NotifyChanged()
  end
end
-- The + menu: tick boxes - your professions (ticked: on this window), then your other characters;
-- clicking (or, with one open, hovering) a character opens its professions beside that row, ticked
-- when they're on the window. A tick goes on / off straight away and the menus stay open, so you can
-- pick several; a click anywhere else closes them.
local addMenu, subMenu
local MENU_ROW = 20
local CHECK = "Interface\\Buttons\\UI-CheckBox-Up"
local TICK = "Interface\\Buttons\\UI-CheckBox-Check"

local function MenuFrame()
  local m = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  m:SetFrameStrata("FULLSCREEN_DIALOG")
  m:SetClampedToScreen(true)
  CR.Backdrop(m, 0.05, 0.05, 0.05, 0.97)
  m:EnableMouse(true)
  m.rows = {}
  m:Hide()
  return m
end
-- a menu's line i: a heading, a tick-box entry, or (more = true) one that opens a sub-menu
local function MenuRow(m, i)
  local r = m.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, m)
  r:SetHeight(MENU_ROW)
  r.box = r:CreateTexture(nil, "ARTWORK")
  r.box:SetSize(18, 18)
  r.box:SetPoint("LEFT", 4, 0)
  r.box:SetTexture(CHECK)
  r.tick = r:CreateTexture(nil, "OVERLAY")
  r.tick:SetAllPoints(r.box)
  r.tick:SetTexture(TICK)
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.head = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  r.head:SetPoint("LEFT", 6, 0)
  r.more = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  r.more:SetPoint("RIGHT", -6, 0)
  r.more:SetText(">")
  r.hl = r:CreateTexture(nil, "HIGHLIGHT")
  r.hl:SetAllPoints()
  r.hl:SetColorTexture(0.2, 0.6, 1, 0.3)
  if CR.NoteThemeFonts then CR.NoteThemeFonts(r) end
  m.rows[i] = r
  return r
end
-- lines: { { head = text } | { text, checked, onClick } | { text, more = true, onClick, onEnter } }
local function FillMenu(m, lines)
  local widest = 120
  for i, l in ipairs(lines) do
    local r = MenuRow(m, i)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * MENU_ROW)
    r:SetPoint("RIGHT", -2, 0)
    r.line = l
    r.text:ClearAllPoints()
    if l.head then
      r.head:SetText(l.head) r.head:Show()
      r.text:Hide() r.box:Hide() r.tick:Hide() r.more:Hide()
      r.hl:SetAlpha(0)
      r:EnableMouse(false)
      widest = math.max(widest, (tonumber(r.head:GetStringWidth()) or 0) + 16)
    else
      r.head:Hide()
      r.text:Show()
      r.hl:SetAlpha(1)
      r:EnableMouse(true)
      r.more:SetShown(l.more and true or false)
      r.box:SetShown(not l.more)
      r.tick:SetShown(not l.more and l.checked and true or false)
      r.text:SetPoint("LEFT", l.more and 10 or 26, 0)
      r.text:SetText(l.text)
      widest = math.max(widest, (tonumber(r.text:GetStringWidth()) or 0) + (l.more and 34 or 40))
    end
    r:SetScript("OnClick", l.onClick and function(self) self.line.onClick(self) end or nil)
    r:SetScript("OnEnter", l.onEnter and function(self) self.line.onEnter(self) end or nil)
    r:Show()
  end
  for i = #lines + 1, #m.rows do m.rows[i]:Hide() end
  m:SetSize(math.ceil(widest), #lines * MENU_ROW + 4)
end

local function ProfLabel(prof, extra)
  local icon = CR.ProfessionIcon and CR.ProfessionIcon(prof)
  return (icon and ("|T" .. icon .. ":16:16|t ") or "") .. prof .. (extra or "")
end

local OpenSub
-- the character's professions, beside its row
function OpenSub(char, row)
  local c = Characters()[char]
  if not c then return end
  subMenu = subMenu or MenuFrame()
  subMenu.char, subMenu.row = char, row
  local have = {}
  for _, k in ipairs(AltKeys()) do have[k] = true end
  local names = {}
  for prof in pairs(c.profs or {}) do if CR.Route and CR.Route(prof) then table.insert(names, prof) end end
  table.sort(names)
  local lines = { { head = CR.ColorText(c.name or char, ClassHex(CharClass(char, c))) .. "'s professions" } }
  for _, prof in ipairs(names) do
    local key = "alt:" .. char .. ":" .. prof
    local sk = c.profs[prof]
    table.insert(lines, { text = ProfLabel(prof, "  " .. CR.ColorText(string.format("%d/%d", sk.rank or 0, sk.maxRank or 0), "aaaaaa")),
      checked = have[key], onClick = function()
        local alts = AltKeys()
        if have[key] then
          for j = #alts, 1, -1 do if alts[j] == key then table.remove(alts, j) end end
          if Settings().goals then Settings().goals[key] = nil end
        else
          table.insert(alts, key)
          ForceAlts()
        end
        Refresh()
        OpenSub(char, row)   -- (its ticks again)
      end })
  end
  if #names == 0 then table.insert(lines, { text = CR.ColorText("No professions recorded", "888888"), more = true }) end
  FillMenu(subMenu, lines)
  subMenu:ClearAllPoints()
  subMenu:SetPoint("TOPLEFT", row, "TOPRIGHT", 4, 2)
  subMenu:Show()
end

local OpenAdd, CloseMenus
function OpenAdd()
  addMenu = addMenu or MenuFrame()
  local lines = {}
  -- your professions: ticked when on the window
  local mine = {}
  for _, name in ipairs(CR.SupportedProfessions()) do
    local _, _, detected = CR.GetSkill(name)
    if detected then table.insert(mine, name) end
  end
  if #mine > 0 then
    table.insert(lines, { head = "Your professions" })
    for _, name in ipairs(mine) do
      table.insert(lines, { text = ProfLabel(name), checked = not Removed()[name], onClick = function()
        Removed()[name] = (not Removed()[name]) or nil
        Refresh()
        OpenAdd()   -- (its ticks again)
      end })
    end
  end
  -- your other characters: their professions in a menu beside the row
  local me, others = MyKey(), {}
  for key, c in pairs(Characters()) do
    if key ~= me and c.profs and next(c.profs) then table.insert(others, key) end
  end
  table.sort(others)
  if #others > 0 then
    table.insert(lines, { head = "Other characters" })
    for _, key in ipairs(others) do
      local c = Characters()[key]
      table.insert(lines, { text = CR.ColorText(c.name or key, ClassHex(CharClass(key, c))), more = true,
        onClick = function(row) OpenSub(key, row) end,
        onEnter = function(row) if subMenu and subMenu:IsShown() and subMenu.char ~= key then OpenSub(key, row) end end })
    end
  end
  if #lines == 0 then table.insert(lines, { text = CR.ColorText("Nothing to add - log in on your other characters once", "888888"), more = true }) end
  local wasShown = addMenu:IsShown()
  FillMenu(addMenu, lines)
  -- placed under the + where it opens, then left there on screen: ticking adds or drops columns,
  -- which moves the + - the menu (and the cursor's place in it) mustn't move with it
  if not wasShown then
    addMenu:ClearAllPoints()
    local l, b = addBtn:GetLeft(), addBtn:GetBottom()
    if l and b then
      local k = addBtn:GetEffectiveScale() / UIParent:GetEffectiveScale()
      addMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * k, b * k - 2)
    else
      addMenu:SetPoint("TOPLEFT", addBtn, "BOTTOMLEFT", 0, -2)
    end
  end
  addMenu:Show()
  if addBtn and addBtn.watch then pcall(addBtn.watch.RegisterEvent, addBtn.watch, "GLOBAL_MOUSE_DOWN") end
  -- an open character menu follows its row (the rows may have moved)
  if subMenu and subMenu:IsShown() then
    for _, r in ipairs(addMenu.rows) do
      if r:IsShown() and r.line and r.line.more and subMenu.row == r then OpenSub(subMenu.char, r) end
    end
  end
end

function CloseMenus()
  if subMenu then subMenu:Hide() end
  if addMenu then addMenu:Hide() end
  if addBtn and addBtn.watch then pcall(addBtn.watch.UnregisterEvent, addBtn.watch, "GLOBAL_MOUSE_DOWN") end
end

local function AddButton()
  if addBtn then return addBtn end
  local a = CreateFrame("Button", nil, frame, "BackdropTemplate")
  a:SetSize(20, 20)
  CR.Backdrop(a, 0.08, 0.08, 0.08, 0.9)
  local hl = a:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.08)
  a.plus = a:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  a.plus:SetPoint("CENTER", 0, 1)
  a.plus:SetText("+")
  addBtn = a
  a:SetScript("OnClick", function()
    if addMenu and addMenu:IsShown() then CloseMenus() else OpenAdd() end
  end)
  a:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Professions on this window")
    GameTooltip:AddLine("Tick your professions on or off, or add your other characters' - their professions are "
      .. "recorded when they log in.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  a:SetScript("OnLeave", GameTooltip_Hide)
  a:SetScript("OnHide", CloseMenus)
  -- a click anywhere but the menus (or the +) closes them
  local watch = CreateFrame("Frame")
  watch:SetScript("OnEvent", function()
    local over = a:IsMouseOver() or (addMenu and addMenu:IsMouseOver()) or (subMenu and subMenu:IsShown() and subMenu:IsMouseOver())
    if not over then CloseMenus() end
  end)
  a.watch = watch
  PassWheel(a)
  CR.AllMaterialsAdd = a   -- (tests)
  CR.AllMaterialsMenus = function() return addMenu, subMenu end   -- (tests)
  return a
end

-- moveOnly: just put the dragged heading under the cursor (every frame while dragging)
local function PlaceDragged()
  local c = dragCol
  if not (c and frame.colsLeft and frame:GetLeft()) then return end
  local x = GetCursorPosition() / frame:GetEffectiveScale() - frame:GetLeft()
  local n = #(frame.profs or {})
  x = math.max(frame.colsLeft - COL_W / 2, math.min(frame.colsLeft + (n - 0.5) * COL_W, x))
  c:ClearAllPoints()
  c:SetPoint("TOPLEFT", frame, "TOPLEFT", x - COL_W / 2, -Top() - HEAD_H + ICON_H)
end

function Refresh(moveOnly)
  if not (frame and frame:IsShown()) then return end
  if moveOnly then PlaceDragged() return end
  local profs, items = Gather()
  frame.profs = profs
  local lines = Lines(items, profs)
  -- the name column: as wide as the longest name, or the width you set (within limits)
  local m = frame.measure
  local nameW = MIN_NAME
  for _, it in ipairs(items) do
    m:SetText(it.name or "")
    nameW = math.max(nameW, (tonumber(m:GetStringWidth()) or 0) + 4)
  end
  nameW = math.min(Settings().nameW or 220, math.ceil(nameW))
  nameW = math.max(MIN_NAME, math.min(MAX_NAME, nameW))
  local left = 8 + (ROW_H - 4) + 5 + nameW
  local width = left + #profs * COL_W + 26 + TOTAL_W + 8 + 10
  frame.colsLeft = left

  -- headings
  local shownCol = {}
  for i, p in ipairs(profs) do
    local c = Col(p.name)
    shownCol[p.name] = true
    c.p = p
    c.icon:SetTexture(CR.ProfessionIcon and CR.ProfessionIcon(p.prof or p.name) or "Interface\\Icons\\INV_Misc_QuestionMark")
    c.char:SetText("")   -- (the character's name goes across all its columns - below)
    -- the goal it tracks to (picked here: gold)
    -- the goal in its rank's colour; picked here: the gold border round the icon
    c.goal:SetText(p.goal and CR.ColorText(tostring(p.goal), RankOf(p.goal)[3]) or "")
    for _, t in ipairs(c.picked) do t:SetShown(p.picked and true or false) end
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", frame, "TOPLEFT", left + (i - 1) * COL_W, -Top() - HEAD_H + ICON_H)
    c:SetAlpha(p.empty and 0.6 or 1)
    c:Show()
    -- the dragged one: its place in the order marked down the list
    if dragCol == c then
      frame.slot:ClearAllPoints()
      frame.slot:SetPoint("TOPLEFT", frame, "TOPLEFT", left + (i - 1) * COL_W, -Top() - HEAD_H + ICON_H)
      frame.slot:SetWidth(COL_W)
    end
  end
  for name, c in pairs(cols) do if not shownCol[name] then c:Hide() end end
  frame.slot:SetShown(dragCol ~= nil)
  PlaceDragged()
  local add = AddButton()
  add:ClearAllPoints()
  add:SetPoint("LEFT", frame, "TOPLEFT", left + #profs * COL_W + 4, -Top() - HEAD_H + ICON_H - 11)   -- (level with the icons)
  add:Show()
  frame.itemHead:ClearAllPoints()
  frame.itemHead:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 8, -Top() - HEAD_H + 2)
  frame.totalHead:ClearAllPoints()
  frame.totalHead:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -18, -Top() - HEAD_H + 2)

  -- how many lines fit: the height you set, else the whole list (up to MAX_ROWS)
  local top = Top() + HEAD_H + 2
  local bottom = 30
  local setH = Settings().height
  local vis = setH and math.max(1, math.floor((setH - top - bottom) / ROW_H)) or math.min(#lines, MAX_ROWS)
  vis = math.min(vis, #lines)
  offset = math.max(0, math.min(offset, #lines - vis))
  local y = top
  for i = 1, vis do
    local l, r = lines[offset + i], Row(i)
    r.l = l
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -y)
    r:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    if l.head then
      -- a band's heading, with a line across
      r:SetHeight(ROW_H)
      r.head:SetText(l.head)
      r.head:Show()
      r.line:Show()
      -- its cost, the line running up to it
      local hasCost = l.cost ~= nil
      r.bandCost:SetText(hasCost and (CR.FormatMoney(l.cost)
        .. ((l.unpriced or 0) > 0 and CR.ColorText(string.format(" +%d", l.unpriced), "ff9966") or "")) or "")
      r.bandCost:SetShown(hasCost)
      r.line:ClearAllPoints()
      r.line:SetPoint("LEFT", r.head, "RIGHT", 6, 0)
      r.line:SetPoint("RIGHT", r.bandCost, "LEFT", -6, 0)
      r.icon:Hide()
      r.name:Hide()
      r.total:Hide()
      r.hl:SetAlpha(0)
      for _, fs in ipairs(r.cells) do fs:Hide() end
      r.spare:Hide()
    else
      r:SetHeight(ROW_H)
      r.head:Hide()
      r.line:Hide()
      r.bandCost:Hide()
      r.hl:SetAlpha(1)
      r.icon:Show()
      r.name:Show()
      r.total:Show()
      local it = l.it
      r.icon:SetTexture(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(it.id) or (GetItemIcon and GetItemIcon(it.id)))
      r.name:SetWidth(nameW)
      r.name:SetText(it.name or "?")
      for j, p in ipairs(profs) do
        local fs = r.cells[j]
        if not fs then fs = Cell(r, "CENTER") r.cells[j] = fs end
        fs:ClearAllPoints()
        fs:SetPoint("RIGHT", r, "LEFT", left - 8 + j * COL_W - 2, 0)
        fs:SetWidth(COL_W - 4)
        local n = l.per[p.name]
        fs:SetText(n and tostring(n) or CR.ColorText("-", "555555"))
        fs:Show()
      end
      for j = #profs + 1, #r.cells do r.cells[j]:Hide() end
      r.spare:ClearAllPoints()
      r.spare:SetPoint("LEFT", r, "LEFT", left - 8 + #profs * COL_W + 4, 0)
      r.spare:Show()
      r.total:ClearAllPoints()
      r.total:SetPoint("RIGHT", r, "RIGHT", 0, 0)
      r.total:SetWidth(TOTAL_W)
      local enough = l.have >= l.need
      r.total:SetText(CR.ColorText(string.format("%d/%d", l.have, l.need), enough and "40ff40" or "ffd100")
        .. ((it.crafted > 0 and not enough) and CR.ColorText(" +", "33ccff") or ""))
    end
    r:Show()
    y = y + ROW_H
  end
  for i = vis + 1, #rows do rows[i]:Hide() end

  -- the scroll mark, when there's more than fits
  local scrolling = #lines > vis
  frame.track:SetShown(scrolling)
  frame.thumb:SetShown(scrolling)
  if scrolling then
    local trackH = vis * ROW_H
    frame.track:ClearAllPoints()
    frame.track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -top)
    frame.track:SetHeight(trackH)
    local thumbH = math.max(12, trackH * vis / #lines)
    frame.thumb:ClearAllPoints()
    frame.thumb:SetPoint("TOP", frame.track, "TOP", 0, -(trackH - thumbH) * offset / math.max(1, #lines - vis))
    frame.thumb:SetHeight(thumbH)
  end

  -- what's still to buy (not what a route makes itself), as the trackers count it
  local cost, unpriced = 0, 0
  for _, it in ipairs(items) do
    local missing = it.need - it.have
    if missing > 0 and it.crafted == 0 then
      if it.price then cost = cost + it.price * missing else unpriced = unpriced + 1 end
    end
  end
  frame.cost:SetText(#items > 0 and (CR.ColorText("Cost  ", "aaaaaa") .. CR.FormatMoney(cost)
    .. (unpriced > 0 and CR.ColorText(string.format("  (+%d unpriced)", unpriced), "ff9966") or "")) or "")
  frame.slot:SetHeight(ICON_H + 2 + math.max(1, vis) * ROW_H)

  -- whose columns: with another character's here, every column says whose it is - one name, in the
  -- class colour, across a character's neighbouring columns (not a cut-off copy over each), and
  -- each column faintly tinted in that colour down the list
  local anyAlt = false
  for _, p in ipairs(profs) do if p.char then anyAlt = true end end
  local myClass = UnitClass and select(2, UnitClass("player"))
  local function Whose(p)
    if p.char then return p.char, p.charName, p.class end
    if anyAlt then return MyKey() or "me", UnitName and UnitName("player") or "", myClass end
  end
  local labelY = -Top() - HEAD_H + ICON_H - 1        -- just over the icons
  local tintTop = Top() + HEAD_H - ICON_H - 14       -- from the name...
  local tintH = (top + math.max(1, vis) * ROW_H) - tintTop   -- ...to the list's end
  local g, i = 0, 1
  while i <= #profs do
    local key, name, class = Whose(profs[i])
    local j = i
    if key then
      while j < #profs and Whose(profs[j + 1]) == key do j = j + 1 end
      local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
      local r, gg, b = cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1
      g = g + 1
      local fs = charLabels[g]
      if not fs then fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") fs:SetWordWrap(false) charLabels[g] = fs end
      fs:ClearAllPoints()
      fs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", left + (i - 1) * COL_W, labelY)
      fs:SetWidth((j - i + 1) * COL_W)
      fs:SetJustifyH("CENTER")
      fs:SetText(name or "")
      fs:SetTextColor(r, gg, b)
      fs:Show()
      for k = i, j do
        local t = colTints[k]
        if not t then t = frame:CreateTexture(nil, "BACKGROUND", nil, 1) colTints[k] = t end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", frame, "TOPLEFT", left + (k - 1) * COL_W + 1, -tintTop)
        t:SetSize(COL_W - 2, tintH)
        t:SetColorTexture(r, gg, b, 0.07)
        t:Show()
        -- (stronger over the header)
        local h = headTints[k]
        if not h then h = frame:CreateTexture(nil, "BACKGROUND", nil, 2) headTints[k] = h end
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0)
        h:SetSize(COL_W - 2, Top() + HEAD_H - tintTop + 2)
        h:SetColorTexture(r, gg, b, 0.16)
      end
    else
      for k = i, j do if colTints[k] then colTints[k]:Hide() end end
    end
    i = j + 1
  end
  for k = g + 1, #charLabels do charLabels[k]:Hide() end
  for k = #profs + 1, #colTints do colTints[k]:Hide() end
  for k = 1, #headTints do
    local ct = colTints[k]
    headTints[k]:SetShown(ct and ct:IsShown() and true or false)
  end
  -- the header row (names, icons, targets): a darker band across, so it reads as the heading
  frame.headBand:ClearAllPoints()
  frame.headBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -tintTop)
  frame.headBand:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
  frame.headBand:SetHeight(Top() + HEAD_H - tintTop + 2)
  frame.empty:ClearAllPoints()
  frame.empty:SetPoint("TOPLEFT", 8, -Top() - HEAD_H - 4)
  frame.empty:SetShown(#items == 0)
  frame.alts:Sync()
  frame.vendor:SetChecked(not Settings().hideVendor)
  frame.sortDD:Sync()
  frame.edit:SetText(editing and "Done" or "Edit")
  frame:SetSize(math.max(width, 300), top + math.max(1, vis) * ROW_H + bottom)
  if CR.ApplyThemeFonts then pcall(CR.ApplyThemeFonts, frame) end
end

-- new scale (the top-left corner stays put on screen) / names width / height; nil: unchanged
local function SetSize(scale, nameW, h)
  local s = Settings()
  if nameW then s.nameW = math.floor(math.max(MIN_NAME, math.min(MAX_NAME, nameW)) + 0.5) end
  if h then s.height = math.floor(math.max(MIN_H, math.min(MAX_H, h)) + 0.5) end
  if scale then
    scale = math.max(MIN_S, math.min(MAX_S, math.floor(scale * 20 + 0.5) / 20))
    local l, t = frame:GetLeft(), frame:GetTop()
    local old = tonumber(frame:GetScale()) or 1
    s.scale = scale
    frame:SetScale(scale)
    if l and t then
      frame:ClearAllPoints()
      frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * old / scale, t * old / scale)
      SavePos()
    end
  end
  Refresh()
end

-- a labelled slider with its value (the size panel)
local function Slider(parent, label, lo, hi, step, get, set, fmt)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(210, 34)
  f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.label:SetPoint("TOPLEFT", 0, 0)
  f.label:SetText(label)
  f.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.value:SetPoint("TOPRIGHT", 0, 0)
  local sl = CreateFrame("Slider", nil, f, "BackdropTemplate")
  sl:SetOrientation("HORIZONTAL")
  sl:SetHeight(12)
  sl:SetPoint("TOPLEFT", 0, -16)
  sl:SetPoint("RIGHT", 0, 0)
  sl:SetMinMaxValues(lo, hi)
  sl:SetValueStep(step)
  if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
  CR.Backdrop(sl, 0.1, 0.1, 0.1, 0.9)
  sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local syncing = false
  sl:SetScript("OnValueChanged", function(_, v)
    f.value:SetText(string.format(fmt, v))
    if not syncing then set(v) end
  end)
  function f:Sync()
    syncing = true
    local v = get()
    sl:SetValue(v)
    f.value:SetText(string.format(fmt, v))
    syncing = false
  end
  return f
end

local function SizePanel(owner)
  if not sizePanel then
    -- on UIParent: as the window's child it would scale too, moving the slider you're dragging
    local p = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    p:SetSize(234, 168)
    p:SetFrameStrata("DIALOG")
    CR.Backdrop(p, 0.05, 0.05, 0.07, 0.97)
    p:EnableMouse(true)
    p:Hide()
    local wsl = Slider(p, "Width (the names)", MIN_NAME, MAX_NAME, 10, function() return Settings().nameW or 220 end,
      function(v) SetSize(nil, v) end, "%d")
    wsl:SetPoint("TOPLEFT", 12, -10)
    local ssl = Slider(p, "Scale", MIN_S, MAX_S, 0.05, Scale, function(v) SetSize(v) end, "%.2f")
    ssl:SetPoint("TOPLEFT", 12, -50)
    local hsl = Slider(p, "Height (shorter scrolls)", MIN_H, MAX_H, 10,
      function() return Settings().height or math.floor(frame:GetHeight() + 0.5) end,
      function(v) SetSize(nil, nil, v) end, "%d")
    hsl:SetPoint("TOPLEFT", 12, -90)
    local reset = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    reset:SetSize(80, 22)
    reset:SetPoint("BOTTOMLEFT", 12, 10)
    reset:SetText("Reset")
    if CR.ThemeRegisterButton then CR.ThemeRegisterButton(reset) end
    reset:SetScript("OnClick", function()
      Settings().nameW, Settings().height = nil, nil
      SetSize(1)
      wsl:Sync() ssl:Sync() hsl:Sync()
    end)
    sizePanelSync = function() if p:IsShown() then wsl:Sync() ssl:Sync() hsl:Sync() end end
    p:SetScript("OnShow", function(self) wsl:Sync() ssl:Sync() hsl:Sync() pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
    p:SetScript("OnHide", function(self) pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
    p:SetScript("OnEvent", function(self)
      if not self:IsMouseOver() and not (self.owner and self.owner:IsMouseOver()) then self:Hide() end
    end)
    sizePanel = p
  end
  sizePanel.owner = owner
  sizePanel:ClearAllPoints()
  sizePanel:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)
  sizePanel:SetShown(not sizePanel:IsShown())
end

local function Build()
  if frame then return end
  frame = CreateFrame("Frame", "CraftRouteAllMaterials", UIParent, "BackdropTemplate")
  frame:SetSize(400, 200)
  frame:SetScale(Scale())
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  if frame.SetDontSavePosition then pcall(frame.SetDontSavePosition, frame, true) end
  CR.Backdrop(frame, 0.04, 0.04, 0.05, 0.85)
  frame:Hide()
  -- moved by any free space (the rows too)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", StartDrag)
  frame:SetScript("OnDragStop", StopDrag)

  -- title bar: name, size panel, close
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.title:SetPoint("TOPLEFT", 8, -8)
  frame.title:SetText("All Materials")
  if CR.ThemeRegisterAccentText then CR.ThemeRegisterAccentText(frame.title) end
  frame.close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.close:SetSize(18, 18)
  frame.close:SetPoint("TOPRIGHT", -4, -4)
  frame.close:SetText("x")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(frame.close) end
  frame.close:SetScript("OnClick", function() CR.ToggleAllMaterials(false) end)
  frame.size = CreateFrame("Button", nil, frame)
  frame.size:SetSize(16, 16)
  frame.size:SetPoint("RIGHT", frame.close, "LEFT", -4, 0)
  frame.size:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  frame.size:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  frame.size:SetScript("OnClick", function(self) SizePanel(self) end)
  frame.size:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Size and scale")
    GameTooltip:AddLine("Ctrl+mouse wheel over the window also scales it.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.size:SetScript("OnLeave", GameTooltip_Hide)
  -- Edit: shows the bar with Vendor items and the order (Done hides it again)
  frame.edit = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.edit:SetSize(40, 18)
  frame.edit:SetPoint("RIGHT", frame.size, "LEFT", -3, 0)
  frame.edit:SetText("Edit")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(frame.edit) end
  frame.edit:SetScript("OnClick", function()
    editing = not editing
    Refresh()
  end)
  frame.edit:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(editing and "Done" or "Edit")
    GameTooltip:AddLine("Nothing here yet.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.edit:SetScript("OnLeave", GameTooltip_Hide)

  -- the bar under it: vendor items shown or not, and the order
  frame.vendor = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.vendor:SetSize(20, 20)
  frame.vendor:SetPoint("TOPLEFT", 6, -Top() - 1)   -- (above the sort, above "Material")
  frame.vendor.label = frame.vendor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.vendor.label:SetPoint("LEFT", frame.vendor, "RIGHT", 2, 0)
  frame.vendor.label:SetText("Vendor items")
  frame.vendor:SetHitRectInsets(0, -76, 0, 0)
  frame.vendor:SetScript("OnClick", function(self)
    Settings().hideVendor = (not self:GetChecked()) or nil
    Refresh()
  end)
  frame.vendor:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Vendor items")
    GameTooltip:AddLine("Ticked: materials vendors sell (thread, dyes, flux...) are listed too. Unticked: left out.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.vendor:SetScript("OnLeave", GameTooltip_Hide)
  frame.sortDD = CR.CreateDropdown(frame, 92, {
    { value = "route", text = "Route order" }, { value = "milestone", text = "Milestones" }, { value = "name", text = "A-Z" },
  }, function() return Settings().sort or "route" end, function(v)
    Settings().sort = (v ~= "route") and v or nil
    offset = 0
    Refresh()
  end)
  frame.sortDD:SetHeight(18)
  frame.sortDD:SetPoint("TOPLEFT", 8, -Top() - 21)
  frame.sortDD:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Sort")
    GameTooltip:AddLine("Route order: by where the routes first use each material. Milestones: split by rank band "
      .. "(1-75, 75-150, ...), each band in the order the routes use them. A-Z: by name. Still-needed ones "
      .. "on top in Route order and A-Z.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  frame.sortDD:SetScript("OnLeave", GameTooltip_Hide)

  frame.itemHead = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.itemHead:SetText("Material")
  frame.totalHead = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.totalHead:SetText("Total")
  frame.measure = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.measure:SetAlpha(0)

  frame.headBand = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
  frame.headBand:SetColorTexture(0, 0, 0, 0.35)
  frame.slot = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
  frame.slot:SetColorTexture(1, 0.82, 0.35, 0.12)
  frame.slot:Hide()
  frame.track = frame:CreateTexture(nil, "ARTWORK")
  frame.track:SetWidth(4)
  frame.track:SetColorTexture(1, 1, 1, 0.08)
  frame.thumb = frame:CreateTexture(nil, "OVERLAY")
  frame.thumb:SetWidth(4)
  frame.thumb:SetColorTexture(1, 0.82, 0.35, 0.6)

  -- the bottom line: the cost, and the Alts tick (the same setting as everywhere)
  frame.cost = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.cost:SetPoint("BOTTOMLEFT", 8, 9)
  frame.alts = CR.CreateAltsCheck(frame, "Alts")
  frame.alts:SetSize(18, 18)
  frame.alts:SetPoint("BOTTOMRIGHT", -44, 5)
  frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.empty:SetPoint("TOPLEFT", 8, -Top() - HEAD_H - 4)
  frame.empty:SetText("No materials needed - none of your professions' routes uses any right now.")

  -- the corner grip: drag for the height (shorter scrolls)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(12, 12)
  grip:SetPoint("BOTTOMRIGHT", -2, 2)
  grip:SetFrameLevel(frame:GetFrameLevel() + 10)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function(self)
    local _, cy = GetCursorPosition()
    self.startY, self.startH = cy, frame:GetHeight()
    self:SetScript("OnUpdate", function()
      local _, y = GetCursorPosition()
      local dy = (self.startY - y) / frame:GetEffectiveScale()
      local h = math.floor(math.max(MIN_H, math.min(MAX_H, self.startH + dy)) + 0.5)
      if h ~= Settings().height then Settings().height = h Refresh() end
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    if sizePanelSync then sizePanelSync() end
  end)

  -- the wheel scrolls; Ctrl+wheel scales
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    if IsControlKeyDown() then
      SetSize(Scale() + delta * 0.05)
      if sizePanelSync then sizePanelSync() end
      return
    end
    offset = offset - delta * 3
    Refresh()
  end)
  Place()
end

-- show (true) / hide (false) / toggle (nil); remembered, so it comes back after a reload
function CR.ToggleAllMaterials(show)
  Build()
  if show == nil then show = not frame:IsShown() end
  Settings().shown = show or nil
  if show then Place() end
  frame:SetShown(show)
  Refresh()
end
CR.RefreshAllMaterials = Refresh

-- This window's list as a lookup, open or not: [itemID] = { need, have, crafted } over every
-- profession it covers (each to its picked guide, the ones taken off left out, vendor items as set)
-- - the loot feed counts against it.
function CR.AllMaterialsById()
  local _, items = Gather()
  local out = {}
  for _, it in ipairs(items) do out[it.id] = { need = it.need, have = it.have, crafted = it.crafted } end
  return out
end

-- The main window's "Materials" button
function CR.AllMaterialsButton(owner)
  local b = CreateFrame("Button", nil, owner, "UIPanelButtonTemplate")
  b:SetSize(80, 22)
  b:SetText("Materials")
  if CR.ThemeRegisterButton then CR.ThemeRegisterButton(b) end
  b:SetScript("OnClick", function() CR.ToggleAllMaterials() end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("All Materials")
    GameTooltip:AddLine("One window with every material your professions' routes still need: a column per "
      .. "profession, and the total you need of each against what you have.", 1, 1, 1, true)
    GameTooltip:AddLine("Double-click a profession's icon there for that profession's own tracker.", 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGOUT" then
    if frame and frame:IsShown() then SavePos() end
    return
  end
  RecordCharacter()
  ForceAlts()
  if Settings().shown then CR.ToggleAllMaterials(true) end
  -- bags, plans, skills changing: the plans built to a picked goal again, and refresh
  CR.OnChange(function() RecordCharacter() wipe(plans) Refresh() end)
end)
