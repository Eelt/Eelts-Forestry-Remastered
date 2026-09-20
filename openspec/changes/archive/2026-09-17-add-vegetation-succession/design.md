# Design

## Context

See `proposal.md` for motivation. What shapes the approach is what already exists.

`add-erosion-boundary-layer` established the ownership mechanism and paid for its
measurement. The mod subscribes to the lua `LoadGridsquare` event, which fires for every
square of every chunk load, and the early exit there costs 0.15 microseconds a square over
600000 squares. A tree it renames is off vanilla erosion for good, and the settle record is
the growth system's own global object bin rather than new storage.

Two constraints from that work carry straight over. The event gives no once per square
guarantee, so anything built on it has to know what it has already done. And whatever runs in
the common case governs whether the feature is affordable at all, because the event cannot be
switched off at the source.

The scoping document is `docs/future/vegetation-succession.md`. It is authoritative on intent
and this design does not contradict it. Where it left a number open, the census below fills it.

## Goals / Non-Goals

**Goals:**

- One ownership mechanism for the whole ladder, not a separate trick per rung.
- Persistent state proportional to what the player disturbed, not to the area of the map.
- Recovery driven by elapsed world time with no per square tick.
- Crowding limits whose ordering between zones is measured rather than preferred.
- A cost profile on chunk load that is cheapest on the ground players cross most.

**Non-Goals:**

- Reproducing vanilla's own vegetation placement. Nothing here has to agree with what
  worldgen or erosion would have done; both are out of the picture once a square is taken.
- A per square simulation. Nothing is ticked for an unloaded square.
- Exposing succession state to other mods. It is internal.

## The census, and what it settles

`docs/future/vegetation-succession.md` says the density ordering between forage zones is a
gameplay preference and that a trunk census on a fresh map is needed before any limit can be
called vanilla derived. That census was run against the installed files instead of in game,
and covers the whole map rather than a sample.

Method. `media/maps/Muldraugh, KY/` holds 4065 cells. Each cell has a `*.lotheader` naming the
tiles it uses and a `world_*.lotpack` holding, per chunk, the tile indices on each square.
`LOTP` files carry 1024 chunk offsets, each chunk 8 by 8 squares, giving a 256 by 256 cell.
Alongside them, `maps/biomemap_*.png` is a 256 by 256 palette image whose grey value is the
pixel `media/lua/server/metazones/BiomeMapConfig.lua` maps to a biome and a forage zone. A
square counts as carrying a tree when one of its tiles has the `tree` property in the shipped
`*.tiles.txt` definitions, which is the same property the tree matrix already uses for size
stages. The census read all 266403840 squares. Orientation was checked by transposing the zone
lookup, which put trees on open water and in town centres, so the row major reading is the
right one.

Slots, not trunks. What the map holds is the placement the map authors made, in legacy
`vegetation_trees_01` and `jumbo_tree_01` sprites. `WorldGenChunk.replaceSquare` swaps each one
for a feature of the mapped biome, and `WorldGenTile.getBiomeTile` retries smaller sizes and
can fail, so the realised trunk count is at or below the slot count. Comparing the in game
survey of 443 trees over an 81 by 81 area of Acidic Forest against the 95.3 slots per thousand
below gives about 71 percent realisation. The ordering is what this establishes; the absolute
numbers are a magnitude, not a target.

| Forage zone | Squares on the map | Tree slots per 1000 | Bush slots per 1000 |
|---|---|---|---|
| Deep Forest | 130297120 | 223.3 | 1.1 |
| Birch Forest | 6756859 | 192.9 | 11.2 |
| Organic Forest | 36386549 | 184.8 | 14.3 |
| Farmland Forest | 2843412 | 129.8 | 10.8 |
| Primary Forest | 12261678 | 100.1 | 9.7 |
| Acidic Forest | 24669016 | 95.3 | 3.8 |
| Managed Forestry | 4841333 | 88.7 | 17.2 |
| Birch Mixed Forest | 10284131 | 75.9 | 10.5 |
| Farm | 80030 | 33.7 | 10.6 |
| Trailer Park | 86622 | 10.2 | 8.2 |
| Town | 7084652 | 6.2 | 5.4 |
| Farmland | 12904431 | 0.9 | 0.3 |
| Forest | 204315 | 2.1 | 4.0 |

