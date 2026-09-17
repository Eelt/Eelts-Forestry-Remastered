## Context

See proposal.md for motivation, and `docs/reference/b42-lua-notes.md` for the disassembly
the approach rests on. The three findings that shape every decision below: erosion takes a
square's tree decision once and never revisits it, lua always runs after erosion on chunk
load, and renaming a tree makes erosion relinquish the square permanently.

What already exists and is reused rather than rebuilt:

- `Eelt_STreeGrowthSystem` is an `SGlobalObjectSystem` holding one lua object per adopted
  tree, persisted in its own bin, keyed by square. Its `isValidIsoObject` matches on
  `ADOPTED_NAME`, which is the same rename that severs erosion.
- `Eelt_STreeGrowthObject:stateToIsoObject` already swaps a tree's base sprite, applies the
  seasonal overlay, transmits to clients and recalculates neighbours.
- `EeltsForestryRemastered_TreeGrowthSprites.identify` reads a tileset and stage back off a
  sprite name, and `getBase` produces a sprite name for any tileset and stage.
- `EeltsForestryRemastered_Propagules` holds `zoneSpecies` and a weighted roll, currently
  reachable only through `rollSpecies`, which takes an item type.

So correcting a square is mostly a matter of calling existing code with a different species.

## Goals / Non-Goals

**Goals:**
- Establish the cost of running on `LoadGridsquare` before anything is built on top of it.
- Reuse the existing adoption and sprite machinery rather than adding a parallel path.
- Add no new persistent storage. The settle record should fall out of state that already
  persists.
- Keep planting's observable behaviour identical while the species weights move.

**Non-Goals:**
- Deciding the succession policy that will eventually sit behind this boundary. This change
  supplies the boundary and one policy, the species reroll, and nothing more.
- Making the hourly tree update cheap in general. Only the part this change makes worse is
  addressed.

## Decisions

### What succession needs from this boundary, and what it does not get here

`docs/future/vegetation-succession.md` is the change that waits on this one, so three of the
decisions below are shaped by it rather than by this change alone.

The species selection split is the first. Succession asks in as many words for the biome
policy to move out of item specific selection, because establishment must draw on the full
species pool rather than one propagule's filtered slice. The split below is therefore into a
zone weight lookup and a weighted roll that takes an optional eligibility filter, not into
something shaped around a tree correction. Correction passes no filter and succession will
pass none either; only planting does.

The cost measurement is the second, and it is worth more than a go/no-go for this change.
Succession's derived vegetation layer, the grass, groundcover and bushes it computes rather
than stores, is planned to run on the same `LoadGridsquare` event. Whatever this pass turns
out to cost per square is subtracted from the budget succession has left, so the measurement
should be recorded as a number rather than a verdict.

The growing bin is the third. Succession adds established trees to the same global object
system this pass fills, so the hourly iteration gets worse again later. Hoisting the season
computation is worth doing now for that reason as much as for this change.

What succession does not get from this change is a boundary over squares that carry no tree.
The boundary layer as `tree-management-and-genetics.md` describes it is a tree boundary
throughout, since renaming a tree is its whole mechanism, so this is the scope that document
sets rather than a narrowing of it. But erosion's other nature categories, grass, groundcover
and bushes, own their squares by the same one shot rule, and succession will have to take
those squares in the same way before it can put its own vegetation on them. The mechanism
generalises, since renaming is what severs ownership for any category, but the pass does not,
and succession should plan for that rather than assume this change covered it.

Succession's own persistent state does not conflict with the settle record chosen here. It
needs one disturbance timestamp per chunk, which is a different record at a different
granularity, and nothing here forecloses it.

### Where the weights are known to be approximate

The composition audit qualifies its own numbers in three ways that matter more once the
weights drive whole forests rather than the occasional planted sapling.

Deep Forest is the significant one. Its entry is derived from the authored branch, pixel 255
of `primary_forest`, and the audit says in as many words that those percentages "cannot
describe every square carrying the Deep Forest forage label", because the zone also maps a
pixel to a procedural branch. The pass applies the entry to every Deep Forest square
regardless, which is what planting already does, but at forest scale rather than one tree at
a time. Recorded as a known approximation rather than hidden, and the fix is the census the
succession document already asks for.

