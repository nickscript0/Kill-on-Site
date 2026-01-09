-- GUI.lua
local ADDON_NAME = ...
local L = KillOnSight_L
local DB = KillOnSight_DB

local GUI = {}
local frame

local function FormatTime(ts)
  if not ts or ts == 0 then return "-" end
  local d = date("%Y-%m-%d %H:%M", ts)
  return d
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00d0ff"..L.ADDON_PREFIX..":|r "..msg)
end

local function CreateBackdrop(f)
  -- Classic uses BackdropTemplate for SetBackdrop
  if not f.SetBackdrop and BackdropTemplateMixin then
    Mixin(f, BackdropTemplateMixin)
  end
  if not f.SetBackdrop then return end
  f:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=32,
    insets={left=8,right=8,top=8,bottom=8}
  })
end

local function MakeButton(parent, text, w, h)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetText(text)
  b:SetSize(w or 100, h or 22)
  return b
end

local function MakeEditBox(parent, w)
  local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  e:SetSize(w or 180, 20)
  e:SetAutoFocus(false)
  e:SetFontObject("ChatFontNormal")
  e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  return e
end

local function MakeCheck(parent, label)
  local c = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
  c.Text:SetText(label)
  return c
end

local KillOnSight_SliderCounter = 0

local function MakeSlider(parent, label, minV, maxV, step)
  KillOnSight_SliderCounter = KillOnSight_SliderCounter + 1
  local name = ("KillOnSight_OptSlider%d"):format(KillOnSight_SliderCounter)
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step or 1)
  s:SetObeyStepOnDrag(true)
  s:SetWidth(160)
  _G[s:GetName().."Text"]:SetText(label)
  _G[s:GetName().."Low"]:SetText(tostring(minV))
  _G[s:GetName().."High"]:SetText(tostring(maxV))
  return s
end