Four results follow, and all four change something.

The ordering is not the one the scoping document guessed. Deep Forest is densest, which it
predicted. But Organic Forest is near the top rather than in the middle, Primary Forest sits
mid table alongside Acidic Forest, and Birch Mixed Forest is the sparsest of the real forests
despite Birch Forest being second densest. Ceilings follow this table.

Plain `Forest` is not a forest. It is 204315 squares, 0.077 percent of the map, and the biome
map gives it `clay_shore` and `clay_lake`. It carries 2.1 tree slots per thousand, which is
lake and stream edge. Both biomes define no TREE, BUSH or PLANT features at all and both use
the `no_tree` subbiome, so vanilla itself declares the zone treeless. Giving it the Organic
Forest species mixture is right, because those are the trees around it, but giving it the
Organic Forest ceiling would put a dense wood on every shoreline. Species pool and ceiling are
separate inputs in this design, which is what lets both be answered correctly.

The eligibility test settles it a second time without being asked to. `clay_shore` replaces its
ground with `features.GROUND.clay`, whose four sprites are exactly the ones
`ISShovelGroundCursor.GetDirtGravelSand` reports as clay rather than dirt, so those squares are
already refused. The pool and the ceiling are belt and braces over a rule that would have held
anyway.

The authored forage zones in `objects.lua` are dead in B42.
`media/lua/server/metazones/metazoneHandler.lua`, `doMapZones`, skips every object whose type
is `Vegitation`, `DeepForest`, `Forest`, `TownZone`, `Farm`, `FarmLand` or `TrailerPark`, so
the 1666 authored `Forest` rectangles covering 11255093 squares never register as zones. Every
zone the mod reads comes from the biome map. This also closes two entries the composition audit
left open: `Vegitation` is commented out of the biome map and skipped from `objects.lua`, so it
exists by neither route, and the same is true of `PHMixForest`. Their `zoneSpecies` entries are
harmless but unreachable.

Deep Forest has no procedural branch on this map. `BiomeMapConfig.lua` maps pixel 96 to
`$random` and pixel 255 to `primary_forest`, and the census found pixel 96 on zero squares.
Every Deep Forest square is the authored branch, so the audit's percentages describe all of it
and the combined estimate it asked for is not needed.

One further result is not about density. Tree slots are heavily clumped: 58.5 percent of Deep
Forest tree squares have all eight neighbours also carrying a tree, and the mean count within
three squares is 33 of a possible 48. The map authors painted slabs, and the spacing a player
sees comes from worldgen refusing footprints inside those slabs, not from the template. So the
census supports a density ceiling and does not support a minimum spacing. The spacing number
below is mod tuning and is labelled as such.

## Decisions

### Ownership is the same rename, for every rung

`zombie/erosion/obj/ErosionObj` is the shared object wrapper behind all four nature categories,
and it is the class carrying the `name` that `getObject` matches on, with a null result making
`updateObj` call `clearCatModData`. The rename that takes a tree square off erosion is
therefore not a tree mechanism, it is an object mechanism, and it releases a grass or bush
square the same way.

So succession does not need a second trick. Everything it places carries a mod name, and the
square is off erosion from that moment.

Alternative considered: `disableErosion`. Rejected for the same reasons as before. It gates
every category on the square rather than vegetation alone, it persists in the save, and lua
cannot undo it, so an uninstalled mod would leave those squares inert permanently.

### Persist the clearing time per square, not per chunk

The scoping document proposes one timestamp per chunk and flags a partial cut inside one chunk
as the case to check first. Per square is chosen instead.

A record is written only when the mod observes a square being cleared, so the cost is
proportional to what the player actually cut, not to the map. A clear cut of a fifty by fifty
field writes two and a half thousand numbers, which is the same order as the tree objects the
player just destroyed to make it. `IsoGridSquare` carries `getModData`, which persists with the
chunk, so no new storage is introduced and nothing has to be reconciled with chunk boundaries.

