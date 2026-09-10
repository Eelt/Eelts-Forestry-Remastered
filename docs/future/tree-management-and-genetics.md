# Tree management and genetics

Future scope for taking trees off vanilla erosion, managing them independently of growth,
and giving them a genetic identity that survives grafting and reseeding. Apart from the two
corrected farm species weights, none of the changes described here is implemented.

The erosion question this work was originally blocked on is answered. Lua cannot disable or
replace `NatureTrees`, but it does not need to: erosion decides a square once and renaming a
tree takes that square off it permanently. The boundary layer below is what remains of the
problem.

Vegetation recovering over time, tree establishment and crowding ceilings moved out to
[vegetation-succession.md](vegetation-succession.md), which is the larger piece of work and
depends on the boundary layer here. The species audit further down feeds both documents.

The existing seed item work remains in [propagule-items.md](propagule-items.md). New
deciduous propagule assets are separate work, but should use the inheritance rules here
when they are added.

## Current behaviour and its limits

Paths in this section are relative to `42.20/media/lua/`.

| Source | Current behaviour | Consequence |
|---|---|---|
| `server/EeltsForestryRemastered_TreeGrowthSystem.lua`, `adoptTree` | Identifies an existing tree, preserves its species and stage, and skips stage 7 | Adoption cannot correct which species erosion establishes. A wild tree first encountered at maximum size never receives the mod's seasonal handling |
| Same file, `mayAdoptWildTrees` and `everyHour` | Wild discovery requires all-trees growth; stock mode exits before either growth or overlay updates | Seasonal correction is coupled to growth settings |
| Same file, `adoptNearPlayers` | Scans a radius of 30 squares around each player hourly | Overlapping scans are harmless for existing adoption checks, but cannot become independent establishment rolls without multiplying spawn opportunities |
| `server/EeltsForestryRemastered_TreeGrowthObject.lua`, `displaySeason` | Computes a stable stagger from coordinates and maps it into autumn progress | Timing belongs to the location, so a graft planted elsewhere does not inherit its parent's timing |
| `shared/EeltsForestryRemastered_Propagules.lua` | Stores `Eelt_Species` on items and selects unmarked items' species using `zoneSpecies` | Species weights can be shared with regeneration, but no genetic trait is stored or transferred |
| `server/EeltsForestryRemastered_TreeDrops.lua` | Captures species before chopping destroys and pools the tree, then stamps new drops | Genetics must be captured at the same point, including from trees not previously managed |
| `server/EeltsForestryRemastered_TreePlanting.lua`, `plantTree` | Creates stage 0 and calls `adoptPlantedTree` | Natural establishment needs a creation path that leaves `planted` false |

Trees adopted before reaching stage 7 remain managed afterward. The seasonal defect affects
trees skipped at discovery, rather than every tree that reaches maximum size.

The current seasonal calculation uses one coordinate-derived value `s` in the range
`0 <= s < 1`. During autumn it keeps summer foliage until progress reaches `s * 0.35`,
then keeps autumn foliage until `0.75 + s * 0.2`. Spring and early summer bypass this split.
The intended windows are therefore the first 0 to 35 percent of autumn for colouring and
75 to 95 percent for leaf fall. The existing discrete calculation stops just short of the
upper endpoints.

These are fractions of the game's autumn, deliberately preserving green summer foliage
instead of vanilla's July tint. They are not fixed month-and-day dates, and the genetics
work must retain that distinction.

## Vanilla evidence

The installed B42.20 reference is the Steam installation documented as 42.20.4, revision
`b0bbce05d5`. During this exploration, the cached class files underlying the CFR reads of
`NatureTrees`, `ErosionMain` and `ErosionWorld` were compared byte for byte with the installed
`projectzomboid.jar` and matched. The biome Lua files were read directly from that install.

Paths below are relative to `Project Zomboid.app/Contents/Java/`.