`PHMixForest` and `Vegitation` have defined mixtures whose map entries are commented out.
The audit says to treat them as compatibility fallbacks rather than proof of an active
region. Applying them costs nothing if those zones never appear.

Plain `Forest`, Urban Area, Trailer Park and Road have no entry, so the pass leaves their
trees alone. That is the audit's own position, that a census is needed before plain Forest
gets a pool and that decorative or preserved town trees establish no proportion. It also
means ornamental trees around houses keep their species, which is the right outcome for a
reason the audit did not have to argue.

### The settle record is the global object bin, not a new one

A square is settled when the growth system already holds a lua object for it. Nothing new is
written, and the record persists because that bin already does.

The alternative was a flag in each square's mod data, which persists automatically but forces
a mod data table into existence on every square the pass examines, including the great
majority carrying no tree. That would grow the save for no benefit. A per chunk record in the
system's own mod data was the other option, and it is smaller, but it still has to be written,
migrated and kept in step with a bin that already records the same thing.

The tree's name alone is not enough. If `IsoObject` names do not survive a save and reload,
a name-only check would reroll every corrected tree on every reload, which is the worst
failure this change could have. Checking the bin is what makes that impossible; the name check
below is only a fast path in front of it.

### The early exit is layered, cheapest first

Ordered by how often it fires and what it costs:

1. No tree on the square. This is the overwhelming majority of squares and costs one call.
2. The tree is already named `ADOPTED_NAME`. Covers every revisit to settled ground, costs
   one call and allocates nothing.
3. Everything else: the bin lookup, the zone lookup, the roll and the sprite swap.

Layer 2 means a reload that loses object names falls through to layer 3, finds the lua object
and treats the square as settled without rerolling. The design is self-healing in that case
rather than dependent on an unverified persistence detail.

### What the measurement returned, and what it settles

Measured on 2026-09-11 over 600,000 squares of mostly unexplored ground, driving and walking.
Net costs per call, with the empty loop subtracted:

| Layer | Call | Net per call | Squares it runs on |
|---|---|---|---|
| 1 | `getTree` | 87 ns | every square |
| 2 | `getName` | 76 ns | squares carrying a tree |
| 3 | `getLuaObjectOnSquare` | 843 ns | unsettled tree squares |
| 3 | `getZones` and the weight walk | 1043 ns | unsettled tree squares |
| 3 | `identify` | 243 ns | unsettled tree squares |

Of the 600,000 squares, 582,053 were bare, 17,880 carried a tree in a zone with weights and
67 carried a tree in a zone with none. That puts the whole pass at 92 ms across the entire
session: 52 ms in layer 1, 1 ms in layer 2 and 38 ms in layer 3.

Per square that averages 0.15 microseconds. Spending one 16.67 ms frame on this pass would
take about 109,000 squares loaded inside that frame, which is roughly two orders of magnitude
more than a chunk burst produces. The pass is affordable with a very large margin.

Two consequences, both simplifying:

The zone weight cache is not needed. `getZones` and its weight walk account for 20 percent of
the total, around 19 ms across 600,000 squares, and no cache is worth having for that. This is
the better outcome, because the cache would have taken the whole chunk's answer from its first
square and misread trees on a zone boundary. That inaccuracy is now simply avoided.

The deferred queue is not needed. Layer 1 is 87 ns on a call that has to happen anyway, so
there is nothing to defer. It stays recorded below as the fallback if a later change makes the
pass much heavier, but this change does not use it.

Two honest limits on the numbers. The per-layer figures come from 15 sampled runs for the
layer 3 calls, and `getName`'s own run total falls below the millisecond timer's resolution,
so its 76 ns is the right order rather than a precise figure. The decision does not rest on
precision; it rests on two orders of magnitude of headroom.

