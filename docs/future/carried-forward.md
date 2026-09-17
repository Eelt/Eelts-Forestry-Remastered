# Carried forward to later changes

What is still unclaimed, and what shipped without ever being watched work. Nothing under
"Still open" is implemented; the "Shipped but unverified" section is the exception and says so.
It is recorded here so that the follow-up work starts from what was already decided rather
than re-deriving it.

The vanilla behaviour it rests on is in
[b42-tree-matrix.md](../reference/b42-tree-matrix.md). Section links below point into that
document.

## Still open

- **Propagule items for the eight deciduous species** are not started. None of them has any
  propagule item in vanilla, so growing one from seed needs `Eelt_` samaras, haws, drupes,
  pods and nutlets to exist first, with icons and world models. See the
  [per-species propagule check](../reference/b42-tree-matrix.md#per-species-propagule-check)
  for what each species would need. The item by item design, the art each one needs and which
  vanilla meshes can cover it are in [propagule-items.md](propagule-items.md). Until they
  exist those eight are planted from a sapling, which is what `add-tree-planting` shipped.

- **American Holly still gets no cone.** It is a broadleaf and bears drupes, so a cone would
  be wrong however much the model looks like a conifer. Expect that to be reported as a bug,
  since Canadian Hemlock now drops cones and the visually similar tree next to it does not.

## Settled elsewhere

Five things that used to be carried forward here have shipped, and are described in the
reference documents and the accepted specs rather than planned in this one.

- **Tree growth**, in `add-tree-growth`. A tree grows on its own elapsed time through all
  eight stages, controlled by `EeltsForestryRemastered.TreeGrowth` and
  `EeltsForestryRemastered.TreeGrowthTimeMultiplier`. The growth setting chooses which trees
  grow rather than how large they get, and there is no separate ceiling option: every tree it
  allows to grow runs to the largest size.

- **The Canadian Hemlock cone drop**, in `fix-conifer-cone-drops`, controlled by
  `EeltsForestryRemastered.FixConiferConeDrops`. Trees felled by a vehicle or by fire remain
  uncorrected, because they do not route through the chopping action.

- **The erosion boundary layer**, in `add-erosion-boundary-layer`. Vanilla cannot be stopped
  from choosing a wild tree's species, but it chooses once per square and renaming the tree
  takes that square off erosion for good, so the mod overwrites the choice on `LoadGridsquare`
  and owns the square from then on. Controlled by
  `EeltsForestryRemastered.CorrectForestComposition`. The behaviour is described in
  `openspec/specs/forest-composition/`.

- **The foliage year**, in `retune-foliage-seasons`. A tree the mod owns runs bare, spring
  foliage, summer green, an early fall look and a deep fall look, timed for Kentucky rather than
  for the season boundary nearest to hand, with each tree changing a little before or after its
  neighbours. `EeltsForestryRemastered.StaggerTreeSeasons` switches between that and the base
  game's own timing. Described in `openspec/specs/tree-seasons/`.

- **Planting**, in `add-tree-planting`. Saplings, pine cones and holly berries plant, gated on
  a digging tool and on having watched the tape. Species inheritance, the forage zone
  fallback, the holly berry's poison state and the acorn's fate are all recorded in
  [what this means for propagation](../reference/b42-tree-matrix.md#what-this-means-for-propagation),
  [the holly berry](../reference/b42-tree-matrix.md#the-holly-berry-and-why-it-is-the-chosen-propagule)
  and [the acorn is unreachable](../reference/b42-tree-matrix.md#the-acorn-is-unreachable).

## Shipped but unverified

Things that work by construction, or in single player, and have never been observed doing
their job. They are listed here rather than left in an archived task list so that a later
change knows to check them.

### From `add-erosion-boundary-layer`

Species correction itself is verified. Three surveys on 2026-09-12 found no tree that was the
wrong species for its own square, Acidic Forest returned 443 Virginia Pine on 443 PHForest
squares, the same survey point returned identical counts either side of a save and reload, and
650000 squares produced no error. What follows is what nobody has watched.

- **The bin under a long game.** Correction takes a tree for every square a player walks past,
  and the growth system iterates all of them hourly. The count reached 10247 in a few hours of
  play and grows with exploration. Nobody has timed the hourly tick against a large bin, and
  the ceiling is unknown. This is the scaling risk the change was designed around and it is
  still open.
- **A dedicated server.** The pass is entirely server side and has only ever run in single
  player. Whether `LoadGridsquare` fires on a dedicated server at all is an assumption, as is
  whether corrected sprites reach clients and whether two players loading the same ground
  correct each square once rather than twice.
- **The other erosion categories.** Correction is supposed to touch trees and nothing else.
  Grass, groundcover, ferns, bushes, street and wall erosion have not been checked in a
  corrected area, and street and wall erosion should still run normally there.
- **Erosion speed and erosion days.** Correction has not been run against a raised erosion
  speed, a positive erosion days setting, a negative one, or a world with erosion switched off.
- **Recovery from a lost bin.** The settle record is the global object bin and the fast path is
  the tree's name. A reload keeps the pair intact, which is proven, but nobody has deleted the
  bin to confirm a corrected forest recovers rather than rerolling into fresh species.
- **The unplaced claim.** Erosion can claim a square and place its tree months later, and a
  square with no object has nothing to rename. The pass cannot see the claim. Needs a fresh
  world and months of elapsed time to observe.
- **Chopping an unadopted erosion tree.** Whether erosion clears its category data rather than
  regrowing the tree is read from bytecode only.

### From `retune-foliage-seasons`

The mod's own foliage year is verified end to end. All five looks were watched in order across a
full simulated year: bare through mid March, spring foliage from 26 March, summer green from 30
April, the early fall look on 8 October, the deep look on 15 to 29 October, bare on 5 November.
Evergreens never change, nothing drifted species or size across eleven repeatedly inspected
squares, and a save played without the mod took the new foliage as soon as the mod was added.

- **How faithfully the unstaggered rule copies vanilla.** With the stagger setting switched off
  the mod is supposed to show what an unmodded tree shows. It reproduces the defect, a Dogwood
  wore the tint on 4 July, but the date may be up to two weeks early. The rule splits summer at
  its midpoint, which on the measured 142 day season falls between 17 June and 2 July depending
  on the square, while `b42-tree-matrix.md` quotes about 2 July from an assumed 100 day summer
  running 13 May to 21 August. Settling it needs a mod-owned tree compared against a genuinely
  unadopted one of the same species, on the same day, with time running rather than jumping.
- **An unadopted Redmaple showed deep autumn colour on 15 October**, where the unstaggered rule
  says vanilla should already be bare. The likely explanation is that erosion only refreshes its
  own objects on its internal timer, so a debug date jump leaves them showing a stale sprite, but
  that is a guess. The same side-by-side test would settle it, and it is the reason that test has
  to let time run rather than jump.

Both only affect the non-default path. With the setting on, which is the default, the timing is
the mod's own and is confirmed.

### From `add-tree-planting`

Three things work by construction and by single player testing.

- **The tape appearing in loot.** `EeltsForestryRemastered_Distributions.lua` adds a
  `Base.VHS_Home` on `OnFillContainer` at 1 in 260 across five room types and five container
  types, and stamps the guide onto it. The lookup half is proven, since the console has never
  printed its "could not find" warning, so the mod is holding a real `MediaData`. The insert
  half has not been watched. With `RequireTreePlantingTape` on by default, this is the only
  route to planting, so if it does not fire the feature is unreachable at default settings.
- **The multiplayer unlock.** The tape grant runs server side and pushes the flag to the owning
  client through a server command. Confirmed in single player, where both halves run in one
  process. Never run against a dedicated server, so it is unknown whether the flag reaches the
  right client and only that client.
- **The multiplayer plant path.** Planting sends a client command that the server revalidates
  before building the tree. Single player skips the hop entirely and calls the builder
  directly, so the command path itself has never executed.

Loot distribution for VHS tapes is out of scope. The 1 in 260 rate was accepted rather than
tuned, and no vanilla distribution table is touched: the mod adds an item on
`OnFillContainer` and leaves `SuburbsDistributions` and `ProceduralDistributions` alone.

## Tape language flagged for later

The tape is `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]`, category `Home-VHS`, item
display name "Home VHS: Tree Planting Guide", title "Tree Planting Guide". It has
`spawning = 0`, so the media system never assigns it to a tape. `add-tree-planting` works
around that by putting the recording onto `Base.VHS_Home` copies it spawns itself, rather
than editing the entry.

Line 11, `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39`, is where the planting unlock hangs and is
the only line now claimed:

> Step firmly on the earth around the base of the tree when you fill the soil back in.

The remaining lines describe mechanics that are not in scope. The candidates they imply are
listed after the table.

| Line | Text | Mechanic implied |
|---|---|---|
| 5 | "If starting from seed, plant in a small pot, and transplant to bigger pots as your tree grows." | Pot tiers and transplanting |
| 6 | "Potted trees can be planted at any time, but bare root stock can only be planted in winter." | Seasonal restriction on bare-root planting |
| 7 | "Ensure the soil is not saturated or your tree's roots may rot." | Soil moisture and root rot failure |
| 8 | "Remove surrounding grass or plants if they will overshadow your tree..." | Clearing the square before planting |
| 9 | "... then dig a hole wider than the rootball, and three times deeper." | A digging step with a shovel |
| 10 | "Plant your tree at the same depth in the ground as it was in your pot." | Planting depth |
| 12 | "Any air pockets in the soil around the roots will greatly harm its chances." | Survival chance modifier |
| 13, 14 | "Leave an adequate distance around your trees, five to ten yards... depending on how high the tree will grow." | Minimum spacing scaled by target size |
| 15 | "Plant well away from nearby structures and power lines..." | Proximity restriction |
| 16, 17 | "... and remember to plant the right trees in the right place. Use the local species as a guide to what thrives and what doesn't." | Species suited to the forage zone, which planting now uses for unmarked propagules only |
| 18 | "Mark your trees if they're not visible from a distance..." | Marker or stake object |
| 19, 20 | "... and protect them from rabbits, deer or livestock... with adequate piping or fencing." | Animal damage and fencing |

### Candidate additions

Low priority, and none of it thought through. This is a list of things the tape describes that
the mod does not do, kept so the ideas are not lost, not a plan and not a commitment. Anything
here would need scoping from scratch before it meant anything.

- Pot tiers, and transplanting a tree up through them as it grows.
- Bare root stock plantable only in winter, potted stock plantable at any time.
- Soil moisture, and roots rotting in ground that is too wet.
- Clearing grass and plants off a square before a tree will take.
- A digging step, with the hole sized against the rootball rather than fixed.
- Planting depth, matching the depth the tree grew at before.
- Air pockets left in the backfill reducing a tree's chance of surviving.
- Minimum spacing between trees, scaled by the size the species reaches.
- A proximity restriction near buildings and power lines.
- A marker or stake object for a tree too small to see from a distance.
- Animal damage from rabbits, deer and livestock, and fencing or piping against it.

Half of one line is already done. Lines 16 and 17, on planting the right species for the place,
are what `zoneSpecies` covers, but only for a propagule carrying no species of its own; nothing
stops a player planting a marked propagule somewhere its species would never grow.
