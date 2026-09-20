# Vegetation succession

Scope for vegetation recovering over time on ground that has been cleared, burned or felled, up
to a density ceiling that varies by biome.

Most of this shipped in `add-vegetation-succession`. Cleared ground now recovers through grass,
tall grass and ferns, bushes and trees on elapsed world time, from a clearing record written on
the square when the mod sees it felled, scythed or dug out; species come from the same
`zoneSpecies` weights planting and correction use, biased by the trees already standing; and
the crowding ceiling is keyed on the worldgen biome. What it does is described in
`openspec/specs/vegetation-succession/`, and what nobody has watched it do is in
[carried-forward.md](carried-forward.md).

What did not ship, and is still scoped here rather than built: genetics and inherited timing on
the chosen parent, seed dispersal and ancestry, and the trunk census follow up that would
confirm the realisation factor outside Acidic Forest. The density ordering itself is no longer
open; it was measured across the whole map and is in
[b42-tree-matrix.md](../reference/b42-tree-matrix.md#the-map-census).

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

Density rises until it reaches a biome specific limit. The ordering between zones is now
measured rather than assumed, and it is in the census section of
[b42-tree-matrix.md](../reference/b42-tree-matrix.md#the-map-census). The English
translations confirm those names map to `DeepForest`, `Forest`, `PRForest` and
`OrganicForest`, and that `primary_forest.lua` supplies Deep Forest despite its name.

A small minimum spacing plus a wider neighbourhood density limit is a proposed way to
express the ceiling. Exact radii, counts and boundary treatment are open. Trees excluded as
seed parents should still count as physical crowding. This scope adds limits to natural
recovery; it does not change player planting spacing and does not thin existing forests.

#### The density ordering is measured

The whole map was read from the shipped files on 2026-09-16 and the result is recorded in
[the map census](../reference/b42-tree-matrix.md#the-map-census). It counts tree slots in the
authored placement per forage zone, across all 266403840 squares, and it replaces the
guesswork this section used to carry.

Deep Forest is densest at 223.3 slots per thousand squares, which the earlier guess got
right. The rest of the guess was wrong. Organic Forest is near the top at 184.8 rather than
in the middle, Primary Forest sits mid table at 100.1 alongside Acidic Forest at 95.3, and
Birch Mixed Forest is the sparsest real forest at 75.9 despite Birch Forest being second
densest at 192.9. Ceilings follow that table.

Plain `Forest` is not a forest and should not be given a forest ceiling. It is 204315
squares, 0.077 percent of the map, mapping to `clay_shore` and `clay_lake`, both of which
define no `TREE`, `BUSH` or `PLANT` features and use the `no_tree` subbiome. It carries 2.1
tree slots per thousand.

Deep Forest's procedural branch does not exist on this map. `BiomeMapConfig.lua` maps pixel
96 to `$random`, and pixel 96 occurs on zero squares, so the authored branch describes all of
Deep Forest and the four way comparison this section once said was impossible is available.

Two qualifications remain. The census counts the slots the map authors placed, before
`WorldGenTile.getBiomeTile` rejects the ones whose footprint will not fit, so realised trunks
are fewer; one in-game survey of Acidic Forest puts that at about 71 percent. And the slots
are painted in slabs, with 58.5 percent of Deep Forest tree squares having all eight
neighbours also carrying a tree, so the census supports a density ceiling and supports no
minimum spacing at all. Any spacing number is mod tuning.

Two earlier comparisons are kept because they are still true and still not density evidence.
`forageZones.lua` gives Primary Forest an item density of 6 to 8 and Organic, plain and Deep
Forest 8 to 10, but those are forage item budgets scaled by zone area and place no trees. And
the authored feature mixtures differ in vegetation structure, Primary Forest favouring
smaller mature stages with Redbud, Hawthorn and Silverbell, Organic Forest carrying Dogwood,
Redmaple and Linden with a larger XXL share, and authored Deep Forest holding only XL and XXL
variants of mainly Hemlock and Holly. Larger tree art changes how dense a forest looks without
changing trunks per area.

A trunk count in game is still worth doing, as a check on the realisation factor in zones
other than Acidic Forest. It is no longer what the ceilings are waiting on.

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
- Crowding numbers. The ordering comes from the census; the absolute values and the spacing
  are mod tuning, and the realisation factor is measured in one zone only.
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
- Check the ceiling in all four forage zones and confirm the ordering matches the census
  table.
- Exercise all three planted parent settings. Confirm natural descendants count as wild and
  that existing trees survive a settings change.
- Watch a clear cut boundary that runs through the middle of a chunk.
- Measure chunk load cost with the derived layer active over a large recovering area.
- Verify recovery and appearance in single player and on a dedicated server, including a
  late join.
