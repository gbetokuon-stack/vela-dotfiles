-- =============================================================================
--  VELA "NOCTURNE PRISM" — Hyprland 0.57.2 Native Lua Config
--  Tailored for HP Victus 15-fb3xxx (Ryzen 7 7445HS + Radeon 740M + RTX 4050)
-- =============================================================================

local home = os.getenv("HOME")
package.path = home .. "/.config/hypr/?.lua;" .. package.path

require("monitors")
require("env")
require("look")
require("rules")
require("keybinds")
require("autostart")
