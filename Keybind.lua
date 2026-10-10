-- Keybind (default Shift+K, set in Bindings.xml): open the profession window on CraftRoute's tab
-- for the profession picked in CraftRoute. Opening a profession is a protected action, so the key
-- clicks a hidden secure button that runs "/cast <profession>"; the profession-window view then
-- switches to its tab once the window is up (Compact.lua). With the window already open it
-- shows CraftRoute's tab, or closes the window when that's what's showing. Fishing (no window)
-- or a profession this character hasn't learned opens the main CraftRoute window instead.
local _, CR = ...

BINDING_HEADER_CRAFTROUTE = "CraftRoute"
_G["BINDING_NAME_CLICK CraftRouteKeybindButton:LeftButton"] = "Open profession on the CraftRoute tab"

local btn = CreateFrame("Button", "CraftRouteKeybindButton", UIParent, "SecureActionButtonTemplate")
btn:SetAttribute("type", "macro")
btn:SetAttribute("macrotext", "")
btn:RegisterForClicks("AnyDown", "AnyUp")
btn:Hide()

btn:SetScript("PreClick", function(self, _, down)
  if InCombatLockdown() then return end   -- attributes are locked; whatever is set runs
  self:SetAttribute("macrotext", "")
  -- one action per key press: on the press the game uses for action keys (down or up)
  local onDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
  if (down and true or false) ~= (onDown and true or false) then return end
  local prof = CraftRouteCharDB and CraftRouteCharDB.profession
  local macro = CR.OpenProfessionMacro and CR.OpenProfessionMacro(prof)
  if macro then
    if CR.KeybindWillOpen then CR.KeybindWillOpen() end
    self:SetAttribute("macrotext", macro)
  elseif not (CR.KeybindToggleView and CR.KeybindToggleView()) then
    CR.SafeCall(CR.ToggleWindow)
  end
end)
