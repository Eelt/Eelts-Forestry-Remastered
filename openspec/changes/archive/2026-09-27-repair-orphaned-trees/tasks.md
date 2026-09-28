# Tasks

Every task below was implemented. An unchecked one in group 3 is a check that was never run,
not code that was never written; those are listed in `docs/future/carried-forward.md`.

## 1. Taking a tree back

- [x] 1.1 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, add
  `reclaimTree(square, tree)`, which identifies the tileset and stage from the tree's sprite,
  returns nil for a sprite that is not one of the species, and otherwise calls the local `adopt`
  with the planted flag off. Done when the method exists and calls `adopt`.
- [x] 1.2 In `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua`, in the settled
  branch, call `reclaimTree` when the growth system has no record on the square, and count trees
  taken back and trees whose sprite was not recognised. Print the first tree taken back with its
  position and stage. Done when the settled branch makes the lookup before it returns and the
  report line carries both counts.

## 2. Watching for lost records

- [x] 2.1 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, set a flag
  around the base `OnChunkLoaded` call, and override `removeLuaObject` to count removals made while
  it is set and print the first five positions before calling the base method. Expose the count.
  Done when a removal outside chunk loading is not counted.
- [x] 2.2 In `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua`, add the removal
  count to the boundary report. Done when the report line shows it.
- [x] 2.3 Record in `docs/reference/b42-lua-notes.md` the order `IsoChunk.doLoadGridsquare` loads a
  chunk in, that `SGlobalObjectSystem:OnChunkLoaded` removes records it cannot match only after
  every square's `LoadGridsquare`, and that the tree growth system has no `loadIsoObject` hook, so a
  lost record is never rebuilt by the base game. Done when the section is present.

## 3. Verification in game

- [x] 3.1 Load the long running save and read the first boundary report. Look for about as many
  trees taken back as the gap between settled trees and records (about 1,300), none unrecognised,
  and a first repair printed. Closed on 2026-09-27 at day 160.05: "1582 already settled, 0
  corrected, 1474 taken back, 0 not recognised, 0 records dropped by the chunk check", with "took
  back 3736,5857 stage 0" printed first.
- [x] 3.2 Straight after loading, inspect several trees that were frozen, such as the stage 3 red
  maple. Look for the `displaySeason` line now printed and the autumn overlay in place. Closed on
  2026-09-27: every deciduous tree wore the right overlay on arrival, and all were bare after a
  skip to mid November. A stage 6 dogwood at 3661,5786 printed its record, stagger 0.5155 and first
  colour at position 2.6562 against its own deep colour boundary of 2.6625, then bare in winter.
- [x] 3.3 With the hourly job report on, let an hour pass. Look for the loaded tree count close to
  the settled count instead of about 133. Closed on 2026-09-27: "hourly job: 74 ms over 36 frames,
  worst frame 3 ms, trees 3375" after travelling, with the boundary having taken back 3852 trees
  over 100000 squares and the chunk check dropping none.
- [x] 3.4 Save, relaunch and load the same area. Look for zero trees taken back and zero records
  removed at chunk load. Record the numbers whatever they are. Closed on 2026-09-27: after a
  relaunch at day 252.13, "1595 already settled, 0 corrected, 0 taken back, 0 not recognised, 0
  records dropped by the chunk check". The save now holds 12720 records against 8423 before.
- [x] 3.5 Note how long the first load takes against a normal load, and with LetMeDrive, its drain
  time against the 671 ms seen before. Record both. Closed on 2026-09-27: LetMeDrive drained the
  starting area in 779 ms on the load that took back 1474 trees and in 679 ms on the next load,
  so the repair cost about 100 ms once, behind the loading screen.
- [x] 3.6 Turn composition correction off and load an area with orphans that has not been visited
  since the repair. Look for them taken back all the same. Closed on 2026-09-27: with correction
  off, 60000 squares of new ground gave 0 corrected and 1489 taken back. The same reports counted
  32 renamed trees whose sprite is not one of the eleven species, left alone as designed; what
  they are is carried forward.
- [ ] 3.7 On a dedicated server, load an area with orphans. Look for the repair counts in the
  server console and the overlays right on a client.
