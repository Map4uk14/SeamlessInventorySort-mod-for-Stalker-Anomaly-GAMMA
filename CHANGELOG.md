# Changelog

## v1.2.2

### Fixed
- **Attaching or detaching a scope, silencer or grenade launcher no longer
  yanks the weapon out of your bag into an empty weapon slot.** GAMMA rebuilds
  a weapon when you change its parts, and the engine was auto-equipping the
  rebuilt weapon whenever the matching slot happened to be free. A weapon you
  are only modifying in the bag now stays in the bag. New toggle **"Keep
  modified weapons in the bag"** (General page, on by default) — turn it off
  for the old behavior.

### Changed
- **Lighter on frame time.** A few hot paths were cleaned up: options are read
  from a cache instead of re-parsing an MCM path string on every cell paint and
  every refresh, the Looting Takes Time reveal check is polled a few times a
  second instead of every frame, and the removal-tracking snapshot is skipped
  entirely while "Keep gaps" is off. Fewer stutters when opening or looting big
  containers.

## v1.2.1

### Changed
- **"No reshuffle on drop/sell/stash" (from v1.2) is now off by default** and
  moved to its own toggle: "Keep gaps after removing items" (General page).
  Some players didn't like the empty slots it leaves behind, so the bag now
  repacks immediately on removal again unless you turn the toggle on.

## v1.2

### Changed
- **Dropping, selling or stashing an item no longer reshuffles the rest of the
  bag.** If nothing was added and nothing else moved, the gap is just left
  where the item was instead of repacking everything below it. The bag
  compacts again next time something is actually added.
- **Re-sorting is noticeably cheaper.** Only cells that actually change
  position get rebuilt now — previously every cell was rebuilt (icon, shadow,
  layers, condition bar) on every re-sort, even ones that hadn't moved. This
  should cut down the stutter when opening big containers or fully stocked
  traders.
- Opening a window that SortingPlus already sorted no longer re-sorts it a
  second time on the first refresh right after.

### Fixed
- **Stale "new loot" highlight on reopening a container.** The highlight marks
  were being cleared too late (after the window had already drawn), and on
  some closing paths weren't cleared at all, so old tints could still show up.
  They're now cleared right when the window opens/switches mode, before
  anything is drawn.
- The very first item you take right after opening a container is now tinted
  too (it used to slip through untinted).

## v1.1

### Added
- **Per-window seamless sort toggles.** The inventory, loot/stash and trade
  windows can now each be turned on or off on their own (General page), on top
  of the existing master Enable switch.

### Changed
- **Looted body handling is now a single dropdown** instead of three separate
  checkboxes. One "Looted body handling" setting on the Looting and Bodies page
  with four clear choices:
  - Sort normally
  - Never sort - keep as found
  - Keep Looting Takes Time order
  - Sort after Looting Takes Time reveal

  This removes the old overlap where "Never sort looted bodies" and the Looting
  Takes Time options could produce the same result in confusing ways.
- **Default body behavior is now "Sort normally"** (previously bodies were left
  in Looting Takes Time's reveal order by default). If you want the old default,
  pick "Keep Looting Takes Time order".

### Fixed
- **Opening a container no longer highlights your whole inventory.** Boxes and
  stashes clear and repopulate the actor bag a moment after opening (an engine
  quirk for items that spawn into a box), which made the new-loot highlight
  treat every item in your bag as freshly looted. The highlight now waits for
  the bag to settle, so only items you actually take are tinted.
- **Hardened the in-place re-sort against a rare crash** tied to a third-party
  sort helper: the kind-aware cell placement is always restored even if a sort
  pass errors, so a later refresh can't crash on a stale helper.
