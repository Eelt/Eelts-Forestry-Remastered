# Tasks

Every task below was implemented. An unchecked one in group 4 is a check that was never run,
not code that was never written, and 3.3 is waiting only on the dedicated server finding from
4.9; both are listed in `docs/future/carried-forward.md`.

## 1. The loaded tree list

- [x] 1.1 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, add an in
  memory table of adopted trees in loaded ground keyed by position, filled from the local
  `adopt` function and from `OnChunkLoaded` in both timing modes before its catch up check.
  Done when both places add to it and nothing saves it.
- [x] 1.2 In the same file, make the hourly tree update and `refreshAllOverlays` walk that table
  instead of `getObjectCount`, dropping a position whose square is unloaded or whose record is
  no longer the system's. Done when neither function calls `getObjectCount` any more.

## 2. The hourly job

- [x] 2.1 In `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, expose one step per
  square of the hourly sweep (`evaluate`, or the discovery check when succession is off) and one
  step per bush of the refresh, and a way to list the loaded bush positions, keeping
  `sweepNearPlayers` and `refreshBushes` for the debug menu. Done when the new functions exist
  and the two old ones are built from them.
- [x] 2.2 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, build the
  hourly job as phases in the design's order: seed (first job of a session only), trees,
  adoption columns, succession sweep columns and bushes, with the season values and player
  positions read once when the job is built and each item rechecking that its square is loaded.
  Done when `everyHour` builds a job and runs none of the work itself.
- [x] 2.3 In the same file, add the cursor driver on `OnTick`: work through the job until 2 ms
  have been spent in the frame, reading the clock every 16 items. Done when a job left alone
  finishes over several ticks.
- [x] 2.4 In the same file, add the coroutine driver over the same phases and items, yielding
  when the frame's deadline passes, never inside a `pcall`, and dropping the job with a printed
  error if `resume` fails. Done when a debug switch selects between the two drivers. The
  coroutine driver was removed after 4.4 found no difference, leaving the cursor.
- [x] 2.5 In the same file, finish an unfinished job at once when the next hour turns over, and
  print a line saying so. Done when a new job is never built while an old one is running.

## 3. Measuring

- [x] 3.1 In `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, make "Time the
  hourly tick" run the whole job at once ten times and print milliseconds and item counts per
  phase, and the save's tree count against the loaded tree count. Done when the printed line
  names every phase.
- [x] 3.2 In the same file, add a switch for the driver and a switch that prints, for each spread
  job, its driver, total milliseconds, frames taken and worst single frame. Done when both
  switches appear under the Planting debug submenu. The driver switch went with the coroutine
  driver after 4.4; the report switch stays.
- [ ] 3.3 Record in `docs/reference/b42-lua-notes.md` that the global object list keeps unloaded
  objects, that `SGlobalObjectSystem:OnChunkLoaded` only validates, and that the coroutine library
  is registered for mod lua, adding what the verification group finds about coroutines and about
  `OnTick` on a dedicated server. Done when the section is present.

## 4. Verification in game

- [x] 4.1 Before any of the above, on the 0.0.2 build, run "Time the hourly tick" on the long
  running save and record the milliseconds a run and the tree count. Closed on 2026-09-27: at
  day 113.94, "hourly tick over 8384 objects: 262 ms for ten runs, 26.20 ms a run", which times
  the tree update alone.
- [x] 4.2 On the new build, in the same save and place, run "Time the hourly tick". Look for the
  tree phase costing a fraction of 4.1, and the loaded tree count well below the save's total.
  Closed on 2026-09-27: 8405 trees in the save and 166 loaded; trees 0.7 ms a run against 26.2
  in 4.1. The other phases: adoption 1.8 ms over 61 columns, sweep 31.3 ms over 41 columns,
  bushes 3.5 ms over 347, and the one off seed about 9 ms over 8405 objects. The sweep is now
  the largest part of the hour; spread over frames it no longer lands in one.
- [x] 4.3 Run `coroutine.create`, `resume` and `yield` once in the debug console in game. Record
  whether they work; if not, use the cursor and skip 4.4. Closed on 2026-09-27 by the job report
  instead, since the debug console runs in its own lua state and would prove nothing about the
  mod's: "hourly job by coroutine: 65 ms over 29 frames, worst frame 4 ms, trees 166, adoption
  61, sweep 41, bushes 347", with no errors. The worst frame is a millisecond over the design's
  estimate of three.
- [x] 4.4 With the job report on, let several hours pass under each driver. Record for each the
  total milliseconds, frames and worst frame, and keep the cheaper driver. Closed on 2026-09-27:
  five hours each on the long running save. Cursor 46/23, 53/26, 48/23, 47/22 and 47/23 ms over
  frames, averaging 48.2 ms over 23.4 frames; coroutine 44/21, 47/24, 46/23, 47/23 and 50/25,
  averaging 46.8 ms over 23.2 frames, after a first run of 65/29 taken just after the timing
  tool. The worst frame was 3 ms every run. No measurable difference, so the cursor was kept
  for not depending on a library no shipped lua uses, and the coroutine driver removed.
- [ ] 4.5 Stand in a forest on a lower end setup and let the hour turn over with and without this
  change. Look for the hitch gone or clearly smaller.
- [x] 4.6 Advance time with the debug menu across a stage and a season boundary. Look for the
  tree growing and changing its look within the hour, the same as the 0.0.2 build. Closed on
  2026-09-27 once `repair-orphaned-trees` had given the long running save's trees their records
  back: every deciduous tree wore the right overlay, all were bare after a skip to mid November,
  and growth was seen on the hourly tick. No side by side run against 0.0.2 was made.
- [ ] 4.7 Under the older timing, leave an area long enough for several stages to fall due and
  return. Look for the trees at the size they were left at, drawn at that size, then growing one
  stage at a time.
- [x] 4.8 Start a session and watch the first hourly job's report. Look for a seed phase and a
  loaded tree count matching the starting area. Closed on 2026-09-27: "hourly job: 67 ms over 33
  frames, worst frame 3 ms, seed 8423, trees 133, adoption 61, sweep 41, bushes 309" on the long
  running save. The 133 are every tree in the starting area that has a record; the boundary
  counted 1499 renamed trees there, and the difference is trees renamed without a record, which
  nothing can find until they are repaired.
- [ ] 4.9 On a dedicated server, let an hour pass with the job report on. Look for the job spread
  over several ticks, which confirms `OnTick` fires there.
- [x] 4.10 With LetMeDrive enabled, let several hours pass. Look for every job finishing within
  its hour. Closed on 2026-09-27: five hours with LetMeDrive's gate installed, every job finished
  in 24 to 27 frames and 49 to 59 ms with a worst frame of 3 ms (4 ms once), and none ran past its
  hour. LetMeDrive captures the job's `OnTick` handler and it still ran as without it.
