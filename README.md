# KillOnSight

**KillOnSight** is a lightweight, real-time player awareness addon for World of Warcraft.  
It helps you identify hostile, Kill-on-Sight (KoS), guild-marked, and stealthed players nearby with clear visual and audio alerts — without cluttering your UI.

Designed for PvP awareness, Classic and Retail compatible, and optimized for performance and readability.

---

## Core Features

### 🧭 Nearby Player Window
- Displays players detected near you in real time
- Automatically grows and shrinks to fit the number of players in the list
- Clean, minimal layout with readable names and spacing
- Class-colored player names
- KoS and Guild tags clearly marked
- Inactive players fade/dim automatically
- No countdown clutter — focused on presence, not noise
- Scrolls only when the list exceeds the visible limit

---

### ⚔️ Kill-on-Sight & Guild Tracking
- Mark players as **KoS** or **Guild KoS**
- KoS and Guild entries are visually distinguished in the Nearby window
- Separate sound handling for KoS/Guild vs general nearby detection
- Optional sound alerts per category

---

### 🕵️ Stealth Detection
- Detects players entering stealth near you (e.g. *Stealth*, *Prowl*)
- Optional center-screen warning banner
- Optional stealth detection sound
- Optional addition of stealthed players to the Nearby list
- Fully configurable timing (banner hold & fade)
- All stealth options apply **live** — no `/reload` required

---

### 🔔 Alerts & Notifications
- Center-screen banner warnings (Spy-style)
- Smooth fade in/out timing
- Optional screen flash
- Chat notifications (optional)
- Sounds can be enabled/disabled independently for:
  - KoS
  - Guild
  - Nearby
  - Stealth detection

---

### ⚙️ Configuration
- In-game options panel
- Live-updating settings (most changes take effect immediately)
- Separate sections for:
  - KoS & Guild options
  - Nearby window options
  - Stealth detection options
- Minimal mode and auto-hide support for the Nearby window

---

### 🧠 Smart & Safe
- Combat-safe (no protected calls during combat)
- Efficient refresh logic (no excessive OnUpdate spam)
- Clean row recycling to prevent UI artifacts
- SavedVariables handled safely (written on reload/logout as per WoW behavior)

---

## Who This Addon Is For
- PvP players who want **situational awareness without clutter**
- Players who liked **Spy**, but want a more minimal, customizable approach
- Anyone who wants clear stealth alerts without spam

---

## Installation
https://www.curseforge.com/wow/addons/kill-on-sight
---

### 🌍 Language Support

KillOnSight now includes built-in localization support and will automatically display text in your game client’s language when available.

**Supported languages:**
- 🇺🇸 English (enUS – fallback)
- 🇧🇷 Portuguese (ptBR)
- 🇷🇺 Russian (ruRU)
- 🇨🇳 Mandarin Chinese (zhCN)
- 🇪🇸 Spanish (esES / esMX)
- 🇫🇷 French (frFR)
- 🇩🇪 German (deDE)
- 🇰🇷 Korean (koKR)
- 🇳🇱 Dutch (nlNL)
- 🇩🇰 Danish (daDK)

If a translation is missing or incomplete, the addon safely falls back to English — no errors, no broken UI.

Localization is applied consistently across:
- Nearby window labels
- Context menus
- Slash command output
- Alerts and notifications
- Minimap tooltips and options

