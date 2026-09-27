# Core rebuild review notes

Historical notes for the earlier core-rebuild branch. For the newer modular experiment, see [architecture](docs/ARCHITECTURE.md) and [testing](docs/TESTING.md). The checks described below apply to the historical version, not the current test suite.

Branch: `refactor/core-rebuild`

This is an experimental rebuild for review and in-game testing before merge.

## What changed

- Replaced parallel global state tables with one state record per inventory container.
- Validated and clamped every cached MCM value at the boundary, including safe fallback behavior when MCM reads fail.
- Rebuilt `soft_resort` as a transactional two-phase operation:
  1. build the optional comparator before touching the container;
  2. calculate the complete layout against a detached grid;
  3. apply only cells whose positions actually changed.
- Added rollback of container bookkeeping and already-moved cells when a renderer fails.
- Preserved nil and multiple return values through compatibility wrappers and made the active sort context exception-safe.
- Replaced frame-count timeouts with elapsed-time deadlines, making FastTransfer, LTT, disassembly, and weapon-slot behavior independent of FPS.
- Coalesced overlapping weapon clone guards and limited them to matching weapon sections when the caller exposes one.
- Fixed unknown non-NPC objects being classified as corpses after an `alive()` access error.
- Restored SortingPlus' NPC sort mode when the corpse override is disabled or no longer applicable.
- Fixed LTT's `sort after reveal` path so holding Shift at reveal completion waits for release instead of silently abandoning the final sort.
- Made temporary compatible-supply classification fail closed outside known bag contexts, trimmed attachment section names, and guarded icon geometry lookup.
- Removed stale ammo-parts ordering immediately when the feature or master switch is disabled.
- Updated the packaged text README with the Compatible Supplies page that was already documented on GitHub.

## Why no feature was removed

The audit did not find a feature whose steady-state cost justified deleting user-facing behavior. Expensive work remains callback-driven or short-lived; no permanent per-frame update loop was introduced. The larger costs were repeated container scans, full cell rebuilds, and unsafe retries, which the rebuild reduces directly.

## Validation performed

- Both `.script` files parse successfully as Lua 5.1 with `luaparse`.
- The localization XML is well formed.
- All 22 runtime defaults have matching MCM controls, and vice versa.
- Every MCM option has a localization label.
- `git diff --check` passes.
- The branch was kept isolated from `main` throughout development.

Run the checks again from PowerShell:

```powershell
.\tools\validate.ps1
```

## Manual in-game checks still required

Static validation cannot emulate Anomaly's UI userdata or the exact GAMMA mod stack. Before merging, test:

1. Add/remove/transfer items in inventory, loot, stash, trade, and repair screens.
2. Hold Shift through a FastTransfer sweep and verify one stable sort after release.
3. Attach/detach each addon type from a bag weapon with an empty weapon slot; also intentionally equip a different weapon during the guard window.
4. Disassemble with animations both enabled and disabled, including repeated ammo breakdown.
5. Exercise all four corpse modes with and without Looting Takes Time.
6. Toggle favorite/junk and change equipped weapons while each inventory window is open.
7. Toggle every MCM feature off and back on without reopening the game.
8. Test with and without Inventory Open Lag Reducer (sea-ex), especially large trader inventories.