Per chunk would have been smaller but wrong at exactly the boundary the document worried
about: felling half a chunk would restart recovery on the half still standing.

Alternative considered: a chunk keyed table in the mod's own global data. Rejected because it
needs its own persistence, its own eviction and its own answer to the partial cut, in exchange
for saving a few thousand integers.

### A square the mod never saw cleared recovers on the world's age

A square with no record is treated as bare since the world began. Without this, ground that was
already open when the world started never recovers, and the abandoned fields that make up
12904431 squares of the map stay bare forever, which is the vanilla behaviour this change
exists to remove.

It has one consequence worth stating plainly. Adding the mod to a world already years old
applies those years at once, so fields jump forward rather than starting from bare. The setting
that restricts recovery to recorded squares is the escape hatch for a player who does not want
that, and the crowding ceiling bounds how much can appear either way.

### The understory is real objects, decided by a pure function

Grass, groundcover, ferns and bushes have no identity, so nothing about them is stored: which
rung a square is on is computed from the square's position, the time since it was cleared and
the local density, the same shape erosion uses with `square.rand(x, y, n)` plus the time axis
erosion lacks.

The object placed is the whole of the state. It carries a mod name, which both takes the square
off erosion and lets the next pass recognise what it put there, so re-evaluating a square is
idempotent and reloading cannot stack two plants on one square.

Alternative considered: storing the rung per square. Rejected because it is the one thing that
does not scale, and because the function has to exist anyway to decide the first placement.

### Three questions per square, not one ladder position

A square is asked three things in order: should it carry a bush, should it carry tall grass or
ferns, and otherwise it carries grass. Trees are the fourth and separate question, answered by
the crowding ceiling. Grass ends up on every square that can grow anything, because that is
what a forest floor looks like; tall grass and ferns take about 30 percent off the top, and
bushes about 5, which is sparing without being rare.

The first build got this wrong in a way that was only visible in a screenshot. It treated the
ladder position as what the square carries, so once an area passed the bush day every eligible
square held a bush, and 1184 of 1216 squares in one sample were carpeted.

Each share fades in across its own window rather than switching on, so an area thickens
instead of arriving whole.

### The position hash has to be scrambled, not just spread

A hash linear in x and y gives equal values along straight lines, and the first build used
one. In game that produced bushes in visible diagonal rows. Kahlua has no bitwise operators
and the game's modulo breaks past 32 bits, which rules out the usual mixing, so the hash is a
shuffled 256 entry permutation table indexed twice, which is Perlin's own trick and costs two
table lookups. Different salts give the independent draws for eagerness, for which of the
three a square carries, and for which sprite it uses.

### Every square is considered, and the cost of that is accepted

Measured on a mature world the pass costs 18.2 microseconds a square, against 1.05 on a young
one. Of 500000 squares, 220602 carried growth already, 95671 were settled and 92172 were
ineligible, and each paid for an object walk on every chunk load to reach the answer it reached
last time. Almost none had ever been cleared by anyone.

Looking at untouched ground less often was tried and rejected. Vanilla nominates every square
for its own categories rather than a sample of them, and the fields that were already open when
the world began are exactly the ground a player expects to see grow over. Recovering only what
the mod watched being cut would miss the common case entirely.

So the work stands and the setting is the escape hatch: regrowing untouched ground is on by
default, and turning it off rejects the rest of the world before anything is read from the
square, which is both a smaller world change and a cheaper pass.

Two things were cheapened without changing what is considered. Deciding whether a sprite is
vanilla vegetation took up to four `string.sub` calls per object, each allocating, and is now
one lookup in a table built out at load. And the ladder gate runs before the ground test, so a
square that has earned nothing yet costs one comparison.

### Trees stay in the global object bin

An established tree is created at stage 0 and adopted as it is created, exactly as a planted
one is, with `planted` false. It then uses the existing elapsed time grower with no new
machinery.

This is the same bin the boundary layer fills, and growing it is the known scaling risk carried
forward from that change. Succession adds to it, so the risk is inherited rather than created,
and the ceiling is what bounds it: a recovering area cannot add trees indefinitely.

### Chunk load decides, the hourly tick maintains

