-- Notifier.lua
local ADDON_NAME = ...
local L = KillOnSight_L
local DB = KillOnSight_DB

local Notifier = {}





-- Additional anti-spam for KoS / Guild alerts across all detection sources (detector + combat log).
-- This prevents duplicate warnings when multiple systems detect the same player close together.
Notifier._lastKosAlertAt = Notifier._lastKosAlertAt or {}

local function ShouldAlertOnce(key, cooldownSeconds)
  local now = GetTime()
  local last = Notifier._lastKosAlertAt[key]
  if last and (now - last) < cooldownSeconds then
    return false
  end
  Notifier._lastKosAlertAt[key] = now
  return true
end

local function ClassHex(classFile)
  if not classFile or not RAID_CLASS_COLORS or not RAID_CLASS_COLORS[classFile] then
    return nil
  end
  local c = RAID_CLASS_COLORS[classFile]
  local r = math.floor((c.r or 1) * 255 + 0.5)
  local g = math.floor((c.g or 1) * 255 + 0.5)
  local b = math.floor((c.b or 1) * 255 + 0.5)
  return string.format("|cff%02x%02x%02x", r, g, b)
end

local function ColorizeName(name, classFile)
  local hex = ClassHex(classFile)
  if not hex then return name end
  return hex .. name .. "|r"
end

function Notifier:GetStealthTiming()
  local prof = DB:GetProfile()
  local hold = tonumber(prof.stealthWarningHoldSeconds) or 6.0
  local fade = tonumber(prof.stealthWarningFadeSeconds) or 1.2
  if hold < 0 then hold = 0 end
  if fade < 0.1 then fade = 0.1 end
  return hold, fade
end

function Notifier:ApplyStealthSettings()
  local prof = DB:GetProfile()
  if prof.stealthDetectCenterWarning == false then
    if self.warningFrame then
      self.warningFrame:Hide()
    end
    if self._stealthHoldTimer and self._stealthHoldTimer.Cancel then
      self._stealthHoldTimer:Cancel()
    end
    if self._stealthFadeTicker and self._stealthFadeTicker.Cancel then
      self._stealthFadeTicker:Cancel()
    end
    self._stealthHoldTimer = nil
    self._stealthFadeTicker = nil
  end
end

local CENTER_WARNING_HOLD = 2.0   -- seconds fully visible
local CENTER_WARNING_FADE = 1.2   -- seconds smooth fade out
local CENTER_WARNING_YOFF = 180   -- vertical offset from center
-- Spy-style center warning frame (custom, reliable across client branches)
local function EnsureSpyWarningFrame()
  if Notifier._spyFrame then return Notifier._spyFrame end

  local parent = _G.UIParent or nil
  local f = CreateFrame("Frame", "KillOnSight_SpyWarningFrame", parent)
  f:SetFrameStrata("HIGH")
  f:SetSize(720, 84)
  if parent then
    f:SetPoint("CENTER", parent, "CENTER", 0, CENTER_WARNING_YOFF)
  else
    f:SetPoint("CENTER", 0, CENTER_WARNING_YOFF)
  end
  f:Hide()
  f:SetAlpha(1)

  -- Banner background
  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(true)
  bg:SetColorTexture(0, 0, 0, 0.55)
  f.bg = bg

  -- Thin red top/bottom lines (Spy-ish)
  local top = f:CreateTexture(nil, "BORDER")
  top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  top:SetHeight(2)
  top:SetColorTexture(1, 0.15, 0.15, 0.9)

  local bottom = f:CreateTexture(nil, "BORDER")
  bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  bottom:SetHeight(2)
  bottom:SetColorTexture(1, 0.15, 0.15, 0.9)

  -- Text
  local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  fs:SetPoint("CENTER")
  fs:SetJustifyH("CENTER")
  fs:SetJustifyV("MIDDLE")
  fs:SetTextColor(1, 0.12, 0.12)
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetShadowOffset(2, -2)
  f.text = fs

  -- Internal fade state
  f._phase = "idle"
  f._t = 0
  f._timer = nil

  Notifier._spyFrame = f
  return f
end

local flashFrame

local function EnsureFlashFrame()
  if flashFrame then return end
  flashFrame = CreateFrame("Frame", nil, UIParent)
  flashFrame:SetAllPoints(UIParent)
  flashFrame:Hide()
  flashFrame.tex = flashFrame:CreateTexture(nil, "BACKGROUND")
  flashFrame.tex:SetAllPoints(true)
  flashFrame.tex:SetColorTexture(1, 0, 0, 0.18)
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00d0ff"..L.ADDON_PREFIX..":|r "..msg)
end

function Notifier:Chat(msg)
  if DB:GetProfile().printToChat then
    Print(msg)
  end
end

function Notifier:Sound()
  if not DB:GetProfile().enableSound then return end
  PlaySound(SOUNDKIT.RAID_WARNING, "Master")
end

function Notifier:Flash()
  if not DB:GetProfile().enableScreenFlash then return end
  EnsureFlashFrame()
  flashFrame:Show()
  flashFrame:SetAlpha(0.65)
  flashFrame.elapsed = 0
  flashFrame:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt
    local a = 0.65 * (1 - (self.elapsed / 0.55))
    if a <= 0 then
      self:SetScript("OnUpdate", nil)
      self:Hide()
    else
      self:SetAlpha(a)
    end
  end)
end

function Notifier:NotifyPlayer(listType, name, reason)
  local suffix = reason and (" - "..reason) or ""

-- Anti-spam: suppress repeated alerts for the same KoS/Guild target
local prof = DB:GetProfile()
local cd = tonumber(prof.kosAlertCooldownSeconds) or 30
local k = ("p:" .. tostring(name or ""):lower())
if cd > 0 and not ShouldAlertOnce(k, cd) then
  return
