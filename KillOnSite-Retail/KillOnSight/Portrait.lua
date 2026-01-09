-- Portrait.lua
-- Adds an overlay "dragon" ring on the Retail/Classic TargetFrame portrait for KoS targets.
--
-- Player KoS  -> Rare (silver) ring
-- Guild KoS   -> Elite (gold) ring
--
-- IMPORTANT: We do NOT re-skin Blizzard's own TargetFrame textures.
-- We render our own overlay texture so we don't stretch/mis-size the default UI assets.

local f = CreateFrame("Frame")

local function NormalizeName(name)
  if not name then return nil end
  return name:match("^([^%-]+)") or name
end

-- Works with both the current refactor DB object and older direct-table layouts.
local function GetDataTables()
  local DB = _G.KillOnSight_DB
  if DB and DB.GetData then
    local data = DB:GetData()
    if data then
      return data.players, data.guilds
    end
  end

  -- Legacy/fallback
  if type(DB) == "table" then
    if DB.players or DB.guilds then
      return DB.players, DB.guilds
    end
    if DB.data and (DB.data.players or DB.data.guilds) then
      return DB.data.players, DB.data.guilds
    end
  end

  return nil, nil
end

local function IsKoSTarget()
  if not UnitExists("target") or not UnitIsPlayer("target") then return false end
  local n, realm = UnitName("target")
  local short = NormalizeName(n)
  if not short then return false end

  local players = select(1, GetDataTables())
  if not players then return false end

  local keyShort = short:lower()
  if players[keyShort] then return true end

  if realm and realm ~= "" then
    local keyFull = (n .. "-" .. realm):lower()
    if players[keyFull] then return true end
  end

  return false
end

local function IsGuildKoSTarget()
  if not UnitExists("target") or not UnitIsPlayer("target") then return false end
  local guildName = GetGuildInfo("target")
  if not guildName or guildName == "" then return false end

  local _, guilds = GetDataTables()
  if not guilds then return false end

  return guilds[guildName:lower()] ~= nil
end

-- ------------------------------------------------------------
-- Overlay texture management
-- ------------------------------------------------------------

local OVERLAY_TEX
local OVERLAY_PARENT
local OVERLAY_ANCHOR

local function GetTargetPortraitFrame()
  -- Retail (Dragonflight / TWW style)
  if _G.TargetFrame and _G.TargetFrame.TargetFrameContainer then
    local c = _G.TargetFrame.TargetFrameContainer
    if c.Portrait then
      return c.Portrait
    end
  end

  -- Classic / legacy
  if _G.TargetFramePortrait then
    return _G.TargetFramePortrait
  end

  -- Fallback: try the portrait region on TargetFrame
  if _G.TargetFrame and _G.TargetFrame.portrait then
    return _G.TargetFrame.portrait
  end

  return nil
end

local function GetOverlayBaseSize(anchor)
  local w = (anchor and anchor.GetWidth and anchor:GetWidth()) or 0
  local h = (anchor and anchor.GetHeight and anchor:GetHeight()) or 0
  local size = math.max(w, h)
  if not size or size <= 0 then
    size = 64
  end

  -- Tuned for Retail 11.2.7. Classic uses a bit smaller ring.
  local ringScale = 1.55
  if WOW_PROJECT_ID and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    ringScale = 1.65
  end

  size = math.floor(size * ringScale + 0.5)
  return size, size
end