Catch up happens on `LoadGridsquare`, because that is where a square arrives carrying however
much elapsed time it has accrued while unloaded, and because it is the only event that sees
every square. The ordering of tests matches the boundary layer's: cheapest and most frequent
first, so ground that was never cleared is rejected before anything is read from mod data.

A square already loaded when it crosses a rung boundary is handled by the hourly tick, which
already walks the bin and already reads the season once per tick.

### Species from the zone, biased by what stands nearby

Selection uses `zoneWeightsAt` and `rollFromWeights`, which `add-erosion-boundary-layer`
already split out of item specific selection for exactly this purpose. Trees within a bounded
radius add to the weight of their own species, bounded so that a species with no weight in the
zone cannot establish from one neighbour alone.

The parent is chosen after the species, from eligible trees of that species nearby. It
contributes nothing today beyond having been chosen, because there is no trait to inherit yet.
It exists now so that inherited timing attaches to a slot that is already in the right place.

A zone with no weights grows understory and no tree, which is the rule correction already
follows and for the same reason.

### Pacing is taken from vanilla's own tree clock, in days rather than by reading it

`ErosionMain.EveryTenMinutes` calls `mainTimer`, so `ticks` advances once per ten in-game
minutes and 144 of them make a day. `eTicks` is then `ticks / tickUnit` with `tickUnit` 144 at
Normal erosion speed, or `ticks / 144 / erosionDays * 100` when the `ErosionDays` sandbox
option is set above zero. Both come to the same thing at the defaults: `eTicks` counts whole
in-game days, and `ErosionDays` of 100 is the default pace rather than a change to it. More
generally `eTicks` is a percentage of the erosion period, so every timing below is a fraction
of it rather than a fixed date.

A wild tree appears when `eTicks` reaches `spawnTime`, which is `130 - eValue`, and a square
bears a tree at all only when `maxStage`, `1 + floor((eValue - 50) / 17)`, is at least 0, which
needs `eValue` of 33 or more. With `eValue` topping out near 100 that puts vanilla's first wild
trees on day 30 and its last on day 97.

Succession's defaults reproduce that window: grass from day 3, groundcover and ferns from day
10, bushes from day 21, and the tree rung opening at day 30 with a per square offset from the
same position noise the understory rungs use, carrying the slowest squares to about day 90. One
multiplier scales the whole ladder, which is the shape `TreeGrowthTimeMultiplier` already has.

Alternative considered: reading `ErosionDays` and expressing the ladder as a fraction of the
erosion period, which is what vanilla does. Rejected. It couples recovery to a system the mod
has deliberately taken these squares away from, and it makes the pace of the mod's own feature
depend on a setting a player changes for an unrelated reason. Absolute days with a multiplier
are the same dial the growth setting already offers, and a player who moves `ErosionDays` can
move this one to match.

### Eligibility is the planting test, and the ladder can climb through it

Succession uses `isPlantableSquare` rather than a rule of its own, so a player never watches a
tree establish somewhere they would be refused one. Crowding is the only thing layered on top.

The test has to let a recovering square keep climbing after the mod has put something on it,
which was worth checking rather than assuming. `IsoGridSquare.isFree` rejects a square for
moving objects, `solid`, `solidtrans`, the `tree` object type, `solidfloor` and stairs, and
neither `e_newgrass_1_*` nor `f_bushes_1_*` nor `vegetation_foliage_01_*` carries any of them.
A square that has grown grass is still eligible for a bush, and then for a tree.

Two deliberate differences from vanilla's own placement rules follow from reusing the planting
test, and both are accepted rather than worked around. It is stricter about ground: only dirt
qualifies, so sand, gravel and clay never recover, where the biome `placements` lists refuse
sand but allow clay. It is looser about `blends_natural_01_64`, `69`, `70` and `71`, the bare
shovelled sprites, which vanilla excludes from plants and bushes while allowing for trees.
Succession exists to recover disturbed ground, so growing grass back over a shovelled square is
the behaviour to want.

### Ceilings are a neighbourhood count, spacing is tuning

