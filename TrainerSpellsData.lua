-- Recipe facts from the TrainerSpells addon, read live at login: each recipe's learn skill, its
-- trainer cost, and who sells it (vendors with faction, quests). Keyed by recipe, so when
-- TrainerSpells updates - a trainer starts teaching something, a recipe moves to another vendor,
-- a skill changes - CraftRoute follows without a CraftRoute update. The values built into
-- Data/*Recipes.lua stay for recipes TrainerSpells doesn't list (and when it isn't installed).
-- Mirrors tools/build_recipes.py, which makes the built-in values the same way.
local _, CR = ...

CR.tsStats = { recipes = 0, changed = 0 }

-- "Sold by {A:Name (Zone)}, {H:...} / Quest reward: ..." from TrainerSpells' sourceLocations.
local function SourceText(data)
  local vendors, quests, seen = {}, {}, {}
  for _, l in ipairs(data.sourceLocations or {}) do
    local entry, list
    if l.questName then entry, list = l.questName, quests
    elseif l.npcName then entry, list = l.npcName .. " (" .. (l.zoneName or "?") .. ")", vendors end
    if entry then
      if l.faction == "Horde" then entry = "{H:" .. entry .. "}"
      elseif l.faction == "Alliance" then entry = "{A:" .. entry .. "}" end
      if not seen[entry] then seen[entry] = true; table.insert(list, entry) end
    end
  end
  local parts = {}
  if #vendors > 0 then table.insert(parts, "Sold by " .. table.concat(vendors, ", ")) end
  if #quests > 0 then table.insert(parts, "Quest reward: " .. table.concat(quests, ", ")) end
  local fs = table.concat(parts, " / ")
  -- TrainerSpells' own text, unless the faction markup is needed (it also says "World drop" etc.)
  local src = data.source or ""
  if fs:find("{", 1, true) and (src:find("^Sold by") or src:find("^Quest reward")) then return fs end
  return src ~= "" and src or (fs ~= "" and fs or nil)
end

local function Apply(r, learn, src, cost)
  local before = r.learn .. "|" .. tostring(r.src)
  -- a pattern can need more skill to read than TrainerSpells' value: keep at least that (ps)
  r.learn = math.max(learn, r.ps or 0)
  if src and src ~= "" then r.src = src end
  if cost then r.cost = cost end
  r._vendorOK = nil   -- source line may have changed; AutoSteps parses it once
  r.fromTrainerSpells = true
  CR.tsStats.recipes = CR.tsStats.recipes + 1
  if before ~= r.learn .. "|" .. tostring(r.src) then CR.tsStats.changed = CR.tsStats.changed + 1 end
end

-- NPC name -> places, filled here so Tasks.lua doesn't walk TrainerSpells a second time.
local function AddIndexedNpc(name, loc, faction)
  if type(name) ~= "string" or name == "" or type(loc) ~= "table" or not loc.uiMapID or not loc.x then return end
  CR.npcIndex = CR.npcIndex or {}
  local list = CR.npcIndex[name]
  if not list then list = {}; CR.npcIndex[name] = list end
  for _, p in ipairs(list) do
    if p.uiMapID == loc.uiMapID and math.abs(p.x - loc.x) < 0.5 and math.abs(p.y - loc.y) < 0.5 then return end
  end
  table.insert(list, { name = name, uiMapID = loc.uiMapID, x = loc.x, y = loc.y, faction = faction or loc.faction })
end

function CR.ApplyTrainerSpells()
  local trainer = type(TrainerSpellsBuiltin_Profession) == "table" and TrainerSpellsBuiltin_Profession
  local vendor = type(TrainerSpellsBuiltin_ProfessionRecipe) == "table" and TrainerSpellsBuiltin_ProfessionRecipe
  if not (trainer or vendor) then return end
  CR.tsStats.recipes, CR.tsStats.changed = 0, 0
  CR.tsCost, CR.tsVendors = {}, {}
  CR.npcIndex = {}
  for profName, p in pairs(CR.professions) do
    -- recipe vendors / quests first, then trainers: a recipe a trainer teaches counts as a trainer
    -- recipe (as the built-in data has it)
    local costs, vendors = {}, {}
    CR.tsCost[profName], CR.tsVendors[profName] = costs, vendors
    for skill, bucket in pairs(vendor and vendor[profName] or {}) do
      for spell, data in pairs(bucket) do
        local r = p.recipes[spell]
        if r and type(skill) == "number" and type(data) == "table" then
          local places = {}
          for _, loc in ipairs(data.sourceLocations or {}) do
            if loc.npcName and loc.uiMapID and loc.x then
              table.insert(places, { name = loc.npcName, uiMapID = loc.uiMapID, x = loc.x, y = loc.y, faction = loc.faction })
              AddIndexedNpc(loc.npcName, loc, loc.faction)
            end
          end
          vendors[spell] = places
          Apply(r, skill, SourceText(data))
        end
      end
    end
    for skill, bucket in pairs(trainer and trainer[profName] or {}) do
      for spell, data in pairs(bucket) do
        local r = p.recipes[spell]
        if r and type(skill) == "number" then
          local cost = type(data) == "table" and data.cost or nil
          if cost then costs[spell] = cost end
          Apply(r, skill, "Trainer", cost)
        end
      end
    end
    -- which recipe counts as "the" maker of an item prefers trainer recipes - sources may have moved
    for spell, r in pairs(p.recipes) do
      if r.item and r.item > 0 then
        local cur = p.byItem[r.item] and p.recipes[p.byItem[r.item]]
        if not cur or (cur.src ~= "Trainer" and r.src == "Trainer") then p.byItem[r.item] = spell end
      end
    end
  end
  if CR.InvalidatePlan then CR.InvalidatePlan() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() CR.SafeCall(CR.ApplyTrainerSpells) end)