local function CreateScrollList(parent, columns)
  -- columns: { {key="name", title="Name", width=160}, ... }
  local container = CreateFrame("Frame", nil, parent)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

  local header = CreateFrame("Frame", nil, container)
  header:SetPoint("TOPLEFT", 12, -10)
  header:SetPoint("TOPRIGHT", -32, -10)
  header:SetHeight(18)

  local x = 0
  for _,col in ipairs(columns) do
    local t = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", x, 0)
    t:SetWidth(col.width)
    t:SetJustifyH("LEFT")
    t:SetText(col.title)
    col._hdr = t
    x = x + col.width
  end

  local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 8, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(scrollFrame:GetWidth(), 1)
  scrollFrame:SetScrollChild(content)
  scrollFrame:HookScript("OnSizeChanged", function(sf)
    content:SetWidth(sf:GetWidth())
  end)

  local rows = {}
  local function EnsureRows(n)
    local rowH = 18
    for i=#rows+1, n do
      local r = CreateFrame("Button", nil, content)
      r:SetHeight(rowH)
      r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((i-1)*rowH))
      r:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((i-1)*rowH))
      r:RegisterForClicks("LeftButtonUp")
      r:EnableMouse(true)
      r.bg = r:CreateTexture(nil, "BACKGROUND")
      r.bg:SetAllPoints()
      r._rowIndex = i
      r.bg:SetColorTexture(1,1,1, i%2==0 and 0.03 or 0.0)
      r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      local ht = r:GetHighlightTexture()
      ht:SetAllPoints(r)
      ht:SetBlendMode("ADD")

      r.cols = {}
      local xx = 0
      for _,col in ipairs(columns) do
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", xx, 0)
        fs:SetWidth(col.width)
        fs:SetJustifyH("LEFT")
        fs:SetText("")
        r.cols[col.key] = fs
        xx = xx + col.width
      end

      r:SetScript("OnClick", function(self)
        container.selectedKey = self._key
        -- highlight selection
        for _,rr in ipairs(rows) do
          if rr == self then
            rr.bg:SetColorTexture(1,1,1, 0.12)
          else
            rr.bg:SetColorTexture(1,1,1, (rr._rowIndex and (rr._rowIndex%2==0) and 0.03 or 0.0))
          end
        end
        if container.onSelect then container.onSelect(self._key) end
      end)

      rows[i] = r
    end
    content:SetHeight(n*rowH)
  end

  container.SetData = function(self, items)
    self.items = items or {}
    EnsureRows(#self.items)
    for i,row in ipairs(rows) do
      local item = self.items[i]
      row:Hide()
      if item then
        row._key = item._key
        row._rowIndex = i
        for _,col in ipairs(columns) do
          local v = item[col.key]
          row.cols[col.key]:SetText(v or "")
        end
        row:Show()
      end
    end
  end

  return container
end

local function SortPairs(tbl, keyFunc)
  local arr = {}
  for k,v in pairs(tbl or {}) do
    arr[#arr+1] = {k=k, v=v}
  end
  table.sort(arr, function(a,b) return keyFunc(a.v, a.k) < keyFunc(b.v, b.k) end)
  return arr
end

local function BuildPlayers()
  local out = {}
  local data = DB:GetData()
  local sorted = SortPairs(data.players, function(v) return (v.name or ""):lower() end)
  for _,it in ipairs(sorted) do
    local e = it.v
    out[#out+1] = {
      _key = it.k,
      name = e.name,
      type = e.type,
      -- reason hidden in UI

      lastSeen = FormatTime(e.lastSeenAt),
      zone = e.lastSeenZone or "",
    }
  end
  return out
end

local function BuildGuilds()
  local out = {}
  local data = DB:GetData()
  local sorted = SortPairs(data.guilds, function(v) return (v.guild or ""):lower() end)
  for _,it in ipairs(sorted) do
    local e = it.v
    out[#out+1] = {
      _key = it.k,
      guild = e.guild,
      type = e.type,
      -- reason hidden in UI

      lastSeen = FormatTime(e.lastSeenAt),
      zone = e.lastSeenZone or "",
    }
  end
  return out
end

local function BuildLastAttackers(limit)
  limit = limit or 200
  local items = {}
  local list = DB:GetLastAttackers()
  for i=1, math.min(#list, limit) do
    local e = list[i]
    items[#items+1] = {
      _key = (e.name or ""):lower(),
      name = e.name or "",
      guild = e.guild or "",
      zone = e.zone or "",
    }
  end
  return items
end

local function BuildLastSeen(limit)
  limit = limit or 200
  local items = {}
  local data = DB:GetData()
  for k,e in pairs(data.players) do
    if e.lastSeenAt then
      items[#items+1] = { kind="P", _key=k, name=e.name, type=e.type, lastSeenAt=e.lastSeenAt, zone=e.lastSeenZone or "", reason=e.reason or "" }
    end
  end
  for k,e in pairs(data.guilds) do
    if e.lastSeenAt then
      items[#items+1] = { kind="G", _key=k, name=e.guild, type=e.type, lastSeenAt=e.lastSeenAt, zone=e.lastSeenZone or "", reason=e.reason or "" }
    end
  end
  table.sort(items, function(a,b) return (a.lastSeenAt or 0) > (b.lastSeenAt or 0) end)
  local out = {}
  for i=1, math.min(#items, limit) do
    local it = items[i]
    out[#out+1] = {
      _key = it.kind..":"..it._key,
      name = it.name,
      type = it.type,
      lastSeen = FormatTime(it.lastSeenAt),
      zone = it.zone,
      -- reason hidden in UI

    }
  end
  return out
end

local function CreateDropdown(parent, values)
  local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dd.values = values
  dd.selected = values[1]
  UIDropDownMenu_SetWidth(dd, 90)
  UIDropDownMenu_Initialize(dd, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for _,v in ipairs(values) do
      info.text = v
      info.func = function()
        dd.selected = v
        UIDropDownMenu_SetText(dd, v)
      end
      info.checked = (dd.selected == v)
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  UIDropDownMenu_SetText(dd, dd.selected)
  return dd
end

local function MakeTab(parent, idx, text)
  local parentName = parent:GetName() or "KillOnSight_MainFrame"
  local tabName = parentName .. "Tab" .. tostring(idx)
  local tab = CreateFrame("Button", tabName, parent, "PanelTabButtonTemplate")
  tab:SetID(idx)
  tab:SetText(text)
  tab:SetScript("OnClick", function(self)
    PanelTemplates_SetTab(parent, self:GetID())
    parent:ShowTab(self:GetID())
  end)
  return tab
end

function GUI:Create()

-- Forward references for enabling/disabling the Add button safely
local addBtn
local nameBox

local function UpdateAddState()
  if not addBtn or not nameBox then return end
  if not addBtn.IsEnabled or not addBtn.Disable then return end
  local txt = (nameBox.GetText and nameBox:GetText() or "") or ""
  txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
  local exists = false
  if txt ~= "" then
    exists = ((DB.HasPlayer and DB:HasPlayer(txt)) or (DB.LookupPlayer and DB:LookupPlayer(txt) ~= nil) or false)
  elseif UnitExists("target") and UnitIsPlayer("target") then
    local tName = UnitName("target")
    if tName and tName ~= "" then
      exists = ((DB.HasPlayer and DB:HasPlayer(tName)) or (DB.LookupPlayer and DB:LookupPlayer(tName) ~= nil) or false)
    end
  end
  if exists then
    addBtn:Disable()
    addBtn:SetAlpha(0.35)
  else
    addBtn:Enable()
    addBtn:SetAlpha(1)
  end
end

  if frame then return end

  frame = CreateFrame("Frame", "KillOnSight_MainFrame", UIParent, "BackdropTemplate")
  frame:SetSize(640, 440)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()
  CreateBackdrop(frame)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOP", 0, -14)
  frame.title:SetText(L.UI_TITLE)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -5, -5)

  -- tabs
  frame.tabs = {}
  frame.tabPanels = {}

  frame.ShowTab = function(self, id)
    for i=1,#self.tabPanels do local p=self.tabPanels[i]; if p then p:Hide() end end
    self.tabPanels[id]:Show()
  end

  local t1 = MakeTab(frame, 1, L.UI_TAB_PLAYERS)
  local t2 = MakeTab(frame, 2, L.UI_TAB_GUILDS)
  local t3 = MakeTab(frame, 3, L.UI_TAB_ATTACKERS)
  local t4 = MakeTab(frame, 4, L.UI_OPTIONS)

  PanelTemplates_SetNumTabs(frame, 4)
  PanelTemplates_SetTab(frame, 1)


-- Tab layout: place tabs BELOW the frame (so they don't overlap the window content)
local tabs = {t1, t2, t3, t4}
for _,t in ipairs(tabs) do
  if PanelTemplates_TabResize then
    PanelTemplates_TabResize(t, 0, nil, 60, 120)
  end
end

local xPad = 12
local yRow1 = 7      -- row 1 just under frame
local yRow2 = -17    -- row 2 below row 1 (if needed)
local gap = 2
local row = 1
local cur = nil

for _,t in ipairs(tabs) do
  t:ClearAllPoints()
  if not cur then
    t:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", xPad, yRow1)
    cur = t
  else
    t:SetPoint("LEFT", cur, "RIGHT", gap, 0)

    local right = (t:GetRight() or 0)
    local frameRight = (frame:GetRight() or 0)

    if frameRight > 0 and right > 0 and right > (frameRight - 10) and row == 1 then
      t:ClearAllPoints()
      t:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", xPad, yRow2)
      row = 2
    end

    cur = t
  end
end

local pPlayers = CreateFrame("Frame", nil, frame)
  pPlayers:SetAllPoints(frame)
  pPlayers:SetPoint("TOPLEFT", 12, -42)
  pPlayers:SetPoint("BOTTOMRIGHT", -12, 12)
  frame.tabPanels[1] = pPlayers

    local syncBtn = MakeButton(pPlayers, L.UI_SYNC, 90, 22)
  syncBtn:SetPoint("TOPRIGHT", pPlayers, "TOPRIGHT", -10, -10)

  local remBtn = MakeButton(pPlayers, L.UI_REMOVE, 80, 22)
  remBtn:SetPoint("RIGHT", syncBtn, "LEFT", -6, 0)

  addBtn = MakeButton(pPlayers, L.UI_ADD, 80, 22)
  addBtn:SetPoint("RIGHT", remBtn, "LEFT", -6, 0)

  local nameLabel = pPlayers:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameLabel:SetText(L.UI_NAME)
  nameLabel:SetPoint("TOPLEFT", pPlayers, "TOPLEFT", 10, -14)

  nameBox = MakeEditBox(pPlayers, 160)
  nameBox:SetPoint("TOPLEFT", pPlayers, "TOPLEFT", 55, -10)
  nameBox:SetPoint("RIGHT", addBtn, "LEFT", -6, 0)
  nameBox:SetText("")
  -- no reason box in UI

  local list = CreateScrollList(pPlayers, {
    {key="name", title=L.UI_NAME, width=170},
    {key="type", title=L.UI_TYPE, width=70},
        {key="lastSeen", title=L.UI_LAST_SEEN, width=130},
    {key="zone", title=L.UI_ZONE, width=150},
  })
  list:SetPoint("TOPLEFT", 0, -42)
  list:SetPoint("BOTTOMRIGHT", 0, 0)

  pPlayers._list = list
  pPlayers._selected = nil
  list.onSelect = function(k)
    pPlayers._selected = k
    local e = DB:GetData().players[k]
    if e and e.name then nameBox:SetText(e.name) end
  end

  addBtn:SetScript("OnClick", function()
    local name = (nameBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
      -- If nothing typed, add current target (player only)
      if UnitExists("target") and UnitIsPlayer("target") then
        local tName = UnitName("target")
        if tName and tName ~= "" then
          name = tName
          nameBox:SetText(name)
        end
      end
    end
    if name == "" then return end
    if ((DB.HasPlayer and DB:HasPlayer(name)) or (DB.LookupPlayer and DB:LookupPlayer(name) ~= nil) or false) then UpdateAddState(); return end
    DB:AddPlayer(name, L.KOS, nil, UnitName("player"))
    nameBox:SetText("")
    GUI:RefreshAll()
    UpdateAddState()
    UpdateAddState()
  end)

  remBtn:SetScript("OnClick", function()
    local key = pPlayers._selected or (pPlayers._list and pPlayers._list.selectedKey)
    local typed = nameBox:GetText()
    if key then
      local entry = DB:GetData().players[key]
      if entry then DB:RemovePlayer(entry.name) end
    elseif typed and typed ~= "" then
      DB:RemovePlayer(typed)
    end
    pPlayers._selected = nil
    if pPlayers._list then pPlayers._list.selectedKey = nil end
    nameBox:SetText("")
    GUI:RefreshAll()
    UpdateAddState()
    UpdateAddState()
  end)

  syncBtn:SetScript("OnClick", function()
    KillOnSight_Sync:Hello()
    KillOnSight_Sync:RequestDiff()
  end)

  -- guilds panel
  local pGuilds = CreateFrame("Frame", nil, frame)
  pGuilds:SetAllPoints(frame)
  pGuilds:SetPoint("TOPLEFT", 12, -42)
  pGuilds:SetPoint("BOTTOMRIGHT", -12, 12)
  pGuilds:Hide()
  frame.tabPanels[2] = pGuilds

  local gSyncBtn = MakeButton(pGuilds, L.UI_SYNC, 90, 22)
  gSyncBtn:SetPoint("TOPRIGHT", pGuilds, "TOPRIGHT", -10, -10)

  local gRemBtn = MakeButton(pGuilds, L.UI_REMOVE, 80, 22)
  gRemBtn:SetPoint("RIGHT", gSyncBtn, "LEFT", -6, 0)

  local gAddBtn = MakeButton(pGuilds, L.UI_ADD, 80, 22)
  gAddBtn:SetPoint("RIGHT", gRemBtn, "LEFT", -6, 0)

  local guildLabel = pGuilds:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  guildLabel:SetText(L.UI_GUILD)
  guildLabel:SetPoint("TOPLEFT", pGuilds, "TOPLEFT", 10, -14)

  guildBox = MakeEditBox(pGuilds, 200)
  guildBox:SetPoint("TOPLEFT", pGuilds, "TOPLEFT", 65, -10)
  guildBox:SetPoint("RIGHT", gAddBtn, "LEFT", -6, 0)
  -- no reason box in UI

  local gList = CreateScrollList(pGuilds, {
    {key="guild", title=L.UI_GUILD, width=220},
    {key="type", title=L.UI_TYPE, width=90},
        {key="lastSeen", title=L.UI_LAST_SEEN, width=130},
    {key="zone", title=L.UI_ZONE, width=150},
  })
  gList:SetPoint("TOPLEFT", 0, -42)
  gList:SetPoint("BOTTOMRIGHT", 0, 0)
  pGuilds._list = gList
  pGuilds._selected = nil
  gList.onSelect = function(k)
    pGuilds._selected = k
    local e = DB:GetData().guilds[k]
    if e and e.guild then guildBox:SetText(e.guild) end
  end

  gAddBtn:SetScript("OnClick", function()
    DB:AddGuild(guildBox:GetText(), L.GUILD_KOS, nil, UnitName("player"))
    guildBox:SetText("")
    GUI:RefreshAll()
  end)

  gRemBtn:SetScript("OnClick", function()
    local key = pGuilds._selected or (pGuilds._list and pGuilds._list.selectedKey)
    local typed = guildBox:GetText()
    if key then
      local entry = DB:GetData().guilds[key]
      if entry then DB:RemoveGuild(entry.guild) end
    elseif typed and typed ~= "" then
      DB:RemoveGuild(typed)
    end
    pGuilds._selected = nil
    if pGuilds._list then pGuilds._list.selectedKey = nil end
    guildBox:SetText("")
    GUI:RefreshAll()
  end)

  gSyncBtn:SetScript("OnClick", function()
    KillOnSight_Sync:Hello()
    KillOnSight_Sync:RequestDiff()
  end)

  -- last seen panel
  local pSeen = CreateFrame("Frame", nil, frame)
  pSeen:SetAllPoints(frame)
  pSeen:SetPoint("TOPLEFT", 12, -42)
  pSeen:SetPoint("BOTTOMRIGHT", -12, 12)
  pSeen:Hide()
    local seenList = CreateScrollList(pSeen, {
    {key="name", title=L.UI_NAME, width=220},
    {key="type", title=L.UI_TYPE, width=90},
    {key="lastSeen", title=L.UI_LAST_SEEN, width=150},
    {key="zone", title=L.UI_ZONE, width=160},
      })
  seenList:SetPoint("TOPLEFT", 0, -10)
  seenList:SetPoint("BOTTOMRIGHT", 0, 0)
  pSeen._list = seenList

  -- last attackers panel
  local pAtk = CreateFrame("Frame", nil, frame)
  pAtk:SetAllPoints(frame)
  pAtk:SetPoint("TOPLEFT", 12, -42)
  pAtk:SetPoint("BOTTOMRIGHT", -12, 12)
  pAtk:Hide()
  frame.tabPanels[3] = pAtk
  local atkList = CreateScrollList(pAtk, {
    {key="name", title=L.UI_NAME, width=260},
    {key="guild", title=L.UI_GUILD, width=170},
    {key="zone", title=L.UI_ZONE, width=220},
  })
  -- Top action bar (keeps buttons accessible even when the list is long)
  local atkBar = CreateFrame("Frame", nil, pAtk)
  atkBar:SetPoint("TOPLEFT", 0, 0)
  atkBar:SetPoint("TOPRIGHT", 0, 0)
  atkBar:SetHeight(28)

  -- List sits below the bar
  atkList:SetPoint("TOPLEFT", 0, -34)
  atkList:SetPoint("BOTTOMRIGHT", 0, 0)
  pAtk._list = atkList

  local btnClearAtk = MakeButton(atkBar, L.UI_CLEAR, 80, 22)
  btnClearAtk:SetPoint("TOPRIGHT", -10, -3)
  btnClearAtk:SetScript("OnClick", function()
    DB:ClearLastAttackers()
    GUI:RefreshAll()
  end)

  local btnAddAtk = MakeButton(atkBar, L.UI_ADD_KOS, 90, 22)
  btnAddAtk:SetPoint("RIGHT", btnClearAtk, "LEFT", -6, 0)
  btnAddAtk:SetScript("OnClick", function()
    local key = atkList.selectedKey
    if not key or key == "" then return end
    local list = DB:GetLastAttackers()
    local name
    for _,e in ipairs(list) do
      if e.name and e.name:lower() == key then name = e.name break end
    end
    if not name or name == "" then return end
    if DB:HasPlayer(name) then return end
    DB:AddPlayer(name, L.KOS, nil, UnitName("player"))
    GUI:RefreshAll()
  end)


  local btnAddGuildAtk = MakeButton(atkBar, (L.UI_ADD_GUILD or "Add Guild"), 90, 22)
  btnAddGuildAtk:SetPoint("RIGHT", btnAddAtk, "LEFT", -6, 0)
  btnAddGuildAtk:SetScript("OnClick", function()
    local key = atkList.selectedKey
    if not key or key == "" then return end
    local list = DB:GetLastAttackers()
    local guild
    for _,e in ipairs(list) do
      if e.name and e.name:lower() == key then
        guild = e.guild
        break
      end
    end
    if not guild or guild == "" then return end
    if DB:HasGuild(guild) then return end
    DB:AddGuild(guild, L.GUILD_KOS, nil, UnitName("player"))
    GUI:RefreshAll()
  end)

  -- options panel
  local pOpt = CreateFrame("Frame", nil, frame)
  pOpt:SetAllPoints(frame)
  pOpt:SetPoint("TOPLEFT", 12, -42)
  pOpt:SetPoint("BOTTOMRIGHT", -12, 12)
  pOpt:Hide()
  frame.tabPanels[4] = pOpt
  local prof = DB:GetProfile()

  local cSound = MakeCheck(pOpt, L.UI_SOUND)
  cSound:SetPoint("TOPLEFT", 20, -20)
  cSound:SetChecked(prof.enableSound)

  local cFlash = MakeCheck(pOpt, L.UI_FLASH)
  cFlash:SetPoint("TOPLEFT", 20, -48)
  cFlash:SetChecked(prof.enableScreenFlash)

  local cInst = MakeCheck(pOpt, L.UI_INSTANCES)
  cInst:SetPoint("TOPLEFT", 20, -76)
  cInst:SetChecked(prof.notifyInInstances)

-- Nearby window options
local cNearby = MakeCheck(pOpt, L.UI_NEARBY_FRAME)
cNearby:SetPoint("TOPLEFT", cInst, "BOTTOMLEFT", 0, -12)
cNearby:SetChecked(prof.showNearbyFrame ~= false)
cNearby:SetScript("OnClick", function(self)
  prof.showNearbyFrame = self:GetChecked()
  if KillOnSight_Nearby and KillOnSight_Nearby.SetShown then
    KillOnSight_Nearby:SetShown(prof.showNearbyFrame)
  end
end)

local cNearbyLock = MakeCheck(pOpt, L.UI_NEARBY_LOCK)
cNearbyLock:SetPoint("TOPLEFT", cNearby, "BOTTOMLEFT", 0, -6)
cNearbyLock:SetChecked(prof.nearbyLocked == true)
cNearbyLock:SetScript("OnClick", function(self)
  prof.nearbyLocked = self:GetChecked()
  if KillOnSight_Nearby and KillOnSight_Nearby.ApplyLocked then
    KillOnSight_Nearby:ApplyLocked()
  end
end)


local cAutoHide = MakeCheck(pOpt, L.UI_NEARBY_AUTOHIDE)
cAutoHide:SetPoint("TOPLEFT", cNearbyLock, "BOTTOMLEFT", 0, -10)
cAutoHide:SetChecked(prof.nearbyAutoHide ~= false)
cAutoHide:SetScript("OnClick", function(self)
  prof.nearbyAutoHide = self:GetChecked()
  if KillOnSight_Nearby and KillOnSight_Nearby.Refresh then
    KillOnSight_Nearby:Refresh()
  end
end)


-- Nearby window scale
local sNearbyScale = CreateFrame("Slider", "KillOnSightNearbyScaleSlider", pOpt, "OptionsSliderTemplate")
sNearbyScale:SetPoint("TOPLEFT", cAutoHide, "BOTTOMLEFT", 0, -18)
sNearbyScale:SetMinMaxValues(0.60, 1.60)
sNearbyScale:SetValueStep(0.05)
sNearbyScale:SetObeyStepOnDrag(true)
_G[sNearbyScale:GetName().."Text"]:SetText(L.UI_NEARBY_SCALE)
_G[sNearbyScale:GetName().."Low"]:SetText("0.6")
_G[sNearbyScale:GetName().."High"]:SetText("1.6")

prof.nearbyFrame = prof.nearbyFrame or {}
if type(prof.nearbyFrame.scale) ~= "number" then prof.nearbyFrame.scale = 1.0 end
sNearbyScale:SetValue(prof.nearbyFrame.scale)
_G[sNearbyScale:GetName().."Text"]:SetText(string.format("%s (%.2f)", (L.UI_NEARBY_SCALE or "Nearby window scale"), prof.nearbyFrame.scale))

sNearbyScale:SetScript("OnValueChanged", function(self, val)
  -- Clamp & round to step
  val = math.floor((val * 100) + 0.5) / 100
  prof.nearbyFrame = prof.nearbyFrame or {}
  prof.nearbyFrame.scale = val
  if KillOnSight_Nearby and KillOnSight_Nearby.ApplyPosition then
    KillOnSight_Nearby:ApplyPosition()
  elseif KillOnSight_Nearby and KillOnSight_Nearby.frame and KillOnSight_Nearby.frame.SetScale then
    KillOnSight_Nearby.frame:SetScale(val)
  end
  _G[self:GetName().."Text"]:SetText(string.format("%s (%.2f)", (L.UI_NEARBY_SCALE or "Nearby window scale"), val))
end)


-- Nearby window is always ultra-minimal (no toggle)
prof.nearbyMinimal = true
if KillOnSight_Nearby and KillOnSight_Nearby.ApplyMinimalMode then
  KillOnSight_Nearby:ApplyMinimalMode()
end


  local sThrottle = CreateFrame("Slider", "KillOnSightThrottleSlider", pOpt, "OptionsSliderTemplate")
  sThrottle:SetPoint("TOPLEFT", sNearbyScale, "BOTTOMLEFT", 0, -26)
  sThrottle:SetMinMaxValues(0, 60)
  sThrottle:SetValueStep(1)
  sThrottle:SetObeyStepOnDrag(true)
  sThrottle:SetWidth(200)
  _G[sThrottle:GetName().."Text"]:SetText(L.UI_THROTTLE)
  _G[sThrottle:GetName().."Low"]:SetText("0")
  _G[sThrottle:GetName().."High"]:SetText("60")
  sThrottle:SetValue(prof.throttleSeconds or 12)

  local sync2 = MakeButton(pOpt, L.UI_SYNC, 120, 22)
  sync2:SetPoint("TOPLEFT", sThrottle, "BOTTOMLEFT", 0, -26)
  sync2:SetScript("OnClick", function()
    KillOnSight_Sync:Hello()
    KillOnSight_Sync:RequestDiff()
  end)

  cSound:SetScript("OnClick", function(self) prof.enableSound = self:GetChecked() end)
  cFlash:SetScript("OnClick", function(self) prof.enableScreenFlash = self:GetChecked() end)
  cInst:SetScript("OnClick", function(self) prof.notifyInInstances = self:GetChecked() end)
  sThrottle:SetScript("OnValueChanged", function(self, v) prof.throttleSeconds = math.floor(v + 0.5) end)
-- Stealth detection options
local tStealth = pOpt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
tStealth:SetPoint("TOPLEFT", 320, -20)
tStealth:SetText(L.UI_STEALTH)

local cStealthEnable = MakeCheck(pOpt, L.UI_STEALTH_ENABLE)
cStealthEnable:SetPoint("TOPLEFT", tStealth, "BOTTOMLEFT", 0, -10)
cStealthEnable:SetChecked(prof.stealthDetectEnabled ~= false)
cStealthEnable:SetScript("OnClick", function(self)
  prof.stealthDetectEnabled = self:GetChecked()
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
end)

local cStealthSound = MakeCheck(pOpt, L.UI_STEALTH_SOUND)
cStealthSound:SetPoint("TOPLEFT", cStealthEnable, "BOTTOMLEFT", 0, -8)
cStealthSound:SetChecked(prof.stealthDetectSound ~= false)
cStealthSound:SetScript("OnClick", function(self)
  prof.stealthDetectSound = self:GetChecked()
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
end)

local cStealthBanner = MakeCheck(pOpt, L.UI_STEALTH_BANNER)
cStealthBanner:SetPoint("TOPLEFT", cStealthSound, "BOTTOMLEFT", 0, -8)
cStealthBanner:SetChecked(prof.stealthDetectCenterWarning ~= false)
cStealthBanner:SetScript("OnClick", function(self)
  prof.stealthDetectCenterWarning = self:GetChecked()
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
end)

local cStealthNearby = MakeCheck(pOpt, L.UI_STEALTH_ADD_NEARBY)
cStealthNearby:SetPoint("TOPLEFT", cStealthBanner, "BOTTOMLEFT", 0, -8)
cStealthNearby:SetChecked(prof.stealthDetectAddToNearby ~= false)
cStealthNearby:SetScript("OnClick", function(self)
  prof.stealthDetectAddToNearby = self:GetChecked()
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
end)

-- Banner timing
local tStealthTiming = pOpt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tStealthTiming:SetPoint("TOPLEFT", cStealthNearby, "BOTTOMLEFT", 0, -48)
tStealthTiming:SetText("|cffffff00Banner Timing|r")

local sStealthHold = MakeSlider(pOpt, L.UI_STEALTH_HOLD or "Banner hold (seconds)", 2, 12, 0.5)
sStealthHold:SetPoint("TOPLEFT", tStealthTiming, "BOTTOMLEFT", 0, -18)
sStealthHold:SetValue(prof.stealthWarningHoldSeconds or 6.0)

-- value label (keep the slider's built-in Text as the title)
local sStealthHoldValue = pOpt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sStealthHoldValue:SetPoint("LEFT", sStealthHold, "RIGHT", 10, 0)
sStealthHoldValue:SetText((prof.stealthWarningHoldSeconds or 6.0) .. "s")

local tStealthHoldHelp = pOpt:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
tStealthHoldHelp:SetPoint("TOPLEFT", sStealthHold, "BOTTOMLEFT", 0, -10)
tStealthHoldHelp:SetText("How long the warning stays fully visible before fading.")

sStealthHold:SetScript("OnValueChanged", function(self, v)
  v = math.floor(v * 10 + 0.5) / 10
  prof.stealthWarningHoldSeconds = v
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
  sStealthHoldValue:SetText(v .. "s")
end)


local sStealthFade = MakeSlider(pOpt, L.UI_STEALTH_FADE or "Banner fade (seconds)", 0.2, 3.0, 0.1)
sStealthFade:SetPoint("TOPLEFT", tStealthHoldHelp, "BOTTOMLEFT", 0, -30)
sStealthFade:SetValue(prof.stealthWarningFadeSeconds or 1.2)

local sStealthFadeValue = pOpt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sStealthFadeValue:SetPoint("LEFT", sStealthFade, "RIGHT", 10, 0)
sStealthFadeValue:SetText((prof.stealthWarningFadeSeconds or 1.2) .. "s")

local tStealthFadeHelp = pOpt:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
tStealthFadeHelp:SetPoint("TOPLEFT", sStealthFade, "BOTTOMLEFT", 0, -10)
tStealthFadeHelp:SetText("How long the warning takes to fade out smoothly.")

sStealthFade:SetScript("OnValueChanged", function(self, v)
  v = math.floor(v * 10 + 0.5) / 10
  prof.stealthWarningFadeSeconds = v
    if KillOnSight_Notifier and KillOnSight_Notifier.ApplyStealthSettings then KillOnSight_Notifier:ApplyStealthSettings() end
  sStealthFadeValue:SetText(v .. "s")
end)


  frame:ShowTab(1)

  -- store references for refresh
  frame._playersPanel = pPlayers
  frame._guildsPanel = pGuilds
  frame._seenPanel = pSeen
  frame._attackersPanel = pAtk
end

function GUI:RefreshAll()
  if not frame then return end
  if frame._playersPanel and frame._playersPanel._list then
    frame._playersPanel._list:SetData(BuildPlayers())
  end
  if frame._guildsPanel and frame._guildsPanel._list then
    frame._guildsPanel._list:SetData(BuildGuilds())
  end
  if frame._seenPanel and frame._seenPanel._list then
    frame._seenPanel._list:SetData(BuildLastSeen())
  end
  if frame._attackersPanel and frame._attackersPanel._list then
    frame._attackersPanel._list:SetData(BuildLastAttackers())
  end
end

function GUI:Show()
  self:Create()
  frame:Show()
  self:RefreshAll()
end

function GUI:Hide()
  if frame then frame:Hide() end
end

function GUI:Toggle()
  self:Create()
  if frame:IsShown() then self:Hide() else self:Show() end
end

KillOnSight_GUI = GUI
