## Why

Taking a tree over renames it to `Eelt_AdoptedTree`, which ends the base game's seasonal handling
of it for good, and gives it a record in the tree growth system, which is what the mod's hourly
work and arrival catch up walk. A tree that is renamed but has no record is owned by nothing: the
base game no longer changes its foliage and the mod never finds it. It keeps whatever overlay it
was wearing when it lost its record, forever. That is the exact failure the tree seasons spec
forbids.

The long running save shows it at scale. At day 159 its starting area held 1494 renamed trees
and 133 records. Every tree inspected in game across three sessions, seventeen inspections from a
stage 0 sapling to a stage 7 red maple, had no record, and every one was frozen on the summer
overlay in autumn. The
same trees are frozen on the 0.0.2 build, so this is not new with the hourly job. How the records
were lost is not known: the save predates the growth system and has been played through every
build since, and was restored from a backup.

## What Changes

- When a renamed tree loads without a record, the mod takes it back: it builds a new record from
  the tree itself, adds it to the loaded tree list, and redraws its overlay for the current
  season at once. The frozen look is gone as soon as the tree's area loads, and from then on the
  tree follows the seasons and grows like any other.
- This happens in every setting. It does not depend on composition correction being on, since
  the tree was taken over long ago and the seasons spec already requires it to be maintained
  whatever the growth setting.
- The load report counts trees taken back, so the repair can be seen working and seen finishing.
- The arrival report counts records the base game removes at chunk load for want of a tree, with
  the first few positions printed, so a future cause of lost records shows up in the console.
- A tree taken back restarts the time towards its next stage, and is recorded as wild. Neither
  can be recovered: both lived only in the lost record.

## Capabilities

### New Capabilities

### Modified Capabilities
- `tree-seasons`: a tree the mod has taken over whose record is missing is taken back when its
  area loads, so its seasonal appearance is maintained again.

## Impact

Changed: `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua`, whose load pass
already sees every renamed tree and now repairs one without a record.
`42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, which gains the method
that takes a tree back and the count of records removed at chunk load.
`docs/reference/b42-lua-notes.md` for the load order below.

Builds on `lighten-hourly-tick`, whose loaded tree list a repaired tree joins. That change is
implemented but not yet merged, so the two are merged together or this one after it.

Unchanged: correction, growth timing, the seasonal rules, and every tree that already has its
record.

### B42 files and tables this rests on

No vanilla file is edited or shadowed. Read on 2026-09-27 from the 42.20 stable install: CFR
0.152 decompiles of `projectzomboid.jar` and the shipped lua.

- `zombie/iso/IsoChunk.doLoadGridsquare` handles each square of a loading chunk in turn,
  calling `ErosionMain.LoadGridsquare`, then `MapObjects.loadGridSquare`, then the lua
  `LoadGridsquare` event. Only after every square does it call `ErosionMain.ChunkLoaded` and then
  `SGlobalObjects.chunkLoaded`, which runs `SGlobalObjectSystem:OnChunkLoaded`.
- The shipped `SGlobalObjectSystem:OnChunkLoaded` removes any record whose square holds no object
  the system accepts, printing "found luaObject without an isoObject" only through the system's
  `noise`, which is silent unless debugging. A record rebuilt during `LoadGridsquare` is therefore
  already in place, next to its tree, when that check runs, and is kept.
- The shipped `SGlobalObjectSystem:loadIsoObject` is the base game's own path for an object that
  loads without a record, and vanilla systems reach it through `MapObjects.OnLoadWithSprite`. The
  tree growth system never registered one, so nothing has ever rebuilt a lost tree record.
- The inspect in the debug menu prints its `displaySeason` line only when the tree has a record,
  which is how the orphans were found.

## Non-goals

- Finding out how the long running save lost its records. The removal count is there to catch a
  cause that is still happening; the save's history is not recoverable.
- Recovering a tree's time towards its next stage, or whether it was planted.
- Re-adopting trees the mod never renamed, which is correction's and adoption's job.
