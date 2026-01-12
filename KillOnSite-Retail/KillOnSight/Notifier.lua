-- Notifier.lua
local ADDON_NAME = ...
local L = KillOnSight_L
local DB = KillOnSight_DB

local Notifier = {}

-- Throttle table for stealth alert popups (per player)
local stealthPopupAt = {}


-- Spy-style flash implementation (copied from Spy)
local SpyFrameFlashManager = CreateFrame("FRAME");
local SPYFADEFRAMES = {};
local SPYFLASHFRAMES = {};
local SpyFrameFlashTimers = {};
local SpyFrameFlashTimerRefCount = {};

-- Fucntion to see if a frame is fading
function SpyFrameIsFading(frame)
	for index, value in pairs(SPYFADEFRAMES) do
		if ( value == frame ) then
			return 1;
		end
	end
	return nil;
end

-- Function to stop flashing --
local function SpyFrameFlashStop(frame)
    tDeleteItem(SPYFLASHFRAMES, frame);
    frame:SetAlpha(1.0);
    frame.flashTimer = nil;
    if (frame.syncId) then
        SpyFrameFlashTimerRefCount[frame.syncId] = SpyFrameFlashTimerRefCount[frame.syncId]-1;
        if (SpyFrameFlashTimerRefCount[frame.syncId] == 0) then
            SpyFrameFlashTimers[frame.syncId] = nil;
            SpyFrameFlashTimerRefCount[frame.syncId] = nil;
        end
        frame.syncId = nil;
    end
    if ( frame.showWhenDone ) then
        frame:Show();
    else
        frame:Hide();
    end
end

-- Call every frame to update flashing frames  --
local function SpyFrameFlash_OnUpdate(self, elapsed)
    local frame;
    local index = #SPYFLASHFRAMES;
     
    -- Update timers for all synced frames
    for syncId, timer in pairs(SpyFrameFlashTimers) do
        SpyFrameFlashTimers[syncId] = timer + elapsed;
    end
     
    while SPYFLASHFRAMES[index] do
        frame = SPYFLASHFRAMES[index];
        frame.flashTimer = frame.flashTimer + elapsed;
        if ( (frame.flashTimer > frame.flashDuration) and frame.flashDuration ~= -1 ) then
            SpyFrameFlashStop(frame);
        else
            local flashTime = frame.flashTimer;
            local alpha;
            if (frame.syncId) then
                flashTime = SpyFrameFlashTimers[frame.syncId];
            end
            flashTime = flashTime%(frame.fadeInTime+frame.fadeOutTime+(frame.flashInHoldTime or 0)+(frame.flashOutHoldTime or 0));
            if (flashTime < frame.fadeInTime) then
                alpha = flashTime/frame.fadeInTime;
            elseif (flashTime < frame.fadeInTime+(frame.flashInHoldTime or 0)) then
                alpha = 1;
            elseif (flashTime < frame.fadeInTime+(frame.flashInHoldTime or 0)+frame.fadeOutTime) then
                alpha = 1 - ((flashTime - frame.fadeInTime - (frame.flashInHoldTime or 0))/frame.fadeOutTime);
            else
                alpha = 0;
            end
            frame:SetAlpha(alpha);
            frame:Show();
        end
        -- Loop in reverse so that removing frames is safe
        index = index - 1;
    end
    if ( #SPYFLASHFRAMES == 0 ) then
        self:SetScript("OnUpdate", nil);
    end
end

-- Function to start a frame flashing
local function SpyFrameFlash(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime, syncId)
    if ( frame ) then
        local index = 1;
        -- If frame is already set to flash then return
        while SPYFLASHFRAMES[index] do		
            if ( SPYFLASHFRAMES[index] == frame ) then
                return;
            end
            index = index + 1;
        end
        if (syncId) then
            frame.syncId = syncId;
            if (SpyFrameFlashTimers[syncId] == nil) then
                SpyFrameFlashTimers[syncId] = 0;
                SpyFrameFlashTimerRefCount[syncId] = 0;
            end
            SpyFrameFlashTimerRefCount[syncId] = SpyFrameFlashTimerRefCount[syncId]+1;
        else
            frame.syncId = nil;
        end
        -- Time it takes to fade in a flashing frame
        frame.fadeInTime = fadeInTime;
        -- Time it takes to fade out a flashing frame
        frame.fadeOutTime = fadeOutTime;
        -- How long to keep the frame flashing
        frame.flashDuration = flashDuration;
        -- Show the flashing frame when the fadeOutTime has passed
        frame.showWhenDone = showWhenDone;
        -- Internal timer
        frame.flashTimer = 0;
        -- How long to hold the faded in state
        frame.flashInHoldTime = flashInHoldTime;
        -- How long to hold the faded out state
        frame.flashOutHoldTime = flashOutHoldTime;
         
        tinsert(SPYFLASHFRAMES, frame);		
         
       SpyFrameFlashManager:SetScript("OnUpdate", SpyFrameFlash_OnUpdate);
    end
end






-- Additional anti-spam for KoS / Guild alerts across all detection sources.
-- Prevents duplicate warnings when multiple systems detect the same player close together.
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


-- Spy's compact alert window (used for stealth announcements)
local function EnsureSpyAlertWindow()
  if Notifier._spyAlertWindow then return Notifier._spyAlertWindow end

  local f = CreateFrame("Frame", "KillOnSight_SpyAlertWindow", UIParent, "BackdropTemplate")
  f:ClearAllPoints()
  f:SetPoint("TOP", UIParent, "TOP", 0, -140)
  f:SetClampedToScreen(true)
  f:SetHeight(42)
  f:Hide()

  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  f:SetBackdropColor(0, 0, 0, 0.90)

  f.Icon = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.Icon:ClearAllPoints()
  f.Icon:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -5)
  f.Icon:SetSize(32, 32)
  f.Icon:SetBackdrop({ bgFile = "Interface\\Icons\\Ability_Stealth" })
  f.Icon:SetBackdropColor(1, 1, 1, 0.5)

  f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.Title:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -3)
  f.Title:SetHeight(12)
  f.Title:SetText("Stealth player detected!")


  f.Name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.Name:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -15)
  f.Name:SetHeight(12)

  f.Location = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.Location:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -26)
  f.Location:SetHeight(12)
  f.Location:SetText("")

  -- Visual styling (match Spy defaults)
  local br, bg, bb, ba = 0.6, 0.2, 1.0, 0.4 -- Stealth Border
  f:SetBackdropBorderColor(br, bg, bb, ba)
  f.Title:SetTextColor(0.6, 0.2, 1.0, 1)     -- Stealth Text
  f.Name:SetTextColor(1, 1, 1, 1)           -- Name Text
  f.Location:SetTextColor(1, 0.82, 0, 1)    -- Location Text (unused for stealth)

  Notifier._spyAlertWindow = f
  return f
