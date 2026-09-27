SEAMLESS INVENTORY SORT - EXPERIMENTAL MODULAR BUILD
==================================================

A SortingPlus companion for S.T.A.L.K.E.R. Anomaly / G.A.M.M.A.

This test build replaces the old monolithic script with focused modules.
The 22 MCM settings and their saved paths are unchanged.

INSTALL WITH MOD ORGANIZER 2
---------------------------
1. Use "Install a new mod from an archive" and select this ZIP.
   gamedata must appear at the archive root.
2. Name it "Seamless Inventory Sort - Modular Test".
3. Disable the previous Seamless Inventory Sort entry; enable only this one.
   Keep the previous entry/archive so you can roll back.
4. Check file conflicts. This entry must provide all siss_*.script helpers,
   both zz_seamless_inventory_sort*.script entry points, XML, and unlocalizer.
5. Fully restart the game. Use a test MO2 profile and a backup save.

Do not install just the old main script: every included module is required.
To roll back, close the game, disable this entry, and enable the old version.
No new save-state fields are added.

REQUIREMENTS
------------
SortingPlus (GAMMA mod 110), GAMMA's modded engine and inventory UI.
Optional: sea-ex Inventory Open Lag Reducer (mod 464), MCM.
The included unlocalizer exposes SortingPlus caches used by this mod.

FEATURES
--------
- In-place sorting after item changes, independently enabled for inventory/
  repair, loot/stash, and both trade sale bags. Trade baskets are not rebuilt.
- Optional keep-gaps behavior after pure removal (off by default).
- Deferred sorting during disassembly, ammo breakdown, and Shift transfers.
- Separate ammo-component category with adjustable rank.
- Temporary priority/icons for compatible equipped-weapon supplies, optionally
  limited to loot/trader stock. Saved favorites and junk are not changed.
- Bounded clone guard for bag weapons modified through supported addon hooks.
- Session loot tint, including items added to an existing stack.
- Corpse modes: normal, stock size-kind layout without automatic kind sorting,
  preserve Looting Takes Time layout, or sort after the reveal.
- Oscillation cooldown and bounded recovery attempts.

MCM: Options -> Mod Configuration Menu -> Seamless Inventory Sort.
Six pages: General, Compatible Supplies, Gaps and Disassembly, Looting and
Bodies, Loot Highlight, Performance. MCM is optional; defaults are built in.

WHAT TO EXPECT
--------------
Most visible behavior should remain familiar. Unchanged refreshes skip sorts
and cell rendering; actual sorts repaint only moved parent cells. Queued work
shares safety gates and is discarded when the inventory session changes.

This is not an engine-level large-stash loading fix. Initial enumeration,
stacking and UI creation still belong to GAMMA. Large-stash lag was also
observed with this mod disabled. Automated Lua tests do not certify game FPS.

TEST BEFORE KEEPING
------------------
Check inventory, stash/body, trade with items in baskets, Shift release,
repeated disassembly (animations on/off), all corpse modes, favorites/junk,
equipment changes, stacked loot tint, and addon changes with empty slots.
Test MCM switches while work is pending. Close/reopen and change partners.
If sorting stops after a renderer error, reopen the inventory and check the
game log for "[Seamless Inventory Sort]". Keep the previous build for rollback.

The repository README and docs/TESTING.md contain full test and build details.

CREDITS
-------
SortingPlus / MCM: RavenAscendant
Inventory Open Lag Reducer: sea-ex
FastTransfer: Ishmaeel
Looting Takes Time (Redux): its respective author
