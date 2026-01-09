-- Core.lua
local ADDON_NAME = ...
local L = KillOnSight_L

local Core = CreateFrame("Frame")

local band = (bit and bit.band) or (bit32 and bit32.band)

local function GetDB() return _G.KillOnSight_DB end
local function GetDetector() return _G.KillOnSight_Detector end
local function GetActivity() return _G.KillOnSight_Activity end
local function GetSync() return _G.KillOnSight_Sync end
local function GetGUI() return _G.KillOnSight_GUI end
local function GetMinimap() return _G.KillOnSight_Minimap end
local function GetNotifier() return _G.KillOnSight_Notifier end
local function GetNearby() return _G.KillOnSight_Nearby end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00d0ff"..L.ADDON_PREFIX..":|r "..msg)
end

-- Nearby list population relies heavily on enemy nameplates (NAME_PLATE_* events / C_NamePlate).
-- If enemy nameplates are disabled, we can only see players when you target/mouseover them.
local function EnsureEnemyNameplatesEnabled()
  -- Intentionally does NOT change the player's nameplate CVars.
  -- Nameplate-based detection will work when enemy nameplates are enabled by the user.
end

local nearbyTicker

local function StartNearbyNameplateScan()
  if nearbyTicker then return end
  if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
  nearbyTicker = C_Timer.NewTicker(2.5, function()
    local Detector = GetDetector()
    if not Detector then return end
    local Nearby = GetNearby()
    if Nearby and Nearby.IsShown and (not Nearby:IsShown()) then return end
    local plates = C_NamePlate.GetNamePlates(false)
    if not plates then return end
    for _, plate in ipairs(plates) do
      local unit = plate and plate.namePlateUnitToken
      if unit then
        Detector:CheckUnit(unit)
      end
    end
  end)
end

local function SplitFirst(s)
  if not s or s == "" then return nil, nil end
  local a, b = s:match("^(%S+)%s*(.-)%s*$")
  return a, b
end

local function Help()
  Print(L.CMD_HELP)
end

local function EnsureName(rest)
  local name = SplitFirst(rest or "")
  if not name or name == "" then
    local unit = "target"
    if UnitExists(unit) and UnitIsPlayer(unit) then
      name = UnitName(unit)
    end
  end
  return name
end

local function AddPlayer(rest)
  local DB = GetDB()
  local Notifier = GetNotifier()
  if not DB or not Notifier then return end

  local name = EnsureName(rest)
  if not name then return Help() end
  if DB:HasPlayer(name) then return end
  DB:AddPlayer(name, L.KOS, nil, UnitName("player"))
  Notifier:Chat(string.format(L.ADDED_PLAYER, L.KOS, name))
  local GUI = GetGUI()
  if GUI then GUI:RefreshAll() end
end

local function RemovePlayer(rest)
  local DB = GetDB()
  local Notifier = GetNotifier()
  if not DB or not Notifier then return end

  local name = SplitFirst(rest or "")
  if not name then return Help() end
  if DB:RemovePlayer(name) then
    Notifier:Chat(string.format(L.REMOVED_PLAYER, name))
  else
    Notifier:Chat(string.format(L.NOT_FOUND, name))
  end
  local GUI = GetGUI()
  if GUI then GUI:RefreshAll() end
end

local function AddGuild(rest)
  local DB = GetDB()
  local Notifier = GetNotifier()
  if not DB or not Notifier then return end

  local guild = SplitFirst(rest or "")
  if not guild then return Help() end
  if DB:HasGuild(guild) then return end
  DB:AddGuild(guild, L.GUILD_KOS, nil, UnitName("player"))
  Notifier:Chat(string.format(L.ADDED_GUILD, L.GUILD_KOS, guild))
  local GUI = GetGUI()
  if GUI then GUI:RefreshAll() end
end

local function RemoveGuild(rest)
  local DB = GetDB()
  local Notifier = GetNotifier()
  if not DB or not Notifier then return end

  local guild = SplitFirst(rest or "")
  if not guild then return Help() end
  if DB:RemoveGuild(guild) then
    Notifier:Chat(string.format(L.REMOVED_GUILD, guild))
  else
    Notifier:Chat(string.format(L.NOT_FOUND, guild))
  end
  local GUI = GetGUI()
  if GUI then GUI:RefreshAll() end
end

