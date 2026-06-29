# Seamless Inventory Sort

> A G.A.M.M.A. RC3 quality-of-life patch — a companion to SortingPlus.

---

## What It Does

SortingPlus orders your inventory when it opens, but the engine drops an item at the **bottom** of the list whenever you modify or move it. This mod snaps the item back into its correct sorted row the instant it lands — seamlessly, with no flicker and without losing your scroll position.

### Fixed Actions

All of these previously caused the "jumps to the end" behaviour:

- Attaching / detaching weapon parts: scopes, holographic sights, suppressors, grenade launchers
- Unloading a magazine
- Repairing / upgrading / crafting / combining items
- Picking items up into your bag
- Moving items into or out of a stash, chest, corpse, or companion
- Buying / selling at a trader
- Marking an item **favorite or junk** — it now snaps to the top / bottom instantly, in place, instead of waiting for a reopen or doing a full-rebuild flicker

### Works in Every Inventory Window

| Window | Coverage |
|--------|----------|
| Inventory / Repair | Your bag |
| Loot / Stash / Container | Your side **and** the container side |
| Trade | Your sale bag **and** the trader's sale bag |

**Bulk transfer** (Ishmaeel's FastTransfer — sweeping items with `SHIFT` held) is handled specially: sorting is deferred while Shift is held and applied in a single pass on release, so bulk stashing stays fast.

---

## Extra Features

- **New-loot highlight** — items you just took from a container, stash or body get a colored background in your bag so you can see at a glance what you found. Cleared when you close the inventory. The color and intensity are configurable in MCM (cyan by default).
- **Looting Takes Time (Redux) compatibility** — looted bodies are left exactly in Looting Takes Time's reveal order rather than being re-sorted, matching how that mod is meant to look. Stashes and your own bag still sort normally. Optional "sort the body once after the reveal" mode in MCM.
- **Anti-oscillation guard** — items with an unstable sort key (e.g. a magazine while it is being bound) can make a container churn on every refresh; the guard detects this and briefly backs off so the list settles.

---

## Requirements

- **G.A.M.M.A. RC3** (or Anomaly) with:
  - **SortingPlus** by RavenAscendant — **GAMMA mod 110** — *required*
  - **Inventory Open Lag Reducer** by sea-ex — **GAMMA mod 464** — *optional, faster sort on large inventories*
  - **MCM (Mod Configuration Menu)** by RavenAscendant — *optional, for the settings menu*

> SortingPlus is the only hard requirement — its "kind" sort is what this mod keeps tidy. Mod 464 is purely a speed-up. If no in-place sort can run (SortingPlus inactive, or a window set to sort by size) the order is simply left untouched and items land at the end like vanilla — no rebuild, no flicker, no performance cost. Without MCM the mod uses its built-in defaults. All of these are included and enabled by default in G.A.M.M.A. RC3.

---

## Configuration (MCM)

Found under **Options → Mod Configuration Menu → Seamless Inventory Sort**, grouped into four pages:

| Page | Settings |
|------|----------|
| **General** | Master enable; re-sort on favorite/junk |
| **Looting Takes Time** | Defer while looting; sort body after reveal (off = keep LTT's order) |
| **New Loot Highlight** | Enable; color (R/G/B); intensity |
| **Performance** | Anti-oscillation guard; re-sorts before back-off; back-off time |

All settings apply live; no restart required.

---

## Installation

1. Place the `501- Seamless Inventory Sort` folder into your GAMMA RC3 mods directory:
   ```
   [Your GAMMA RC3 install]\mods\
   ```
2. Enable it in **Mod Organizer 2** (left panel).
3. **Load order does not matter.** The `zz_` prefix loads it after `ui_inventory.script`. Safe to add or remove mid-playthrough.

---

## How It Works *(for mod authors)*

SortingPlus places items by "kind" using an `rKind` row tracker. When the stock `*Mode_RefreshInventories` functions add an item incrementally, `FindFreeCell` sees the new item's `kind ~= rKind.last` and drops it at `row_end + 1` (the end).

This mod hooks `IMode_`, `LMode_`, and `TMode_RefreshInventories`. Immediately after the stock refresh — in the **same frame**, before the UI draws — it re-sorts the affected container so the item never renders at the end. This is what makes it seamless, including the holographic sight's two-stage weapon respawn.

The re-sort (`soft_resort`) does **not** rebuild the container. It **repositions** existing cells into their sorted slots via `UICellItem:Set`, reusing the sea-ex fast comparator when mod 464 is present and SortingPlus' own otherwise. Because nothing is added or removed there is no `Reset`/`Show(false)` blink, stacked-item children stay intact, and loot-box put/take callbacks are not re-fired. A position-aware fingerprint guards against redundant re-sorts.

**Favorite / junk** toggles change sort order without moving a cell, so the refresh hooks never see a change. SortingPlus signals them through `rax_icon_layers.refresh`, which this mod hooks to run the same `soft_resort` in place, replacing the stock full-rebuild.

**Trade is soft-only** — trade containers are never `Reinit`'d. A trade `Reinit` rebuilds from `ParseInventory(npc)`, which still holds basketed items and would re-add them to the sale bag (the classic duplicate / stuck-in-basket bug). Repositioning cannot do that.

**Looting Takes Time** is detected through its public `is_item_hidden`; while a looted body has hidden items (or always, per MCM) the body is left in LTT's order. **New-loot** items are detected by diffing the actor bag during loot, and painted via SortingPlus' `rax_persistent_highlight`.

---

## Compatibility

- Compatible with standard G.A.M.M.A. mods
- Works alongside Ishmaeel's FastTransfer (mod 124), Looting Takes Time (Redux), and Mags Redux
- Modifies **no existing files** — only new scripts
- Safe to add or remove mid-playthrough

---

## Credits

| Mod | Author |
|-----|--------|
| SortingPlus / MCM | RavenAscendant |
| Inventory Open Lag Reducer | sea-ex |
| FastTransfer | Ishmaeel (Nitpicker's Modpack) |
| Looting Takes Time (Redux) | its respective author |
| G.A.M.M.A. UI | Tronex |
| G.A.M.M.A. RC3 | Grok and the G.A.M.M.A. team |
