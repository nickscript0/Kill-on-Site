# KillOnSight VanasKoS Importer

This tool allows you to **import explicit Kill-On-Sight (KoS) entries from VanasKoS**
into **KillOnSight**, even though VanasKoS is no longer maintained.

The importer works **offline** (make sure game is closed before running or will not work), reads SavedVariables directly, and is **100% safe**:
it will never delete or overwrite existing KillOnSight data.

---

## ✅ What this tool does

- Imports **explicit KoS entries only** from `VanasKoS.lua`
- Adds them into `KillOnSight.lua`
- Imports **class, guild, and reason** fields when present
- **Add-only import** (no deletes, no overwrites)
- Creates **automatic backups** before modifying anything

VanasKoS does **NOT** need to load in-game.

---

## ❌ What this tool does NOT do

- ❌ Does NOT import seen-player / DataGatherer data
- ❌ Does NOT delete any KillOnSight entries
- ❌ Does NOT overwrite existing KoS data
- ❌ Does NOT modify `VanasKoS.lua`
- ❌ Does NOT run inside World of Warcraft

---

## 📂 Requirements

- Windows
- World of Warcraft installed
- Existing SavedVariables files:
  - `VanasKoS.lua`
  - `KillOnSight.lua`

These are normally found here:

```
World of Warcraft
 └─ _classic_
    └─ WTF
       └─ Account
          └─ <YourAccountName>
             └─ SavedVariables
```
- Will depend on game version _classic_ or  _classic_era_ or _anniversary_ or _retail_
---

## ▶ How to use the importer

### 1️⃣ Run the importer
Double-click:

```
KillOnSight VanasKoS Importer.exe
```

(No Python installation required)

---

### 2️⃣ Select your files
Click **Browse…** and select:

- `VanasKoS.lua`
- `KillOnSight.lua`

```
World of Warcraft
 └─ _classic_
    └─ WTF
       └─ Account
          └─ <YourAccountName>
             └─ SavedVariables
```

The file picker opens in your **World of Warcraft folder by default**.

---

### 3️⃣ Choose the realm key
Select the correct **KillOnSight realm key**, for example:

```
Nightslayer-Alliance
```

---

### 4️⃣ (Optional) Dry Run
Click **Dry Run** to preview:
- how many VanasKoS entries were found
- how many will be added
- how many already exist and will be skipped

No files are modified during Dry Run.

---

### 5️⃣ Import
Click **Import (Add Only)**.

Before any changes are made:
- **two backup copies** of `KillOnSight.lua` are created on your **Desktop**

Example:
```
KillOnSight.lua.bak
KillOnSight_2026-01-22_14-30-11.lua.bak
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
4. Rename it to:
   ```
   KillOnSight.lua
   ```

Nothing is ever lost.

---

## ℹ Notes 

- VanasKoS stores large amounts of **non-KoS data**
- This importer intentionally ignores everything except **explicit KoS lists**
- Imported entries are tagged with:
  ```
  addedBy = "VanasKoS Import"
  ```
  so you can always identify their origin

---

## ❤️ Credits

- **KillOnSight** — Milestorme  
- **VanasKoS** — original VanasKoS authors  

Importer created specifically for safe migration to Retail 12.0.x.

---

## ⚠ Disclaimer

This is an **offline utility**.
It is not affiliated with Blizzard Entertainment.
Use at your own discretion (automatic backups are created before any changes).

---

Happy hunting 👀
