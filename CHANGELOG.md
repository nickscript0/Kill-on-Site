# KillOnSight – Changelog

## 3.0.2
### Added
- Unified Retail + Classic target frame handling with automatic fallback.
- Sanctuary handling: Nearby list is cleared and disabled while in sanctuary areas.
- Inline stealth icon for Hidden enemies (clears on visibility).
- Independent sound toggles for KoS/Guild, Stealth, and Nearby.
- Full locale coverage across all supported languages (all keys present).

### Fixed
- Retail target frame dragon icons not displaying.
- Hidden state being lost during Nearby refreshes.
- Duplicate stealth icon rendering.
- Missing locale files referenced by Retail TOC.
- Stats entries missing class colors or showing seen = 0.
- Attackers list incorrectly populating without actual attacks.

### Changed
- Pruning policy enabled by default to prevent SavedVariables bloat.
- Options UI made scrollable with clearer section headings.

## 3.0.1
- Nearby: replace [Hidden] text with a compact stealth icon; icon clears automatically when the player becomes visible.
- Sounds: KoS/Guild, Stealth Detection, and Nearby list sounds are independent toggles.
- UI: Options panel is scrollable; headings added for KoS/Guild, Nearby, and Stealth Detection.
- Stats: improved class backfill and seen-count display; pruning policy enabled by default.
- Attackers: list only populates when an enemy actually attacks you.
- Maintenance: removed legacy/dead config keys from defaults and clean them from existing SavedVariables.

## 3.0.0
- Major update: multi-TOC Classic-era support; Stats and Attackers tabs; bounded sync changelog; performance and UI improvements.
