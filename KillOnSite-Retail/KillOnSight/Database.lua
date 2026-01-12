-- Database.lua
local ADDON_NAME = ...
local L = KillOnSight_L

KillOnSightDB = KillOnSightDB or {}


-- NOTE: SavedVariables are handled via KillOnSightDB.
-- Any legacy migration code was removed during cleanup because it was either a no-op or dead code.

local DB = {}

-- 2.9.2 bounded changelog (prevents SavedVariables bloat)
local CHANGELOG_KEEP = 800
local CHANGELOG_PRUNE_EVERY = 25

local function Now() return time() end

local function RealmKey()
  local realm = GetRealmName() or "UnknownRealm"
  local faction = UnitFactionGroup("player") or "Neutral"
  return realm .. "-" .. faction
end

local DEFAULTS = {
  profile = {
    enableSound = true,
    enableScreenFlash = true,
    throttleSeconds = 12,
    guildAlertCooldownSeconds = 30,
    kosAlertCooldownSeconds = 30,
    activityThrottleSeconds = 8,
    notifyInInstances = true,
    printToChat = true,
    minimap = { hide=false, minimapPos=220 },
    showNearbyFrame = true,
    nearbyFrameLocked = false,
    nearbyFrame = { point="CENTER", relPoint="CENTER", x=280, y=80, scale=0.80 },
    nearbyAlpha = 0.80,
    nearbyAutoHide = false,
    nearbyFade = false,
    -- Nearby window is always ultra-minimal (no toggle)
    nearbyMinimal = true,
    nearbyRowIcons = true,
    nearbyRowFade = true,
-- Stealth detection
stealthDetectEnabled = true,
stealthDetectSound = true,
stealthDetectCenterWarning = true,
stealthDetectAddToNearby = true,
stealthWarningHoldSeconds = 6.0,
stealthWarningFadeSeconds = 1.2,
  },
  data = {
    revision = 0,          -- global revision
    changeSeq = 0,         -- monotonically increasing change id
    oldestSeq = 0,         -- lowest retained change id (for pruning)
    players = {},          -- [lowerName] = entry
    guilds  = {},          -- [lowerGuild] = entry
    changes = {},          -- [seq] = { op="upsert"/"delete", kind="P"/"G", key, entry, rev }
    lastAttackers = {},    -- array of {name, guid, zone, at}
  }
}