end
  self:Chat(string.format(L.SEEN, listType, name, suffix))
  self:Sound()
  self:Flash()

  -- Ensure alerts also show in the Nearby list.
  -- Some detection paths can notify without the spy-like hostile scan having
  -- populated the Nearby window yet.
  if _G.KillOnSight_Nearby and _G.KillOnSight_Nearby.Seen then
    _G.KillOnSight_Nearby:Seen(name, nil, nil, listType, nil)
  end
end

function Notifier:NotifyGuild(listType, name, guild, reason)
  local suffix = reason and (" - "..reason) or ""

-- Anti-spam: suppress repeated alerts for the same guild KoS target
local prof = DB:GetProfile()
local cd = tonumber(prof.guildAlertCooldownSeconds) or 30
local k = ("g:" .. tostring(guild or ""):lower() .. ":" .. tostring(name or ""):lower())
if cd > 0 and not ShouldAlertOnce(k, cd) then
  return
end
  self:Chat(string.format(L.SEEN_GUILD, listType, name, guild, suffix))
  self:Sound()
  self:Flash()

  -- Ensure alerts also show in the Nearby list.
  if _G.KillOnSight_Nearby and _G.KillOnSight_Nearby.Seen then
    _G.KillOnSight_Nearby:Seen(name, nil, guild, listType, nil)
  end
end


function Notifier:CenterWarning(msg)
  local hold, fade = self:GetStealthTiming()
  if self._stealthHoldTimer and self._stealthHoldTimer.Cancel then self._stealthHoldTimer:Cancel() end
  if self._stealthFadeTicker and self._stealthFadeTicker.Cancel then self._stealthFadeTicker:Cancel() end
  self._stealthHoldTimer = nil
  self._stealthFadeTicker = nil
  if not msg or msg == "" then return end

  local f = EnsureSpyWarningFrame()
  if f and f.text then
    f.text:SetText(msg)
    f:SetAlpha(1)
    f:Show()

    -- Cancel any existing timer
    if f._timer and f._timer.Cancel then
      f._timer:Cancel()
      f._timer = nil
    end

    -- Reset any running OnUpdate fade
    f:SetScript("OnUpdate", nil)
    f._phase = "hold"
    f._t = 0

    -- After hold time, begin fade-out smoothly
    if _G.C_Timer and _G.C_Timer.NewTimer then
      f._timer = _G.C_Timer.NewTimer(hold, function()
        if not f then return end
        f._phase = "fade"
        f._t = 0
        f:SetScript("OnUpdate", function(self, elapsed)
          self._t = (self._t or 0) + elapsed
          local p = self._t / fade
          if p >= 1 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetAlpha(1)
            self._phase = "idle"
            return
          end
          self:SetAlpha(1 - p)
        end)
      end)
    else
      -- Very old fallback: do both hold+fade inside OnUpdate
      f._phase = "hold"
      f._t = 0
      f:SetScript("OnUpdate", function(self, elapsed)
        self._t = (self._t or 0) + elapsed
        if self._phase == "hold" then
          if self._t >= hold then
            self._phase = "fade"
            self._t = 0
          end
          return
        end

        local p = self._t / fade
        if p >= 1 then
          self:SetScript("OnUpdate", nil)
          self:Hide()
          self:SetAlpha(1)
          self._phase = "idle"
          return
        end
        self:SetAlpha(1 - p)
      end)
    end

    return
  end

  -- Fallback: UIErrorsFrame (some UIs filter it)
  if _G.UIErrorsFrame and _G.UIErrorsFrame.AddMessage then
    pcall(function() _G.UIErrorsFrame:AddMessage(msg, 1, 0.1, 0.1) end)
    return
  end

  -- Fallback: Raid warning (top-middle).
  if _G.RaidNotice_AddMessage and _G.RaidWarningFrame and _G.ChatTypeInfo then
    _G.RaidNotice_AddMessage(_G.RaidWarningFrame, msg, _G.ChatTypeInfo["RAID_WARNING"])
    return
  end
end
function Notifier:NotifyHidden(name, spellName, guid)
  local prof = DB:GetProfile()

  -- Master stealth toggle (live)
  if prof.stealthDetectEnabled == false then
    return
  end

  local classFile
  if guid and GetPlayerInfoByGUID then
    local _, cls = GetPlayerInfoByGUID(guid)
    classFile = cls
  end

  local coloredName = ColorizeName(name, classFile)
  local label = spellName and (spellName .. ": ") or ""

  -- Chat output (Chat() respects printToChat)
  self:Chat(string.format(L.SEEN_HIDDEN, label .. coloredName))

  -- Center warning banner
  if prof.stealthDetectCenterWarning ~= false then
    self:CenterWarning(string.format(L.SEEN_HIDDEN, label .. coloredName))
  end

  -- Stealth sound
  if prof.enableSound and prof.stealthDetectSound ~= false then
    local ok = pcall(PlaySoundFile, "Interface\\AddOns\\KillOnSight\\Sounds\\detected-stealth.mp3", "Master")
    if not ok then
      PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
  end

  self:Flash()

  -- Add to Nearby list (pass class so row can be colored/iconed)
  if prof.stealthDetectAddToNearby ~= false then
    if _G.KillOnSight_Nearby and _G.KillOnSight_Nearby.Seen then
      _G.KillOnSight_Nearby:Seen(name, classFile, nil, L.HIDDEN, nil)
    end
  end
end

function Notifier:NotifyActivity(listType, name, activity, reason)
  local suffix = reason and (" - "..reason) or ""
  self:Chat(string.format(L.ACTIVITY, listType, name, activity, suffix))
  self:Sound()
end

KillOnSight_Notifier = Notifier
