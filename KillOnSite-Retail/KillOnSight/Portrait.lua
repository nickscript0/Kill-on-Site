-- Portrait.lua
-- TargetFrame dragon border (Retail/Classic):
--   Player KoS  -> Rare (silver) dragon frame
--   Guild KoS   -> Elite (gold) dragon frame
--
-- Retail and Classic have slightly different TargetFrame widget trees.
-- We resolve the correct "portrait border" texture dynamically and then swap
-- the Blizzard textures for perfect alignment.

local f = CreateFrame("Frame")

local ORIGINAL_TEXTURE
local ORIGINAL_ATLAS
local ORIGINAL_VC


local ORIGINAL_POINTS

-- Retail alignment tweak: Blizzard's modern TargetFrame container can apply different offsets
-- than the classic textures we swap in. Adjust these if needed.
local BORDER_X_OFFSET = 12
local BORDER_Y_OFFSET = 0
local function NormalizeName(name)
  if not name then return nil end
  return name:match("^([^%-]+)") or name
end

-- Recursively scan a frame tree for a texture that looks like the target-frame border.
local function ScanForTargetBorderTexture(frame, depth)
  if not frame or depth > 6 then return nil end

  -- Regions (textures, fontstrings, etc.)
  if frame.GetRegions then
    local regions = { frame:GetRegions() }
    for _, r in ipairs(regions) do
      if r and r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
        local t = r:GetTexture()
        if type(t) == "string" then
          -- Classic: Interface\TargetingFrame\UI-TargetingFrame
          -- Retail: still commonly contains "TargetingFrame" for the portrait border
          if t:find("TargetingFrame") or t:find("UI%-TargetingFrame") then
            return r
          end
        end
      end
    end
  end

  -- Children
  if frame.GetChildren then
    local kids = { frame:GetChildren() }
    for _, child in ipairs(kids) do
      local found = ScanForTargetBorderTexture(child, depth + 1)
      if found then return found end
    end
  end

  return nil
end

local function GetTargetFrameTexture()
  -- Classic global
  local tex = _G.TargetFrameTextureFrameTexture
          or (_G.TargetFrameTextureFrame and _G.TargetFrameTextureFrame.Texture)
  if tex and tex.SetTexture then
    return tex
  end

  -- Retail (Dragonflight / The War Within style container)
  if _G.TargetFrame and _G.TargetFrame.TargetFrameContainer then
    local c = _G.TargetFrame.TargetFrameContainer
    if c.FrameTexture and c.FrameTexture.SetTexture then
      return c.FrameTexture
    end
    if c.Portrait and c.Portrait.Border and c.Portrait.Border.SetTexture then
      return c.Portrait.Border
    end
  end

  -- Fallback scans
  if _G.TargetFrameTextureFrame then
    local found = ScanForTargetBorderTexture(_G.TargetFrameTextureFrame, 0)
    if found then return found end
  end
  if _G.TargetFrame then
    local found = ScanForTargetBorderTexture(_G.TargetFrame, 0)
    if found then return found end
  end

  return nil
end

local function EnsureOriginal(tex)
  if ORIGINAL_TEXTURE or ORIGINAL_ATLAS then return end
  if tex and tex.GetTexture then
    ORIGINAL_TEXTURE = tex:GetTexture()
  end
  if tex and tex.GetAtlas then
    ORIGINAL_ATLAS = tex:GetAtlas()
  end
  if tex and tex.GetVertexColor then
    local r,g,b,a = tex:GetVertexColor()
    ORIGINAL_VC = {r,g,b,a}
  end
  if tex and tex.GetPoint then
    local p, rel, rp, x, y = tex:GetPoint(1)
    if p then
      ORIGINAL_POINTS = {p, rel, rp, x, y}
    end
  end
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

  -- Legacy/fallback (not expected in 2.8.9 but safe)
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
  local n, r = UnitName("target")
  local short = NormalizeName(n)
  if not short then return false end

  local players = select(1, GetDataTables())
  if not players then return false end

  local keyShort = short:lower()
  if players[keyShort] then return true end

  if r and r ~= "" then
    local keyFull = (n .. "-" .. r):lower()
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

