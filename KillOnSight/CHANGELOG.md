# KillOnSight – Changelog

## 3.0.8 (Classic / TBC Anniversary)

### Sync
- Reworked guild sync to be **safe and non-destructive**.
- Removed all reset and delete behavior — sync now **only merges additions and updates**.
- Restricted sync traffic to the **GUILD channel only**.
- Added clear chat feedback when a sync completes, including how many entries were merged or ignored.

### Data & Persistence
- KoS entries now persist **realm suffix** and **guild** when available.
- Existing entries are **automatically enriched** with realm/guild data when players are encountered again.
- No breaking changes to existing SavedVariables.

### Stability
- Improved safety around cross-realm data handling.
- Hardened sync logic against malformed or unexpected messages.

---

## Version 3.0.7 


### 🛡️ Notification & Zone Rules
- **Sanctuary zones now fully respected**
  - KoS and Guild notifications no longer fire in sanctuaries
- **Booty Bay & Gadgetzan suppression enforced everywhere**
  - Notification rules now apply consistently across all detection paths
- **Booty Bay / Gadgetzan option hidden on Retail**
  - Option remains available for Classic / TBC where applicable


### 🎨 UI & Layout Improvements
- **Options UI width increased by 15%**
  - Improves readability for verbose locales (notably German)
- **Stealth Detection options spacing adjusted**
  - Moved ~6% further from KoS/Guild & Nearby sections for clarity
- Layout spacing preserved when Retail-only options are hidden

### 🔧 Stability & Compatibility
- Updated embedded libraries where required to avoid BugSack/BugGrabber dependency issues
- Ensured Retail changes do **not** affect:
  - Classic
  - TBC
  - Wrath
- No functional regressions on non-Retail clients

---

### Notes
Retail behavior intentionally differs from Classic-era clients due to Blizzard API changes in Patch 12.0. Nearby detection on Retail requires **enemy nameplates enabled** for full functionality.


## 3.0.6
### Fixed
- Deferred guild resolution (Spy-style): guild names now populate reliably for Nearby, Attackers, and Stats once the data becomes available (target/mouseover/nameplates)
- Attackers UI now refreshes automatically when guild info is enriched
- Fixed Nearby list click-to-target reliability, especially in battlegrounds (e.g. Alterac Valley).
  - Secure targeting attributes are now consistent and no longer desync during combat.
  - Clicking a player name now targets the correct unit reliably.

- Fixed KoS / Guild alert spam caused by repeated aura, combat log, and visibility updates.
  - KoS and Guild alerts (sound, screen flash, chat announce) now trigger **only once per player while they remain in the Nearby list**.
  - Alerts reset only after the player fully leaves the Nearby list and is seen again.
### Added
- Optional **Notes** column on the KoS tab
  - Clickable note icon per entry (dimmed when empty)
  - Mouseover shows full note text in a wrapped, scrollable tooltip
  - Click opens a small editor to create/edit/clear notes
  - Notes are stored as `reason` in SavedVariables (Spy imports show here automatically)

### Changed
- `/kos importspy` now refreshes the KoS list immediately
- `/kos importspy` prints a message even when no new entries are found

### Notes
- Notes are metadata only and do not change KoS/Guild detection

---

## 3.0.5
### Added
- Added **Spy KoS import support**
  - New slash command: `/kos importspy`
  - Imports Kill-on-Sight entries from Spy’s SavedVariables
  - Automatically skips entries already present in KillOnSight
  - Safe to disable Spy after import
- Imported metadata (such as Spy “reason”) is stored safely and ignored by core KoS logic

### Notes
- Spy must be enabled and loaded at least once before importing
- No changes to KillOnSight KoS/Guild detection or behavior

---

## 3.0.4
### Fixed
- NPC **rare, rare elite, elite, and world boss** targets now always display their dragon indicators
- Corrected client detection so Classic-era clients use proper target-frame handling
- Ensured Retail and Classic use appropriate visual paths without conflict

### Notes
- Player KoS and Guild behavior is unchanged
- This fix applies across Retail, Classic Era, TBC Anniversary, Wrath, and Titan-Reforged

---

## 3.0.3
### Added
- Full localization support for all major languages
- Shortened tooltip strings to prevent overflow on non-English clients
- Added TOC localization metadata

### Fixed
- Retail fallback handling for target frames
- Minor UI consistency issues across versions

---

## 3.0.2
### Fixed
- Cross-version targeting fallback logic
- Sanctuary zone handling for Nearby list
- Stability and performance improvements

---

## 3.0.1
### Added
- Retail target-frame support with safe fallbacks
- Improved stealth detection handling
- Performance optimizations and throttling improvements
