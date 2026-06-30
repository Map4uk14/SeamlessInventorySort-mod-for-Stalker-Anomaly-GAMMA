# Changelog

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
