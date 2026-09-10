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

Three things that used to be carried forward here have shipped, and are now described in the
reference documents rather than planned in this one.

- **Tree growth**, in `add-tree-growth`. A tree grows on its own elapsed time through all
  eight stages, controlled by `EeltsForestryRemastered.TreeGrowth` and
  `EeltsForestryRemastered.TreeGrowthTimeMultiplier`. The growth setting chooses which trees
  grow rather than how large they get, and there is no separate ceiling option: every tree it
  allows to grow runs to the largest size.

- **The Canadian Hemlock cone drop**, in `fix-conifer-cone-drops`, controlled by
  `EeltsForestryRemastered.FixConiferConeDrops`. Trees felled by a vehicle or by fire remain
  uncorrected, because they do not route through the chopping action.

- **Planting**, in `add-tree-planting`. Saplings, pine cones and holly berries plant, gated on
  a digging tool and on having watched the tape. Species inheritance, the forage zone
  fallback, the holly berry's poison state and the acorn's fate are all recorded in
  [what this means for propagation](../reference/b42-tree-matrix.md#what-this-means-for-propagation),
  [the holly berry](../reference/b42-tree-matrix.md#the-holly-berry-and-why-it-is-the-chosen-propagule)
  and [the acorn is unreachable](../reference/b42-tree-matrix.md#the-acorn-is-unreachable).

## Shipped but unverified

Three things in `add-tree-planting` work by construction and by single player testing, and
have never been observed doing their job. They are listed here rather than left in an archived
task list so that a later change knows to check them.

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

The remaining lines describe mechanics that are not in scope. Each is a candidate for later
work.

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
