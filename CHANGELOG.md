# KillOnSight – Changelog

## 3.0.6
### Added
- **KoS Notes system**
  - New Notes column on the KoS tab
  - Clickable note icon per KoS entry
  - Hover tooltip shows full note text (wrapped and scrollable)
  - Click to add, edit, or clear notes
  - Notes stored as metadata and do not affect KoS detection
- **Spy import improvements**
  - Imported Spy reasons populate KoS Notes automatically
  - KoS list refreshes immediately after `/kos importspy`
  - Clear chat message when no new KoS entries are imported

### Fixed
- UI layout refinements for KoS table (Notes column placement and width)
- Localization coverage for Notes header across all supported languages

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
