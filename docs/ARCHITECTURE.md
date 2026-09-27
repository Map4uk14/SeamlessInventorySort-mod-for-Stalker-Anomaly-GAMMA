# Modular architecture

The implementation keeps existing MCM paths and features while replacing the monolith.
The tested baseline is commit `6ac1d8a` on `refactor/core-rebuild`.

## Boundaries

| Module | Owns | Does not own |
| --- | --- | --- |
| `siss_config` | One option schema, normalization, MCM pages | Game callbacks |
| `siss_util` | Transparent wrappers, scoped context, hook registry | Feature policy |
| `siss_sort` | Plan/apply/rollback for existing cells | Scheduling or inventory rebuilds |
| `siss_policy` | Window, corpse, reveal and disassembly gates | Sorting |
| `siss_controller` | Exact snapshots, pending requests, cooldowns | Third-party hooks |
| `siss_supplies` | Compatible sections, category and icon caches | Inventory refreshes |
| `siss_loot` | Session loot marks and targeted repaint | Sorting |
| `siss_weapons` | Bounded clone guard | Unrelated equipment |
| `siss_runtime` | Game adapters, lifecycle, composition | Core algorithms |
| `zz_seamless_inventory_sort` | Startup entry point | Feature state |

## Design rules

- Each module exposes a small factory/API; instance state lives in closures.
- Helpers use the game's `.script` namespaces, not a new module loader. Only the entry point registers startup callbacks.
- Every sort request passes through the same policy and scheduler, including favorites and compatible supplies.
- One pending sort per container; close, reset, partner change and disabled options invalidate pending work.
- Reuse opening sorts: collect equipment supplies before stock Reinit. Showing an unchanged menu must not trigger another sort.
- Compare exact ID/index/parent mappings rather than collision-prone aggregate fingerprints. Position snapshots are needed only for gap preservation.
- Cache section metadata, never live game objects across inventory sessions.
- At a loot-window reset, snapshot actor-owned IDs for the highlight baseline, including stack children. UI cells can be empty or only partially populated during storage opening; populating those cells is not a pickup. Ordinary refreshes do not repeat the ownership scan.
- Renderer failures get best-effort rollback and bounded diagnostics/retries. No fallback may rebuild trade baskets.
- Keep the game adapter thin so the same production modules can run against a simulated clock and inventory in Lua 5.1 tests.

## Research

- [Lua closures and private state](https://www.lua.org/pil/16.4.html): closures can own private state behind small table interfaces.
- [Humble Object](https://martinfowler.com/bliki/HumbleObject.html): separate testable decisions from difficult-to-test UI integration.
- [GAMMA UI implementation](https://github.com/Grokitach/Stalker_GAMMA/blob/main/G.A.M.M.A/modpack_addons/G.A.M.M.A.%20UI/gamedata/scripts/utils_ui.script): `Grow`/`TakeRoom` mutate grid bookkeeping; `UICellItem:Set` may return false as well as throw.
- [GAMMA startup](https://github.com/Grokitach/Stalker_GAMMA/blob/main/G.A.M.M.A/modpack_patches/gamedata/scripts/axr_main.script): scripts are loaded into namespaces; scripts exposing `on_game_start` are invoked at startup.
- [GAMMA weapon operations](https://github.com/Grokitach/Stalker_GAMMA/blob/main/G.A.M.M.A/modpack_patches/gamedata/scripts/item_weapon.script): scope attach/detach changes child/parent weapon sections.
- [RAX icon refresh](https://github.com/RAX-Anomaly/anomaly-dependencies-project/blob/main/dependencies/rax_icon_layers/gamedata/scripts/rax_icon_layers.script): refresh mode 1 sorts; other modes update icons. Our compatibility hook must distinguish those intents.
- [SortingPlus setters and caches](https://github.com/Grokitach/Stalker_GAMMA/blob/ab0f743af42a3b3b0b0ee853b3676f5189f7f0d0/G.A.M.M.A/modpack_addons/110-%20SortingPlus%20-%20RavenAscendant/gamedata/scripts/zzz_rax_sortingplus_mcm.script): favorite/junk setters are distinct from icon refresh; kind caches need isolation when bag-dependent temporary categories are used.
- [sea-ex comparator/placement factory](https://github.com/Grokitach/Stalker_GAMMA/blob/ab0f743af42a3b3b0b0ee853b3676f5189f7f0d0/G.A.M.M.A/modpack_addons/464-%20Inventory%20Open%20Lag%20Reducer%20-%20sea-ex/gamedata/scripts/seax_sortingplus_opt_sort_by_kind.script): comparator and placement share item-set caches, so a temporary placement function must never remain installed after a pass.
- [Engine unlocalizer format](https://github.com/Grokitach/Stalker_GAMMA/blob/ab0f743af42a3b3b0b0ee853b3676f5189f7f0d0/G.A.M.M.A/modpack_patches/gamedata/configs/unlocalizers/unlocalizer_test.ltx): the included small unlocalizer exposes item_order and ab_k; ab_k's shared declaration also exposes ab_w/ab_h. No third-party script is replaced or vendored.

These upstream sources establish contracts, not the exact installed GAMMA override stack. Engine UI behavior and perceived performance still require in-game testing. The user's A/B test already found the large-stash opening delay with this mod disabled; this redesign does not claim to fix that upstream cost.

## Names for the approach

This is a small **modular monolith**, not a plugin framework. Closure factories provide **dependency injection** without a container library. The game boundary follows the **Humble Object / ports-and-adapters** idea: thin API translation around directly testable decisions. The controller is a **coalescing scheduler** with session-owned state; layout changes use a **plan/apply/best-effort-rollback** operation.

Splitting files alone does not improve frame time. The concrete savings come from avoiding redundant work, caching stable section data, processing parent cells during sorting, and repainting only changed positions. No generic event bus, service locator, persistent save cache, or new module loader was introduced.

## Costs and limits

- An unchanged refresh compares exact mappings in O(number of IDs), with no new snapshot tables on that fast path. This includes stacked child IDs because a stack-parent change can affect the layout.
- An actual sort collects parent cells, delegates ordering to sea-ex or SortingPlus, plans placement, and calls Set only on moved cells. Grid packing retains upstream costs.
- Equipment scans examine four slots and rebuild compatible-section data only when their signature changes (or settings explicitly force a scan).
- One sort scheduler runs only while work is pending; it polls at most every 50 ms. A busy LTT reveal is checked at most every 250 ms. Previously finished reveals are rechecked when a new request arrives.
- Sort errors retry at one-second intervals, at most three times. A failed renderer rollback suspends that container immediately. No recovery path rebuilds trade baskets.
- Engine userdata, third-party callbacks inside Set, and item destruction cannot be made fully transactional in Lua. Rollback is best effort, and reopening may be needed.
- The clone guard uses a short-lived family match, not an engine-issued clone token. It excludes known preexisting bag weapons but cannot distinguish a separate newly acquired same-family weapon during the brief guard window. This remains an in-game edge case.
- The corpse option historically called "Never sort" uses the stock size-kind opening layout; it does not promise raw engine item order. Its label now states this explicitly while preserving the saved enum value.

## Extending the mod

Add or change a setting in siss_config's schema and its XML strings together. Implement feature decisions in a focused factory with injected dependencies. Request sorting through siss_controller; do not call stock Reset/Reinit to implement a refresh. Add regression tests for the decision and a contract-shaped runtime test for any new hook. Keep runtime startup registration idempotent and wrappers transparent to original errors/multiple return values.
