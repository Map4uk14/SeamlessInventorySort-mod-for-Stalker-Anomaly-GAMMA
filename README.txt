================================================================================
  SEAMLESS INVENTORY SORT
  A G.A.M.M.A. RC3 quality-of-life patch
================================================================================

DESCRIPTION
-----------
A companion to SortingPlus. SortingPlus sorts your inventory when it opens, but
when you then modify or move an item the engine appends it to the BOTTOM of the
list instead of keeping it in its correct sorted row. This mod snaps the item
back to its proper sorted position the instant it lands -- seamlessly, with no
flicker and without losing your scroll position.

(SortingPlus is therefore REQUIRED -- without it there is nothing to keep sorted
and this mod does nothing.)

Fixed actions (the vanilla "jumps to the end" behaviour):
  - Attaching / detaching weapon parts: scopes, HOLOGRAPHIC sights,
    suppressors, grenade launchers
  - Unloading a magazine
  - Repairing / upgrading / crafting / combining items
  - Picking items up into your bag
  - Moving items into or out of a stash, chest, corpse, or companion
  - Buying / selling at a trader
  - Marking an item FAVORITE or JUNK (SortingPlus's K / J keys or the
    right-click menu): the item now snaps to the top (favorite) or bottom
    (junk) instantly, in place -- previously it stayed put until you reopened
    the window, or did a full-rebuild flicker.

WORKS IN EVERY INVENTORY WINDOW
  - Inventory / repair         (your bag)
  - Loot / stash / container    (your side AND the container side)
  - Trade                       (your sale bag AND the trader's sale bag)

Bulk transfer (Ishmaeel's FastTransfer -- sweeping items with SHIFT held) is
handled specially: sorting is frozen while you hold shift and done once in a
single pass when you release it, so bulk stashing stays fast.


REQUIREMENTS
------------
  - SortingPlus by RavenAscendant            (GAMMA mod 110)  -- REQUIRED
  - Inventory Open Lag Reducer (sea-ex)       (GAMMA mod 464)  -- optional
                                              (just makes the sort faster on
                                               very large inventories)

Both are included & enabled by default in G.A.M.M.A. RC3. On vanilla Anomaly you
only need SortingPlus; the mod uses SortingPlus's own sort, and if sea-ex's mod
is also present it uses its faster sort instead.

Sorting runs only when a window is sorted by "kind" (the SortingPlus default).
If SortingPlus is absent -- or a window's sort option is switched to "sizekind"
-- the mod simply does NOTHING for that window (items land at the end, as in
vanilla). It never does a heavy rebuild, so it cannot cause stutter or FPS drops
in any configuration.


INSTALLATION
------------
1. Place the "501- Seamless Inventory Sort" folder into:
     [Your GAMMA RC3 install]\mods\

2. Enable it in Mod Organizer 2 (tick its checkbox in the left panel).

3. Load order does not matter. The script uses the "zz_" prefix so it loads
   after ui_inventory.script. Safe to add or remove mid-playthrough.


HOW IT WORKS (for mod authors)
------------------------------
SortingPlus places items by "kind" using an rKind row tracker. When the stock
*Mode_RefreshInventories functions add an item incrementally, FindFreeCell sees
the new item's kind != rKind.last and drops it at row_end + 1 (the end).

This mod hooks IMode_/LMode_/TMode_RefreshInventories. Right after the stock
refresh runs -- in the SAME frame, before the UI draws -- it re-sorts the
affected container so the item never renders at the end (this is what makes it
seamless, including the holo sight's two-stage weapon respawn).

The re-sort ("soft_resort") does NOT rebuild the container. It REPOSITIONS the
existing cells into their sorted slots via UICellItem:Set(area), using
SortingPlus's own kind comparator + FindFreeCell (or sea-ex's faster equivalent
if that mod is installed). Because nothing is added or removed:
  - there is no Reset()/Show(false) blink, even on huge stashes;
  - stacked-item children are left intact;
  - loot-box put/take callbacks are not re-fired (no rebuild feedback loop).

It is SOFT-ONLY: it never calls Reinit. If the in-place sort cannot run it skips
(leaving vanilla order) rather than doing a heavy rebuild -- this keeps it free
of stutter/FPS cost, and on trade specifically prevents a Reinit from re-adding
basketed items (still in the ruck) into the sale bag (the classic duplicate /
stuck-in-basket bug). A position-aware fingerprint guards against redundant
re-sorts. Shift state is read with key_state(DIK_LSHIFT/RSHIFT), matching
FastTransfer, so bulk-transfer detection works with both shift keys.

Favorite / junk toggles are handled separately: they change an item's sort
order without moving any cell, so the refresh hooks never see a layout change.
SortingPlus signals them through rax_icon_layers.refresh, which this mod hooks
to run the same soft_resort (unconditionally, since the fingerprint is
unchanged, and regardless of SortingPlus's RESORT setting) -- replacing the
stock full-rebuild On_Sort with the seamless in-place re-sort.


COMPATIBILITY
-------------
  - Compatible with standard G.A.M.M.A. mods.
  - Works alongside Ishmaeel's FastTransfer (Nitpicker's Modpack, mod 124).
  - Modifies NO existing files -- a single new script only.
  - Safe to add or remove mid-playthrough.


CREDITS
-------
  SortingPlus                 -- RavenAscendant
  Inventory Open Lag Reducer  -- sea-ex
  FastTransfer                -- Ishmaeel (Nitpicker's Modpack)
  G.A.M.M.A. UI               -- Tronex
  G.A.M.M.A. RC3              -- Grok and the G.A.M.M.A. team

================================================================================
