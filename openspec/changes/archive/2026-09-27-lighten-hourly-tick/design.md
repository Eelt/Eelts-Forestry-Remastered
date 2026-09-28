# Design

## Context

See `proposal.md` for the problem and the vanilla behaviour this rests on.

`Eelt_STreeGrowthSystem.everyHour` runs four things back to back in one frame:
`updateAdoptedTrees`, which loops over `self.system:getObjectCount()` objects, that is every tree
the mod has adopted in the save; `adoptNearPlayers`, a 61 by 61 square scan around each
player; `succession.sweepNearPlayers`, a 41 by 41 square `evaluate` around each player; and
`succession.refreshBushes`, which walks the in memory table of recovered bushes in loaded
ground.

For an unloaded tree, `grow()` still raises the stage and resets `enteredHour` and sends the
record to clients, and `refreshOverlay` works out the season before finding no tree to draw.
Under the default timing, `OnChunkLoaded` then runs `catchUp` on arrival, which brings the tree
to the exact stage its elapsed time earned and carries any part stage forward. Under the older
timing, `OnChunkLoaded` returns straight away, so a tree grown while unloaded is drawn at its
old size until its next `grow()` redraws it.

Succession already keeps its own in memory table of recovered bushes in loaded ground, filled
as the chunk load pass sees them and pruned when the hourly refresh finds one gone. The tree
list below copies that shape.

## Goals / Non-Goals

**Goals:**

- The hourly work touches only what is loaded.
- No frame spends more than a small fixed budget on it.
- Every result is what today's code would produce, at most a few seconds later within the
  same hour.
- A like for like measure of the coroutine and a plain cursor, so the choice between them is
  made on a number.

**Non-Goals:**

- Round robin across the ten minute ticks.
- Changing the chunk load passes or arrival catch-up.
- A setting for the budget.

## Decisions

### Loaded trees are kept in a list, not filtered from the whole save

`TreeGrowthSystem` gains a table of adopted trees in loaded ground, keyed by position. A tree
joins it when it is adopted, through the one local `adopt` function every adoption path shares,
and when `OnChunkLoaded` reports its chunk, in both timing modes, before the catch up check.
The hourly update walks that table, and a position whose square is no longer loaded, or whose
record is no longer the system's, is dropped.

Starting a session relies on `OnChunkLoaded` firing for the starting area. To avoid depending
on that, the first hourly job of a session has an extra first phase that walks the whole object
list and adds the trees whose square is loaded. It is sliced like every other phase, so it is
one pass over the save per session, spread over frames, instead of one unspread pass per hour.

The debug menu's forced refresh walks the same table, since an unloaded tree has nothing to
redraw.

Alternative considered: keeping the loop over every object and skipping the ones whose square
is not loaded. Rejected because the loop and the lookup per tree are themselves the cost that
grows with the save.

### The hourly work becomes a job worked through a frame at a time

On the hour, `everyHour` builds a job instead of doing the work. The job is four phases, in
today's order, each a list of items and a function for one item:

| Phase | Items | One item |
|---|---|---|
| Seed, first job only | every object index | add the tree if its square is loaded |
| Trees | the loaded tree table, copied when the phase begins | grow if due, otherwise refresh the look |
| Adoption | one column of the 61 by 61 scan per player | adopt any tree in that column |
| Succession sweep | one column of the 41 by 41 sweep per player | `evaluate` or the discovery check per square |
| Bushes | the loaded bush table, copied when the phase begins | apply the current look |

The season values and the player positions are read once, when the job is built, the way one
pass reads them today. Every item checks its square is still loaded when its turn comes, since
chunks can unload during the job.

An `OnTick` handler works through the job until a budget of 2 ms has been spent in that frame,
checking the clock every 16 items because `getTimestampMs` counts whole milliseconds. If an hour
turns over while a job is still running, the old job is finished at once before the new one is
built, and a line is printed, since that means the budget is too small for the machine.

Succession gains the per square and per bush steps as functions the job can call, alongside
the existing `sweepNearPlayers` and `refreshBushes`, which stay for the debug menu.

Alternative considered: running each phase to completion in its own frame. Rejected because
the tree phase on its own is the spike.

### Two drivers over the same job, measured against each other

The job's phases and items are shared. Two drivers work through them:

- A coroutine, which loops over the phases and items in plain lua and calls `coroutine.yield`
  when the frame's deadline passes. `OnTick` resumes it. It never yields inside a `pcall`, and
  if `resume` returns an error the job is dropped and the error printed, so a fault cannot
  resume forever.
- A cursor, a phase and an index kept between frames.

A debug switch selects the driver. A coroutine does not make the work itself cheaper; what is
measured is its overhead per frame and per item against the cursor, and the worst frame each
produces. Whichever is cheaper stays as the only driver, and the other is removed before the
change is archived. If the coroutine library turns out not to be usable in game, the cursor is
the driver and the result is recorded.

### What is measured

"Time the hourly tick" in the debug menu runs the whole job at once ten times and prints the
milliseconds for each phase, the number of items in each, and how many trees the save holds
against how many are loaded. A second debug switch prints, for each spread job, its driver, its
total milliseconds, how many frames it took and its worst single frame.

## Risks / Trade-offs

- Under the older timing a tree no longer grows while unloaded. That is the requested change
  and matches the setting's name and spec, but a player on that setting who is used to trees
  growing in their absence will see them stop.
- `OnTick` on a dedicated server is taken from LetMeDrive's source, not read from the jar. If it
  did not fire there, the unfinished job would be finished at the next hour, correct but with
  the old spike. Checked on a server below.
- LetMeDrive captures `OnTick` handlers registered after it and, when its players opt in to
  shedding while driving fast, may skip heavy ones every other frame. That would only slow the
  job down, never change its results.
- `getTimestampMs` counts whole milliseconds, so a 2 ms budget is really between one and three.
  Good enough for a hitch a player notices; not a precise limit.
- The seeding pass at the start of a session still grows with the save's age. It is spread over
  frames like the rest and happens once per session, and it is measured with the rest.
