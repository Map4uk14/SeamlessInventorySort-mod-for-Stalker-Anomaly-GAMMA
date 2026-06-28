# Seamless Inventory Sort

> A G.A.M.M.A. RC3 quality-of-life patch

---

## What It Does

When you modify or move an item, the engine appends it to the **bottom** of the list instead of keeping it in its correct sorted row. This mod snaps the item back to its proper sorted position the instant it lands — seamlessly, with no flicker and without losing your scroll position.

### Fixed Actions

All of these previously caused the "jumps to the end" behaviour:

- Attaching / detaching weapon parts: scopes, holographic sights, suppressors, grenade launchers
- Unloading a magazine
- Repairing / upgrading / crafting / combining items
- Picking items up into your bag
- Moving items into or out of a stash, chest, corpse, or companion
- Buying / selling at a trader

It also fixes **marking an item favorite or junk** (SortingPlus' `K` / `J` keys or the right-click menu): the item now snaps to the top (favorite) or bottom (junk) instantly, in place — previously it stayed put until you reopened the window, or did a full-rebuild flicker.

### Works in Every Inventory Window

| Window | Coverage |
|--------|----------|
| Inventory / Repair | Your bag |
| Loot / Stash / Container | Your side **and** the container side |
| Trade | Your sale bag **and** the trader's sale bag |

**Bulk transfer** (Ishmaeel's FastTransfer — sweeping items with `SHIFT` held) is handled specially: sorting is frozen while you hold Shift and applied in a single pass when you release it, so bulk stashing stays fast.

---

## Requirements

- **G.A.M.M.A. RC3** (or Anomaly) with:
  - [SortingPlus](https://github.com/RavenAscendant) by RavenAscendant — **GAMMA mod 110** *(required)*
  - Inventory Open Lag Reducer by sea-ex — **GAMMA mod 464** *(optional, recommended)*

> SortingPlus is the only hard requirement — its "kind" sort is what this mod keeps tidy. Mod 464 is purely a speed-up: when present, its faster precomputed sort is used; when absent, SortingPlus' own comparator is used instead — either way the re-sort is seamless and in place. If neither can run (SortingPlus inactive, or a window set to sort by size), the order is simply left untouched and items land at the end like vanilla — no rebuild, no flicker, no performance cost. Both 110 and 464 are included and enabled by default in G.A.M.M.A. RC3.

---

## Installation

1. Place the `501- Seamless Inventory Sort` folder into your GAMMA RC3 mods directory:
   ```
   [Your GAMMA RC3 install]\mods\
   ```
2. Enable it in **Mod Organizer 2** (left panel).
3. **Load order does not matter.** The script uses the `zz_` prefix so it loads after `ui_inventory.script`. Safe to add or remove mid-playthrough.

---

## How It Works *(for mod authors)*

SortingPlus places items by "kind" using an `rKind` row tracker. When the stock `*Mode_RefreshInventories` functions add an item incrementally, `FindFreeCell` sees the new item's `kind != rKind.last` and drops it at `row_end + 1` (the end).

This mod hooks `IMode_`, `LMode_`, and `TMode_RefreshInventories`. Right after the stock refresh runs — in the **same frame**, before the UI draws — it re-sorts the affected container so the item never renders at the end. This is what makes it seamless, including the holographic sight's two-stage weapon respawn.

The re-sort (`soft_resort`) does **not** rebuild the container. It **repositions** existing cells into their sorted slots via `UICellItem:Set(area)`, reusing the sea-ex fast comparator when mod 464 is present and SortingPlus' own comparator otherwise. Because nothing is added or removed:

- There is no `Reset()`/`Show(false)` blink, even on huge stashes
- Stacked-item children are left intact
- Loot-box put/take callbacks are not re-fired (no rebuild feedback loop)

A position-aware fingerprint guards against redundant re-sorts.

**Favorite / junk** toggles are handled separately: they change an item's sort order without moving any cell, so the refresh hooks never see a layout change. SortingPlus signals them through `rax_icon_layers.refresh`, which this mod hooks to run the same `soft_resort` (unconditionally, since the fingerprint is unchanged, and regardless of SortingPlus' RESORT setting) — replacing the stock full-rebuild `On_Sort` with the seamless in-place re-sort.

**Trade is SOFT-ONLY** — trade containers are never `Reinit`'d. A trade `Reinit` would rebuild from `ParseInventory(npc)`, which still contains basketed items (they stay in the ruck until the deal is confirmed) and would re-add them to the sale bag, causing the classic duplicate / stuck-in-basket bug. Repositioning cannot do that, so it is safe.

Shift state is read with `key_state(DIK_LSHIFT/RSHIFT)`, matching FastTransfer, so bulk-transfer detection works with both Shift keys.

---

## Compatibility

- Compatible with standard G.A.M.M.A. mods
- Works alongside Ishmaeel's FastTransfer (Nitpicker's Modpack, mod 124)
- Modifies **no existing files** — a single new script only
- Safe to add or remove mid-playthrough

---

## Credits

| Mod | Author |
|-----|--------|
| SortingPlus | RavenAscendant |
| Inventory Open Lag Reducer | sea-ex |
| FastTransfer | Ishmaeel (Nitpicker's Modpack) |
| G.A.M.M.A. UI | Tronex |
| G.A.M.M.A. RC3 | Grok and the G.A.M.M.A. team |
