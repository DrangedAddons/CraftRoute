-- Keybind (default Shift+K, set in Bindings.xml): open the profession window on CraftRoute's tab.
-- Always the tab - never the main CraftRoute window. It opens the profession picked in
-- CraftRoute; if that one has no window (Fishing) or isn't learned on this character, the
-- nearest one that has (Cooking for Fishing, else your first crafting profession). Like other
-- addons' profession openers (EllesmereUI's data bar) it calls C_TradeSkillUI.OpenTradeSkill from
-- the key press itself - a real key press may - rather than casting the profession. With the
-- window already open it shows CraftRoute's tab, or closes the window when that's showing.
-- (While dead the game won't switch to a crafting page at all - a known client issue.)
local _, CR = ...

BINDING_HEADER_CRAFTROUTE = "CraftRoute"
BINDING_NAME_CRAFTROUTE_PROFESSION_TAB = "CraftRoute Profession Tab"

local function SkillLine(name)
  local s = name and name ~= "Fishing" and CR.skill[name]
  return s and s.skillLine
end

-- The profession to open: the picked one, else the nearest that has a crafting window.
local function Target()
  local prof = CraftRouteCharDB and CraftRouteCharDB.profession
  local route = prof and CR.Route(prof)
  prof = route and route.recipeProf or prof
  if SkillLine(prof) then return prof end
  if prof == "Fishing" and SkillLine("Cooking") then return "Cooking" end
  for _, name in ipairs(CR.SupportedProfessions()) do
    if SkillLine(name) then return name end
  end
end

function CraftRoute_KeybindPressed()
  if InCombatLockdown() then CR.Print("Can't open professions in combat.") return end
  -- the window's already up (any profession): show CraftRoute's tab, or close the window
  if ProfessionsFrame and ProfessionsFrame:IsShown() and CR.KeybindToggleView then
    local prof = Target()
    if not prof or CR.TradeSkillOpenFor(prof) then CR.KeybindToggleView() return end
  end
  local prof = Target()
  if not prof then
    CR.Print("No crafting profession learned on this character to open.")
    return
  end
  if CR.KeybindWillOpen then CR.KeybindWillOpen() end
  C_TradeSkillUI.OpenTradeSkill(SkillLine(prof))
end

-- 0.25.0 bound Shift+K to a hidden button ("CLICK CraftRouteKeybindButton:LeftButton"); move a
-- key still bound to that onto this binding.
local mig = CreateFrame("Frame")
mig:RegisterEvent("PLAYER_LOGIN")
mig:SetScript("OnEvent", function()
  if not (GetBindingKey and SetBinding) or InCombatLockdown() then return end
  local moved = false
  for _, key in ipairs({ GetBindingKey("CLICK CraftRouteKeybindButton:LeftButton") }) do
    if not GetBindingKey("CRAFTROUTE_PROFESSION_TAB") then
      SetBinding(key, "CRAFTROUTE_PROFESSION_TAB")
      moved = true
    else
      SetBinding(key)
    end
  end
  if moved and SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
end)
