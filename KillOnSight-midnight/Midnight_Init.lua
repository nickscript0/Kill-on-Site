-- KillOnSight: Midnight init (no hard version locks)
-- Loads before other files.

local addonName = ...

-- Ensure main SavedVariables table exists (compat with old KillOnSight).
_G.KillOnSightDB = _G.KillOnSightDB or {}


-- Always alias Midnight DB reference back to the main DB for compatibility.
_G.KillOnSightMidnightDB = _G.KillOnSightDB

-- Fork flags (feature gating should happen per-module, not by early return here).
_G.KOS_MIDNIGHT = true

-- Correct addon folder for assets (logo.tga, sounds, etc.)
_G.KOS_ADDON_FOLDER = "KillOnSight"

-- Helpful environment flags (do NOT hard-stop execution here).
_G.KOS_IS_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

do
  local _, _, _, build = GetBuildInfo()
  _G.KOS_CLIENT_BUILD = tonumber(build) or 0
end
