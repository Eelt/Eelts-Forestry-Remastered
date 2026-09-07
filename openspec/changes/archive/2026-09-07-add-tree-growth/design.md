## Context

See `proposal.md` for motivation and `docs/reference/b42-tree-matrix.md` for the tree facts. The
constraints that shape the approach:

- No vanilla file or table may be edited, and vanilla erosion actively manages the same
  trees we want to grow. Coexistence is the central problem, not stage arithmetic.
- Growth state has to outlive chunk unload, so it needs real persistence rather than object
  mod data.
- There is no test suite. Everything has to reduce to something observable by placing a
  tree and waiting.
- The sandbox option and translation plumbing is already proven by `fix-conifer-cone-drops`
  and is reused unchanged.

## Goals / Non-Goals

**Goals:**

- A tree advances stages on its own elapsed time, persists across save and load, and is
  consistent in multiplayer.
- Selecting stock behaviour leaves vanilla completely alone.
- Adopted trees keep looking right all year, including autumn colour and snow.

**Non-Goals:**

- Reproducing erosion's seasonal display timing. It puts autumn colour on trees in early
  July, which is wrong for the setting; see the autumn decision below.
- Any notion of tree health, water, death or species change.
- Multi-square occupancy. A tree is one object on one square at every stage.

## Decisions

### Build on `SGlobalObjectSystem`, modelled on `SFarmingSystem`

`SGlobalObjects.registerSystem(name)` gives a persistent, square-keyed object store written
to `gos_<name>.bin` in the save. `SFarmingSystem` is the working reference for every part
of the pattern this change needs: `setModDataKeys` for system-level fields,
`setObjectModDataKeys` for per-object fields, `RegisterSystemClass` to wire the lifecycle
events, and a client-side `CGlobalObjectSystem` counterpart paired through `sendCommand`
and `OnServerCommand`.

Rejected: storing growth state in the `IsoTree`'s own mod data. It would not survive the
object being pooled on chunk unload, and it gives no server-authoritative tick.

### Tick on `EveryHours`, accumulate hours

Each tree stores the hour count at which it entered its current stage, so advancing is a
comparison rather than a countdown, which is what makes it survive unload cleanly.

`EveryTenMinutes` and `EveryHours` are both in-game time, driven by `GameTime.getTimeOfDay`,
not real time. At the default day length ten in-game minutes is roughly twenty five real
seconds. `SFarmingSystem` subscribes to `EveryTenMinutes` and then discards five of every
six calls to get an hourly tick; this change subscribes to `EveryHours` directly instead,
which is the same cadence for a sixth of the calls and removes the need to track the
previous hour.

Rejected: driving growth from erosion's `eTicks`. That counter is exactly what makes
vanilla growth wrong, being global and capped.

### Take ownership of a tree by renaming it

This is the load-bearing decision. Erosion finds the tree it manages on a square through
`ErosionObj.getObject`, which matches on `IsoObject:getName()` against the species display
name such as `"Canadian Hemlock"`. In `ErosionCategory.updateObj`, when that lookup returns
null erosion calls `clearCatModData` and stops managing the square altogether.

So renaming an adopted tree makes erosion relinquish it permanently, at the next point
erosion would otherwise have touched it. Without that, erosion reasserts its own stage
whenever its computed stage or the season changes, which is several times a year, and the
tree visibly snaps back.

The cost is that `getName()` no longer reports the species. That is acceptable because the
sprite name still identifies the species and is what all of this mod's code uses; the
matrix records both. `IsoTree.getObjectName()` returns the hardcoded `"Tree"` and is
unaffected.

Rejected alternatives: setting erosion's `doNothing` flag, which is Java-side with no lua
access; and re-applying our stage after each erosion revert, which produces visible
flicker and still loses the seasonal overlay.

`NEEDS IN-GAME CHECK`: that renaming makes erosion relinquish the tree and does not disturb
anything else, particularly save and load.

### Own the seasonal appearance too

Taking a tree from erosion means taking its seasonal appearance. The mechanism is not a
single sprite swap, and the design has to match what erosion actually does:

- The **base** sprite is always the season position 0 sprite for the stage. Indices come
  straight from the matrix: `stage` for stages 0 to 3, `0` and `1` on the JUMBO sheet for
  stages 4 and 5, and `0` on the JUMBOXL and JUMBOXXL sheets for stages 6 and 7.
- The **seasonal** look is a child sprite layered into the object's `attachedAnimSprite`,
  not a replacement base sprite. Its index uses the same per-stage formula at the season's
  position, `season * 4 + stage` for stages 0 to 3 and so on.
