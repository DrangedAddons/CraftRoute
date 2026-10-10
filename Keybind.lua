-- Keybind (default Shift+K, set in Bindings.xml): open the profession picked in CraftRoute on
-- CraftRoute's tab. Like other addons' profession openers (EllesmereUI's data bar), it calls
-- C_TradeSkillUI.OpenTradeSkill from the key press itself - a real key press may - rather than
-- casting the profession, which doesn't work while dead. The profession-window view switches to
-- its tab once the window is up (Compact.lua). With the window already open on that profession
-- it shows CraftRoute's tab, or closes the window when that's what's showing. Fishing (no
-- window) or a profession this character hasn't learned opens the main CraftRoute window.
local _, CR = ...

BINDING_HEADER_CRAFTROUTE = "CraftRoute"
BINDING_NAME_CRAFTROUTE_PROFESSION_TAB = "CraftRoute Profession Tab"

function CraftRoute_KeybindPressed()
  if InCombatLockdown() then CR.Print("Can't open professions in combat.") return end
  local prof = CraftRouteCharDB and CraftRouteCharDB.profession
  local route = prof and CR.Route(prof)
  prof = route and route.recipeProf or prof
  local s = prof and CR.skill[prof]
  if not (s and s.skillLine) or prof == "Fishing" then
    CR.SafeCall(CR.ToggleWindow)   -- nothing to open a profession window for
    return
  end
  if CR.TradeSkillOpenFor(prof) and CR.KeybindToggleView and CR.KeybindToggleView() then return end
  if CR.KeybindWillOpen then CR.KeybindWillOpen() end
  C_TradeSkillUI.OpenTradeSkill(s.skillLine)
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