The ceiling is a maximum number of trees within a radius, taken from the census ordering and
scaled by the realisation factor, plus a minimum spacing. The neighbourhood count is what the
census supports. The spacing is not, since the map's own slots are slabs, so it is chosen for
how a recovered wood should look and exposed to a sandbox multiplier along with the count.

The ceiling is keyed on the worldgen biome rather than on the forage zone, which the census
table is grouped by. A zone's own slot count says how the land was being used, not what it can
carry: Farmland measures 0.9 slots per thousand because it is under the plough, but the biome
map gives it `farmmix_forest`, the same biome as Farmland Forest at 129.8. Reading the ceiling
off the zone would leave an abandoned field permanently unable to become woodland, which is
the case succession exists to fix. Reading it off the biome gives Farm, Farmland and Farmland
Forest one ceiling, and leaves Town, Trailer Park and plain Forest at zero on vanilla's own
evidence, since `townhouse`, `clay_shore` and `clay_lake` all take the `no_tree` subbiome.

Two further limits came out of building it. Establishment is attempted on one day in five per
square rather than on every chunk load, because the neighbourhood scan is the only expensive
thing in the pass and a crowded square would otherwise repeat it every time its chunk loads.
And a square whose neighbourhood is more than a quarter unloaded refuses to establish, because
it cannot see the trees in the chunk next door and would read a boundary as empty ground. That
is the boundary treatment the scoping document left open.

Existing trees count toward crowding whether or not they are eligible parents. Recovery stops
when the limit is reached and never removes a tree to get under it, so an existing stand denser
than its ceiling is simply left alone.

## Risks / Trade-offs

- The global object bin under a long game. This was already the boundary layer's open risk, at
  10247 objects after a few hours of play, and succession adds every established tree to the
  same bin and iterates it hourly. Mitigation: the ceiling bounds how many trees recovery can
  add to an area, and the bin cost is measured against a large bin as part of this change
  rather than carried forward again.
- Cost on chunk load. Succession has to consider more squares than correction did, because
  correction rejected everything without a tree and succession is interested in ground that has
  none. Mitigation: measure first, as the boundary layer did, and order the tests so that a
  square with no clearing record and no recovering neighbour is rejected before any mod data is
  read.
- The unplaced claim, now met more often. Erosion can claim a square and place its object
  months later, and succession puts objects on exactly the bare squares such a claim sits on.
  Mitigation: none that closes it. The square is renamed the moment the mod places something,
  which is the strongest available position, and a reconciliation sweep for a square holding
  two objects remains the fallback it already was.
- Save size from per square clearing times. A player who clear cuts repeatedly writes a number
  on every square they cut. Mitigation: one integer per disturbed square, written once, on
  ground the player has already spent hours changing.
- Erosion's grass category is active rather than one shot. Trees are decided once, but
  `NatureGeneric` and `NatureBush` cycle their own objects on their own timer, so an understory
  square is contested until the rename lands. Mitigation: place and rename in the same
  operation, and treat a square carrying an unnamed vanilla object as not yet owned.
- The census measures slots rather than trunks. Ceilings derived from it could sit above what
  vanilla ground actually carries. Mitigation: the realisation factor from the Acidic Forest
  survey, and a sandbox multiplier so a player can move every ceiling together.
- A world that already ran for years jumps forward when the mod is added. Mitigation: the
  setting that restricts recovery to recorded squares, described in terms of this case.

## Migration Plan

Nothing has to be rewritten. A square with no clearing record is read as bare since the world
began, which is the same answer an existing save gives without any migration step, and trees
that already exist are already in the bin.

Rollback is turning the setting off. That stops further recovery and leaves what was placed,
because a square cannot be given back to erosion once it has been taken. This is the same
one way property correction already has and is described the same way in the setting's text.

## Open Questions

- Stage durations and the total recovery span. The scoping document calls all of it tuning and
  none of it derived from vanilla, and nothing in the specs depends on the numbers.
- The radius and strength of the local species bias, and the eligible parent sizes.
- Whether groundcover and ferns want to be one rung or two. They are one rung here, which the
  ladder in the spec allows either way.
- Whether the realisation factor measured in Acidic Forest holds in the other zones. It scales
  every ceiling equally today, and a per zone factor would need one in game count per zone.
