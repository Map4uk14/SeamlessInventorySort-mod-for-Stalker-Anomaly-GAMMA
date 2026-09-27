# Seamless Inventory Sort

A SortingPlus companion for S.T.A.L.K.E.R. Anomaly / G.A.M.M.A. that keeps existing inventory cells sorted after items change, without rebuilding the whole inventory.

## Experimental modular rebuild

This branch replaces the former monolithic script with nine focused modules and two small game/MCM entry points. The 22 existing MCM settings and their saved paths are preserved. This is a test build, not an in-game-certified release.

The redesign separates settings, layout planning, sort policy, scheduling, compatible supplies, loot marks, weapon handling, and game integration. See [architecture and research](docs/ARCHITECTURE.md) and [validation / in-game checklist](docs/TESTING.md).

## Features

- Automatic in-place sorting after item changes in inventory/repair, loot/stash, and both trade sale bags. Each window can be disabled independently.
- Optional **Keep gaps after removing items** (off by default). Pure removals can leave gaps; additions or other layout changes trigger packing.
- Disassembly protection: defer this mod's sorting while parts arrive, then settle once. Includes ammo breakdown, animation delay, and the configurable extra delay.
- A separate ammo-component category with an adjustable rank.
- Temporary priority, highlights, and icons for supplies compatible with equipped weapons. Saved SortingPlus favorites/junk are not modified; explicit player choices retain precedence.
- A bounded weapon-clone guard to return matching replacement weapons to the bag after addon changes. Equipped, foreign, unidentified, and known preexisting bag weapons are excluded.
- Coalesced sorting after Shift/FastTransfer release.
- Session-scoped new-loot tint, including items added to an existing stack.
- Corpse handling: normal sorting, stock size-kind layout without automatic kind sorting, keep Looting Takes Time's layout, or sort after its reveal. Corpse rules do not apply to stashes or living partners.
- An oscillation cooldown and bounded retries for renderer failures.

Only kind-sorted bags are automatically repacked. Game-owned stacking, inventory ownership, trade baskets, and ordinary refresh operations remain with GAMMA.

## What is optimized—and what is not

Unchanged refreshes skip layout planning and rendering. Actual sorts plan against a detached grid and repaint only moved parent cells. Deferred requests share one scheduler; equipment events are coalesced. Compatible sections are collected before opening-time sorting, avoiding the extra sort/redraw previously requested when the window appeared.

These improvements reduce work attributable to this mod. They do not remove GAMMA's inventory enumeration, stacking, or initial UI construction. Large-stash opening lag was also observed with this mod disabled; no engine-level FPS improvement is claimed.

## Requirements and settings

- SortingPlus (GAMMA mod 110), with GAMMA's modded engine and inventory UI.
- Inventory Open Lag Reducer by sea-ex (mod 464): optional optimized comparator.
- MCM: optional. Without it, validated built-in defaults are used.

MCM: **Options → Mod Configuration Menu → Seamless Inventory Sort**. The existing six pages remain: General, Compatible Supplies, Gaps and Disassembly, Looting and Bodies, Loot Highlight, and Performance.

The included engine unlocalizer exposes the SortingPlus rank/kind caches needed for the new categories and per-bag cache isolation. This package does not replace SortingPlus or GAMMA UI files.

## Install / test in Mod Organizer 2

1. Install the modular ZIP using MO2's **Install a new mod from an archive** button. The archive has `gamedata/` at its root.
2. Give it a separate name, such as **Seamless Inventory Sort - Modular Test**.
3. Disable the previous Seamless Inventory Sort entry; enable only the modular test entry. Keep the old entry/archive for rollback.
4. Check MO2's file conflicts: this build must supply its own `siss_*.script`, both `zz_seamless_inventory_sort*.script` entry points, localization, and unlocalizer.
5. Restart the game fully, then follow the [in-game checklist](docs/TESTING.md#in-game-checklist).

For a loose-folder installation, put the folder containing `gamedata` into MO2's mods directory. Do not install just the old single script: the helper modules are required.

The mod adds no save-state fields. Keep a backup save and use a test MO2 profile while evaluating the rebuild. To roll back, close the game, disable this entry, and re-enable the previous version.

## Development

Use Python 3.9+ with the development-only Lua runtime:

```powershell
python -m pip install -r requirements-dev.txt
.\tools\validate.ps1
.\tools\validate.ps1 -Upstream
.\tools\package.ps1
```

`-Upstream` additionally downloads a pinned sea-ex source revision and tests its actual comparator/placement functions. It requires network access; ordinary tests are offline. `-Python 'C:\path\to\python.exe'` selects a particular interpreter.

Packaging validates first, includes all game files plus README.txt and LICENSE, then verifies every archived file's SHA-256 against the source. It creates a new timestamped ZIP without overwriting earlier builds. Python, tests, Git metadata, and development dependencies are not shipped.

## Credits

- SortingPlus / MCM — RavenAscendant
- Inventory Open Lag Reducer — sea-ex
- FastTransfer — Ishmaeel
- Looting Takes Time (Redux) — its respective author
