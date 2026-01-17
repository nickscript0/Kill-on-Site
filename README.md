# KillOnSight

**KillOnSight** is a comprehensive PvP awareness and threat-detection addon for World of Warcraft, designed to provide early warnings, visual clarity, and reliable tracking of hostile players — without UI clutter or performance overhead.

It supports **Retail and all Classic-era clients** from a single unified codebase, with automatic fallbacks where client behavior differs.

---

## Core Feature Overview

KillOnSight combines **nearby detection**, **stealth awareness**, **KoS / Guild tracking**, **enemy statistics**, and **attacker history** into a single, clean interface.

---

## 🧭 Nearby Enemy Detection

- Real-time detection of hostile players in your vicinity
- Spy-style Nearby window with clean, minimal layout
- Automatically grows and shrinks based on active entries
- Sorted by **last seen**, newest activity always prioritized
- Class-colored names with optional KoS / Guild indicators
- Inline **stealth icon** when an enemy is detected via stealth
- Hidden/stealth icon clears immediately when the player becomes visible
- Inactive players dim/fade automatically
- Scrollable only when the list exceeds visible space
- **Automatically disabled and cleared in sanctuary/safe zones**

---

## ⚔️ Kill-on-Sight (KoS) & Guild Targets

- Mark individual players as **Kill-on-Sight**
- Mark entire guilds as **Guild KoS**
- KoS and Guild targets are visually distinguished in:
  - Nearby window
  - Target frames
- **Dragon icons** shown on target frames:
  - Silver for KoS
  - Gold for Guild KoS
- Automatic **Retail vs Classic target-frame fallback**
- Separate sound and visual alert handling for KoS vs Guild

---

## 🕵️ Stealth Detection

- Detects stealth-capable enemies using combat log analysis:
  - Rogue: Stealth, Vanish
  - Druid: Prowl
- Works even if the enemy was already present in the Nearby list
- Displays a **stealth icon inline** next to the enemy name
- Optional Spy-style center-screen warning banner
- Optional stealth detection sound
- Optional chat notification
- Stealth indicators clear instantly when the enemy becomes visible
- All stealth options apply **live** (no reload required)

---

## 🔔 Alerts & Notifications

- Center-screen alert banners (Spy-style)
- Configurable fade-in, hold, and fade-out timing
- Optional screen flash
- Optional chat notifications
- **Fully independent sound toggles** for:
  - KoS alerts
  - Guild KoS alerts
  - Nearby detection
  - Stealth detection

No sound options are coupled — disable exactly what you want.

---

## 📊 Enemy Statistics

- Persistent stats per enemy player:
  - Times seen
  - Wins / losses
  - Last seen timestamp
- Class information and colors reliably populated
- Old/legacy entries automatically cleaned up
- Efficient list rendering (virtualized rows for performance)

---

## 🗡️ Attackers Tracking

- Dedicated **Attackers** tab
- Only records players who **actually attacked you**
  - Damage events
  - Missed attacks
  - Hostile debuffs and CC
- Clean separation from Nearby detection
- Attackers list is not polluted by passive sightings

---

## 🧠 Smart Data Management

- **Pruning policy enabled by default**
- Prevents SavedVariables bloat
- Incremental, low-cost pruning
- Safe across upgrades
- Slash commands available:
  ```
  /kos prune on
  /kos prune off
  /kos prune now
  /kos prune status
  ```

---

## ⚙️ Configuration & UI

- In-game configuration panel
- Scrollable options UI (no overlap)
- Clear section headings:
  - KoS / Guild
  - Nearby
  - Stealth Detection
- Changes apply live where possible
- Minimap icon with tooltip and click support

---

## 🌍 Localization

KillOnSight includes **complete translations** for all supported locales.

Supported languages:
- English (enUS – base)
- German (deDE)
- French (frFR)
- Spanish (esES, esMX)
- Portuguese (ptBR)
- Russian (ruRU)
- Korean (koKR)
- Chinese (zhCN)
- Dutch (nlNL)
- Danish (daDK)

All locale files contain the full key set — no missing strings, no fallback errors.

---

## 🧩 Supported Game Versions

- Retail (Mainline)
- Classic Era / Anniversary
- Burning Crusade Classic
- Wrath of the Lich King Classic
- Mists of Pandaria Classic

One unified addon with automatic runtime fallbacks.

---

## ⚙️ Slash Commands

```
/kos            – Open main UI
/kos add        – Add a player to KoS
/kos remove     – Remove a player from KoS
/kos clear      – Clear KoS list
/kos prune      – Pruning controls
/kos help       – Show full command list
```

---

## Performance & Safety

- No protected API calls
- Combat-safe logic
- Throttled detection paths
- No excessive OnUpdate usage
- Final release sanity sweep completed for 3.0.2

---

KillOnSight is built for players who want **accurate PvP awareness without noise**, and who value **clarity, reliability, and performance** across all WoW clients.