More importantly, `settled` stayed at zero for the entire run. The spike corrects nothing, and
the hourly proximity scan had not adopted anything in the ground covered, so the layer 2 early
exit was never actually taken. Its cost is known, since `getName` costs the same whatever the
name says, but the claim that a revisit is cheaper than a first visit is still arithmetic
rather than observation: 0.16 microseconds against 2.29, about 14 times cheaper. It is
confirmed in the group 6 reload check, not here. The 92 ms figure is correspondingly an
overestimate of steady state, because layer 3 ran again on every revisit to a tree square
instead of once ever.

### Correction reuses adoption with the stage guard lifted

`adoptTree` refuses stage 7 and takes the species from the sprite. Correction needs neither.
Rather than loosen `adoptTree` for both callers, the system gains a second entry point that
takes the target tileset and stage explicitly and applies no ceiling, and `adoptTree` keeps
its guard for the proximity scan, where the guard is still right: there is no size left for a
full grown tree to grow into, so the scan has no reason to take it.

Correction then calls `adoptFrom(tree, rolledTileset, existingStage, false)` followed by
`stateToIsoObject`, which does the sprite swap, the overlay and the client transmit that
already work for growth.

### The species selection splits into weights and roll

`rollSpecies` answers "what may this item become here", which is two policies fused: the zone
weights, and a uniform fallback across the item's eligible species when the zone matches none
of them. The boundary layer wants the first and must not have the second, because the spec
leaves a tree alone when its zone has no recorded species.

So the shared parts become separately callable, the zone weight lookup and the weighted roll,
and `rollSpecies` is rebuilt on them with its item filtering and its fallback intact. Planting
behaviour does not change, which matters because there is no test suite to catch it if it does.

### Making seasons run under stock growth is a deletion

`everyHour` returns early under stock growth, before `updateAdoptedTrees`. But `mayGrow`
already returns false for stock mode, so `updateAdoptedTrees` would refresh overlays without
growing anything, and `adoptNearPlayers` already gates itself on the all-trees setting. The
early return is therefore redundant with the guards underneath it, and removing the line is
all that is needed to decouple seasonal refresh from the growth setting. Which seasonal rule
that refresh follows is the separate setting below.

### The hourly update hoists the season computation

Correction adopts every wild tree the player ever walks past, so the bin grows far larger than
growth alone would make it. `updateAdoptedTrees` iterates every object hourly, and
`refreshOverlay` calls `displaySeason` per object, which reaches `getClimateManager` and
`ErosionMain.getInstance():getSeasons()` every time.

Only the per square stagger varies between objects; the season name and the season progress
are the same for all of them within one tick. Computing those once per tick and passing them
down turns two engine calls per tree per hour into two per hour.

This is not a general optimisation of the hourly update. It is the specific part that
correction makes expensive, and it is in scope because the change causes the problem.

### If the pass is too expensive, it defers rather than shrinks

The fallback, if the measurement fails, is to keep only the first layer in the event handler
and push qualifying squares onto a bounded queue drained on a timer. The visible cost is that
a player can see the wrong species briefly before it is corrected. That is preferable to
restricting correction to a radius around players, which would leave a permanent ragged
boundary between corrected and uncorrected forest.

### The mod is authoritative on a square it has taken

Once a square is corrected the mod owns it outright. The base game's growth of that tree ends
and is not emulated, so under the base-game growth setting a corrected tree stays the size it
was corrected at.

`vegetation-succession.md` already assumes this. Its premise section is titled "There is
nothing in vanilla to extend", it says the scope "is not a correction of vanilla behaviour and
not a system running alongside one" but "the only succession the game will have", and it
specifies that a newly established tree "start[s] at stage 0 and then use[s] the existing
elapsed time growth system, subject to the selected growth mode". That is the mod's own
grower, keyed off each tree's `enteredHour`, not erosion's global `eTicks`. A corrected tree
holding its size under stock growth is the same behaviour an established tree would show, for
the same reason: the mod's grower is the growth system, and stock growth tells it not to grow.

