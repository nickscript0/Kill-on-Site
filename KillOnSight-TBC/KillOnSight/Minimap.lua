-- Minimap.lua (LibDataBroker + LibDBIcon)
-- This is the "Auto Junk Destroyer" proven pattern for perfect minimap alignment + saved position.
local ADDON_NAME = ...
local L = KillOnSight_L
local DB = KillOnSight_DB

local Minimap = {}
local icon = LibStub("LibDBIcon-1.0")
local LDB  = LibStub("LibDataBroker-1.1")

-- EasyMenu shim (Classic-safe). Some libraries call EasyMenu; Classic doesn't always expose it.
if not EasyMenu then
  function EasyMenu(menuList, menuFrame, anchor, x, y, displayMode)
    -- Minimal replacement using UIDropDownMenu APIs
    if type(menuFrame) ~= "table" then
      menuFrame = CreateFrame("Frame", "KillOnSight_EasyMenuShim", UIParent, "UIDropDownMenuTemplate")
    end
    UIDropDownMenu_Initialize(menuFrame, function(self, level)
      for _,item in ipairs(menuList or {}) do
        local info = UIDropDownMenu_CreateInfo()
        for k,v in pairs(item) do info[k] = v end
        UIDropDownMenu_AddButton(info, level)
      end
    end, displayMode or "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchor or "cursor", x or 0, y or 0)
  end
end

local function ShowDropdown(menuTable)
  if not Minimap._menuFrame then
    Minimap._menuFrame = CreateFrame("Frame", "KillOnSight_MinimapMenu", UIParent, "UIDropDownMenuTemplate")
  end
  local f = Minimap._menuFrame
  UIDropDownMenu_Initialize(f, function(self, level)
    for _,item in ipairs(menuTable) do
      local info = UIDropDownMenu_CreateInfo()
      for k,v in pairs(item) do info[k] = v end
      UIDropDownMenu_AddButton(info, level)
    end
  end, "MENU")
  ToggleDropDownMenu(1, nil, f, "cursor", 0, 0)
end

local dataobj = LDB:NewDataObject("Kill on Sight", {
  type = "data source",
  text = L.UI_TITLE,
  icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8", -- skull raid marker
})

function dataobj:OnTooltipShow()
  self:AddLine("Kill on Sight")
  self:AddLine("Left-click: Open/Close", 1,1,1)
  self:AddLine("Right-click: Menu", 1,1,1)
end

function dataobj:OnClick(btn)
  if btn == "LeftButton" then
    if KillOnSight_GUI and KillOnSight_GUI.Toggle then
      KillOnSight_GUI:Toggle()
    end
    elseif btn == "RightButton" then
    local prof = DB:GetProfile()
    prof.minimap = prof.minimap or { hide=false, minimapPos=220 }

    local isPlayerTarget = UnitExists("target") and UnitIsPlayer("target")
    local tName = isPlayerTarget and UnitName("target") or nil
    local already = false
    if tName and tName ~= "" then
      if DB.HasPlayer then
        already = DB:HasPlayer(tName)
      elseif DB.LookupPlayer then
        already = DB:LookupPlayer(tName) ~= nil
      end
    end

    local menu = {
      { text = L.UI_TITLE, isTitle = true, notCheckable = true },
      { text = L.UI_ADD_KOS_TARGET, notCheckable = true, disabled = (not isPlayerTarget) or already, func = function()
          if not (UnitExists("target") and UnitIsPlayer("target")) then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00d0ff"..L.ADDON_PREFIX..":|r "..L.ERR_NO_PLAYER_TARGET)
            return
          end
          local name = UnitName("target")
          if (DB.HasPlayer and DB:HasPlayer(name)) or (DB.LookupPlayer and DB:LookupPlayer(name)) then
            return
          end
          DB:AddPlayer(name, L.KOS, nil, UnitName("player"))
          if KillOnSight_Notifier and KillOnSight_Notifier.Chat then
            KillOnSight_Notifier:Chat(string.format(L.ADDED_PLAYER, L.KOS, name))
          end
          if KillOnSight_GUI and KillOnSight_GUI.RefreshAll then
            KillOnSight_GUI:RefreshAll()
          end
        end
      },
      { text = L.UI_SYNC, notCheckable = true, func = function() KillOnSight_Sync:RequestDiff() end },
      { text = L.UI_CLOSE, notCheckable = true, func = function() if KillOnSight_GUI then KillOnSight_GUI:Hide() end end },
    }
    ShowDropdown(menu)
  end
end

function Minimap:Create()
  local prof = DB:GetProfile()
  prof.minimap = prof.minimap or { hide=false, minimapPos=220 }
  if not icon:IsRegistered("KillOnSight") then
    icon:Register("KillOnSight", dataobj, prof.minimap)
  end
  icon:Refresh("KillOnSight", prof.minimap)
end

KillOnSight_Minimap = Minimap
