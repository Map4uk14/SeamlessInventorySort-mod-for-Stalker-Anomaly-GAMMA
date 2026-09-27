# Validation and game test checklist

## Automated validation

Development requires Python 3.9+ and the pinned Lupa dependency. Game installations do not require Python.

```powershell
python -m pip install -r requirements-dev.txt
.\tools\validate.ps1
.\tools\validate.ps1 -Upstream
.\tools\package.ps1
```

Use `-Python 'C:\path\to\python.exe'` if Python is not on PATH. Validation fails rather than silently skipping Lua checks. The default suite is offline after dependency installation. `-Upstream` downloads the unmodified sea-ex source at the pinned revision in `tools/run_tests.py`, executes it with a restricted dependency environment, and checks integration with production layout planning. No remote code is installed into the game or added to the archive.

Validated on 2026-09-28:

- 11 production scripts compile in genuine Lua 5.1.
- All 22 generated MCM controls have their existing paths, labels, descriptions, and list values; localization XML parses.
- 59 local behavior tests plus 3 pinned upstream integration tests pass (62 total).
- The compatible-supplies regression covers an empty second weapon slot and temporarily unavailable slot, weapon ID, or section during equipment changes.
- Storage-opening regressions cover empty UI cells, staged population, existing stacked children, and the first real pickup into a genuinely empty inventory. Existing owned items must not get the new-loot tint.
- Tests cover settings, wrapper return/error semantics, hook idempotence, layout planning/rollback, stacking, exact change tracking, deferred gates, cancellation, retry bounds, supplies, highlights, weapon guard, menu opening, trade baskets, and MCM callback ordering.
- A synthetic workload of 1,000 parent cells / 10,000 IDs over 250 unchanged refreshes performs zero sorts, zero renderer calls, and schedules zero sort events. Timings are printed for reproducibility, not used as a flaky pass/fail threshold or as game FPS evidence.

The runtime tests use contract-shaped tables, not Anomaly's C++ UI userdata. They cannot prove all load-order combinations, UI animation behavior, save compatibility, or perceived responsiveness. The checks below have **not** been performed in-game for this modular build.

## In-game checklist

Use a separate MO2 profile, a backup save, and the modular archive as a separate mod entry. Disable the old version without deleting it. Fully restart the game after switching builds.

| Scenario | Check |
| --- | --- |
| Open small and large stashes repeatedly | Normal opening order; no second visible reshuffle or lingering tint. Measure opening delay separately from refresh responsiveness. |
| Inventory and repair | Attach/detach, unload, repair, craft, move/drop items; confirm ordering and scroll stability. |
| Keep gaps on/off | Removal alone leaves gaps only when enabled; addition or manual movement can repack. |
| Trade with nonempty baskets | Favorite/junk toggles, buying/selling, Shift and pending sorts must not re-add basket items to sale bags or change the basket contents. |
| Shift transfer | Hold Shift through a transfer batch, then release; one settle sort. Close/change partner before release and verify no late sort in the next session. |
| Disassembly | Item, weapon, outfit, and ammo breakdown; animations on/off; delay 0 and nonzero; repeated operations extend the hold. |
| Corpse modes | All four modes with LTT; without LTT, its two modes fall back to normal sorting. Hold Shift as a reveal finishes. Test stashes and living companions separately. |
| Favorite/junk | Toggle with SortingPlus RESORT both on and off. Plain icon refreshes should not reshuffle. Explicit saved favorites/junk should remain intact. |
| Compatible supplies | Change equipped weapons with windows open/closed; test own-bag toggle, manual junk, different scopes, and weapons with the same compatible ammo. |
| Weapon clone guard | Modify a bag weapon with empty slots; modify an equipped weapon; equip a different or already-owned same-family weapon during the guard window. Check scope parent/child section transitions. |
| New loot | First pickup into an empty bag; pickup into an existing stack; remove that new child; close/reopen; switch bodies. |
| Options while pending | Disable master/window/LTT/disassembly/favorites while Shift or reveal work is pending. Change SortingPlus sort settings too. |
| Optional integrations | Test with and without sea-ex on the installed GAMMA version; check MO2 conflicts and Lua logs. |

## Diagnostics and rollback

Read-only counters are available through `zz_seamless_inventory_sort.debug_stats()` (`sorted`, `unchanged`, `deferred`, `failed`). They are cumulative for the runtime instance; `deferred` counts requests, not distinct timer jobs. No continual console polling is needed.

Errors are logged once per diagnostic key with the prefix `[Seamless Inventory Sort]`. If a renderer fails repeatedly or rollback fails, automatic sorting pauses for that container until a reset/reopen. Save the relevant game log and report the window, action, MCM settings, and MO2 conflicts.

To roll back: close the game, disable the modular entry, and re-enable the old one. Do not enable both. This build introduces no new save-state data. Keep the backup save regardless while evaluating an experimental script rewrite.

## Packaging

`tools/package.ps1` validates before creating a uniquely named ZIP under `packages/`. It includes `gamedata/`, README.txt, and LICENSE only. The archive is reopened and each file's SHA-256 is compared with its working-tree source. Existing archives are never overwritten; Git and development files are excluded. Packaging uses the current uncommitted files and does not commit or push anything.