The one sentence pointing the other way was in `tree-management-and-genetics.md`, asking that
seasonal-only ownership preserve the selected growth behaviour rather than suppress stock
growth. It described a narrower case, a tree taken over for seasons alone, and it predates
knowing that the base game's ceiling for an erosion tree,
`maxStage = 2 + floor((eValue - 50) / 17) - 1`, depends on `noiseMainInt` on
`ErosionData$Square`, a class the lua exposer does not list. The ceiling cannot be read, so it
cannot be reproduced, and that sentence has been amended to match.

Approximating the ceiling with a single value was considered and rejected. It would hand some
squares more growth than the base game would have and others less, in a pattern nobody can
predict or check, purely to imitate a system the correction exists to replace.

### The seasonal control, and what it shows when it is off

`docs/future/tree-management-and-genetics.md` requires that seasonal correction get
independent sandbox controls, enabled by default, and leaves only their number and labels
unsettled. So this change adds one, on by default, separate from the growth setting.

It also leaves a question to whichever design adds that control: how a tree the mod already
owns should display vanilla seasons once the control is off. Renaming has already taken the
square off erosion, so the base game will never season that tree again, and simply stopping
overlay updates would freeze whatever foliage it happened to be wearing. Answering it here is
the price of adding the control here.

The answer is that the mod keeps driving the tree's foliage either way, and the control
chooses which rule it drives it by. On, it uses the mod's rule: a per square stagger that
holds summer foliage into autumn and drops leaves late. Off, it uses the base game's rule,
the reported season taken directly, so every tree in an area turns together and turns the
moment the game says autumn.

The first draft assumed the base game's July colouring came from a fourth overlay position the
mod never asks for. That assumption was right, and a later "correction" of mine was wrong.
`b42-tree-matrix.md` sets it out under "The July problem": `seasonDisp[2]` marks summer as
split with `season2 = 3`, so once a square passes the halfway point of summer, adjusted by its
own magic number, the tree moves to overlay position 4 while `curSeason` still reads Early
Summer. Summer runs roughly 13 May to 21 August, so trees begin tinting around 2 July. Position
4 is reached through the display split, not by `setSeasonData` ever assigning that season, which
is why the note that Late Summer is unreachable as a season name is true and irrelevant here.

The same table records that vanilla goes bare through the second half of autumn, not at the end
of it.

So vanilla's rule is not "follow the reported season". It is: spring foliage in spring, green
for the first half of summer, tinted for the second half, autumn colour for the first half of
autumn, bare for the second half and for winter, with the two midpoints staggered per square.
Deferring that July tint is the whole reason this mod drives foliage itself, because 2 July is
far too early for Kentucky.

The plain rule was built wrong on the back of that mistake, returning the reported season and
so reproducing neither the July tint nor the mid-autumn drop. It now carries both midpoints,
split at `0.45 + stagger * 0.1`, and `Late Summer` sits at overlay position 4. Off gives the
unmodded look, July tint included; on gives Kentucky.

What the mod's own rule does with that fourth look is a separate question. It still never asks
for it, so a tree goes from full summer green to full autumn colour in one step, and in a
64 day autumn beginning in September the current windows put that deep colour on trees in the
first three weeks of September. Retuning those windows and giving the tint a place belongs to
its own change, not to the erosion boundary.

### The policy this boundary carries, and the policy it does not

The same document describes the boundary asking the mod's policy what belongs "using the
mod's species weights, stage distribution and genetics", and then says in the next sentence
that "what the policy decides is the subject of vegetation-succession.md; the boundary layer
only has to make sure the answer is the mod's".

This change builds the mechanism and carries the one part of the policy that can be sourced
today. The species weights exist, audited against the installed biome files. Genetics does
not exist at all, and the same document puts the boundary layer first precisely because
everything else waits on it. Stage distribution is the part that belongs to succession: the
only numbers for it are the jumbo, XL and XXL shares in `vegetation-succession.md`, which
that document labels a baseline needing a trunk census before anything is derived from it,
and applying them would mean growing a young erosion forest up into a mature size mixture,
which is recovery rather than composition.