- **Snow needs no work.** `ErosionIceQueen` maps a base sprite to its winter counterpart at
  the `IsoSprite` level and swaps them globally on `setSnow`. Because adopted trees reuse
  the same base sprites, snow keeps working with nothing from us. Confirmed applicable to
  evergreens too: `iceQueen.addSprite` runs before the `if (!seasonal) continue` guard in
  `NatureTrees.init`.
- **The inherited overlay must be cleared.** Setting a new base sprite without clearing
  `attachedAnimSprite` leaves the pre-adoption season overlay attached, and it renders as a
  second, bare tree behind the real one. `ErosionObj.setStageObject` calls
  `attachedAnimSprite.clear()` before setting, and the growth system has to do the same.
  Observed in testing on 2026-09-07.

### Autumn follows the season boundary, staggered, not vanilla's split summer

Adopted trees deliberately do **not** reproduce vanilla's seasonal display timing, because
that timing is wrong for the setting.

`ErosionCategory.currentSeason` reads a `seasonDisp` table, and summer is marked
`split = true` with `season2 = 3`. Once a square's `seasonDay` passes the halfway point
adjusted by its magic number, the tree displays season 3, an autumnal set, while the world
is still in summer. Summer runs from roughly 13 May to 21 August, so trees begin showing
autumn colour around **2 July**. That is far too early for Knox County, Kentucky.

The season boundaries themselves are fine. `hottestDay` is 22 June and `summerEndDay` is
that plus `floor(40 + 40 * summerMod)`, where `summerMod = 0.02 * tempMax` and `tempMax`
defaults to 25, giving about **21 August** and varying roughly 1 August to 10 September by
year. Autumn then runs to 22 December.

So this change uses the autumn season boundary and ignores the split-summer rule. Adopted
trees stay green until autumn proper, then turn.

Staggering is kept, because turning a whole forest on one day looks worse than turning it
early. Erosion staggers with a per-square magic number; this change derives an equivalent
stable value from the tree's coordinates and spreads the change across the first part of the
autumn window. Same effect, no dependency on erosion's per-square data.

Note that `ClimateManager` is not a separate source of truth here: `getClimateManager()`
returns a season object that is literally `ErosionMain.getInstance().getSeasons()`, so the
boundaries above are the ones any approach would use.

The accepted consequence is that an adopted tree and an unadopted neighbour will disagree
during July and early August, the adopted one still green. That is the intended direction of
the difference.

### Adopt by periodic scan near loaded players, only below the ceiling

A tree is adopted when a player is near it and it is below the ceiling. Its starting stage
is read from its current sprite, so a part-grown tree continues rather than restarting.
Trees at or above the ceiling are never adopted, which leaves the authored map's jumbo trees
untouched and keeps the object count down.

`SGlobalObjectSystem:OnChunkLoaded` cannot be used for this, despite the name. Its own
comment states it fires only for chunks that already contain objects of that system, and its
body only removes orphans. On a fresh save no tree would ever be adopted.

There is no usable placement hook either. `OnObjectAdded` is triggered exclusively from lua,
in player-driven paths such as traps, rain barrels and moveables; no Java class raises it.
Every wild tree arrives through Java instead: the authored map through `CellLoader`,
worldgen through `WorldGenChunk`, and respawns through `NatureTrees.validateSpawn`. None of
them is observable from lua.

`Events.LoadGridsquare` was rejected as the alternative: vanilla uses it exactly once, in a
debug file, and it fires for every square the game loads, which is the cost the global object
system was designed to avoid.

So adoption piggybacks on the growth tick, scanning squares within a bounded radius of each
loaded player. Cost is proportional to player count rather than world size, and it still
satisfies the spec, which requires only that adoption happen when the area is loaded and that
unvisited areas stay untouched.

Note for the planting change: a player-planted tree will fire `OnObjectAdded`, so the
enum's player-planted value can be implemented with no scanning at all.

### Two sandbox options, formats already proven

```
option EeltsForestryRemastered.TreeGrowth
{
    type = enum,
    numValues = 3,
    default = 3,
    page = EeltsForestryRemastered,
    translation = EeltsForestryRemastered_TreeGrowth,
    valueTranslation = EeltsForestryRemastered_TreeGrowth_Values,
}

option EeltsForestryRemastered.TreeGrowthTimeMultiplier
{
    type = double,
    default = 1.0,
    min = 0.1,
    max = 20.0,
    page = EeltsForestryRemastered,
    translation = EeltsForestryRemastered_TreeGrowthTimeMultiplier,
}
```

Enum values are 1-based: 1 stock behaviour, 2 player-planted only, 3 all growth. Default 3.
Value labels are `Sandbox_<valueTranslation>_option1` through `_option3`, confirmed against
Skill Recovery Journal.

