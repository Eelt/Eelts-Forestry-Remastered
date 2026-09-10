# Vegetation succession

Future scope for vegetation recovering over time on ground that has been cleared, burned or
felled, up to a density ceiling that varies by biome. None of it is implemented.

This is the largest piece of the forestry work and it stands alone. Tree identity, seasonal
management and inherited timing are in
[tree-management-and-genetics.md](tree-management-and-genetics.md), which also holds the
species audit this document's weights come from and the boundary layer that takes a square
off vanilla erosion in the first place.

## There is nothing in vanilla to extend

The [lua notes](../reference/b42-lua-notes.md#erosion-has-no-succession-between-its-nature-categories)
record the finding this document rests on. Erosion's region 0 carries the whole vegetation
ladder, `NatureGeneric` for grass and ferns, `NaturePlants` for groundcover, `NatureBush`
for bushes and `NatureTrees` for trees, and exactly one of them owns a square. The
assignment is made once, at that square's first erosion load, and never revisited.

Nothing promotes a square from one category to the next. Grass does not become bush, bush
does not become tree, and a square that loses its object keeps nothing in its place.
`IsoChunk.CheckGrassRegrowth` does not fill the gap either; it is the animal pasture
mechanic, scoped to `GrassRegrowth` zones.

So a clear cut field in vanilla stays a clear cut field permanently. No trees, no bushes and
no grass return to it. This scope is not a correction of vanilla behaviour and not a system
running alongside one. It is the only succession the game will have.

That also means no vanilla process can contradict it later. Once the boundary layer has
taken a square, nothing else will ever place vegetation there.

## Shape of the system

Ground that has been disturbed recovers in stages as time passes. Bare ground gains grass,
then groundcover and ferns, then bushes, and finally trees, with density rising at each
stage until the biome's crowding ceiling stops it. A wildfire, a clear cut and a player
levelling a field all produce the same starting condition and the same recovery.

Recovery is driven by elapsed time rather than by ticks accrued while a chunk happened to be
loaded. A region left alone for two years should look like two years of recovery on the
first visit back, not like the handful of hours a player spent near it.

### Persist trees, derive everything below them

Storing per square state for the whole ladder does not scale. A cleared fifty by fifty field
is two and a half thousand squares, and the global object system currently holds one lua
object per adopted tree.

Split the ladder by whether the thing has an identity:

- Grass, groundcover, ferns and bushes have none. No individual grass tile matters, so its
  stage can be a pure function of position, time since the area was disturbed and local
  density. Compute it on load, render it, store nothing. This mirrors what erosion does with
  `square.rand(x, y, n)` and per square noise, with a time axis erosion lacks.
- Trees carry species, stage, genetics and provenance. They stay real objects in the global
  object system, as they are now.

The only state that must persist is when an area was last disturbed. Recording that per
chunk rather than per square keeps it small. Whether one timestamp per chunk is coarse
enough to look right at a clear cut boundary is open, and a partial cut inside one chunk is
the case to check first.

### Crowding ceilings

Density rises until it reaches a biome specific limit. Deep Forest should end substantially
denser than plain Forest, with Primary Forest and Organic Forest somewhere between. The
English translations confirm those names map to `DeepForest`, `Forest`, `PRForest` and
`OrganicForest`, and that `primary_forest.lua` supplies Deep Forest despite its name.

A small minimum spacing plus a wider neighbourhood density limit is a proposed way to
express the ceiling. Exact radii, counts and boundary treatment are open. Trees excluded as
seed parents should still count as physical crowding. This scope adds limits to natural
recovery; it does not change player planting spacing and does not thin existing forests.

#### The density ordering is not evidence based yet

The ordering above is a gameplay preference. The English label for `DeepForest` is Deep
Forest, not Dense Forest, and the four names alone do not establish trees per area.

The installed `media/lua/shared/Foraging/forageZones.lua` defines these values:

| Forage zone | Item density minimum and maximum | Daily refill percent |
|---|---|---|
| Primary Forest, `PRForest` | 6 to 8 | 5 |
| Organic Forest, `OrganicForest` | 8 to 10 | 5 |
| Forest, `Forest` | 8 to 10 | 7 |
| Deep Forest, `DeepForest` | 8 to 10 | 7 |

These are forage item parameters. `forageSystem.fillZone` scales the density draw by zone
area and writes `itemsLeft` and `itemsTotal`; `checkRefillZone` restores that budget. They
do not place trees or measure canopy cover. Organic Forest shares the same base range as
Forest and Deep Forest, and Primary Forest is lower. Neither result supplies a crowding
limit.

The authored map tree features give a different comparison, among tree selections before
placement failures:

| Biome | Jumbo, stages 4 and 5 | XL, stage 6 | XXL, stage 7 |
|---|---|---|---|
| Primary Forest | 50% | 33.3% | 16.7% |
| Organic Forest | 30% | 30% | 40% |
| Deep Forest, authored branch | 0% | 52.6% | 47.4% |
| Plain Forest | No single tree mixture identified | No single tree mixture identified | No single tree mixture identified |

Primary Forest favours smaller stages within the mature range and contains Redbud, Hawthorn
and Silverbell. Organic Forest contains Dogwood, Redmaple and Linden with a larger XXL
share. Authored Deep Forest contains only XL and XXL variants, mainly Hemlock and Holly. The
tree subbiome specifies bushes for Primary Forest, grass for Organic Forest and bushes for
authored Deep Forest. Those are differences in vegetation structure, not a numeric density
ordering. Primary and Organic Forest share `FOREST` landscape, `MEDIUM` temperature and
`DRY`/`RAIN` hygrometry, so nothing there justifies treating Organic Forest as denser
either.

Initial map tree positions, feature footprints, placement restrictions and subbiome
replacement all affect the resulting number of trunks, and larger tree art changes how dense
a forest looks without proving more trunks per area. Deep Forest's procedural branch and
plain Forest's missing single mixture prevent an exact four way comparison from the
definitions alone.

Before claiming vanilla derived crowding limits, count trunks in multiple equal area samples
within the four forage zones on a fresh map. Record canopy cover separately, avoid mixed
zone boundaries, and distinguish authored from procedural Deep Forest. Until that
measurement exists, leave the placement of Primary and Organic Forest open and label any
assigned limits as mod tuning.

## Tree establishment

New trees start at stage 0 and then use the existing elapsed time growth system, subject to
the selected growth mode.

Physical eligibility matches player planting. `shared/EeltsForestryRemastered_Planting.lua`,
`isPlantableSquare`, requires outside ground at z=0, no building or existing tree, a free
square, no water or farming crop, and ground classified as dirt. Natural establishment needs
no player, tool, item or tape.

Species follow the biome weights in `zoneSpecies`. Move that policy out of item specific
selection so planting and establishment share it. The current `rollSpecies` fallback picks
any eligible item species uniformly when no local match exists, which is a convenience for
planting an item rather than an appropriate policy for an unknown zone. Establishment should
use the full species policy rather than one item's filtered distribution, since a pine cone
filters to the two conifers and a holly berry is fixed to Holly.

`NatureTrees.validateSpawn` rolls `square.rand(x, y, 101)` against
`spawnChance[square.noiseMainInt]`. That is deterministic per square and available as a
density reference if the mod's own rate should agree with vanilla's without inheriting its
species choice.

### Local parents

Nearby eligible trees should influence species selection and provide a parent when possible,
with the biome weights as the fallback. Keep it bounded: seed dispersal objects, pollination
simulation and ancestry tracking are not required.

A proposed implementation is to adjust the biome weights with a limited local contribution,
choose a species, then choose a nearby eligible parent of that species. If none exists,
initialise genetics without a parent. The mixing formula, influence radius and eligible
parent sizes are open. A single parent is sufficient.

### Player planted trees as parents

Provide a three value sandbox dropdown:

| Value | Behaviour |
|---|---|
| Disabled, default | Directly player planted trees do not influence species selection or serve as parents |
| Native species only | Directly player planted trees contribute only when their species has positive weight in the destination biome's pool |
| All species | Directly player planted trees may contribute outside their normal biome, with the same local influence, ground and crowding restrictions |

For an undocumented zone, the proposed default under Native species only is to exclude a
player planted tree unless a known species pool establishes that it is native there.

Naturally established offspring count as wild immediately, even when their parent was player
planted. Do not retain player planted ancestry. Those descendants can contribute as wild
trees regardless of the dropdown, including after it returns to Disabled, and they do not
qualify for planted only growth. Changing the setting governs future establishment and does
not remove existing trees.

## Open work

- The disturbance record. Per chunk granularity, what counts as disturbance, and how a
  partial cut inside one chunk behaves.
- The derived layer. Whether grass, groundcover and bushes can be rendered from a pure
  function cheaply enough at chunk load, and what happens when a player watches a square
  cross a stage boundary.
- Recovery rates, stage durations and the density curve. All tuning, none of it derived from
  vanilla.
- Crowding numbers, which need the trunk census above before they can be called anything but
  mod tuning.
- Interaction with the erosion stacking case in
  [tree-management-and-genetics.md](tree-management-and-genetics.md), since establishment
  puts trees on squares erosion may still be holding an unplaced claim on.

## Verification before shipping

- Clear cut a measured area, then confirm grass, groundcover, bushes and trees return in
  order and stop at the biome ceiling.
- Leave a cleared area unloaded for a long stretch and confirm the first visit back shows
  elapsed time recovery rather than loaded time recovery.
- Compare recovered composition against the biome pools, including PHForest, and confirm no
  square carries a species its local pool does not support.
- Check the ceiling in all four forage zones and confirm the ordering matches whatever the
  trunk census established.
- Exercise all three planted parent settings. Confirm natural descendants count as wild and
  that existing trees survive a settings change.
- Watch a clear cut boundary that runs through the middle of a chunk.
- Measure chunk load cost with the derived layer active over a large recovering area.
- Verify recovery and appearance in single player and on a dedicated server, including a
  late join.
