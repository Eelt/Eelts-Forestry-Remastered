## Why

A tree the mod owns advances one size stage per in-game hour, driven by a tick that walks
every tree in the global object bin whether or not a player is anywhere near it. Both halves
of that are wrong.

Leave a sapling for a year and come back to it and it is still a sapling. It then climbs one
stage an hour while you stand there, so it takes seven in-game hours to reach the size it
should already have been when you arrived, and you watch it happen. The tree's own elapsed
time is recorded correctly; only the rate at which it is allowed to catch up is wrong.

The walk is also the scaling risk carried forward from `add-erosion-boundary-layer`. The bin
held 10247 objects after a few hours of play and grows with exploration, and `add-vegetation-
succession` adds every naturally established tree to the same bin.

Vegetation succession already solved this shape of problem: work out what the ground should be
carrying from the time that has passed, and apply it when the area loads. Growth should be the
same.

## What Changes

- A tree is brought up to date when its chunk loads, advancing every stage that has fallen due
  in one step rather than one per hour. Arriving after a long absence shows a tree at the size
  it should be, with no visible catching up.
- The remainder is carried forward rather than discarded, so a tree that catches up repeatedly
  does not drift later and later relative to one that was watched the whole time.
- The hourly tick keeps running and keeps its present job. It drives seasonal foliage, which
  has to change while a player is watching, and it still grows a loaded tree. It no longer has
  anything to catch up, because at most one stage can fall due per stage duration and the tree
  arrived already correct.
- A setting chooses between the two, defaulting to catching up on arrival. The base game's
  behaviour choice on the existing growth setting is unaffected; this is about when a tree the
  mod grows is brought up to date, not about which trees grow.

## Capabilities

### Modified Capabilities
- `tree-growth`: a tree is brought up to date when its area loads rather than one stage an hour
  after arrival, and a setting chooses between that and the old timing.

## Impact

Changed: `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua` for advancing
several stages at once and keeping the remainder,
`42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua` for the chunk load hook,
`42.20/media/sandbox-options.txt` and `Translate/EN/Sandbox.json` for the setting.

### B42.20 files and tables this rests on

No vanilla file is edited or shadowed.

`SGlobalObjectSystem:OnChunkLoaded(wx, wy)` in `media/lua/server/Map/SGlobalObjectSystem.lua`
calls `self.system:getObjectsInChunk(wx, wy)` and walks the result, so it hands a system
exactly its own objects in the chunk being loaded with no scanning. Its base body removes
orphans and then returns the list to a pool with `finishedWithList`, which an override has to
respect. `docs/reference/b42-lua-notes.md` records that this hook is useless for discovering
new objects, which is true and does not apply here: catching up trees the mod already owns is
exactly the set it reports.

Elapsed time comes from `GameTime.getWorldAgeHours`, which is built from `getNightsSurvived`
and the time of day rather than from the calendar, as recorded in the same document.

## Non-goals

- Which trees grow. The existing growth setting keeps that job untouched.
- Per tree variation in growth rate. A tree's stage stays a function of the time since it
  reached its current stage and the pace multiplier, with no position noise. Trees already
  differ because they are adopted and planted at different moments.
- Removing the hourly tick. Seasonal foliage has to keep updating for a tree a player is
  standing next to, and that is what the tick is for.
- The size of the global object bin. This change reduces what the bin walk has to do but does
  not shrink the bin, and the scaling risk stays open until it is measured.
- Growth of anything other than trees. The understory carries no stages.
