# KillOnSight – Changelog

## 3.0.6
### Fixed
- Deferred guild resolution (Spy-style): guild names now populate reliably for Nearby, Attackers, and Stats once the data becomes available (target/mouseover/nameplates)
- Attackers UI now refreshes automatically when guild info is enriched
- Fixed Nearby list click-to-target reliability, especially in battlegrounds (e.g. Alterac Valley).
  - Secure targeting attributes are now consistent and no longer desync during combat.
  - Clicking a player name now targets the correct unit reliably. Unless combat blocked

- Fixed KoS / Guild alert spam caused by repeated aura, combat log, and visibility updates.
  - KoS and Guild alerts (sound, screen flash, chat announce) now trigger **only once per player while they remain in the Nearby list**.
  - Alerts reset only after the player fully leaves the Nearby list and is seen again.
### Added
- **Notes** column on the KoS tab
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
