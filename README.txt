================================================================================
  SEAMLESS INVENTORY SORT
  A G.A.M.M.A. RC3 companion to SortingPlus
================================================================================

SortingPlus sorts your inventory when it opens, but the engine drops any item
you modify or move to the bottom of the list. This mod snaps it back into its
sorted place the moment it lands -- no flicker, no lost scroll position.

SortingPlus is REQUIRED.


FEATURES
--------
  - Keeps the list sorted after: attaching/detaching weapon parts, unloading
    magazines, repairing/crafting, picking items up, moving items to/from
    stashes and bodies, trading, and marking items favorite/junk.
  - Works in the inventory, loot/stash (both sides) and trade (both sale
    bags); each window can be toggled on or off on its own.
  - No more reshuffle on drop/sell/stash: removing an item just leaves the
    gap instead of shoving everything below it up a slot. Fills back in next
    time something is actually added.
  - No more jumping on disassembly: while you take items ammo
    apart, nothing in the bag moves - each dismantled item's slot stays
    empty and the parts land at the end. When you stop, a single re-sort
    folds the parts into their group and closes the gaps (delay
    configurable, 0-8 s).
  - Own category for ammo parts: casings, bullets and gunpowder
    sort into their own group right below the ammo instead of mixing in
    between the ammo boxes.
  - Modified weapons stay in the bag: attaching or detaching a scope, silencer
    or GL no longer kicks the weapon out of your bag into an empty weapon slot.
  - FastTransfer: while SHIFT is held the sort is deferred, then applied once
    on release.
  - New-loot highlight: items you just looted get a colored tint in your bag
    until you close the inventory. Color is configurable (cyan by default).
  - Looted body handling: one setting chooses how dead bodies behave -- sort
    normally, never sort (leave as found), keep Looting Takes Time's reveal
    order, or sort after the reveal finishes. Stashes, containers, companions
    and your own bag always sort.
  - Anti-oscillation guard: backs off if an unstable item (e.g. a magazine
    being bound) makes a list churn.


CONFIGURATION (MCM)
-------------------
Optional. Options -> Mod Configuration Menu -> Seamless Inventory Sort, in five
pages: General, Gaps and Disassembly, Looting and Bodies, New Loot Highlight,
Performance. Without MCM the mod uses its built-in defaults.


REQUIREMENTS
------------
  - SortingPlus (GAMMA mod 110)                       -- REQUIRED
  - Inventory Open Lag Reducer by sea-ex (mod 464)    -- optional, faster sort
  - MCM                                               -- optional, settings menu


INSTALLATION
------------
1. Place the "501- Seamless Inventory Sort" folder into your GAMMA mods\ folder.
2. Enable it in Mod Organizer 2. Load order does not matter. Safe to add or
   remove mid-playthrough.


CREDITS
-------
  SortingPlus / MCM           -- RavenAscendant
  Inventory Open Lag Reducer  -- sea-ex
  FastTransfer                -- Ishmaeel
  Looting Takes Time (Redux)  -- its respective author

================================================================================
