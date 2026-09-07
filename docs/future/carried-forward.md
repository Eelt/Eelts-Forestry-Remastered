# Carried forward to later changes

Decisions that were settled while the reference documents were being produced, and the
tape language that is still unclaimed. **None of it is implemented.** It is recorded here so
that the follow-up work starts from what was already decided rather than re-deriving it.

The vanilla behaviour every one of these rests on is in
[b42-tree-matrix.md](../reference/b42-tree-matrix.md). Section links below point into that
document.

## Decisions

- **VHS unlock.** Wrap `ISRadioInteractions`'s `checkPlayer` and grant the recipe when the
  line with translation key `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39` plays.
  `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]` is not mutated, which keeps the
  no-vanilla-mutation rule intact. Appending an `RCP=` code to that line's `codes` would
  have been smaller and would have reused vanilla's once-per-player `isKnownMediaLine`
  guard, so the wrapper has to provide that guard itself.
- **Maximum growable size** is a configuration dropdown, not a constant. At least three
  options: stock erosion behaviour, player-planted trees may reach JUMBOXXL, and all growth
  may reach JUMBOXXL. Default is all growth may reach JUMBOXXL.
- **Requiring the tape** before planting is a configuration option, defaulting to on.
- **Cone species** is stamped onto `Base.Pinecone`'s modData when harvested from a known
  tree. Cones from vanilla `dropWood` and from foraging stay untagged and fall back to a
  roll weighted by the forage zone they are planted in.
- **American Holly's propagule is `Base.HollyBerry`.** The drop already exists in vanilla
  and is gated to Autumn and Winter at `1 in roll * 2` per log, which makes it the only
  seasonal propagule in the tree set and a mechanic worth keeping rather than smoothing away.
  A sapling graft should remain the fast route, with the berry as the slow one, reflecting
  holly's real seed dormancy. The poison state, the seasonal window and the eat-or-plant
  ambiguity all need resolving; see
  [the holly berry](../reference/b42-tree-matrix.md#the-holly-berry-and-why-it-is-the-chosen-propagule).

  American Holly still gets no cone. It is a broadleaf and bears drupes, so a cone would be
  wrong however much the model looks like a conifer. Expect that to be reported as a bug
  once Canadian Hemlock starts dropping cones and the visually similar tree next to it does
  not.
- **Propagule items for the eight deciduous species** are flagged for future work and not
  started. None of them has any propagule item in vanilla, so growing one from seed needs
  `Eelt_` samaras, haws, drupes, pods and nutlets to exist first, with icons and world
  models. See the [per-species propagule check](../reference/b42-tree-matrix.md#per-species-propagule-check) for what each
  species would need. The item by item design, the art each one needs and which vanilla
  meshes can cover it are in [propagule-items.md](propagule-items.md). That work is out of
  scope for the planting change, which ships on the sapling graft, the cone and the berry.
- **The acorn's fate** is unresolved. There is no oak species in B42.20, so restoring an
  acorn drop has no correct target. The options are to leave `Base.Acorn` foraging-only,
  which is where it stands today, to attach it to a deciduous species as a stand-in, or to
  fold it into the propagule items above. See
  [the acorn is unreachable](../reference/b42-tree-matrix.md#the-acorn-is-unreachable).

The Canadian Hemlock cone drop is no longer carried forward; it shipped as the
`fix-conifer-cone-drops` change and is controlled by
`EeltsForestryRemastered.FixConiferConeDrops`. Trees felled by a vehicle or by fire remain
uncorrected, because they do not route through the chopping action.

Tree growth is no longer carried forward either. The `add-tree-growth` change gives a tree
its own elapsed-time growth through all eight stages, controlled by
`EeltsForestryRemastered.TreeGrowth` and `EeltsForestryRemastered.TreeGrowthTimeMultiplier`.
It takes a tree away from erosion by renaming it, which is what makes erosion relinquish the
square, and then drives both stage and seasonal overlay itself. It deliberately skips overlay
position 4, so an adopted tree stays green through July and turns only once autumn begins.
The visible consequence is that an adopted tree and an unadopted neighbour disagree during
July and early August.

## Tape language flagged for later

The tape is `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]`, category `Home-VHS`, item
display name "Home VHS: Tree Planting Guide", title "Tree Planting Guide". It has
`spawning = 0`, so it does not spawn in loot by any of the media system's own rules.

Line 11, `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39`, currently `codes = "FRM+1"`, is where
the planting unlock hangs:

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
| 16, 17 | "... and remember to plant the right trees in the right place. Use the local species as a guide to what thrives and what doesn't." | Species suited to the forage zone, which the zone tables above already support |
| 18 | "Mark your trees if they're not visible from a distance..." | Marker or stake object |
| 19, 20 | "... and protect them from rabbits, deer or livestock... with adequate piping or fencing." | Animal damage and fencing |