| Source | Finding |
|---|---|
| `zombie/erosion/categories/NatureTrees.class`, `validateSpawn` | Chooses species from `soilRef` using erosion soil and location randomness. It does not read the forage zone |
| `zombie/erosion/ErosionMain.class`, `initChunk` and `initGridSquare` | Derives soil from moisture and mineral noise and copies chunk soil to the square |
| `media/lua/server/metazones/BiomeMapConfig.lua` | Maps `PHForest` to `ph_forest` |
| `media/lua/server/WorldGen/biomes/map/ph_forest.lua` | Its tree features are exclusively Virginia Pine, with jumbo, XL and XXL probabilities of 0.1, 0.4 and 0.2 |
| `zombie/erosion/categories/NatureTrees.class`, `update` | Growth depends on global erosion ticks and the category's spawn time and maximum stage |
| `zombie/erosion/ErosionMain.class` | Erosion speed scales the tick interval; positive erosion days overrides the schedule, and negative erosion days stops progression |
| `zombie/erosion/ErosionWorld.class`, `validateSpawn` | Calls existing-object replacement before spawn validation, and stops at the first category in a region that claims the square |
| `zombie/erosion/ErosionMain.class`, `loadGridsquare` | Guards `validateSpawn` behind `if (!square.init)`, so a square's tree decision is taken once and never revisited |
| `zombie/Lua/LuaManager$Exposer.class`, `shouldExpose` | A `HashSet.contains` against an explicit list. Only `ErosionConfig`, `ErosionMain` and `ErosionSeason` are reachable from lua |
| `zombie/iso/IsoChunk.class`, `doLoadGridsquare` | Runs `ErosionMain.LoadGridsquare` before firing the lua `LoadGridsquare` event on the same square |
| `zombie/erosion/obj/ErosionObj.class`, `getObject` | Matches its object by `getName()`, and a null result makes `updateObj` call `clearCatModData` |

