-- Locale/enUS.lua
local ADDON_NAME = ...
KillOnSight_L = KillOnSight_L or {}
local L = KillOnSight_L

L.ADDON_PREFIX = "KILLONSIGHT"

-- list types
L.KOS = "KoS"
L.GUILD_KOS = "Guild-KoS"

L.HIDDEN = "Hidden"
L.SEEN_HIDDEN = "Hidden detected: %s"

-- commands
L.CMD_HELP = "Commands: /kos help | show | add [name] | remove <name> | addguild <guild> | removeguild <guild> | list | sync"
L.ADDED_PLAYER = "Added player to %s: %s"
L.REMOVED_PLAYER = "Removed player: %s"
L.ADDED_GUILD = "Added guild to %s: %s"
L.REMOVED_GUILD = "Removed guild: %s"
L.NOT_FOUND = "Not found: %s"

-- notifications
L.SEEN = "%s spotted nearby: %s%s"
L.SEEN_GUILD = "%s guild spotted nearby: %s (%s)%s"
L.ACTIVITY = "%s nearby: %s (%s)%s"

-- sync
L.SYNC_SENT = "Sync request sent."
L.SYNC_RECEIVED = "Received sync data from %s."
L.SYNC_DONE = "Sync complete."
L.SYNC_DISABLED = "Sync requires being in a group, party/raid, or guild."
L.SYNC_COOLDOWN = "Sync is on cooldown: %ds remaining."

-- UI
L.UI_TITLE = "Kill on Sight"
L.UI_TAB_PLAYERS = "Players"
L.UI_TAB_GUILDS = "Guilds"
L.UI_TAB_ATTACKERS = "Attackers"
L.UI_OPTIONS = "Options"

L.UI_ADD = "Add"
L.UI_REMOVE = "Remove"
L.UI_NAME = "Name"
L.UI_GUILD = "Guild"
L.UI_TYPE = "Type"
L.UI_ZONE = "Zone"
L.UI_LAST_SEEN = "Last seen"
L.UI_SYNC = "Sync Now"
L.UI_SOUND = "Sound"
L.UI_FLASH = "Flash"
L.UI_ALERT_NEW = "Alert on new nearby enemy"
L.UI_INSTANCES = "Notify in instances"
L.UI_STEALTH = "Stealth Detection"
L.UI_STEALTH_ENABLE = "Enable stealth detection"
L.UI_STEALTH_SOUND = "Play stealth sound"
L.UI_STEALTH_BANNER = "Show center warning banner"
L.UI_STEALTH_ADD_NEARBY = "Add hidden to Nearby list"
L.UI_STEALTH_HOLD = "Banner hold (seconds)"
L.UI_STEALTH_FADE = "Banner fade (seconds)"
L.UI_THROTTLE = "Throttle (sec)"
L.UI_ATTACKED_AT = "Attacked"
L.UI_CLEAR = "Clear"
L.UI_ADD_KOS = "Add KoS"

L.UI_NEARBY_FRAME = "Nearby window"
L.UI_NEARBY_LOCK = "Lock nearby window"
L.UI_NEARBY_ALPHA = "Nearby transparency"
L.UI_NEARBY_AUTOHIDE = "Auto-hide when empty"
UI_NEARBY_SCALE = "Nearby window scale"
L.UI_NEARBY_FADE = "Fade in/out"
L.UI_NEARBY_MINIMAL = "Ultra-minimal nearby window"
L.UI_NEARBY_ROWICONS = "Row icons (class/skull)"
L.UI_NEARBY_ROWFADE = "Per-row fade timers"

L.UI_CLOSE = "Close"


-- Added for full localization pass (Retail)
L.CHAT_PLAYERS = "Players: "
L.CHAT_GUILDS = "Guilds: "
L.CHAT_LOADED = "Loaded. Type /kos show"
L.MM_ADD_TARGET = "Add KoS (target)"
L.MM_NO_TARGET = "No player targeted."
L.MM_REMOVE_KOS = "Remove KoS"
L.MM_CLEAR_NEARBY = "Clear Nearby List"
L.UI_HEADER_NLT = "Name / Level / Time"
L.UI_NEARBY_COUNT = "Nearby: %d"
L.UI_NEARBY_ZERO = "Nearby: 0"
L.TOOLTIP_LEVEL = "Level %s"
L.TOOLTIP_ON_KOS = "On KoS list"
L.SYNC_APPLIED = "Applied %d changes."
L.HELP_BANNER_HOLD = "How long the warning stays fully visible before fading."
L.HELP_BANNER_FADE = "How long the warning takes to fade out smoothly."

L.TOOLTIP_LEFTCLICK = "Left-click: Open/Close"
L.TOOLTIP_RIGHTCLICK = "Right-click: Menu"
