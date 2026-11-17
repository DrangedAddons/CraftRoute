-- Training from an open trainer: the task card's "Train" button.
-- A task that a trainer teaches carries task.train:
--   { recipe = "Nightscape Boots", spell = 10558 }        a recipe
--   { skill = "Leatherworking", rank = "Expert" }          a rank (Apprentice = learning it)
-- While a trainer window is open, CR.TrainerService(task.train) finds that service in it.
local _, CR = ...

local trainerOpen = false
function CR.TrainerOpen() return trainerOpen end

local SERVICE_TYPES = { available = true, unavailable = true, used = true }

-- name, rank text, category ("available" / "unavailable" / "used" / "header"). Classic returns
-- name, rank, category, ...; Forever returns name, category, icon, level, rank (as TrainerSpells reads it).
local function ServiceInfo(i)
  local name, second, third, _, fifth = GetTrainerServiceInfo(i)
  if SERVICE_TYPES[second] then return name, type(fifth) == "string" and fifth or "", second end
  return name, type(second) == "string" and second or "", third
end

local function ServiceSpell(i)
  if C_TooltipInfo and C_TooltipInfo.GetTrainerService then
    local ok, data = pcall(C_TooltipInfo.GetTrainerService, i)
    if ok and data and data.id and (not Enum or not Enum.TooltipDataType or data.type == Enum.TooltipDataType.Spell) then
      return data.id
    end
  end
end

local function Lower(s) return type(s) == "string" and s:lower() or "" end

-- "Leatherworking" -> "leatherwork" (matches "Leatherworker" too)
local function Stem(skill)
  local s = Lower(skill)
  return (s:gsub("ing$", ""))
end

local function Matches(train, name, rank, i)
  name, rank = Lower(name), Lower(rank)
  if train.recipe then
    if name == Lower(train.recipe) then return true end
    return train.spell ~= nil and ServiceSpell(i) == train.spell
  end
  if not train.skill then return false end
  local want, stem = Lower(train.rank), Stem(train.skill)
  if want == "" then return false end
  -- "Leatherworking" (rank "Expert"), or "Expert Leatherworker" / "Expert Leatherworking"
  if name == Lower(train.skill) and rank:find(want, 1, true) then return true end
  return name:find(want, 1, true) ~= nil and name:find(stem, 1, true) ~= nil
end

-- The open trainer's service for this task: index, category, cost. nil when no trainer is open or
-- it doesn't list it (another profession's trainer, or the trainer window's filters hide it).
function CR.TrainerService(train)
  if not trainerOpen or not train or not GetNumTrainerServices or not GetTrainerServiceInfo then return nil end
  local n = GetNumTrainerServices() or 0
  local best
  for i = 1, n do
    local name, rank, category = ServiceInfo(i)
    if category ~= "header" and name and Matches(train, name, rank, i) then
      -- one already trained is a match too, but an available one wins
      if category == "available" then best = i break end
      best = best or i
    end
  end
  if not best then return nil end
  local _, _, category = ServiceInfo(best)
  local cost = GetTrainerServiceCost and GetTrainerServiceCost(best) or 0
  return best, category, cost
end

-- Train it: look it up again (the list can move between drawing and clicking), then buy it.
function CR.TrainService(train)
  local i, category, cost = CR.TrainerService(train)
  if not i then CR.Print("This trainer doesn't list that.") return end
  if category ~= "available" then CR.Print("This trainer can't teach you that yet.") return end
  if GetMoney and cost and cost > GetMoney() then CR.Print("Not enough money to train that.") return end
  if BuyTrainerService then BuyTrainerService(i) end
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED", "TRAINER_UPDATE" }) do
  if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(e)) then
    pcall(f.RegisterEvent, f, e)
  end
end
f:SetScript("OnEvent", function(_, event)
  if event == "TRAINER_SHOW" then trainerOpen = true elseif event == "TRAINER_CLOSED" then trainerOpen = false end
  if CR.NotifyChanged then CR.NotifyChanged() end
end)