local function ApplyBorder(mode)
  -- mode: "none" | "rare" | "elite"
  local tex = GetTargetFrameTexture()
  if not tex then return end
  EnsureOriginal(tex)

  local function RestoreOriginal()
    if ORIGINAL_ATLAS and tex.SetAtlas then
      tex:SetAtlas(ORIGINAL_ATLAS)
    elseif ORIGINAL_TEXTURE and tex.SetTexture then
      tex:SetTexture(ORIGINAL_TEXTURE)
    elseif tex.SetTexture then
      tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")
    end
    if tex.SetVertexColor then
      if ORIGINAL_VC then
        tex:SetVertexColor(ORIGINAL_VC[1], ORIGINAL_VC[2], ORIGINAL_VC[3], ORIGINAL_VC[4] or 1)
      else
        tex:SetVertexColor(1,1,1,1)
      end
    end
  end

  if mode == "none" then
    RestoreOriginal()
    return
  end

  -- Prefer texture files (present on both Classic and Retail). If the resolved texture is atlas-based,
  -- SetTexture still works on most frames; if not, we fall back to trying SetAtlas with common atlas names.
  if mode == "rare" then
    if tex.SetTexture then tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare") end
    if tex.SetAtlas and tex.GetAtlas and tex:GetAtlas() and not tex:GetTexture() then
      -- best-effort atlas fallback (harmless if missing)
      pcall(tex.SetAtlas, tex, "UI-TargetingFrame-Rare")
    end
    if tex.SetVertexColor then tex:SetVertexColor(1,1,1,1) end
    if ORIGINAL_POINTS and tex.ClearAllPoints and tex.SetPoint then
      tex:ClearAllPoints()
      tex:SetPoint(ORIGINAL_POINTS[1], ORIGINAL_POINTS[2], ORIGINAL_POINTS[3], (ORIGINAL_POINTS[4] or 0) + BORDER_X_OFFSET, (ORIGINAL_POINTS[5] or 0) + BORDER_Y_OFFSET)
    end
    return
  end

  if tex.SetTexture then tex:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite") end
  if tex.SetAtlas and tex.GetAtlas and tex:GetAtlas() and not tex:GetTexture() then
    pcall(tex.SetAtlas, tex, "UI-TargetingFrame-Elite")
  end
  if tex.SetVertexColor then tex:SetVertexColor(1,1,1,1) end
end

local function Update()
  local tex = GetTargetFrameTexture()
  if not tex then
    if C_Timer and C_Timer.After then
      C_Timer.After(0.2, Update)
    end
    return
  end

  -- Do not override Blizzard's own elite/rare/boss classification visuals for NPCs.
  -- We only apply custom borders for PLAYER targets that are KoS or Guild KoS.
  if not UnitExists("target") then
    if TargetFrame_CheckClassification then TargetFrame_CheckClassification(TargetFrame) end
    return
  end

  if UnitIsPlayer("target") then
    if IsKoSTarget() then
      ApplyBorder("rare")
      return
    elseif IsGuildKoSTarget() then
      ApplyBorder("elite")
      return
    end

    -- Non-KoS player: restore Blizzard default (no dragon)
    if TargetFrame_CheckClassification then
      TargetFrame_CheckClassification(TargetFrame)
    else
      ApplyBorder("none")
    end
    return
  end

  -- NPC target: always restore Blizzard default classification (elite/rare/boss dragon etc.)
  if TargetFrame_CheckClassification then
    TargetFrame_CheckClassification(TargetFrame)
  else
    ApplyBorder("none")
  end
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(_, event, addonName)
  -- Ensure we only kick on after our addon & the target UI are ready.
  if event == "ADDON_LOADED" then
    if addonName == "Blizzard_TargetingUI" or addonName == "KillOnSight" then
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
