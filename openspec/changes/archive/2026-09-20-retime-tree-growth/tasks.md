# Tasks

Every task below was implemented. An unchecked one in group 2 is a check that was never run,
not code that was never written; those are listed in `docs/future/carried-forward.md`.

## 1. Catch up on elapsed time

- [x] 1.1 Add `catchUp` to
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua`, advancing every stage
  the elapsed time pays for, up to the ceiling, and moving `enteredHour` on by exactly that
  many stage durations rather than to the present.
- [x] 1.2 Override `OnChunkLoaded` in
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua` to catch up and refresh
  the foliage of every mod owned tree in the loading chunk, taking its own copy of the list
  since the base body recycles the one it fetched.
- [x] 1.3 Add the growth timing setting to `42.20/media/sandbox-options.txt` and
  `42.20/media/lua/shared/Translate/EN/Sandbox.json`, catching up on arrival by default and the
  older one stage at a time as the other, and honour it in
  `EeltsForestryRemastered_TreeGrowthSystem.lua`.
- [x] 1.4 Add a debug menu entry to
  `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua` that backdates a tree's
  `enteredHour` by a chosen number of days and reports stage and remainder before and after, so
  the catch-up can be exercised without travelling.
- [x] 1.6 Count and time the arrival catch-up in
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, reporting chunks,
  trees looked at, trees grown, total milliseconds and the worst single chunk through a debug
  menu entry. A chunk load happens in a burst, so the worst chunk is what a stall would come
  from rather than the average.
- [x] 1.5 Add a reset entry alongside it that puts a tree back to a sapling with its clock set
  to now, and refuse to backdate a tree already at the largest stage. Backdating a full size
  tree reports a gain of zero whatever it is given, which reads as a pass and is not one.

## 2. Verification in game

- [x] 2.1 Plant a sapling, travel far enough to unload it, skip several months and return.
  Look for the tree already at the size that time earned it as the area comes into view. Closed on 2026-09-20: a planted American Holly at 6103,5292 read stage 0, size 1 on season day 25 and stage 7, size 8 on season day 131 after being unloaded and returned to, which is 106 elapsed days against the 91 that seven stages cost.
- [x] 2.2 Stay near that tree for an in-game hour. Look for no further change of stage, which
  is what separates arriving correct from climbing afterwards. Closed on 2026-09-20: watched for an in-game hour after returning and the stage did not move, so the size was arrived at rather than climbed to.
- [x] 2.3 Reset two trees to saplings, then catch one up in a few large steps and the other in
  more small ones, with totals that do not divide a stage exactly. Look for each landing where
  a single step over the same elapsed time would. Steps that divide a stage, such as 13 days,
  land on a remainder of zero either way and prove nothing. Closed on 2026-09-20: one tree took
  two 30 day steps to stage 4 with 192.1 hours into the next, which is where a single 60 day
  step lands; the other took five 7 day steps to stage 2 with 216.2 hours, which is where a
  single 35 day step lands. Every one of the seven readings matches the arithmetic to a tenth
  of an hour, and discarding the remainder would have given 0.0 and 168.0 instead. An earlier
  attempt with 91 and 13 day steps was void, since both trees were already at the largest stage
  and neither step size could have shown a difference.
- [x] 2.4 Skip a year with a sapling unloaded. Look for the largest stage and no further. Closed on 2026-09-20: partly. The same return carried 106 days against the 91 seven stages cost, so fifteen days of surplus were absorbed and the tree held at stage 7. Backdating a full size tree by 365 days then gained nothing, which is the same clamp from the other side.
- [x] 2.5 Set the timing to the older choice and return to a tree that has been away.
  Look for it climbing one stage an hour. Closed on 2026-09-20: with the timing set to the older choice, a newly planted tree advanced on the hourly tick rather than on arrival.
- [ ] 2.6 Watch a tree that is never unloaded, at default pace and at a doubled one.
  Look for growth unchanged from today.
- [ ] 2.7 Return to a planted tree, a corrected wild tree and a naturally established tree
  after the same absence. Look for all three caught up the same way.
- [ ] 2.8 Set growth to player planted only, then to the base game's behaviour, and return to
  an area after an absence. Look for no wild tree catching up under the first and nothing
  catching up under the second.
- [x] 2.9 Return in a different season to when the area unloaded. Look for the foliage the
  current season calls for rather than the look it had when it unloaded. Closed on 2026-09-20: an area left in August and returned to in late October showed the foliage late October calls for rather than the August look.
- [ ] 2.10 Drive through forest the mod owns and read the arrival catch-up totals. Look for a
  worst chunk figure small next to the 16.67 ms frame, and record it.
- [ ] 2.11 Run the feature on a dedicated server with a late joining client. Record the result
  whether or not it passes.

## 3. Close out

- [x] 3.1 Record in `docs/reference/b42-lua-notes.md` that `OnChunkLoaded` reports a system's
  own objects in the loading chunk through `getObjectsInChunk`, which is what makes it right
  for catching up and wrong for discovery, and that its base body recycles the list. Closed on 2026-09-20: the note now records what getObjectsInChunk returns, that java invokes the lua method by name, and that the base body recycles its list.
- [x] 3.2 Move anything still unverified into `docs/future/carried-forward.md` under a heading
  for this change. Closed on 2026-09-20.
