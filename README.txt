================================================================================
  SEAMLESS INVENTORY SORT
  A G.A.M.M.A. RC3 quality-of-life patch -- companion to SortingPlus
================================================================================

DESCRIPTION
-----------
SortingPlus orders your inventory when it opens, but the engine drops an item at
the BOTTOM of the list whenever you modify or move it. This mod snaps the item
back into its correct sorted row the instant it lands -- seamlessly, with no
flicker and without losing your scroll position.

SortingPlus is REQUIRED -- without it there is nothing to keep sorted.

Fixed actions (the vanilla "jumps to the end" behaviour):
  - Attaching / detaching weapon parts: scopes, holographic sights,
    suppressors, grenade launchers
  - Unloading a magazine
  - Repairing / upgrading / crafting / combining items
  - Picking items up into your bag
  - Moving items into or out of a stash, chest, corpse, or companion
  - Buying / selling at a trader
  - Marking an item FAVORITE or JUNK -- it snaps to the top / bottom instantly,
    in place, instead of waiting for a reopen or a full-rebuild flicker

Works in every inventory window:
  - Inventory / repair         (your bag)
  - Loot / stash / container    (your side AND the container side)
  - Trade                       (your sale bag AND the trader's sale bag)

Bulk transfer (Ishmaeel's FastTransfer -- sweeping items with SHIFT held) is
handled specially: sorting is deferred while Shift is held and applied in a
single pass on release, so bulk stashing stays fast.


EXTRA FEATURES
--------------
  - New-loot highlight: items you just took from a container, stash or body get
    a colored background in your bag so you can see at a glance what you found.
    Cleared when you close the inventory. Color and intensity are set in MCM
    (cyan by default).

  - Looting Takes Time (Redux) compatibility: looted bodies are left exactly in
    that mod's reveal order instead of being re-sorted. Stashes and your own bag
    still sort normally. Optional "sort the body once after the reveal" in MCM.

  - Anti-oscillation guard: items with an unstable sort key (e.g. a magazine
    while it is being bound) can make a container churn on every refresh; the
    guard detects this and briefly backs off so the list settles.


REQUIREMENTS
------------
  - SortingPlus by RavenAscendant            (GAMMA mod 110)  -- REQUIRED
  - Inventory Open Lag Reducer (sea-ex)       (GAMMA mod 464)  -- optional
                                              (faster sort on large inventories)
  - MCM / Mod Configuration Menu              -- optional (for the settings menu)

If no in-place sort can run (SortingPlus inactive, or a window sorted by size)
the order is simply left untouched -- items land at the end, as in vanilla. The
mod never does a heavy rebuild, so it cannot cause stutter in any configuration.
Without MCM the mod uses its built-in defaults.


CONFIGURATION (MCM)
-------------------
Options -> Mod Configuration Menu -> Seamless Inventory Sort, in four pages:

  General             Master enable; re-sort on favorite/junk.
  Looting Takes Time  Defer while looting; sort body after reveal
                      (off = keep Looting Takes Time's order).
  New Loot Highlight  Enable; color (R/G/B); intensity.
  Performance         Anti-oscillation guard; re-sorts before back-off;
                      back-off time.

All settings apply live; no restart required.


INSTALLATION
------------
1. Place the "501- Seamless Inventory Sort" folder into:
     [Your GAMMA RC3 install]\mods\
2. Enable it in Mod Organizer 2 (left panel).
3. Load order does not matter. The "zz_" prefix loads it after
   ui_inventory.script. Safe to add or remove mid-playthrough.


HOW IT WORKS (for mod authors)
------------------------------
SortingPlus places items by "kind" using an rKind row tracker. When the stock
*Mode_RefreshInventories functions add an item incrementally, FindFreeCell sees
the new item's kind ~= rKind.last and drops it at row_end + 1 (the end).

This mod hooks IMode_/LMode_/TMode_RefreshInventories. Right after the stock
refresh -- in the SAME frame, before the UI draws -- it re-sorts the affected
container so the item never renders at the end (this is what makes it seamless,
including the holo sight's two-stage weapon respawn).

The re-sort (soft_resort) does NOT rebuild the container. It REPOSITIONS the
existing cells into their sorted slots via UICellItem:Set, using SortingPlus's
own kind comparator + FindFreeCell (or sea-ex's faster equivalent if installed).
Because nothing is added or removed there is no Reset/Show(false) blink, stacked
children stay intact, and loot-box put/take callbacks are not re-fired. A
position-aware fingerprint guards against redundant re-sorts.

It is soft-only: it never calls Reinit. On trade this prevents a Reinit from
re-adding basketed items (still in the ruck) into the sale bag -- the classic
duplicate / stuck-in-basket bug.

Favorite / junk toggles change sort order without moving a cell, so the refresh
hooks never see a change. SortingPlus signals them through
rax_icon_layers.refresh, which this mod hooks to run the same soft_resort in
place. Looting Takes Time is detected via its public is_item_hidden; new-loot
items are detected by diffing the actor bag during loot and painted via
SortingPlus's rax_persistent_highlight.


COMPATIBILITY
-------------
  - Compatible with standard G.A.M.M.A. mods.
  - Works alongside FastTransfer (mod 124), Looting Takes Time (Redux),
    and Mags Redux.
  - Modifies NO existing files -- only new scripts.
  - Safe to add or remove mid-playthrough.


CREDITS
-------
  SortingPlus / MCM           -- RavenAscendant
  Inventory Open Lag Reducer  -- sea-ex
  FastTransfer                -- Ishmaeel (Nitpicker's Modpack)
  Looting Takes Time (Redux)  -- its respective author
  G.A.M.M.A. UI               -- Tronex
  G.A.M.M.A. RC3              -- Grok and the G.A.M.M.A. team

================================================================================