local function EnsureOverlay()
  local anchor = GetTargetPortraitFrame()
  if not anchor then return nil end

  -- In Retail, the "portrait" we find is often a Texture object, not a Frame.
  -- Textures do not have :CreateTexture(), so we create our overlay on the parent frame,
  -- but keep it anchored to the portrait region for perfect alignment.
  local parent = (anchor.CreateTexture and anchor) or (anchor.GetParent and anchor:GetParent()) or _G.TargetFrame
  if not parent or not parent.CreateTexture then return nil end

  if OVERLAY_TEX and OVERLAY_PARENT == parent and OVERLAY_ANCHOR == anchor then
    return OVERLAY_TEX
  end

  OVERLAY_PARENT = parent
  OVERLAY_ANCHOR = anchor

  OVERLAY_TEX = parent:CreateTexture(nil, "OVERLAY", nil, 7)
  OVERLAY_TEX:ClearAllPoints()
  OVERLAY_TEX:SetPoint("CENTER", anchor, "CENTER", 0, 0)

  local w, h = GetOverlayBaseSize(anchor)
  if OVERLAY_TEX.SetSize then
    OVERLAY_TEX:SetSize(w, h)
  end

  OVERLAY_TEX:Hide()
  return OVERLAY_TEX
end

local function ApplyOverlay(mode)
  -- mode: "none" | "rare" | "elite"
  local tex = EnsureOverlay()
  if not tex then return end

  if mode == "none" then
    tex:Hide()
    return
  end

  local anchor = OVERLAY_ANCHOR or GetTargetPortraitFrame() or tex

  -- Base size
  local w, h = GetOverlayBaseSize(anchor)
  local offsetX = 0

  -- Per-mode fit adjustments:
  -- Rare is just slightly too big on Retail target frame, so scale down a touch.
  if mode == "rare" then
    w = math.floor(w * 0.88 + 0.5)
    h = w
	offsetX = 4
  end

  -- Elite (gold winged) atlas is visually left-heavy, so:
  -- - smaller than rare
  -- - nudged right a bit
  if mode == "elite" then
    w = math.floor(w * 0.94 + 0.5)
    h = w
    offsetX = 12
  end

  tex:ClearAllPoints()
  tex:SetPoint("CENTER", anchor, "CENTER", offsetX, 0)
  if tex.SetSize then tex:SetSize(w, h) end

  local function TryAtlas(list)
    if not tex.SetAtlas then return false end
    for _, a in ipairs(list) do
      local ok = pcall(function()
        -- Use our explicit sizing (no native atlas sizing) to match TargetFrame.
        tex:SetAtlas(a, false)
      end)
      if ok then
        return true
      end
    end
    return false
  end

  local applied = false

  if mode == "rare" then
    applied = TryAtlas({
      "ui-hud-unitframe-target-portraiton-boss-rare-silver",
      "ui-hud-unitframe-target-portraiton-boss-rare-silver-2x",
      "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare",
    })

    if not applied then
      tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
      tex:SetTexCoord(0, 1, 0, 1)
    end
  else
    applied = TryAtlas({
      "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
      "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",
      "ui-hud-unitframe-target-portraiton-boss-gold-winged",
      "ui-hud-unitframe-target-portraiton-boss-gold",
    })

    if not applied then
      tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
      tex:SetTexCoord(0, 1, 0, 1)
    end
  end

  if tex.SetVertexColor then tex:SetVertexColor(1, 1, 1, 1) end
  tex:Show()
end

-- ------------------------------------------------------------
-- Update loop
-- ------------------------------------------------------------

local function Update()
  if not UnitExists("target") then
    ApplyOverlay("none")
    return
  end

  -- Only apply to PLAYER targets. NPCs keep Blizzard visuals.
  if not UnitIsPlayer("target") then
    ApplyOverlay("none")
    return
  end

  if IsKoSTarget() then
    ApplyOverlay("rare")
  elseif IsGuildKoSTarget() then
    ApplyOverlay("elite")
  else
    ApplyOverlay("none")
  end
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(_, event, addon)
  -- Ensure we only kick on after our addon & the target UI are ready.
  if event == "ADDON_LOADED" then
    if addon == "Blizzard_TargetingUI" or addon == "KillOnSight" then
      if C_Timer and C_Timer.After then
        C_Timer.After(0.1, Update)
      else
        Update()
      end
    end
    return
  end

  Update()
end)