So stage is left alone here, and the boundary is built so that adding stage to the policy
later is a change to what the policy returns, not to how the pass works.

### The proximity scan is kept

The document asks whether the hourly scan still earns its place once the boundary settles
squares as they load, and this is the decision. It is kept. With correction turned off it is
the only route by which any tree gets taken over, and it covers trees in areas loaded before
the mod was installed. Removing it would silently drop both cases. Revisit it when the
management change reworks adoption properly.

## Risks / Trade-offs

- **The pass runs on every square of every chunk load and cannot be switched off at the
  source.** → Measure before building on it. Layer the early exit so the common cases cost
  one call. Keep the deferred queue as a designed fallback rather than an improvisation.

- **The bin grows without bound as a player explores.** → Hoist the season computation out of
  the per object loop. Accept that the bin is proportional to explored forest; this is
  inherent to taking squares off erosion, since a tree cannot be off erosion and unmanaged at
  the same time. Measure the hourly tick over a heavily explored save before shipping.

- **Correction is irreversible per square.** → Once a tree is renamed, erosion has
  relinquished the square and cannot be made to take it back. Turning the setting off stops
  further correction and cannot undo what is done. This is stated in the spec and must be
  stated in the setting's own description.

- **A world played before this change ends up mixed.** → Trees the proximity scan already
  adopted are named and will be skipped, so they keep whatever species erosion gave them,
  while their neighbours get corrected. Correcting them too would mean rerolling trees a
  player has watched grow. Accept the mix and say so in the release notes.

- **A corrected tree never grows under stock growth, and a player may read that as a bug.** →
  It follows from the mod owning the square outright, and the base game's per square ceiling
  is unreadable so it cannot be emulated. Say it plainly in the correction setting's
  description rather than leaving it to be discovered.

- **Rerolling every tree is visible on ground a player already knows.** → This was chosen
  deliberately over correcting only out-of-pool species, because leaving in-pool trees alone
  reproduces erosion's proportions rather than the biome's. The setting exists for players who
  do not want it.

- **Losing both the object bin and the tree's name would reroll a corrected forest.** → The
  settle record is the bin and the fast path is the name, so a square is only re-examined
  when both are gone. Erosion cannot reclaim it either way, since the cleared category data
  persists in the square, but the pass would roll a fresh species and the forest would change
  around a returning player. The reload check in the verification list exists specifically to
  catch this.

- **Correction runs inside chunk loading, and that is the untested part.** → `LoadGridsquare`
  fires from within `IsoChunk.doLoadGridsquare`, so `newLuaObjectOnSquare`, `setSprite` and
  `RecalcAllWithNeighbours` all run while the chunk is still being built. Nothing in the
  bytecode says that is unsafe and nothing says it is safe either. If it misbehaves, the
  remedy is the deferred queue that the cost measurement made unnecessary: keep the tree test
  in the handler and drain corrections on a timer instead. This is the first thing to watch
  for in game.

- **The unplaced claim can still stack a tree on a corrected square.** → Out of scope and
  recorded in `docs/future/tree-management-and-genetics.md`. A square with no object has
  nothing to rename, and `ErosionCategory$Data` is not exposed, so lua cannot see the claim.
  The in-game check for it is in this change's verification list even though the fix is not.

- **`LoadGridsquare` on a dedicated server is assumed, not observed.** → The server maintains
  the world and loads its own chunks, so the event should fire there. Verify on a dedicated
  server before shipping, because the whole change is server side.

## Migration Plan

No save migration and no data format change. An existing save picks up correction the next
time each area is loaded, and areas never visited again are never corrected. Rolling back is
uninstalling the mod, which leaves corrected trees standing as ordinary trees on squares
erosion has already relinquished.

## Open Questions

Both questions this design opened have been answered by the measurement above. The zone weight
cache and the deferred queue are not needed, and neither answer changed a requirement.

The one thing still unobserved is the layer 2 early exit, which the spike could not exercise
because it corrects nothing. It is picked up by the reload check in group 6.