local function List()
  local DB = GetDB()
  if not DB then return end
  local d = DB:GetData()
  Print(L.CHAT_PLAYERS..tostring((d.players and #d.players) or 0))
  Print(L.CHAT_GUILDS..tostring((d.guilds and #d.guilds) or 0))
end

SLASH_KILLONSIGHT1 = "/kos"
SlashCmdList[L.ADDON_PREFIX] = function(msg)
  local cmd, rest = SplitFirst((msg or ""):lower())
  cmd = cmd or ""

  if cmd == "" or cmd == "show" then
    local GUI = GetGUI()
    if GUI then GUI:Toggle() end
    return
  end

  if cmd == "help" then return Help() end
  if cmd == "add" then return AddPlayer(rest) end
  if cmd == "remove" or cmd == "del" then return RemovePlayer(rest) end
  if cmd == "addguild" then return AddGuild(rest) end
  if cmd == "removeguild" then return RemoveGuild(rest) end
  if cmd == "list" then return List() end
  if cmd == "sync" then
    local Sync = GetSync()
    if Sync then
      Sync:Hello()
      return Sync:RequestDiff()
    end
    return
  end

  Help()
end

local clSeenAt = {}      -- [nameLower] = GetTime()
local clNotifyAt = {}    -- [key] = GetTime()

-- 2.9.2: combat log cache cleanup
C_Timer.NewTicker(600, function()
  local now = (GetTime and GetTime()) or 0
  for k, t in pairs(clNotifyAt) do
    if now - t > 900 then clNotifyAt[k] = nil end
  end
  for k, t in pairs(clSeenAt) do
    if now - t > 10 then clSeenAt[k] = nil end
  end
end)

-- Guild resolve cache (prevents expensive ResolveGuildForGuid scans on every combat log tick)
local guildCache = {} -- [guid] = { guild = "name", t = GetTime(), lastTry = GetTime() }
local GUILD_CACHE_TTL = 60          -- seconds to keep a resolved guild
local GUILD_RESOLVE_TRY_COOLDOWN = 10 -- seconds between expensive resolve attempts per GUID

local function GetCachedGuild(guid, now)
  local e = guid and guildCache[guid]
  if not e then return nil end
  if (now - (e.t or 0)) > GUILD_CACHE_TTL then
    guildCache[guid] = nil
    return nil
  end
  return e.guild
end

local function NoteResolveTry(guid, now)
  if not guid then return end
  local e = guildCache[guid] or {}
  e.lastTry = now
  guildCache[guid] = e
end

local function CanTryResolveGuild(guid, now)
  if not guid then return false end
  local e = guildCache[guid]
  if not e or not e.lastTry then return true end
  return (now - e.lastTry) >= GUILD_RESOLVE_TRY_COOLDOWN
end

local function SetCachedGuild(guid, guild, now)
  if not guid or not guild or guild == "" then return end
  guildCache[guid] = { guild = guild, t = now }
end


local function IsFlagPlayer(flags)
  if not band then return false end
  return band(flags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0
end

local function IsFlagHostileSpy(flags)
  -- Spy-style: only treat units as hostile if the HOSTILE reaction bit is set.
  -- This avoids same-faction/friendly entries showing up from certain combat log flag combinations.
  if not band then return false end
  local f = flags or 0
  return COMBATLOG_OBJECT_REACTION_HOSTILE
     and band(f, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
end

local function ResolveGuildForGuid(name, guid)
  local function Clean(n)
    if not n then return nil end
    return (n:match('^[^-]+') or n)
  end
  local cleanName = Clean(name)
  local function GuildFromUnit(unit)
    if not unit or not UnitExists or not UnitExists(unit) then return nil end
    if guid and UnitGUID and UnitGUID(unit) ~= guid then return nil end
    if (not guid) and cleanName and UnitName then
      local un = UnitName(unit)
      if not un or Clean(un) ~= cleanName then return nil end
    end
    local g = GetGuildInfo and GetGuildInfo(unit)
    if g and g ~= '' then return g end
    return nil
  end
  -- Quick checks
  local g = GuildFromUnit('target') or GuildFromUnit('mouseover') or GuildFromUnit('focus')
  if g then return g end
  -- Nameplates (most reliable for enemies)
  if C_NamePlate and C_NamePlate.GetNamePlates then
    local plates = C_NamePlate.GetNamePlates()
    if plates then
      for i=1,#plates do
        local unit = plates[i] and plates[i].namePlateUnitToken
        g = GuildFromUnit(unit)
        if g then return g end
      end
    end
  end
  -- Party/Raid (for same-faction situations)
  if IsInGroup and IsInGroup() then
    if IsInRaid and IsInRaid() then
      local n = GetNumGroupMembers and GetNumGroupMembers() or 0
      for i=1,n do
        g = GuildFromUnit('raid'..i)
        if g then return g end
      end
    else
      for i=1,4 do
        g = GuildFromUnit('party'..i)
        if g then return g end
      end
    end
  end
  return nil
end

local function IsFlagHostileOrNeutral(flags)
  if not band then return false end
  local f = flags or 0
  -- Prefer outsider affiliation when available (avoids listing party/raid/friendly units from combat log).
  if COMBATLOG_OBJECT_AFFILIATION_OUTSIDER then
    if band(f, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then return false end
  end
  -- Exclude friendly reaction explicitly (some subevents can carry mixed flags).
  if COMBATLOG_OBJECT_REACTION_FRIENDLY and band(f, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then
    return false
  end
  return (COMBATLOG_OBJECT_REACTION_HOSTILE and band(f, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0)
      or (COMBATLOG_OBJECT_REACTION_NEUTRAL and band(f, COMBATLOG_OBJECT_REACTION_NEUTRAL) ~= 0)
end


local function IsGroupOrSelfByName(name)
  if not name or name == "" then return true end
  local clean = name:match("^[^-]+") or name
  local playerName = UnitName and UnitName("player")
  if playerName and clean == (playerName:match("^[^-]+") or playerName) then
    return true
  end
  -- Party (includes player at index 0 via "party1..4")
  if IsInGroup and IsInGroup() then
    if IsInRaid and IsInRaid() then
      local n = GetNumGroupMembers and GetNumGroupMembers() or 0
      for i=1,n do
        local rn = UnitName("raid"..i)
        if rn and (rn:match("^[^-]+") or rn) == clean then return true end
      end
    else
      for i=1,4 do
        local pn = UnitName("party"..i)
        if pn and (pn:match("^[^-]+") or pn) == clean then return true end
      end
    end
  end
  return false
end

local function ShouldCLSeen(nameLower, now)
  local last = clSeenAt[nameLower]
  if last and (now - last) < 1.0 then return false end
  clSeenAt[nameLower] = now
  return true
end

local function ShouldCLNotify(key, now, cooldown)
  local last = clNotifyAt[key]
  if last and (now - last) < cooldown then return false end
  clNotifyAt[key] = now
  return true
end

local STEALTH_SPELL_IDS = {
  [1784] = true,  -- Rogue: Stealth
  [5215] = true,  -- Druid: Prowl
  [1856] = true,  -- Rogue: Vanish (often logged as aura)
  [20580] = true, -- Night Elf: Shadowmeld
}

local STEALTH_SPELL_NAMES = {
  ["Stealth"] = true,
  ["Prowl"] = true,
  ["Vanish"] = true,
  ["Shadowmeld"] = true,
}

local function IsStealthAura(spellId, spellName)
  if spellId and STEALTH_SPELL_IDS[spellId] then return true end
  if spellName and STEALTH_SPELL_NAMES[spellName] then return true end
  return false
end

local function HandleCombatLog()
  local DB = GetDB()
  local Notifier = GetNotifier and GetNotifier() or _G.KillOnSight_Notifier
  local Nearby = GetNearby()
  if not DB then return end
  if not CombatLogGetCurrentEventInfo then return end

  local timestamp, subevent, hideCaster,
    srcGUID, srcName, srcFlags, srcRaidFlags,
    dstGUID, dstName, dstFlags, dstRaidFlags,
    spellId, spellName, spellSchool = CombatLogGetCurrentEventInfo()

  local now = (GetTime and GetTime()) or 0

  -- Stealth detection (Spy-style): alert on ANY hostile player entering stealth/prowl/shadowmeld.
  if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
    if IsFlagPlayer(srcFlags) and IsFlagHostileSpy(srcFlags) and IsStealthAura(spellId, spellName) then
      local cleanName = srcName and (srcName:match("^[^-]+") or srcName)
      if cleanName and not IsGroupOrSelfByName(cleanName) then
        local key = cleanName:lower()
        if ShouldCLNotify("cl:stealth:" .. key, now, 8) then
          -- Add to Nearby as L.HIDDEN
          if Nearby and Nearby.Seen then
            local classFile
            if srcGUID and GetPlayerInfoByGUID then
              local _, cls = GetPlayerInfoByGUID(srcGUID)
              classFile = cls
            end
            Nearby:Seen(cleanName, classFile, nil, L.HIDDEN, nil)
          end

          if Notifier and Notifier.NotifyHidden then
            local prof = DB and DB:GetProfile()
      if prof and prof.stealthDetectEnabled ~= false then
        Notifier:NotifyHidden(cleanName, spellName, srcGUID)
      end
          end
        end
      end
    end
  end


  local function HandleName(name, flags, guid)
    if not name or name == "" then return end
    if not IsFlagPlayer(flags) then return end
    if not IsFlagHostileSpy(flags) then return end

    local cleanName = name:match("^[^-]+") or name
    local key = cleanName:lower()

    -- Never add yourself or party/raid members from combat log.
    if IsGroupOrSelfByName(cleanName) then return end

    -- Try to resolve class from GUID (Spy-style). This may be nil if unavailable.
    local classFile
    if guid and GetPlayerInfoByGUID then
      local _, cls = GetPlayerInfoByGUID(guid)
      classFile = cls
    end

    -- Feed Nearby list (even when we only know the name from combat log)
    if Nearby and Nearby.Seen and ShouldCLSeen(key, now) then
      local kosType = nil
      if DB.LookupPlayer then
        local pe = DB:LookupPlayer(cleanName)
        if pe then kosType = pe.type or L.KOS end
      end
      Nearby:Seen(cleanName, classFile, nil, kosType, nil)
    end

    -- If this hostile player is on KoS, alert (Spy-like behaviour)
    if Notifier and DB.LookupPlayer then
      local pe = DB:LookupPlayer(cleanName)
      if pe then
        local nk = "cl:p:" .. key
        if ShouldCLNotify(nk, now, 15) then
          DB:MarkSeenPlayer(cleanName)
          Notifier:NotifyPlayer(pe.type or L.KOS, cleanName, pe.reason)
        end
      end
    end
  end

  HandleName(srcName, srcFlags, srcGUID)
  HandleName(dstName, dstFlags, dstGUID)

  -- Keep the old "Last attackers" tracking, but only when the player is the victim.
  local playerGUID = UnitGUID("player")
  if not playerGUID or dstGUID ~= playerGUID then return end
  if not srcName or srcName == "" then return end
  if not IsFlagPlayer(srcFlags) then return end
  if not IsFlagHostileSpy(srcFlags) then return end

  if not (subevent and subevent:find("_DAMAGE")) and subevent ~= "SWING_DAMAGE" and subevent ~= "RANGE_DAMAGE" then
    return
  end

  local guildName = ""
  if srcGUID then
    guildName = GetCachedGuild(srcGUID, now) or ""
    if guildName == "" and CanTryResolveGuild(srcGUID, now) then
      NoteResolveTry(srcGUID, now)
      local resolved = ResolveGuildForGuid(srcName, srcGUID)
      if resolved and resolved ~= "" then
        guildName = resolved
        SetCachedGuild(srcGUID, resolved, now)
      end
    end
  end
  DB:AddLastAttacker(srcName, srcGUID, (GetRealZoneText and GetRealZoneText()) or "", guildName)
end

Core:SetScript("OnEvent", function(self, event, ...)
  local Detector = GetDetector()
  local Sync = GetSync()
  local GUI = GetGUI()
  local Minimap = GetMinimap()
  local Activity = GetActivity()

  if event == "ADDON_LOADED" then
    local addon = ...
    if addon ~= ADDON_NAME then return end
    local DB = GetDB()
    if DB then DB:Init() end
    if Sync then Sync:Init() end
    if Minimap and Minimap.Create then Minimap:Create() end
    local Nearby = GetNearby()
    if Nearby and Nearby.Init then Nearby:Init() end
    StartNearbyNameplateScan()
    Print(L.CHAT_LOADED)
    return
  end

  if event == "CHAT_MSG_ADDON" then
    if Sync then Sync:OnMessage(...) end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    if Detector then Detector:CheckUnit("target") end
    if GUI then GUI:RefreshAll() end
    if Sync then Sync:Hello() end
    return
  end

  if event == "PLAYER_TARGET_CHANGED" then
    if Detector then Detector:CheckUnit("target") end
    if GUI then GUI:RefreshAll() end
    return
  end

  if event == "UPDATE_MOUSEOVER_UNIT" then
    if Detector then Detector:CheckUnit("mouseover") end
    return
  end

  if event == "NAME_PLATE_UNIT_ADDED" then
    local unit = ...
    if Detector then Detector:CheckUnit(unit) end
    return
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    HandleCombatLog()
    if Activity and Activity.OnCombatLog then Activity:OnCombatLog() end
    return
  end
end)

Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("CHAT_MSG_ADDON")
Core:RegisterEvent("PLAYER_ENTERING_WORLD")
Core:RegisterEvent("PLAYER_TARGET_CHANGED")
Core:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
Core:RegisterEvent("NAME_PLATE_UNIT_ADDED")
Core:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
