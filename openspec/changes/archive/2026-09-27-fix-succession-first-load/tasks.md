# Tasks

Every task below was implemented. An unchecked one in group 2 is a check that was never run,
not code that was never written; those are listed in `docs/future/carried-forward.md`.

## 1. Refresh on the first square

- [x] 1.1 In `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`, give
  `validateSprites` a `validated` flag so a second call returns at once. Done when the function
  returns before any `getSprite` call when the flag is set, and the `OnGameStart` registration
  is still in place.
- [x] 1.2 In `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, add a `ready`
  upvalue and test it first in `onLoadGridsquare`. On the first call set it, call
  `refreshOptions` and `understory.validateSprites`, and print one line with the world day read.
  Done when the handler's first statement after the nil check is the `ready` test, and the
  read at the bottom of the file and the `OnGameStart` and `EveryTenMinutes` registrations are
  unchanged.

## 2. Verification in game

- [x] 2.1 Load a long running save standing in or beside recovering ground. Look for the new
  print with the save's real world day before the first succession report, the understory
  prints before that report too, and a first report whose "too soon" count is no longer most of
  the squares. Closed on 2026-09-27: "first square read the world at day 113.87" printed after
  the two understory prints and before the first report, which read 0 too soon (17795 in the
  session before the fix) and established 21 trees in the starting area. LetMeDrive's drain of
  the starting area took 517 ms, up from 139 ms, now that those squares are judged.
- [x] 2.2 In the same load, look at a recovered bush in the starting area without waiting an
  in-game hour. Look for the current season's look. Closed on 2026-09-27: loaded at day 113.93
  and inspected at 113.94, both inside the same in-game hour, so before any hourly refresh. Two
  recovered bushes, New Jersey tea at 3692,5758 and blueberry at 3675,5753, each carried exactly
  the overlay they wanted (the summer foliage at year position 1.97, with neither inside its
  flower or fruit window) and were tracked.
- [x] 2.3 Start a brand new world. Look for the print reading day 0, and for no lua errors.
  Closed on 2026-09-27: "first square read the world at day 0.00", no errors from the mod, and a
  first report of 18071 too soon, which is correct on day 0.
- [x] 2.4 Load the same save with LetMeDrive enabled and again with it disabled. Look for the same
  first report in both, allowing for which squares happened to load. Closed on 2026-09-27: with
  LetMeDrive the refresh read day 113.87 and without it day 113.93, both before the first
  report, and both reports read 0 too soon with growing, unchanged and ineligible counts within
  a few percent of each other. Without LetMeDrive the first square still arrived after
  `OnGameTimeLoaded`.
- [ ] 2.5 Start a dedicated server on a long running save and read its console. Look for the new
  print with the save's real world day before the first succession report.
