# Kill on Sight: Midnight — Fork Notes

## Ping on Click (Nearby List)

Left-clicking a player name in the Nearby list now **targets the player and pings the minimap** at your location, drawing attention to the targeted enemy.

On Retail (10.2.5+), you can also **hold the Ping key (default: G) and click** a player name to send an in-game ping on that unit, visible to your party or raid members. This requires the enemy to have an active nameplate or unit token.

Both behaviors are controlled by the **"Ping on click"** toggle in the Options tab under the Nearby section. Enabled by default.

## Installing the Midnight Addon (macOS)

Copy the addon folder to WoW's Retail AddOns directory using `rsync`:

```sh
rsync -av --delete KillOnSight-midnight/ "/Applications/World of Warcraft/_retail_/Interface/AddOns/KillOnSight/"
```
