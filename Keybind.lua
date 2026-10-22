-- Keybind (default Shift+K, set in Bindings.xml): open the profession window on CraftRoute's tab -
-- with the profession CraftRoute's tab was last on this session (else your first profession); with
-- the window up, on any tab, it closes the window.
-- Always the tab once a profession is learned. With nothing learned there is no skill line for
-- OpenTradeSkill, so it opens the game's own professions frame (CraftRoute's trainer pins already
-- sit on its unlearned sections) and does not select CraftRoute's tab. A gathering profession
-- has no crafting window either (Herbalism, Skinning, Fishing): the same frame opens, with
-- CraftRoute's tab on that profession's guide. It never opens the /cr window.
-- It opens the profession picked in CraftRoute; if that one has no window (Fishing) or isn't
-- learned on this character, the nearest one that has (Cooking for Fishing, else your first
-- crafting profession). Like other addons' profession openers (EllesmereUI's data bar) it calls
-- C_TradeSkillUI.OpenTradeSkill from the key press itself - a real key press may - rather than
-- casting the profession. With the window already open it closes the window - first press,
-- whatever tab or page is showing.
-- (While dead the game won't switch to a crafting page at all - a known client issue.)
local _, CR = ...

BINDING_HEADER_CRAFTROUTE = "CraftRoute"
BINDING_NAME_CRAFTROUTE_PROFESSION_TAB = "CraftRoute Profession Tab"
BINDING_NAME_CRAFTROUTE_MATERIALS = "CraftRoute Materials Window"

-- The Materials key: opens the Materials window, or closes it when it's up.
function CraftRoute_MaterialsKeyPressed()
  if CR.ToggleAllMaterials then CR.SafeCall(CR.ToggleAllMaterials) end
end

local function SkillLine(name)
  local s = name and not CR.NO_WINDOW[name] and CR.skill[name]
  return s and s.skillLine
end

-- The game's professions frame, loaded on demand. Nothing learned means no skill line, so
-- OpenTradeSkill cannot open it. Shown as Blizzard leaves it: CraftRoute's tab is not selected.
-- That tab comes up when CR.KeybindWillOpen is set: a profession opening, or gathering-only.
local function EnsureProfessionsFrame()
  if ProfessionsFrame then return true end
  if type(ProfessionsFrame_LoadUI) == "function" then pcall(ProfessionsFrame_LoadUI) end
  if not ProfessionsFrame and C_AddOns and C_AddOns.LoadAddOn then
    pcall(C_AddOns.LoadAddOn, "Blizzard_Professions")
  end
  if not ProfessionsFrame and type(UIParentLoadAddOn) == "function" then
    pcall(UIParentLoadAddOn, "Blizzard_Professions")
  end
  if not ProfessionsFrame and type(LoadAddOn) == "function" then
    pcall(LoadAddOn, "Blizzard_Professions")
  end
  return ProfessionsFrame ~= nil
end

local function OpenEmptyProfessionsFrame()
  if not EnsureProfessionsFrame() or InCombatLockdown() then return false end
  if not ProfessionsFrame:IsShown() then
    if ShowUIPanel then pcall(ShowUIPanel, ProfessionsFrame) end
    if not ProfessionsFrame:IsShown() and type(ToggleProfessionsBook) == "function" then
      pcall(ToggleProfessionsBook)
    end
    if not ProfessionsFrame:IsShown() and ProfessionMicroButton and ProfessionMicroButton.Click then
      pcall(ProfessionMicroButton.Click, ProfessionMicroButton)
    end
  end
  return ProfessionsFrame:IsShown()
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

-- No crafting window (Herbalism, Skinning, Fishing). The saved profession if this character
-- has it, else the first learned one with a route - the same order login uses.
local function GatheringTarget()
  local saved = CraftRouteCharDB and CraftRouteCharDB.profession
  if saved and CR.skill[saved] and CR.professions[saved] and CR.professions[saved].routes then
    return saved
  end
  for _, name in ipairs(CR.SupportedProfessions()) do
    if CR.skill[name] then return name end
  end
end

-- Hide a professions frame that has no trade skill loaded. CloseTradeSkill leaves it up.
local function HideProfessionsFrame()
  if not ProfessionsFrame then return end
  if HideUIPanel then HideUIPanel(ProfessionsFrame) else ProfessionsFrame:Hide() end
end

function CraftRoute_KeybindPressed()
  if InCombatLockdown() then CR.Print("Can't open professions in combat.") return end
  -- read the professions fresh: the list from login can be empty or out of date
  if CR.ScanSkills then pcall(CR.ScanSkills) end
  -- the window's up (whatever profession, whatever tab): it closes - the key opens and closes the
  -- whole window
  if ProfessionsFrame and ProfessionsFrame:IsShown() then
    -- Up, on any tab or page (the Professions summary included, which has no profession loaded):
    -- the key closes the whole window on the first press. Nothing is loaded or switched first.
    -- The next press reopens what was last loaded (CR.KeybindReopen).
    local loaded = not (CR.NoTradeSkillLoaded and CR.NoTradeSkillLoaded())
    if loaded and C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then C_TradeSkillUI.CloseTradeSkill() end
    if ProfessionsFrame:IsShown() then HideProfessionsFrame() end
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
    -- no crafting window. Nothing learned: Blizzard's frame, CraftRoute's tab stays off.
    -- A gathering profession: the same frame, with CraftRoute's tab on that guide.
    if CR.HasAnyProfession and CR.HasAnyProfession() then
      local name = GatheringTarget()
      if name and CR.KeybindShowGathering then CR.KeybindShowGathering(name) end
      if CR.KeybindWillOpen then CR.KeybindWillOpen() end
    end
    OpenEmptyProfessionsFrame()
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