The multiplier scales elapsed time, so larger means slower. At 1.0 the baseline is roughly
three in-game months from stage 0 to stage 7, which is seven transitions, so about thirteen
in-game days per stage. Naming it a time multiplier rather than a speed multiplier is
deliberate: it is unambiguous in the tooltip.

Both options are read live through `getSandboxOptions():getOptionByName(...)`, never through
`SandboxVars`. That is the correction forced by `fix-conifer-cone-drops`: the in-game
sandbox editor never calls `toLua()`, so `SandboxVars` goes stale.

### Setting stock behaviour has to mean nothing happens

When the enum is stock behaviour the system adopts nothing and touches nothing. Trees
already adopted in that save stay at whatever stage they reached and simply stop advancing;
they are not handed back to erosion, because renaming already made erosion drop them and
there is no supported way to give them back.

That asymmetry is worth stating plainly: turning the setting off stops further change but
does not undo what already happened.

### The game's lua overflows `%` at 32 bits

The stagger hash originally multiplied coordinates by large primes before taking a modulo,
which is the ordinary way to write one. In the game it returned 8419185853 instead of a
value under 1, so every tree's turn threshold became astronomically large and no tree ever
left the pre-turn branch.

The operands reached 1.06e13. The game returned exactly `a - 2147483647 * 1000`, so its lua
truncates to `Integer.MAX_VALUE` somewhere inside `%`. Any modulo whose left operand can
exceed `2^31 - 1` is unsafe.

The fix reduces both coordinates before multiplying, keeping the largest intermediate at
about 252000. Verified uniform across 201201 coordinates, with adjacent trees still landing
far apart.

Two things worth carrying forward. Validating with `luajit -bl` catches syntax but **not**
this: LuaJIT computes the same expression correctly, so the local check passed while the
game was wrong. And a symptom this odd was only findable by printing the intermediate values;
three rounds of reasoning about the formula got nowhere.

### Most trees on a fresh map are not adoptable

The authored map only ever places the `_jumbo`, `_jumbo_xl` and `_jumbo_xxl` features, so
nearly every tree in a new world already sits at stage 4 to 7. Stage 7 trees are skipped
outright because they have nowhere to grow, and the rest have at most a few stages left.

Observed on 2026-09-07: standing outdoors in a fresh Custom Sandbox world, a forced tick
reported only two adopted trees, and a hand-picked Dogwood was correctly refused because it
was already stage 7.

The consequence is that this change has little visible effect on a brand new map. Growth
applies mainly to erosion respawns, which accumulate slowly, and it will matter far more
once planting exists and the player is creating stage 0 trees deliberately. That is a
limitation of the world, not of the system, and no code change would fix it without
shrinking trees the map deliberately placed at full size.

### The overlay lags by up to one in-game hour

`refreshOverlay` runs on the hourly tick, so a tree keeps last season's overlay until the
next in-game hour rather than changing the instant the season does. In normal play that is
invisible. It is obvious when the date is moved by hand, as the debug harness does: a tree
observed on 2026-09-07 still wore its green summer overlay immediately after the season was
forced to Winter, and corrected itself once an hour elapsed.

Refreshing more often was rejected. The season only changes a handful of times a year, and
an hourly walk of every adopted tree is already the cheapest cadence that keeps the tree list
in one place.

## Risks / Trade-offs

- The rename lever is inferred from decompiled control flow and is unverified in game. If
  erosion does not relinquish, the whole approach needs rethinking. Mitigation: it is the
  first task, and it is observable by watching a renamed tree across a season change.
- Adopting every undersized tree in every loaded chunk could mean a large object count in
  forest areas. Mitigation: only trees below the ceiling are adopted, and the tick is a
  comparison per object every ten minutes. If it proves heavy, adoption can be narrowed.
- Growth changes tree size, which changes log yield and line of sight everywhere it
  happens. That is the intended feature, but it is a large blast radius on an existing
  save. Mitigation: the enum defaults can be set to stock behaviour by the player, and the
  effect is gradual and confined to visited areas.
- Seasonal staggering is lost for adopted trees, so a partly adopted forest will turn over
  unevenly. Accepted and documented above.
- Multiplayer is designed from the vanilla pattern but, as with the last change, will not
  be tested. Recorded as a known gap.

## Migration Plan

Additive. A save without `gos_Eelt_TreeGrowth.bin` simply starts adopting trees as chunks
load. Rolling back means removing the lua and the two options; adopted trees keep their
current sprite and stop changing, and their renamed state persists harmlessly.