Erosion can spawn Virginia Pine, but several soil pools exclude it. The problem is the
independence of erosion's species selection from biome composition, not a universal absence
of Pine. The complete pools and stage limits are in the
[tree matrix](../reference/b42-tree-matrix.md#erosion-respawn).

The [Lua notes](../reference/b42-lua-notes.md#lua-sees-three-erosion-classes-and-no-more)
now carry the erosion findings in full. Three of them govern this document. Lua cannot name
`NatureTrees` or the category list, so the category can be neither disabled nor replaced.
No lua runs before erosion on chunk load, so its placement cannot be intercepted. Renaming a
tree makes erosion relinquish the square permanently, and since `validateSpawn` never runs
again there, it can never be reclaimed.

Together these turn the problem around. Erosion is not an ongoing competitor to be
suppressed; it is a single throwaway decision per square that the mod can overwrite once,
on the `LoadGridsquare` event it already receives.

## Initial forest composition audit

The estimates below come from the installed game's authored-map placement definitions,
not visual counts. The audit follows `BiomeMapConfig.lua` to `WorldGen/biomes/map/*.lua`,
then resolves every referenced tree feature through `WorldGen/features/tree/*.lua` to its
actual sprite species. Player-facing zone names come from
`media/lua/shared/Translate/EN/IG_UI.json`, under `IGUI_SearchMode_Zone_Names_*`.

The supplied [map viewer](https://pzmap.org/) and
[tree thumbnails](https://github.com/Paddlefruit/ProjectZomboid_BlenderAssets/tree/main/Thumbnails)
were inspected as available references, but no visual map census was performed. Direct
sprite resolution avoids confusing similarly shaped trees and ties the result to the
installed build. Map sampling with the forage overlay remains useful for testing realised
composition against this baseline.

### Method and limits

Each referenced tree feature resolves to one species. Sum its selection mass across jumbo,
XL and XXL variants, then divide by the mass of tree outcomes only. Bushes, rocks and grass
are excluded from the denominator. These percentages describe species relative to other
trees, not tree coverage per ground square or canopy area.

Fresh CFR reads of the installed JAR's `WorldGenChunk`, `WorldGenReader` and `WorldGenTile`
establish two qualifications. `genMapSquare` replaces existing tree placements according
to the mapped biome, with protected sprites and placement restrictions. `getBiomeTile`
filters features by footprint and retries smaller target sizes when placement fails.
Consequently, the table estimates an unrestricted feature selection, before footprint
failures, boundaries, protected map objects and subsequent erosion affect the visible
forest. A jumbo variant choice is not an additional tree count.

`WorldGenTile.findFeature` draws in `[0, 1)` and accumulates
`featureWeight / postfilterTotal * prefilterTotal`. With no size filtering, this is the raw
weight, not a normalised weight. A total below one permits no selection; a total above one
clips the tail of the list. `WorldGenReader` appends features in Lua table iteration order;
the shipped `J2SEPlatform.newTable` uses a `LinkedHashMap`, and `KahluaTableImpl.iterator`
uses its key order. This makes the declared order relevant for the farmland mixture.

### Estimated shares among trees

Names in the composition column abbreviate Canadian Hemlock, American Holly, Virginia Pine,
Cockspur Hawthorn, Carolina Silverbell, Eastern Redbud and American Linden. Percentages are
rounded and can sum to 99.9 or 100.1.

| Forage biome | Zone key and map biome | Estimated initial selection share | Comparison with current mod |
|---|---|---|---|
| Acidic Forest | `PHForest`, `ph_forest` | Pine 100% | Matches |
| Birch Forest | `BirchForest`, `birch_forest` | Riverbirch 100% | Matches |
| Primary Forest | `PRForest`, `pr_forest` | Redbud 33.3%, Hawthorn 33.3%, Silverbell 33.3% | Matches |
| Birch Mixed Forest | `BirchMixForest`, `birchmix_forest` | Riverbirch 44.4%, Redmaple 20%, Dogwood 18.9%, Linden 16.7% | Matches |
| Organic Forest | `OrganicForest`, `organic_forest` | Dogwood 35%, Redmaple 35%, Linden 30% | Matches |
| Managed Forestry | `FarmForest`, `farm_forest` | Silverbell 40%, Redmaple 35%, Yellowwood 25% | Matches since the 2026-09-09 correction |
| Farmland Forest and Farmland | `FarmMixForest`, `Farm`, `FarmLand`, all `farmmix_forest` | Redmaple 35%, Dogwood 22%, Silverbell 20%, Yellowwood 13%, Linden 10% | Mod normalises to Redmaple 33.3%, Dogwood 21%, Silverbell 19%, Linden 14.3%, Yellowwood 12.4% since the 2026-09-09 correction |
| Deep Forest, authored branch | `DeepForest`, `primary_forest`, pixel 255 | Hemlock 36.8%, Holly 36.8%, Redmaple 10.5%, Dogwood 10.5%, Linden 5.3% | Matches this branch only |

The existing `zoneSpecies` entries match the feature-name sums for all ten defined tree
mixtures. Resolving sprites reveals that the names conceal an error in two mixtures.

### Yellowwood and farmland discrepancies

Vanilla's `features/tree/yellowwood_jumbo_xl.lua` actually contains
`e_carolinasilverbellJUMBOXL_1_0`. Its jumbo and XXL variants resolve to Yellowwood. Counting
the XL feature as Yellowwood therefore overstates Yellowwood and understates Silverbell.

In Managed Forestry, 0.10 of the declared mass moves from Yellowwood to Silverbell. The
result is Yellowwood 0.25, Silverbell 0.40 and Redmaple 0.35.

In the farmland mixture, the same feature carries 0.05. Resolving it gives Yellowwood
0.13, Silverbell 0.20, Redmaple 0.35, Dogwood 0.22 and Linden 0.15, totalling 1.05.
Normalising those corrected masses gives 12.4%, 19%, 33.3%, 21% and 14.3% respectively.

Both corrections were applied to `zoneSpecies` on 2026-09-09. `rollSpecies` divides by the
summed weight of the species a given item may become, not by the table total, so leaving
the farmland entries summing to 1.05 is intended and the normalised shares above are what
an unmarked sapling actually rolls.

That is not the unrestricted vanilla selection. The last feature is Linden XXL with
weight 0.05, after the cumulative mass has already reached one. It has effectively no
selection interval, apart from negligible floating-point endpoint effects. The two earlier
Linden variants contribute 0.10, producing the 13/20/35/22/10 mixture in the table. Size
filtering can alter those proportions, so this is a baseline rather than an exact census.

Retain the mod's normalisation for regeneration. Correcting the two mixtures for the actual
sprite species was the adjustment made; reproducing vanilla's cutoff is unnecessary.
Farmland Linden stays at 0.15 and the corrected total of 1.05 is normalised at roll time.
The unrestricted vanilla estimate remains useful as a comparison, not the target for an
accidental cutoff. Do not edit the vanilla Yellowwood feature as part of this work.

### Zones without a single supported estimate

- `PHMixForest` has a defined `phmix_forest` mixture: Pine 46%, Redmaple 23%, Linden 17.2%
  and Dogwood 13.8%. The mod matches it, but its entry in `BiomeMapConfig.lua` is commented
  out. Treat this as a compatibility fallback, not proof of an active vanilla map region.
- `Vegitation` similarly has a defined 100% Redbud mixture and a commented-out map entry.
- `DeepForest` also maps pixel 96 to `$random`. `genMapSquare` routes that branch through
  procedural generation. The primary-forest percentages cannot describe every square
  carrying the Deep Forest forage label. A combined estimate needs the distribution of
  those branches and procedural biomes in the sampled area.
- Plain `Forest` maps to `clay_shore` and `clay_lake` in this configuration. Those files
  define ground replacements, not a tree mixture. The mod has no `Forest` species entry.
  Its unmarked sapling fallback is uniform across all eleven eligible species; this is not
  evidence that the initial Forest composition is uniform. A map census is needed before
  assigning it a representative pool.
- Urban Area, Trailer Park and Road have no tree mixture in their mapped definitions.
  Existing decorative or preserved trees do not establish a biome-wide proportion from
  these tables alone.

The current planting selection also filters by item eligibility. These full mixtures apply
to an unmarked sapling, which can become any supported species. A pine cone filters to the
two conifers; a holly berry is fixed to Holly. Regeneration should use the full species
policy rather than inherit one item's filtered distribution.

These findings support retaining the other known biome weights. They do not establish
density limits: a 100% Pine share says which species the trees are, not how closely they
stand. The two farm mixtures are the only runtime weights this audit changed.

## Agreed scope

### Manage trees independently of growth

Every supported tree, including an already fully grown wild tree, must be eligible for
genetic identity and seasonal management. Maximum size stops size progression; it must
not prevent corrected foliage or inheritance from that tree.

Keep growth eligibility separate from management. Stock, planted-only and all-trees growth
remain growth choices. Seasonal correction gets independent sandbox controls, enabled by
default. The exact number and labels of those controls are not settled; separate colouring
and leaf-fall toggles are a possible refinement rather than an agreed requirement.

Changing seasonal settings must not reroll stored genetics. A later design must specify
how disabled correction displays vanilla seasons on a tree already owned by the mod.
Renaming currently makes erosion relinquish the tree, so simply stopping overlay updates
would leave stale foliage rather than restore vanilla behaviour.

### The erosion boundary layer

Every square enters the mod's world through vanilla erosion first, and lua cannot get ahead
of it. `IsoChunk.doLoadGridsquare` runs `ErosionMain.LoadGridsquare` and then fires the lua
`LoadGridsquare` event on the same square in the same loop iteration, so the mod always
arrives after erosion has placed whatever it placed.

That is survivable because erosion's decision is a one shot. `validateSpawn` sits behind an
`if (!square.init)` guard and `ErosionWorld.update` only ever revisits category data that
already exists. Handle a square once and it is settled for good.

The boundary layer therefore discards vanilla's decision rather than negotiating with it.
On first sight of a square, delete whatever erosion put there and ask the mod's own policy
what belongs, using the mod's species weights, stage distribution and genetics. Vanilla's
choice contributes nothing beyond having been the trigger. What the policy decides is the
subject of [vegetation-succession.md](vegetation-succession.md); the boundary layer only has
to make sure the answer is the mod's.

Adoption renames the tree, and the rename is what takes the square off erosion. Nothing
further is required. In particular `disableErosion` must not be used: it gates every erosion
category on the square rather than trees alone, it persists in the save, and lua cannot undo
it, so an uninstalled mod would leave those squares inert permanently.

Two constraints on the pass itself:

- `LoadGridsquare` fires on every chunk load, not only the first, so unlike erosion the pass
  gets no free once per square guarantee and must record which squares it has settled.
- The event fires for every square of every chunk load, so the early exit in the common case
  governs whether this is affordable at all. Establish that cost before building policy on
  top of it.

#### The unplaced claim problem

`NatureTrees.validateSpawn` claims a square immediately but sets `spawnTime` to
`130 - noiseMainInt`, and `update` places nothing until `eTicks` reaches it. A claimed square
can therefore sit visibly empty for a long stretch of a young world.

`ErosionObj.placeObject` does not check occupancy. Anything the mod puts on such a square
does not stop erosion adding its own tree on top when the tick finally arrives, and lua
cannot see the pending claim because `ErosionCategory$Data` is not exposed.

This is not only a future concern. The current planting feature can hit it today: plant on
bare ground early in a world and an erosion tree may appear on the same square months later.
Confirm the stacking in game before designing around it. A sweep that reconciles a square
holding two trees is the obvious fallback, but it is a cleanup rather than a fix.

### Inherited autumn timing

Store genetic metadata on trees and propagate it through plantable items. A sapling graft
copies its source tree's genetics exactly. A seed propagule receives a small variation
earlier or later than its parent, bounded by the fixed permitted range in every generation.
Moving or replanting an item must not replace its inherited timing with the destination's
coordinate calculation.

One normalised autumn trait controlling both colouring and leaf fall is the proposed
initial representation. Mapping it through the current two formulas preserves their
relationship and the existing autumn-relative windows. Independent traits and additional
genetic characteristics are outside this initial scope.

Assign each seed item's variation once, when the drop is created and stamped, and transfer
it unchanged during planting. Natural establishment assigns its offspring trait once when
the tree is created. Sampling within the valid neighbourhood of the parent is preferable
to clamping out-of-range rolls, which would accumulate values at the endpoints. Mutation
distribution and magnitude remain tuning work.

Existing trees and unmarked items need initial genetics. A proposed migration for existing
trees is to store their current coordinate-derived stagger once, preserving managed trees'
current timing. A tree encountered only during chopping must receive identity before drops
are generated, so all grafts from it agree. The initialisation policy for unmarked items
must be defined without rerolling on every attempted planting.

## Integration work for a proposal

Erosion ownership is settled and no longer blocks a proposal. Renaming is the mechanism,
the mod already does it, and no vanilla file is edited or shadowed.

The boundary layer is the first piece of work, because everything else waits on it.
Subscribe to `LoadGridsquare`, decide cheaply whether a square has already been settled, and
do nothing at all in the common case. Establish that cost before building policy on top of
it, and record which squares are settled since the event gives no once per square guarantee
of its own.

Tree management then needs separate decisions for identity, seasonal display and size
progression. Removing the stage-7 adoption guard alone does not remove the stock-mode
early return or planted-only discovery restriction. Seasonal-only ownership must also
preserve the selected growth behaviour rather than accidentally suppress stock growth.

Move the biome species policy out of item-specific selection so planting and
[succession](vegetation-succession.md) share it. The current `rollSpecies` fallback chooses
any eligible item species uniformly when no local match exists. That convenience for
planting an item is not automatically an appropriate policy for an unknown zone.

The global object system currently persists `tileset`, `stage`, `enteredHour`, `planted`
and `overlaySeason`. Its recovery path `stateFromIsoObject` reconstructs species and stage
from sprites, resets elapsed time and sets `planted` false. Genetics cannot be reconstructed
from a sprite. Define persistent tree metadata, global object storage and recovery together,
including preservation of direct planting provenance used by the new dropdown.

Extend the existing drop capture before destruction, not a lookup after the tree is pooled.
The present wrapper observes chopping only; vehicle and fire destruction remain separate
coverage gaps and must not be described as supporting inheritance without further work.

The planting action currently removes the item and sends coordinates and species, while
the server builder accepts only a square and tileset. Genetics requires a deliberate
transfer through this path. The server must resolve and validate authoritative item traits
before consumption rather than trust a newly supplied client trait table. Include item
metadata synchronisation, saved trees and late-joining clients in that design.

The hourly `adoptNearPlayers` scan is a discovery mechanism, not a dispersal radius. Once the
boundary layer settles squares as they load, decide whether the scan still earns its place
or whether it only covers trees that predate the mod being installed.

## Verification before shipping

- Find a fully grown wild deciduous tree and confirm corrected seasons under every growth
  mode, with seasonal correction enabled and disabled.
- Follow a managed tree to maximum size and confirm that its genetics and seasons persist.
- Plant multiple grafts from one tree at different coordinates and confirm matching timing
  within each year's autumn. Save and reload without changing the traits.
- Follow seed inheritance through repeated generations and confirm both variation and
  fixed bounds. Check endpoint parents and siblings separately.
- Confirm the boundary layer leaves no square carrying a species its local pool does not
  support, in known biome pools including PHForest.
- Revisit settled squares after several in-game months and confirm erosion has not
  reasserted a species or a stage on any of them.
- Watch a chopped erosion tree that the mod never adopted, and confirm whether erosion
  clears its category data rather than regrowing the tree. This is read from bytecode only.
- Plant on bare ground early in a fresh world and watch for an erosion tree appearing on the
  same square later. This is the unplaced claim case and has not been seen in game.
- Check erosion speed, erosion days, disabled erosion, overlapping players and area reloads.
  Confirm that street and wall erosion is untouched everywhere.
- Measure the boundary layer while loading unexplored chunks, and confirm the early exit
  keeps it off the frame budget.
- Verify item transfer and seasonal appearance in single player and on a dedicated server,
  including a late join and recovery from missing global object state.

The two farm species weights are the only runtime change made from this document, and no
in-game verification accompanies it. Mutation size and the boundary layer's cost remain
unresolved. The erosion mechanism no longer does.