end

function Notifier:ShowSpyStealthAlert(name, classFile)
  local f = EnsureSpyAlertWindow()
  -- Apply class-colored name (Spy-style)
  local coloredName = ColorizeName(name, classFile)
  f.Name:SetText(coloredName or (name or ""))
  -- Name position (no class icon)
  f.Name:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -15)

  -- Width = max(title, name) + 52 (Spy formula)
  f:SetWidth(f.Title:GetStringWidth() + 52)
  if (f.Title:GetStringWidth() < f.Name:GetStringWidth()) then
    f:SetWidth(f.Name:GetStringWidth() + 52)
  else
    f:SetWidth(f.Title:GetStringWidth() + 52)
  end
  f.Name:SetWidth(f:GetWidth() - 52)
  f.Location:SetWidth(f:GetWidth() - 52)

  SpyFrameFlashStop(f)
  -- Spy uses (0,1,5,false,4,0) for stealth
  SpyFrameFlash(f, 0, 1, 5, false, 4, 0)
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
  if allowPopup then
    self:Flash()
  end

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
  if allowPopup then
    self:Flash()
  end

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

  -- Center warning banner (Spy-style window) with per-player throttle so refreshes don't re-flash
  local now = (GetTime and GetTime()) or 0
  local popupKey = name and name:lower() or ""
  local popupCooldown = prof.stealthDetectPopupCooldown or 20  -- seconds
  local allowPopup = true
  if popupKey ~= "" then
    local last = stealthPopupAt[popupKey]
    if last and (now - last) < popupCooldown then
      allowPopup = false
    else
      stealthPopupAt[popupKey] = now
    end
  end

  if prof.stealthDetectCenterWarning ~= false and allowPopup then
    self:ShowSpyStealthAlert(name, classFile)
  end

  -- Stealth sound
  if allowPopup and prof.enableSound and prof.stealthDetectSound ~= false then
    local ok = pcall(PlaySoundFile, "Interface\\AddOns\\KillOnSight\\Sounds\\detected-stealth.mp3", "Master")
    if not ok then
      PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
  end

  if allowPopup then
    self:Flash()
  end

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