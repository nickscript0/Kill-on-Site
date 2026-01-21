# KillOnSight Spy Importer for Midnight (Retail 12.0.x)

This tool allows you to **import your Kill-On-Sight (KoS) list from Spy** into **KillOnSight**, even though Spy no longer loads on Retail 12.0.x (Midnight).

It works **offline**, reads Spy’s SavedVariables directly, and **never deletes or overwrites** existing KillOnSight entries.

---

## ✅ What this tool does

- Imports **KoS player entries** from `Spy.lua`
- Adds them into `KillOnSight.lua`
- Imports **reason text** if Spy has one
- **Add-only** import (no deletes, no overwrites)
- Creates **automatic backups** before making any changes

Spy **does NOT** need to be enabled or load in-game.

---

## ❌ What this tool does NOT do

- ❌ Does NOT delete any KillOnSight entries
- ❌ Does NOT overwrite existing KoS data
- ❌ Does NOT modify `Spy.lua`
- ❌ Does NOT run inside World of Warcraft
- ❌ Does NOT require Spy to load on 12.0.x

---

## 📂 Requirements

- Windows
- World of Warcraft installed
- Existing SavedVariables files:
  - `Spy.lua`
  - `KillOnSight.lua`

These are normally found here:

```
World of Warcraft
 └─ _retail_
    └─ WTF
       └─ Account
          └─ <YourAccountName>
             └─ SavedVariables

```
## ▶ Download here - [KillOnSight-Spy-Importer.zip](https://github.com/milestorme/Kill-on-Site/releases/download/release/KillOnSight-Spy-Importer.zip)
---

## How to use the importer

### 1️⃣ Run the importer
Double-click:

```
KillOnSight Spy Importer.exe
```

*(If using the `.py` version, run it with Python 3)*

---

### 2️⃣ Select your files
Click **Browse…** and select:

- `Spy.lua`
- `KillOnSight.lua`
```
World of Warcraft
 └─ _retail_
    └─ WTF
       └─ Account
          └─ <YourAccountName>
             └─ SavedVariables

```
---

### 3️⃣ Choose the realm key
Select the correct **KillOnSight realm key** from the dropdown, for example:

```
Frostmourne-Alliance
```

---

### 4️⃣ (Optional) Dry Run
Click **Dry Run** to preview:
- how many Spy entries were found
- how many will be added
- how many already exist and will be skipped

No files are modified during a Dry Run.

---

### 5️⃣ Import
Click **Import (Add Only)**.

Before any changes are made:
- **two backup copies** of `KillOnSight.lua` are created on your **Desktop**

Example:
```
KillOnSight.lua.bak
KillOnSight_2026-01-21_19-44-02.lua.bak
```

The import then runs safely.

---

## 🔒 Safety & Recovery

If anything ever goes wrong:

1. Close World of Warcraft
2. Copy one of the backup files from your Desktop
3. Paste it back into:
   ```
   WTF\Account\<AccountName>\SavedVariables
   ```
4. Rename it back to:
   ```
   KillOnSight.lua
   ```

Nothing is ever lost.

---

## ℹ Notes for Retail 12.0.x (Midnight)

- Spy no longer loads due to Blizzard API restrictions
- This tool exists to **preserve your historical KoS data**
- Imported entries are tagged with:
  ```
  addedBy = "Spy Import"
  ```
  so you can identify their source

---

## ❤️ Credits

- **KillOnSight** — Milestorme  
- **Spy** — original Spy authors  

Importer tool created specifically for Retail 12.0.x migration.

---

## ⚠ Disclaimer

This is an **offline utility**.
It is not affiliated with Blizzard Entertainment.
Use at your own discretion (automatic backups are created before any changes).

---

Happy hunting 👀