local function DeepCopy(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = dst[k] or {}
      DeepCopy(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local function norm(s)
  if not s or s == "" then return nil end
  s = s:gsub("^%s+",""):gsub("%s+$","")
  if s == "" then return nil end
  return s
end

function DB:Init()
  KillOnSightDB.realms = KillOnSightDB.realms or {}
  local key = RealmKey()
  KillOnSightDB.realms[key] = KillOnSightDB.realms[key] or {}
  local realmDB = KillOnSightDB.realms[key]
  DeepCopy(realmDB, DEFAULTS)
  self.realmKey = key
  self.realmDB = realmDB

  -- Force ultra-minimal Nearby window (no option to change)
  realmDB.profile.nearbyMinimal = true

    -- prune very old change log if it grew huge
  local data = realmDB.data
  data.changes = data.changes or {}
  local count = 0
  for _ in pairs(data.changes) do count = count + 1 end
  if count > CHANGELOG_KEEP then
    self:PruneChangeLog()
  else
    -- ensure oldestSeq is set at least once
    if not data.oldestSeq then
      local minSeq
      for k in pairs(data.changes) do
        local kn = tonumber(k)
        if kn and (not minSeq or kn < minSeq) then minSeq = kn end
      end
      data.oldestSeq = minSeq or data.changeSeq or 0
    end
  end
end


function DB:GetProfile() return self.realmDB.profile end
function DB:GetData() return self.realmDB.data end

function DB:PruneChangeLog()
  local d = self:GetData()
  d.changes = d.changes or {}
  -- Fast path: count
  local count = 0
  for _ in pairs(d.changes) do count = count + 1 end
  if count <= CHANGELOG_KEEP then
    -- keep oldestSeq up to date if possible
    if not d.oldestSeq then
      -- find minimum existing
      local minSeq
      for s in pairs(d.changes) do
        if type(s) == "number" then
          if not minSeq or s < minSeq then minSeq = s end
        else
          local sn = tonumber(s)
          if sn and (not minSeq or sn < minSeq) then minSeq = sn end
        end
      end
      d.oldestSeq = minSeq or d.changeSeq or 0
    end
    return
  end

  local keys = {}
  for k in pairs(d.changes) do
    local kn = tonumber(k)
    if kn then keys[#keys+1] = kn end
  end
  table.sort(keys)
  local keepFrom = math.max(1, #keys - CHANGELOG_KEEP + 1)
  for i = 1, keepFrom - 1 do
    d.changes[keys[i]] = nil
  end
  d.oldestSeq = keys[keepFrom] or d.changeSeq or 0
end

function DB:GetOldestChangeSeq()
  local d = self:GetData()
  return tonumber(d.oldestSeq or 0) or 0
end

function DB:_IncRevision()
  local d = self:GetData()
  d.revision = (d.revision or 0) + 1
  return d.revision
end

function DB:_PushChange(op, kind, key, entry)
  local d = self:GetData()
  d.changeSeq = (d.changeSeq or 0) + 1
  local seq = d.changeSeq
  d.changes[seq] = { op=op, kind=kind, key=key, entry=entry, rev=d.revision }

  d._pruneCounter = (d._pruneCounter or 0) + 1
  if d._pruneCounter >= CHANGELOG_PRUNE_EVERY then
    d._pruneCounter = 0
    self:PruneChangeLog()
  end
end


local function MakePlayerEntry(name, listType, reason, addedBy, existing, class)
  return {
    name = name,
    
    class = class or (existing and existing.class) or nil,
type = listType or L.KOS,
    reason = norm(reason),
    addedBy = addedBy or UnitName("player") or "Unknown",
    addedAt = existing and existing.addedAt or Now(),
    modifiedAt = Now(),
    lastSeenAt = existing and existing.lastSeenAt or nil,
    lastSeenZone = existing and existing.lastSeenZone or nil,
  }
end

local function MakeGuildEntry(guild, listType, reason, addedBy, existing)
  return {
    guild = guild,
    type = listType or L.GUILD_KOS,
    reason = norm(reason),
    addedBy = addedBy or UnitName("player") or "Unknown",
    addedAt = existing and existing.addedAt or Now(),
    modifiedAt = Now(),
    lastSeenAt = existing and existing.lastSeenAt or nil,
    lastSeenZone = existing and existing.lastSeenZone or nil,
  }
end

function DB:AddPlayer(name, listType, reason, addedBy, class)
  name = norm(name); if not name then return false end
  local key = name:lower()
  local d = self:GetData()
  local existing = d.players[key]
  local entry = MakePlayerEntry(name, listType, reason, addedBy, existing, class)
  d.players[key] = entry
  self:_IncRevision()
  self:_PushChange("upsert","P",key,entry)
  return true
end

function DB:SetPlayerClass(name, class)
  if not name or not class then return false end
  local key = name:lower()
  local d = self:GetData()
  local e = d.players[key]
  if not e then return false end
  if e.class == class then return false end
  e.class = class
  e.modifiedAt = Now and Now() or time()
  self:_IncRevision()
  self:_PushChange("upsert","P",key,e)
  return true
end



function DB:RemovePlayer(name)
  name = norm(name); if not name then return false end
  local key = name:lower()
  local d = self:GetData()
  if d.players[key] then
    d.players[key] = nil
    self:_IncRevision()
    self:_PushChange("delete","P",key,nil)
    return true
  end
  return false
end

function DB:AddGuild(guild, listType, reason, addedBy)
  guild = norm(guild); if not guild then return false end
  local key = guild:lower()
  local d = self:GetData()
  local existing = d.guilds[key]
  local entry = MakeGuildEntry(guild, listType, reason, addedBy, existing)
  d.guilds[key] = entry
  self:_IncRevision()
  self:_PushChange("upsert","G",key,entry)
  return true
end

function DB:RemoveGuild(guild)
  guild = norm(guild); if not guild then return false end
  local key = guild:lower()
  local d = self:GetData()
  if d.guilds[key] then
    d.guilds[key] = nil
    self:_IncRevision()
    self:_PushChange("delete","G",key,nil)
    return true
  end
  return false
end

function DB:LookupPlayer(name)
  if not name then return nil end
  return self:GetData().players[name:lower()]
end

function DB:LookupGuild(guild)
  if not guild or guild == "" then return nil end
  return self:GetData().guilds[guild:lower()]
end

function DB:HasPlayer(name)
  return self:LookupPlayer(name) ~= nil
end

function DB:HasGuild(guild)
  return self:LookupGuild(guild) ~= nil
end
function DB:MarkSeenPlayer(name)
  local e = self:LookupPlayer(name)
  if e then
    e.lastSeenAt = Now()
    e.lastSeenZone = GetRealZoneText() or GetZoneText() or ""
  end
end

function DB:MarkSeenGuild(guild)
  local e = self:LookupGuild(guild)
  if e then
    e.lastSeenAt = Now()
    e.lastSeenZone = GetRealZoneText() or GetZoneText() or ""
  end
end

-- Apply changes received from sync
function DB:ApplyRemoteChange(sender, change)
  local d = self:GetData()
  if not change or not change.kind or not change.key then return end

  if change.kind == "P" then
    if change.op == "delete" then
      d.players[change.key] = nil
    elseif change.op == "upsert" and change.entry then
      d.players[change.key] = change.entry
    end
  elseif change.kind == "G" then
    if change.op == "delete" then
      d.guilds[change.key] = nil
    elseif change.op == "upsert" and change.entry then
      d.guilds[change.key] = change.entry
    end
  end

  -- keep our revision monotonic
  d.revision = math.max(tonumber(d.revision or 0), tonumber(change.rev or 0))
end


function DB:AddLastAttacker(name, guid, zone, guild, classFile)
  if not name or name == "" then return end
  local d = self:GetData()
  d.lastAttackers = d.lastAttackers or {}
  local keyName = name:lower()
  local keyGUID = (guid and guid ~= "") and guid or nil

  local priorClass

  -- remove existing entry (prefer GUID match when available)
  for j = #d.lastAttackers, 1, -1 do
    local e = d.lastAttackers[j]
    if e then
      if keyGUID and e.guid == keyGUID then
        priorClass = priorClass or (e and e.class)
        table.remove(d.lastAttackers, j)
      elseif (not keyGUID) and e.name and e.name:lower() == keyName then
        priorClass = priorClass or (e and e.class)
        table.remove(d.lastAttackers, j)
      end
    end
  end

  table.insert(d.lastAttackers, 1, { name = name, guid = guid or "", zone = zone or "", guild = guild or "", class = classFile or priorClass })

  -- cap
  while #d.lastAttackers > 50 do
    table.remove(d.lastAttackers)
  end
end

function DB:UpdateLastAttackerGuild(name, guild)
  if (not guild) or guild == "" then return end
  local d = self:GetData()
  d.lastAttackers = d.lastAttackers or {}

  local keyName = (name and name ~= "") and name:lower() or nil
  local keyGUID = (name and name:find("^Player%-")) and name or nil
  -- If caller passed a GUID in the first arg, match by GUID; otherwise match by name.
  for j = 1, #d.lastAttackers do
    local e = d.lastAttackers[j]
    if e then
      if keyGUID and e.guid == keyGUID then
        e.guild = guild
        return
      elseif (not keyGUID) and keyName and e.name and e.name:lower() == keyName then
        e.guild = guild
        return
      end
    end
  end
end

function DB:UpdateLastAttackerGuildByGUID(guid, guild)
  if not guid or guid == "" then return end
  if not guild or guild == "" then return end
  local d = self:GetData()
  d.lastAttackers = d.lastAttackers or {}
  for i=1,#d.lastAttackers do
    local e = d.lastAttackers[i]
    if e and e.guid == guid then
      e.guild = guild
      return true
    end
  end
end

function DB:GetLastAttackers()
  local d = self:GetData()
  d.lastAttackers = d.lastAttackers or {}
  return d.lastAttackers
end

function DB:ClearLastAttackers()
  local d = self:GetData()
  d.lastAttackers = {}
end


KillOnSight_DB = DB
