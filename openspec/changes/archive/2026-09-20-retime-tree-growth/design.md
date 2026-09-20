# Design

## Context

See `proposal.md` for motivation.

`Eelt_STreeGrowthObject` already records `enteredHour`, the world age at which the tree
reached its current stage, and it already persists. So the information needed to know how far
behind a tree is has been stored correctly all along. What is missing is a moment at which to
act on it, and permission to advance more than one stage.

`Eelt_STreeGrowthSystem.everyHour` walks the whole bin, growing what is ready and refreshing
the seasonal overlay on everything else. That walk is the only thing that has ever advanced a
tree.

## Goals / Non-Goals

**Goals:**

- A tree is the right size the moment its area comes into view.
- No new persistent state. The catch-up is arithmetic on what is already stored.
- The hourly tick keeps its job and gains nothing to catch up.
- The old timing stays available, so a player who preferred it is not forced off it.

**Non-Goals:**

- Shrinking the bin, or changing how often the tick walks it.
- Any change to which trees grow, or to the pace multiplier's meaning.

## Decisions

### Catch up on the hook that already reports the right trees

`SGlobalObjectSystem:OnChunkLoaded(wx, wy)` calls `self.system:getObjectsInChunk(wx, wy)`, so
it hands the system exactly its own objects in the chunk being loaded. No scan, no radius, no
guessing at which trees are affected.

The base body removes orphaned lua objects and then calls `finishedWithList`, which returns
the list to a pool. An override therefore does its own work against its own fetch of the list
rather than holding the one the base method is about to recycle.

Alternative considered: growing from the succession pass, which already visits every square on
`LoadGridsquare` and already exits early on a square carrying a tree. Rejected because it
would tie growth to a feature that can be switched off, and because it would test every square
in the world to find the few that hold a mod owned tree, which is what
`getObjectsInChunk` answers directly.

Alternative considered: a radius scan around each player on the hourly tick, as
`adoptNearPlayers` does. Rejected because it would still be a tick, so a tree would still be
wrong for up to an hour after a player arrives.

### Advance every due stage, and keep the remainder

`grow` currently takes one step and sets `enteredHour` to now. Setting it to now is what
throws away the part of the next stage already earned, which matters once a tree can advance
several stages at a time: a tree caught up ten times would lose ten partial stages against one
that was never unloaded.

So the catch-up computes how many whole stages the elapsed time pays for, advances by that
many or up to the ceiling, and moves `enteredHour` forward by exactly that many stage
durations rather than to the present. What is left over is the progress toward the next stage,
which is what a watched tree would have had.

The ceiling is applied as it is today, so a tree that has been away for a decade arrives at
the largest stage and no further.

### The tick is left alone

Seasonal foliage has to change while a player is standing next to a tree, and the tick is what
does that. It also still grows a loaded tree, which is harmless: once arrival has brought a
tree up to date, at most one stage can fall due per stage duration, so the tick's one step is
always enough and the two paths agree.

This means the bin walk is unchanged and the scaling risk from
`add-erosion-boundary-layer` is neither helped nor worsened here. It stays open.

## Risks / Trade-offs

- A chunk load now does work proportional to the mod owned trees in that chunk. Mitigation:
  the hook reports only those trees, the arithmetic is a subtraction and a division per tree,
  and `stateToIsoObject` already runs on every stage change today. It is measured against a
  chunk dense with owned trees before the change is called done.
- A tree that is due several stages changes sprite once rather than several times, which
  transmits to clients once. This is strictly less work than the old path did over seven hours,
  but it happens during a chunk load rather than spread out.
- Catching up on arrival makes the growth setting's effect more visible: a player who had trees
  quietly lagging will see them jump to their correct size the first time they revisit an area
  after installing this. That is the fix working, and it happens once per area.

## Migration Plan

Nothing to rewrite. `enteredHour` is already stored and already means the right thing, so an
existing save's trees catch up the first time each area loads.

Rollback is the setting: choosing the older timing restores one stage per hour and leaves the
stored state valid for either path.

## Open Questions

- Whether the tick should skip trees whose area is not loaded, now that arrival handles them.
  It would cut the walk's cost but needs the bin measurement from
  `add-vegetation-succession` first, and nothing in the specs depends on it.
