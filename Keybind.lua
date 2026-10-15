-- Keybind (default Shift+K, set in Bindings.xml): open the profession window on CraftRoute's tab -
-- where it was when last closed this session (else your first profession); with the window up, it
-- shows CraftRoute's tab, or closes the window when that's showing.
-- Always the tab. With no crafting profession to open (nothing learned, or only gathering) it
-- opens the main window's Professions tab instead: pick a profession, pin its nearest trainer. It opens the profession picked in
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
  local s = name and not CR.NO_WINDOW[name] and CR.skill[name]
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
  -- read the professions fresh: the list from login can be empty or out of date
  if CR.ScanSkills then pcall(CR.ScanSkills) end
  -- the window's up (whatever profession): CraftRoute's tab if it isn't showing, else close the
  -- window - never a switch to another profession
  if ProfessionsFrame and ProfessionsFrame:IsShown() and CR.KeybindToggleView then
    -- up but empty (no profession loaded, e.g. after a reload): load one, on CraftRoute's tab
    if CR.OpenFallbackProfession and CR.OpenFallbackProfession() then return end
    CR.KeybindToggleView()
    return
  end
  -- closed: open it on CraftRoute's tab, where it was when last closed this session (else your
  -- first profession)
  local line = CR.KeybindReopen and CR.KeybindReopen()
  if line then
    if CR.KeybindWillOpen then CR.KeybindWillOpen() end
    C_TradeSkillUI.OpenTradeSkill(line)
    return
  end
  local prof = Target()
  if not prof then
    -- no crafting profession window to open: the Professions tab (pick one, find its trainer);
    -- pressing it again while that's showing closes it
    if CR.IsWindowShown() and CR.CurrentTab and CR.CurrentTab() == "start" then
      CR.ToggleWindow()
    else
      CR.SafeCall(CR.ShowWindow, "start")
    end
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
