# B42 tree matrix

Reference for the trees Project Zomboid B42.20 ships. This describes vanilla behaviour
only; nothing here is something Eelt's Forestry Remastered adds or changes.

Target build: B42.20. Values were read on 2026-09-06 from the Steam install at
`Project Zomboid.app/Contents/Java/`, which reports version `42.20.4`, revision
`b0bbce05d5`. Java-side values come from CFR decompiles of the shipped
`projectzomboid.jar`.

Most of this is read straight out of the files and is stated flatly. Anything that is an
inference, or that has been checked in game, is tracked in
[Verification status](#verification-status). One claim there is still untested and is
marked `NEEDS IN-GAME CHECK` where it appears.

## How to re-check this

Each source file below backs a specific claim. On a version bump, walk the list rather
than re-deriving from scratch.

| Source | Backs |
|---|---|
| `zombie/erosion/categories/NatureTrees.class` | Species list and order, evergreen flags, stage to tileset mapping, seasonal sprite indices, the natural spawn stage cap, the `soilRef` table |
| `zombie/erosion/ErosionMain.class`, `ErosionConfig.class` | The global `eTicks` counter, `tickunit` of 144, the `erosionDays` and erosion speed sandbox settings |
| `zombie/erosion/obj/ErosionObj.class`, `ErosionObjSprites.class` | How an erosion tree becomes an `IsoTree`, how a stage resolves to a sprite |
| `zombie/iso/objects/IsoTree.class` | The `tree` property to size mapping, `LOGS_PER_SIZE`, the `dropWood` drop table |
| `zombie/core/random/RandInterface.class`, `RandAbstract.class` | `NextBool` semantics at and below zero |
| `media/tiledefinitions_erosion.tiles.txt` | Base tileset names, sheet sizes, `tree` property for sizes 1 to 4 |
| `media/jumbo_trees.tiles.txt` | JUMBO tilesets, `tree` property 5 and 6 |
| `media/jumbo_trees_big.tiles.txt` | JUMBOXL and JUMBOXXL tilesets, `tree` property 7 and 8 |
| `media/newtiledefinitions.tiles.txt` | Declared `vegetation_trees_01_*` sprite names |
| `media/lua/server/WorldGen/features/tree/*.lua` | Which sprites each worldgen feature places |
| `media/lua/server/WorldGen/biomes/map/*.lua` | Authored map biome tree lists and probabilities |
| `media/lua/server/WorldGen/biomes/worldgen/*.lua` | Procedural biome tree lists |
| `media/lua/server/metazones/BiomeMapConfig.lua` | Forage zone to biome mapping and pixel values |
| `media/lua/shared/Foraging/forageZones.lua` | Forage zone definitions and densities |
| `media/lua/shared/Foraging/Categories/Firewood.lua`, `WildPlants.lua` | Zone weights and months for cones, acorns and saplings |
| `media/scripts/generated/items/{normal,food,weapon}.txt` | The `Pinecone`, `Acorn` and `Sapling` item definitions |
| `media/lua/shared/Translate/EN/Recorded_Media.json` | The tape's English line text |

For anything that needs the tree to be looked at rather than read about, the visual
reference is [Paddlefruit's Blender asset library](https://github.com/Paddlefruit/ProjectZomboid_BlenderAssets),
which carries rendered thumbnails and meshes for all eleven species under `Thumbnails/` and
`Models/`. It is a third-party repository with no license stated, so treat it as a reference
to look at, not as a source of assets to reuse. Checked against the state of that repository
as of its 2026-07-23 update.

## Species

Eleven species, keyed by base erosion tileset. Order matches the `trees` array in
`NatureTrees`, and the index is that array position. The display name is what
`IsoObject:getName()` returns on an erosion-managed tree.

| # | Tileset key | Display name | Real species | Category | Propagation |
|---|---|---|---|---|---|
| 0 | `e_americanholly_1` | American Holly | *Ilex opaca* | Evergreen broadleaf | Sapling only; its berry is food and poison, not a seed |
| 1 | `e_canadianhemlock_1` | Canadian Hemlock | *Tsuga canadensis* | Conifer | Sapling only (see [cone test defects](#cone-test-defects)) |
| 2 | `e_virginiapine_1` | Virginia Pine | *Pinus virginiana* | Conifer | Cone, stage 3 and up only |
| 3 | `e_riverbirch_1` | Riverbirch | *Betula nigra* | Deciduous broadleaf | Sapling only |
| 4 | `e_cockspurhawthorn_1` | Cockspur Hawthorn | *Crataegus crus-galli* | Deciduous broadleaf | Sapling only |
| 5 | `e_dogwood_1` | Dogwood | *Cornus florida* | Deciduous broadleaf | Sapling only |
| 6 | `e_carolinasilverbell_1` | Carolina Silverbell | *Halesia carolina* | Deciduous broadleaf | Sapling only |
| 7 | `e_yellowwood_1` | Yellowwood | *Cladrastis kentukea* | Deciduous broadleaf | Sapling only |
| 8 | `e_easternredbud_1` | Eastern Redbud | *Cercis canadensis* | Deciduous broadleaf | Sapling only |
| 9 | `e_redmaple_1` | Redmaple | *Acer rubrum* | Deciduous broadleaf | Sapling only |
| 10 | `e_americanlinden_1` | American Linden | *Tilia americana* | Deciduous broadleaf | Sapling only |

Two display names, `Riverbirch` and `Redmaple`, are unspaced in vanilla. They are
reproduced verbatim above because they are what the game returns.

### Macro categories

`NatureTrees` carries a single boolean per species and no conifer flag. The constructor
parameter is named `seasonal` but is assigned to a field named `evergreen`, and the three
species passed `true` are American Holly, Canadian Hemlock and Virginia Pine. Everything
that flows from the flag, seasonal sprite sets and snow handling, keys off that.

The flag is not a conifer flag, and the game has no conifer concept anywhere. Of the three
evergreens only Canadian Hemlock and Virginia Pine are conifers. American Holly is an
evergreen broadleaf: it keeps its leaves, so vanilla treats it like the conifers for
sprites, but it bears drupes rather than cones and vanilla gives it a berry drop instead.

So the useful split is three ways, not two:

- Conifer: Virginia Pine, Canadian Hemlock
- Evergreen broadleaf: American Holly
- Deciduous broadleaf: the remaining eight

The closest thing vanilla has to a stated conifer grouping is the procedural
`pine_forest` and `light_pine_forest` biomes, which put Virginia Pine, Canadian Hemlock and
American Holly together at equal weight. That grouping is evergreen, not coniferous.

### The models disagree with the botany

Checked against the rendered models in
[Paddlefruit's Blender asset library](https://github.com/Paddlefruit/ProjectZomboid_BlenderAssets),
which mirrors the game's tree meshes.

American Holly is modelled as a dense conical evergreen with foliage to the ground and no
visible trunk. It reads as a fir or spruce, and it is arguably the most conifer-looking of
the three evergreens, more so than Canadian Hemlock or Virginia Pine, both of which show a
bare trunk at the base. There is no broadleaf character in the model at all: no visible
broad or spined leaves, no open habit. Real *Ilex opaca* looks nothing like it.

The eight deciduous species are unmistakably different: a rounded or spreading canopy on a
clear trunk, with visible broad leaves.

So the three axes disagree, and which one is correct depends on what the classification is
for:

| Axis | Conifer-like | Not conifer-like |
|---|---|---|
| `NatureTrees` evergreen flag | Holly, Hemlock, Pine | the other eight |
| Botany | Hemlock, Pine | Holly plus the other eight |
| Visual model | Holly, Hemlock, Pine | the other eight |

Only the botany separates American Holly out. Both the code flag and the art group it with
the conifers, and a player looking at one in game has no way to tell it is a broadleaf.
Anything player-facing should follow the art; anything about propagation should follow the
botany, because that is what the berry drop already does.

### Seasonal sprites

`NatureTrees.init` builds sprite names as `<tileset>_<sheetid>`. For stages 0 to 3,
`sheetid = season * 4 + stage`, where `season` runs 0 to 5 over the `snames` array
`{0, 5, 1, 2, 3, 4}`. Position 0 is the base sprite and position 1 is registered with
`ErosionIceQueen` as the snow variant. Positions 2 to 5 are set as child sprites only when
the species is not evergreen.

An evergreen species therefore uses sprite indices 0 to 7 only. A deciduous species is
addressed up to index 23.

Only indices 0 to 7 are ever used as the object's own sprite, and only those indices carry
a `tree` property. That is not a problem, because the base sprite is always the season 0
one. `NatureTrees.init` constructs every tree as
`new ErosionObj(objSpr, 60, 0.0f, 0.0f, true)`, where the last argument is `noSeasonBase`,
and both `createObject` and `setStageObject` resolve the base as
`getBase(stage, noSeasonBase ? 0 : season)`. Season positions 2 to 5 are registered with
`setChildSprite`, which ends up in `obj.attachedAnimSprite` and never passes through
`setSprite`, so `initTree` is not re-run for them. The snow variant is applied by
`ErosionIceQueen.setSnow` calling `IsoSprite.setSnowSprite` on the shared sprite, a
render-time swap that never touches the object either.

Size and log yield therefore do not drift with the season.

## Size stages

There are eight stages, 0 to 7. The `tree` property on the sprite is what actually drives
`IsoTree.initTree`, and a sprite with no `tree` property falls back to size 4. That
fallback does not trigger for erosion trees, which always take a sprite from indices 0 to 7;
see [seasonal sprites](#seasonal-sprites). It is a live concern for any sprite a mod assigns
by hand.

| Stage | `tree` | Tileset family | Footprint | Logs | Chop damage |
|---|---|---|---|---|---|
| 0 | 1 | `e_<species>_1` | 1x1 | 1 | 40 |
| 1 | 2 | `e_<species>_1` | 1x1 | 1 | 40 |
| 2 | 3 | `e_<species>_1` | 1x1 | 2 | 80 |
| 3 | 4 | `e_<species>_1` | 1x1 | 3 | 160 |
| 4 | 5 | `e_<species>JUMBO_1` | 2x2 | 4 | 240 |
| 5 | 6 | `e_<species>JUMBO_1` | 2x2 | 5 | 320 |
| 6 | 7 | `e_<species>JUMBOXL_1` | 3x3 | 6 | 400 |
| 7 | 8 | `e_<species>JUMBOXXL_1` | 5x5 | 8 | 560 |

Logs come from `IsoTree.LOGS_PER_SIZE`, which is `{1, 1, 2, 3, 4, 5, 6, 8}` indexed by
size minus one. Chop damage is `max((logYield - 1) * 80, 40)`, set in `initTree` and
returned by `getMaxHealth`.

All eleven species have all four tileset families present: eleven base sheets in
`tiledefinitions_erosion.tiles.txt`, eleven JUMBO in `jumbo_trees.tiles.txt`, and eleven
JUMBOXL plus eleven JUMBOXXL in `jumbo_trees_big.tiles.txt`. The two `e_stumps_JUMBOXL`
and `e_stumps_JUMBOXXL` sheets in that last file are stumps, not a twelfth species.

Every stage therefore has real art for every species. Nothing is missing at the sprite
level.

### Worldgen feature cross-reference

Worldgen feature names do not line up one to one with stages.

| Feature | Stages | Sprites used |
|---|---|---|
| `<species>_sapling` | 0 and 1 | base `_0`, `_1` |
| `<species>` | 2 and 3 | base `_2`, `_3` |
| `<species>_jumbo` | 4 and 5 | JUMBO `_0`, `_1` |
| `<species>_jumbo_xl` | 6 | JUMBOXL `_0` |
| `<species>_jumbo_xxl` | 7 | JUMBOXXL `_0` |

The separate `stumps` feature places `crafted_02_86` and is not a tree.

## What chopping a tree yields

`IsoTree.dropWood` runs on topple. `numPlanks` is the log yield from the table above and
`roll = min(6 - numPlanks, 4)`.

`Rand.NextBool(n)` is `Next(n) == 0`, and `Next(max)` returns `0` whenever `max <= 0`.
So every `NextBool` call with a non-positive argument returns true. At stage 6 `roll` is
`0` and at stage 7 it is `-2`, which makes every random drop on the biggest two stages
guaranteed rather than chance.

Combined with the `i > 2` guard inside the log loop, sapling yield is not monotonic:

| Stage | Logs | `roll` | Saplings | Large branches |
|---|---|---|---|---|
| 0 | 1 | 4 | 0 | 0 |
| 1 | 1 | 4 | 0 | 0 |
| 2 | 2 | 4 | 1 guaranteed | 0 |
| 3 | 3 | 3 | 0 | 0 |
| 4 | 4 | 2 | 0 | 0 |
| 5 | 5 | 1 | 1 guaranteed | 1 guaranteed |
| 6 | 6 | 0 | 2 guaranteed | 2 guaranteed |
| 7 | 8 | -2 | 4 guaranteed | 4 guaranteed |

Stage 2 gets its sapling from the explicit `numPlanks == 2` branch, which drops one
`Base.Sapling` and one `Base.Log`. Stages 3 and 4 are a dead zone: the log loop runs only
two and three times, so the `i > 2` guard never passes and no sapling can drop. Stage 0 and
stage 1 are indistinguishable in drops, since both yield one log and take the
`numPlanks == 1` branch, which drops a single `Base.TreeBranch2`.

`Base.Splinters` always drops. `Base.TreeBranch2` and `Base.Twigs` each roll once per log
in a trailing loop, so both are also guaranteed at stages 6 and 7.

### The species drops sit behind the same gate

The cone, acorn and holly berry lines all live inside the `numPlanks > 2` block, so they
require a log yield of at least 3, which is size 4 and therefore stage 3. Nothing below
stage 3 can drop a species item of any kind.

| Stage | Logs | Cone, acorn or berry possible |
|---|---|---|
| 0 to 2 | 1 to 2 | no |
| 3 and up | 3 and up | yes, once per log iteration |

For Virginia Pine the cone chance per iteration is `1 in roll`, so it is 1 in 3 at stage 3,
1 in 2 at stage 4, and guaranteed from stage 5 up where `roll` reaches 1 and then 0.

## Forage zones and natural spawning

### Zone to biome mapping

`media/lua/server/metazones/BiomeMapConfig.lua` maps a biome map pixel value to a forage
zone and a worldgen biome. This is the authoritative link between the two systems.

| Pixel | Biome | Forage zone |
|---|---|---|
| 0 | none | Water |
| 59 | `clay_shore` | Forest |
| 64 | none | ForagingNav |
| 79 | `clay_lake` | Forest |
| 96 | `$random` | DeepForest |
| 102 | `townhouse` | TrailerPark |
| 115 | `townhouse` | TownZone |
| 128 | `farmmix_forest` | Farm |
| 141 | `farmmix_forest` | FarmLand |
| 153 | `ph_forest` | PHForest |
| 179 | `pr_forest` | PRForest |
| 192 | `farmmix_forest` | FarmMixForest |
| 204 | `farm_forest` | FarmForest |
| 217 | `birch_forest` | BirchForest |
| 230 | `birchmix_forest` | BirchMixForest |
| 243 | `organic_forest` | OrganicForest |
| 254 | `dirt` | ForagingNav |
| 255 | `primary_forest` | DeepForest |

Two rows are commented out in that file: pixel 171 for `vegitation` and `Vegitation`, and
pixel 166 for `phmix_forest` and `PHMixForest`. Both zones are still defined in
`forageZones.lua` and both biomes still exist, but neither is reachable from the biome map.
Foraging definitions that weight `Vegitation` are therefore weighting a zone that is not
currently placed.

The `Forest` and `DeepForest` zones map to `map_forest` and `map_deep_forest`, which have
`generate = false` and no `TREE` features at all. Trees in those zones are hand-placed on
the authored map, not generated.

### What each biome may place

Probabilities are as written in the biome files. Non-tree entries in the same `TREE` block,
bushes, ore and grass, are omitted.

| Forage zone | Biome | Species and probability |
|---|---|---|
| PHForest | `ph_forest` | Virginia Pine 0.2 xxl, 0.4 xl, 0.1 jumbo |
| PRForest | `pr_forest` | Eastern Redbud 0.05 xxl, 0.1 xl, 0.15 jumbo; Cockspur Hawthorn 0.05 xxl, 0.1 xl, 0.15 jumbo; Carolina Silverbell 0.05 xxl, 0.1 xl, 0.15 jumbo |
| BirchForest | `birch_forest` | Riverbirch 0.3 xxl, 0.4 xl, 0.1 jumbo |
| BirchMixForest | `birchmix_forest` | Riverbirch 0.15 xxl, 0.2 xl, 0.05 jumbo; Dogwood 0.07 xxl, 0.05 xl, 0.05 jumbo; Redmaple 0.08 xxl, 0.05 xl, 0.05 jumbo; American Linden 0.05 xxl, 0.05 xl, 0.05 jumbo |
| OrganicForest | `organic_forest` | Dogwood 0.15 xxl, 0.1 xl, 0.1 jumbo; Redmaple 0.15 xxl, 0.1 xl, 0.1 jumbo; American Linden 0.1 xxl, 0.1 xl, 0.1 jumbo |
| FarmForest | `farm_forest` | Yellowwood 0.15 xxl, 0.1 xl, 0.1 jumbo; Redmaple 0.15 xxl, 0.1 xl, 0.1 jumbo; Carolina Silverbell 0.1 xxl, 0.1 xl, 0.1 jumbo |
| Farm, FarmLand, FarmMixForest | `farmmix_forest` | Yellowwood 0.08 xxl, 0.05 xl, 0.05 jumbo; Redmaple 0.15 xxl, 0.1 xl, 0.1 jumbo; Carolina Silverbell 0.05 xxl, 0.05 xl, 0.05 jumbo; Dogwood 0.07 xxl, 0.1 xl, 0.05 jumbo; American Linden 0.05 xxl, 0.05 xl, 0.05 jumbo |
| DeepForest | `primary_forest` | Canadian Hemlock 0.15 xxl, 0.2 xl; American Holly 0.15 xxl, 0.2 xl; Redmaple 0.05 xxl, 0.05 xl; Dogwood 0.05 xxl, 0.05 xl; American Linden 0.05 xxl |
| TownZone, TrailerPark | `townhouse` | none, subbiome is `no_tree` |
| ForagingNav | `dirt` | none, `NONE.none` at 1.0 |
| Forest | `map_forest`, `clay_shore`, `clay_lake` | none placed by worldgen |
| not reachable | `phmix_forest` | Virginia Pine 0.1 xxl, 0.2 xl, 0.1 jumbo; Dogwood 0.07 xxl, 0.025 xl, 0.025 jumbo; Redmaple 0.05 xxl, 0.1 xl, 0.05 jumbo; American Linden 0.05 xxl, 0.05 xl, 0.05 jumbo |
| not reachable | `vegitation` | Eastern Redbud 1.0 xxl |

`PHForest` is pure Virginia Pine with no deciduous species at all. `BirchForest` is pure
Riverbirch. `primary_forest`, the old-growth biome behind `DeepForest`, is hemlock and
holly dominant.

`PH` and `PR` are not expanded anywhere in the game files. `PHForest` being pure pine is
consistent with `PH` meaning soil pH, but that is not stated in the files and is a guess.

### Only jumbo sizes are placed

Every biome under `biomes/map/` places only `_jumbo`, `_jumbo_xl` and `_jumbo_xxl`
features. None of them places a plain `<species>` or `<species>_sapling` feature.

All eleven `<species>_sapling` features exist in `WorldGen/features/tree/`, but exactly one
is referenced by any biome: `pine_sapling`, in `biomes/worldgen/sand_bank.lua`. That file
registers into `worldgen.biomes` rather than `worldgen.biomes_map`, so it belongs to the
procedural generator and is not reachable from `BiomeMapConfig.lua`.

`CONFIRMED IN GAME, 2026-09-06`: no stage 0 to 3 tree exists on the authored Knox County map
before erosion runs, and erosion respawn is the only source of small trees. Predicted from
the biome files and matched by observation in play.

### Procedural biomes

`biomes/worldgen/` holds a second set of biomes registering into `worldgen.biomes`:
`birch_forest`, `light_birch_forest`, `maple_forest`, `light_maple_forest`, `pine_forest`,
`light_pine_forest`, `grass_plain`, `flower_plain`, `sand_bank` and `water`. None is
reachable from `BiomeMapConfig.lua`. Unlike the authored map biomes, these do place plain
and sapling features, and several place `stumps`.

### Erosion respawn

Erosion is the second and entirely separate way a tree appears. `NatureTrees.validateSpawn`
ignores the forage zone completely and picks a species from a twelve-row `soilRef` table
indexed by the square's soil value, so erosion and worldgen can and do disagree about what
grows where.

| Soil | Species pool, by count of entries |
|---|---|
| 0 | Hemlock 1, Riverbirch 3, Hawthorn 7 |
| 1 | Holly 2, Hemlock 3, Riverbirch 10, Hawthorn 4 |
| 2 | Hemlock 8, Holly 4, Pine 2, Riverbirch 3, Hawthorn 1 |
| 3 | Holly 1, Silverbell 3, Redbud 7 |
| 4 | Hemlock 2, Holly 3, Silverbell 10, Redbud 4 |
| 5 | Holly 8, Hemlock 4, Pine 2, Silverbell 3, Redbud 1 |
| 6 | Holly 1, Hemlock 1, Yellowwood 3, Dogwood 8 |
| 7 | Holly 2, Hemlock 2, Pine 1, Yellowwood 10, Dogwood 5 |
| 8 | Holly 6, Hemlock 6, Pine 2, Yellowwood 3, Dogwood 1 |
| 9 | Pine 1, Redmaple 3, Linden 7 |
| 10 | Holly 2, Pine 3, Redmaple 10, Linden 4 |
| 11 | Holly 4, Hemlock 4, Pine 8, Redmaple 3, Linden 1 |

The rows fall into four groups of three, each group built around a species pair: birch and
hawthorn, silverbell and redbud, yellowwood and dogwood, redmaple and linden. Within a
group the first row is signature heavy, the second is signature dominant, and the third
shifts hard toward the evergreens.

Spawn chance is zero for a noise value below 50 and ramps by cosine interpolation to 90 at
99. The cap that matters is the stage:

```
maxStage = 2 + floor((eValue - 50) / 17) - 1
```

For `eValue` in 50 to 99 that gives 1 to 3. An erosion-spawned tree can never exceed stage
3, so erosion alone never produces a jumbo tree of any size.

Trees already on the map take a different path. `replaceExistingObject` converts a
`jumbo_tree_01` sprite to `stage = maxStage = 5 + floor(eValue / 51) - 1` and a
`vegetation_trees` sprite to `3 + floor(eValue / 51) - 1`, and adopts an existing `e_*`
tree at stage 3, JUMBO at 4 or 5, JUMBOXL at 6 and JUMBOXXL at 7.

## Propagation items and the gaps

Four items are candidates for a propagule. All are defined in
`media/scripts/generated/items/`, and none carries any species information.

| Item | File | Definition |
|---|---|---|
| `Base.Pinecone` | `normal.txt` | Junk, weight 0.1, tagged `isfirefuel` and `isfiretinder` |
| `Base.Acorn` | `food.txt` | Food, `FoodType = Nut`, 55 calories, cookable |
| `Base.Sapling` | `weapon.txt` | Improvised two-handed blunt weapon, `TreeDamage = 0` |
| `Base.HollyBerry` | `food.txt` | Food, berry |

That is the complete set. A sweep of the item scripts for anything else seed-shaped turns
up nothing usable: every `*Seed` and `*BagSeed` item belongs to the farming system and is a
vegetable or herb, and the only two items with `FoodType = Nut` are `Base.Acorn` and
`Base.Peanuts`. There is no cutting, pit, stone, sucker or bare-root item of any kind.

### Per-species propagule check

Each species was checked against what it actually reproduces from in the real world, and
the item scripts were searched for a matching item under every plausible name.

| Species | Real propagule | Item in B42.20 |
|---|---|---|
| American Holly | Red drupe | `Base.HollyBerry`, but see [the holly berry is a hazard](#the-holly-berry-is-a-hazard-not-a-seed) |
| Canadian Hemlock | Small seed cone | none |
| Virginia Pine | Seed cone | `Base.Pinecone` |
| Riverbirch | Winged samaras in a strobile | none |
| Cockspur Hawthorn | Pome, a haw | none |
| Dogwood | Red drupe | none |
| Carolina Silverbell | Four-winged dry drupe | none |
| Yellowwood | Legume pod | none |
| Eastern Redbud | Legume pod | none |
| Redmaple | Paired samara | none |
| American Linden | Nutlet on a papery bract | none |

Searches run against `scripts/generated/items/*.txt` for `Birch`, `Hawthorn`, `Haw`,
`Dogwood`, `Silverbell`, `Yellowwood`, `Redbud`, `Maple`, `Linden`, `Basswood`, `Samara`,
`Catkin`, `Cone`, `Nut`, `Pod`, `Berry`, `Drupe`, `Sap` and `Bark`. The only hits for the
deciduous species are furniture and clothing that happen to carry the word, `Mov_BirchCounter`,
`Hat_BaseballCap_WestMapleCountryClub` and similar, plus `Base.MapleSyrup`, which is a sap
product and not a propagule.

The other berry items that exist, `BeautyBerry`, `BerryBlack`, `BerryBlue`, `BerryGeneric1`
through `5`, `BerryPoisonIvy` and `WinterBerry`, belong to bushes rather than trees. Bushes
are a separate erosion category, `NatureBush`, and are out of scope for this document.
`Base.HollyBerry` is the one berry item that belongs to a species in the tree roster.

So exactly two of the eleven species have any species-specific item at all, and only one of
those, Virginia Pine's cone, functions as a seed.

### The holly berry is a hazard, not a seed

`Base.HollyBerry` is the game's designated poison berry. In
`Foraging/Categories/Berries.lua` it is the sole entry in the `poison` group, with
`poisonChance = 1000` and a comment saying that value exists to keep the chance independent
of skill, `poisonPowerMin = 5`, `poisonPowerMax = 10` and `poisonDetectionLevel = 5`. A
forager below Foraging level 5 cannot tell it apart from a safe berry.

Its item script carries no poison fields. The poison is applied at forage time by
`forageSystem.doPoisonItemSpawn`, which calls `setPoisonPower` and
`setPoisonDetectionLevel` on the spawned items. `IsoTree.dropWood` calls
`square.AddWorldInventoryItem` directly and does not run that spawn function, so a holly
berry obtained by chopping a tree is not poisoned while an identical one obtained by
foraging is. That asymmetry is vanilla behaviour, derived from the files.

Everything about the item points at food and hazard flavour rather than propagation:
`FoodType = Berry`, `HerbalistType = Berry`, a full `EvolvedRecipe` list, and membership of
the poison group. Vanilla has no planting system, so there is no planting intent to read
here at all.

Real *Ilex opaca* can be grown from the seed inside the drupe, so a berry route is not
absurd, but it is slow and unusual: holly seed has deep double dormancy and commonly takes
one to three years to germinate, nursery propagation is almost always from cuttings, and
holly is dioecious so only female trees bear fruit. Treating American Holly as sapling-only
matches both vanilla intent and horticultural practice. This is a design choice for the
planting change rather than a fact about the game; see
[carried forward to later changes](#carried-forward-to-later-changes).

### Gaps

- **No tree in the game can drop an acorn.** There is no oak species in the eleven, and
  chopping cannot produce one either; see [the acorn is unreachable](#the-acorn-is-unreachable).
  `Base.Acorn` is obtainable only by foraging and from one randomized zone story, and it
  grows nothing.
- `Base.Pinecone` drops only from Virginia Pine. Canadian Hemlock is a true conifer and
  never drops one. See below.
- `Base.Sapling` is a weapon with no species field, so a sapling in the player's inventory
  cannot say what it came from.
- American Holly's `Base.HollyBerry` is a food item, and vanilla drops it only in Autumn
  and Winter.

### Cone test defects

`IsoTree.dropWood` decides these drops by testing the sprite name:

```java
boolean acorn = name != null && (name.toLowerCase().contains("oak")
    || name.equals("vegetation_trees_01_13") || name.equals("vegetation_trees_01_14")
    || name.equals("vegetation_trees_01_15"));
boolean pinecone = name != null && (name.toLowerCase().contains("pine")
    || name.equals("vegetation_trees_01_08") || name.equals("vegetation_trees_01_09")
    || name.equals("vegetation_trees_01_010") || name.equals("vegetation_trees_01_011"));
boolean holly = name != null && name.toLowerCase().contains("holly")
    && ("Autumn".equals(...getSeasonName()) || "Winter".equals(...getSeasonName()));
```

Two defects follow.

First, the conifer test is a substring match on `pine`, not a species check.
`e_virginiapine_1` is the only tileset name of the eleven that contains it, so Canadian
Hemlock never drops a cone despite `NatureTrees` flagging it evergreen and despite it being
a true conifer.

Second, all four legacy fallbacks in the cone test are dead. They are written
`vegetation_trees_01_08`, `_09`, `_010` and `_011`, while `newtiledefinitions.tiles.txt`
declares those sprites without zero padding, as `vegetation_trees_01_8`, `_9`, `_10` and
`_11`. No equality test can match, so legacy pines drop no cone either. The acorn test
immediately above uses `_13`, `_14` and `_15` unpadded, and those do match, which is what
makes the padding look like a typo rather than a convention.

`NEEDS IN-GAME CHECK`: the consequence, that neither Canadian Hemlock nor any legacy pine
drops a cone.

In practice the legacy branch is doubly unreachable. Every
`vegetation_trees_01_8` through `_15` tile carries `tree = 2`, which is size 2 and a log
yield of 1, so a legacy tree takes the `numPlanks == 1` branch and drops a single
`Base.TreeBranch2`. The `numPlanks > 2` block that holds the cone, acorn and berry lines
never runs for them at all. Fixing the zero padding would change nothing.

On top of that, `NatureTrees.replaceExistingObject` converts any sprite whose name starts
with `vegetation_trees` into one of the eleven erosion species on chunk load, so on a save
with erosion running the original sprite is usually gone before it can be chopped.

### The acorn is unreachable

`Base.Acorn` cannot be obtained by chopping any tree in B42.20, for two independent reasons.

The `contains("oak")` test matches no sprite name in the game. No tileset in any `.tiles`
file is named for oak. The 126 `oak` strings in `newtiledefinitions.tiles` are furniture
`GroupName` values such as "Oak Round Table" and "Oakwood Floating", and `dropWood` tests
`getSprite().getName()`, not the group name.

The three equality tests that are written correctly, `vegetation_trees_01_13`, `_14` and
`_15`, point at sprites with `tree = 2`. That is a log yield of 1, so the `numPlanks > 2`
block containing the acorn line never executes for them.

The remaining acorn sources are the foraging tables and
`zombie.randomizedWorld.randomizedZoneStory.RZSHermitCamp`, which adds `Base.Acorn` to a
hermit camp's loot. Those two are the only ways to get one.

There is a matching vestige in worldgen: `biomes/worldgen/maple_forest.lua` registers
`worldgen.biomes["oak_forest"]` and `light_maple_forest.lua` registers `light_oak_forest`,
both of which actually contain Redmaple, American Linden and Yellowwood. The files were
renamed from oak to maple and the internal names were left behind. There is no oak
anywhere in B42.20 beyond furniture naming and these two dead identifiers.

### What this means for propagation

Ten of the eleven species have no usable seed item. Virginia Pine's cone is the only one,
and American Holly's berry is a food and poison item rather than a seed. Sapling propagation
is the only route available for every species, and it is an accepted limitation for the
first planting release.

The sapling supply itself is uneven. Per
[what chopping a tree yields](#what-chopping-a-tree-yields), a chopped tree gives no
sapling at all at stages 0, 1, 3 and 4, one at stages 2 and 5, two at stage 6 and four at
stage 7.

### Foraging availability

Cones, acorns and saplings are also forageable, and the foraging tables have no
relationship to the species actually growing in the zone. A cone foraged in `BirchForest`
is the same item as one foraged in `PHForest`.

| Zone | Pinecone | Acorn | Sapling |
|---|---|---|---|
| DeepForest | 15 | 10 | 3 |
| Forest | 15 | 10 | 2 |
| OrganicForest | 25 | 15 | 7 |
| BirchForest | 20 | 15 | 3 |
| PRForest | 20 | 15 | 3 |
| PHForest | 20 | 15 | 3 |
| Vegitation | 10 | 5 | 1 |
| FarmLand | 10 | 5 | |
| TrailerPark | 5 | | |
| TownZone | 5 | | |
| ForagingNav | 5 | | |

`Pinecone` is in the Firewood category, 1 to 3 per find, 1 xp, months 9 to 12. `Acorn` is
in WildPlants, 3 to 6 per find, 5 xp, months 3 to 11 with a bonus in 5 to 7 and a malus in
3 and 4. `Sapling` is in Firewood, 2 xp, no month restriction, bonus in 9 to 11.

Note that `Vegitation` is weighted for all three but is not currently reachable from the
biome map.

## How erosion grows a tree

Growth is driven by one global counter, not by per-tree elapsed time.

`ErosionMain.mainTimer` increments `ticks` once per call and rolls `eTicks` up by one every
`tickUnit`, which defaults to 144. The erosion speed sandbox setting divides or multiplies
`tickunit` by 5 or 2, and if the `erosionDays` sandbox setting is above zero it overrides
the whole scheme with `eTicks = ticks / 144 / erosionDays * 100`. Setting `erosionDays`
below zero pins `eTicks` at 0 and stops erosion entirely.

`NatureTrees.update` then computes:

```
stage = floor((eTick - spawnTime) / (cycleTime / (maxStage + 1)))
```

`cycleTime` is 60 for every species, set in `init` where each `ErosionObj` is constructed.
`spawnTime` is `130 - eValue`, so a square with a high noise value starts sooner.

Three consequences make this unsuitable as a backend for player planting:

- Growth is a function of world age, not of when a particular tree was planted. Two trees
  with the same `spawnTime` are always the same size, wherever they are.
- Once `eTicks` passes `spawnTime + cycleTime` the tree is at `maxStage` forever. Nothing
  grows after that.
- Combined with the stage 3 cap on erosion spawns, erosion alone never produces a jumbo
  tree.

Erosion trees are real `IsoTree` objects. `ErosionObj.createObject` calls
`IsoTree.getNew()`, assigns the sprite, calls `initTree()` and sets the object name to the
species display name, with `doNotSync = true`. `IsoTree.setSprite` calls `initTree()` again,
so size and log yield are recomputed from the sprite every time the stage or season changes.

## Verification status

1. **Seasonal sprites do not affect size. RESOLVED, not a defect.** Originally flagged on
   the grounds that only indices 0 to 7 carry a `tree` property while `NatureTrees`
   addresses up to index 23. That flag was wrong. The base sprite is always the season 0
   one, so the object never takes a sprite without the property, and the seasonal variants
   are overlays. See [seasonal sprites](#seasonal-sprites) for the chain. No in-game check
   is needed.
2. **Neither Canadian Hemlock nor any legacy pine drops a cone. NOT YET TESTED.** Provable
   from the files for the substring test, the padding mismatch and the size 2 gate; the
   drop behaviour itself is still unobserved. Check by chopping a Canadian Hemlock.
3. **No stage 0 to 3 tree exists on the authored map before erosion runs. CONFIRMED
   in game, 2026-09-06.** Predicted from the biome files placing only jumbo features, and
   matches what is observed in play: small trees and saplings are not present on the map
   until erosion starts producing them.

Two further claims are proven from the files and were never in doubt, but are worth naming
because they contradict what players commonly assume:

- No tree can drop an acorn. See [the acorn is unreachable](#the-acorn-is-unreachable).
  If acorns appear to come from a tree in play, they were foraged. `Base.Acorn` is a
  WildPlants forage item yielding 3 to 6 per find across every forest zone, which makes it
  common enough to look like a tree drop.
- Nothing below stage 3 drops a cone, acorn or berry, because those lines sit inside the
  `numPlanks > 2` block.

## Kentucky context

Kentucky forest is roughly 76 percent oak-hickory, with mixed mesophytic forest on the
moister slopes of the east. Typical mixed mesophytic canopy species are sugar maple, beech,
tuliptree, basswood, northern red oak and hickory. Virginia Pine favours dry acidic sites,
and Eastern Hemlock favours cool moist north-facing slopes on acidic sandstone-derived
soils, which is consistent with `ph_forest` being pure Virginia Pine and `primary_forest`
being hemlock dominant.

The game ships no oak and no hickory tileset, so the vanilla palette is a stylised subset
rather than a representative sample of Kentucky forest. Yellowwood, *Cladrastis kentukea*,
is the most obviously deliberate pick.

Project Zomboid's Knox County is a fictional county modelled on the Louisville area, Meade
and Bullitt counties and the Knobs region. It is not the real Knox County, which is in
south-eastern Kentucky on the Cumberland Plateau. Real Knox County composition is not a
useful guide to what the map should contain.

Sources:

- [Kentucky Forest Action Plan](https://eec.ky.gov/Natural-Resources/Forestry/Documents/2020%20Kentucky%20Forest%20Action%20Plan.pdf)
- [Tsuga canadensis, eastern hemlock, USDA Forest Service](https://research.fs.usda.gov/feis/species-reviews/tsucan)

## Carried forward to later changes

Decisions settled while producing this document. They constrain the follow-up work and are
not implemented anywhere yet.

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
- **American Holly is sapling-only**, pending confirmation. `Base.HollyBerry` stays a food
  and poison item and is not a propagule, which matches vanilla intent and real propagation
  practice, and avoids giving a poison item a second meaning that players would have to
  learn. If a berry route is wanted later, the natural shape is berry as a very slow route
  reflecting holly's seed dormancy against sapling as the fast one.

  Sapling-only also sidesteps the classification conflict rather than picking a side. The
  model reads as a conifer, so a player will expect a cone; the botany says broadleaf, so a
  cone would be wrong. Giving it neither, and only a sapling, is consistent whichever axis
  the player is reasoning from. The propagule drop fix should keep this in mind: once
  Canadian Hemlock starts dropping cones, American Holly will be the visually similar tree
  that does not, and that will read as an oversight unless it is deliberate.
- **Propagule drop fix** is a committed feature behind its own setting, defaulting to on.
  It is one change covering every way `dropWood` fails to give a tree its propagule:

  - Canadian Hemlock never drops a cone, because the test is a substring match on `pine`.
  - The four legacy cone fallbacks are dead from zero padding, and moot anyway because
    those sprites are size 2.
  - No tree drops an acorn, because `contains("oak")` matches no sprite and the three
    working equality tests point at size 2 sprites. See
    [the acorn is unreachable](#the-acorn-is-unreachable).

  Open question for that change, not settled here: there is no oak species in B42.20, so
  restoring an acorn drop has no correct target. The options are to leave `Base.Acorn`
  foraging-only, to attach it to a deciduous species as a stand-in, or to give the eight
  deciduous species their own propagule items, which the planting system may want regardless.
  Decide it in that change with the
  [per-species propagule check](#per-species-propagule-check) in hand.

  The hook point is `ISChopTreeAction:animEvent`, wrapped rather than replaced: vanilla
  already tests `self.tree:getObjectIndex() == -1` there to detect the tree toppling, so the
  wrapper can capture the sprite name before delegating and add the drop after. No lua event
  fires on topple and `toppleTree` and `dropWood` have no lua entry point, so this is the
  only interception that avoids editing a vanilla file. Known gap: trees felled by a vehicle
  or by fire do not route through the timed action and will not be corrected.

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
