# Design

## Context

See `proposal.md` for the defect, the evidence and the vanilla load order this rests on.

`EeltsForestryRemastered_ErosionBoundary.lua` runs on `LoadGridsquare` and looks at every tree as
its square loads. A tree already named `Eelt_AdoptedTree` is counted as settled and left alone,
before the composition setting is read. Any other tree is corrected, which ends in
`Eelt_STreeGrowthSystem:adoptCorrectedTree` and the growth system's one local `adopt` function.

`adopt` refuses a square that already has a record, renames the tree, creates the record with
`newLuaObjectOnSquare`, fills it with `adoptFrom` (stage from the sprite, `enteredHour` now, the
planted flag as given), draws it with `stateToIsoObject`, which sets the stage's base sprite and
the current season's overlay and sends both to clients, and, since `lighten-hourly-tick`, adds it
to the loaded tree list.

## Goals / Non-Goals

**Goals:**

- No tree the mod renamed is ever left without a record once its area has loaded.
- A tree taken back looks right the moment its area loads, not an hour later.
- Something in the console shows whether records are still being lost.

**Non-Goals:**

- Recovering what the lost record held beyond the tree's species and size.
- Explaining the long running save's history.

## Decisions

### The repair lives in the boundary pass's settled branch

The settled branch already runs for every renamed tree that loads, in every setting. It gains one
lookup: if the growth system has no record on the square, the tree is taken back. The lookup is
one `getLuaObjectOnSquare` per renamed tree per load, the same call correction already makes for
every tree it considers.

Alternative considered: registering `MapObjects.OnLoadWithSprite` for every tree sprite, which is
how vanilla systems reach `loadIsoObject` and which runs before the chunk check and outside
LetMeDrive's deferral. Rejected because it registers a hook for each of several hundred sprite
names to make the same test the boundary pass already makes, and because the load order means the
repaired record is in place before the chunk check either way.

### Taking a tree back goes through `adopt`

`Eelt_STreeGrowthSystem` gains `reclaimTree(square, tree)`, which identifies the tileset and stage
from the tree's sprite and calls `adopt` with the planted flag off and no stage ceiling, as
correction does. `adopt` already does everything the repair needs: it builds the record, draws the
current season's overlay at once, sends it to clients and adds the tree to the loaded list. A
sprite that does not identify as one of the eleven species is left alone and counted.

Alternative considered: the shipped `loadIsoObject`, which builds a record through
`stateFromIsoObject`. Rejected because it neither redraws the tree nor adds it to the loaded list,
so the frozen overlay would stay until the next hourly job, and it would be a second adoption path
beside the one every other adoption uses.

`adopt` ends in `stateToIsoObject`, which recalculates the square and its neighbours. On the long
running save that is about 1,300 trees on the first load, once each. The cost is measured in the
verification tasks; if it proves too high, the repair can set only the overlay when the tree
already wears its stage's base sprite, which every inspected orphan did.

### Counting what is repaired and what is lost

The boundary report gains a count of trees taken back, and the first one is printed with its
position and stage, the way the first correction is.

The growth system counts records the base game removes during `OnChunkLoaded`. Its override sets a
flag around the call to the base method, and an override of `removeLuaObject` counts removals made
while the flag is set and prints the first five positions before passing each one to the base
method. The count is added to the boundary report. Removals at any other time, such as a tree
being felled, are not counted.

A second load of the same area should then read zero trees taken back and zero records removed.
A count that keeps rising across loads would mean records are still being lost, and the positions
say where to look.

## Risks / Trade-offs

- A tree taken back restarts the time towards its next stage and is recorded as wild, so under
  "Only trees you plant" a planted tree that lost its record stops growing, and it no longer
  counts as a planted parent. Neither fact survives anywhere but the lost record.
- About 1,300 redraws on the first load of the long running save, which with LetMeDrive runs in
  its drain and without it during loading. Measured below.
- With LetMeDrive the repair runs later than the chunk check. That is harmless, since an orphan
  has no record for the check to remove, but it means a repaired tree appears a few frames after
  its area does.
