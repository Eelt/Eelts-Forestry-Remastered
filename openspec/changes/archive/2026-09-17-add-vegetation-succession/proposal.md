## Why

Nothing in the base game ever puts vegetation back. Erosion assigns each square one nature
category at its first load and never revisits it, nothing promotes grass to bush or bush to
tree, and `IsoChunk.CheckGrassRegrowth` is the animal pasture mechanic scoped to
`GrassRegrowth` zones. A clear cut field stays a clear cut field for the rest of the world's
life. The mod can fell a whole forest and grow a new tree from a sapling, and the ground it
cleared to do it stays bare dirt forever.

`add-erosion-boundary-layer` removed the thing that blocked this. A square the mod renames is
off erosion permanently, so there is no competitor to negotiate with: once the mod has taken a
square, nothing else will ever place vegetation on it. This is the largest remaining piece of
the forestry work and the one that makes felling a forest a decision rather than a permanent
scar.

## What Changes

- Ground the mod sees cleared recovers through the whole ladder as time passes: bare ground
  gains grass, then groundcover and ferns, then bushes, and finally trees, with density rising
  at each stage until the zone's crowding ceiling stops it.
- Recovery is driven by elapsed world time, not by time a chunk spent loaded. A region left
  alone for two years looks like two years of recovery on the first visit back.
- A square records when it was last cleared, written when the mod observes the clearing. A
  square with no record recovers on the world's own age, so long abandoned fields revegetate;
  a setting restricts recovery to squares the mod actually saw cleared.
- Grass, groundcover, ferns and bushes carry no identity, so what stands on such a square is a
  function of its position, the time since it was cleared and the local density, evaluated on
  chunk load. The object placed is the whole of the state; the mod stores nothing per square
  for them beyond the clearing time.
- Trees carry identity, so an established tree is a real object in the global object system
  exactly as a corrected or planted one is. It starts at stage 0 and then uses the existing
  elapsed time grower, subject to the growth setting.
- Species come from the same `zoneSpecies` weights correction and planting already use, not
  from one propagule's filtered list. Nearby standing trees bias the weights within a bounded
  radius, so a stand reseeds as itself rather than rerolling the zone mixture every time.
- A three value setting decides whether player planted trees count as local parents: disabled
  by default, native species only, or all species. Naturally established offspring count as
  wild immediately whatever their parent was, and never qualify for planted only growth.
- Each forage zone gets a crowding ceiling, expressed as a minimum spacing and a wider
  neighbourhood limit. The ordering between zones is taken from a census of the shipped map
  rather than assigned by preference, and the absolute numbers are mod tuning.
- Plain `Forest` gets a species pool for the first time, the Organic Forest mixture, but the
  near zero ceiling its own ground measures. It is lake and clay shore, not forest.
- **BREAKING** for `forest-composition`. Its "Only trees are touched" requirement says the mod
  leaves grass, groundcover, ferns and bushes exactly as they are, and its "Density is
  unchanged" scenario says the mod adds no tree where the base game placed none. Both were
  written about the correction pass and both stop being true of the mod as a whole. They are
  narrowed to correction, with succession named as the exception.
- **BREAKING** for the growth setting's base-game choice again. `tree-growth` says an unmodded
  world needs the growth setting on the base game's behaviour and correction off. It now needs
  succession off as well.
- Succession runs on its own setting, on by default, independent of both existing ones.
- The cost of evaluating a recovering square on chunk load is measured before the rest is
  built on it, the same way the boundary layer's per square cost was.

## Capabilities

### New Capabilities
- `vegetation-succession`: how cleared ground recovers over time through grass, groundcover,
  bushes and trees, what decides the species and the ceiling, and what it costs.

### Modified Capabilities
- `forest-composition`: the promise that the mod touches only trees and adds no tree of its
  own is narrowed to the correction pass, since succession now places both understory and
  trees.
- `tree-growth`: a naturally established tree is taken over as it is created, the same way a
  planted one is, and counts as wild rather than player planted; and the combination of
  settings that leaves a world unmodded gains a third member.

## Impact

New: a succession system under `42.20/media/lua/server/`, an understory layer it drives, and a
crowding and eligibility helper under `42.20/media/lua/shared/` that planting can also read.

Changed: `EeltsForestryRemastered_TreeGrowthSystem.lua` for establishment adopting at
creation, `EeltsForestryRemastered_TreeDrops.lua` for stamping a square's clearing time when
the tree it wraps is chopped, `EeltsForestryRemastered_Propagules.lua` for the local parent
bias and the plain `Forest` pool, `EeltsForestryRemastered_Planting.lua` for the eligibility
test succession shares, `42.20/media/sandbox-options.txt` and `Translate/EN/Sandbox.json` for
the new settings.

### B42.20 files and tables this rests on

No vanilla file is edited or shadowed.

The absence of succession in vanilla was established in `add-erosion-boundary-layer` and is
recorded in `docs/reference/b42-lua-notes.md` under "Erosion has no succession between its
nature categories". The rename mechanism that takes a square off erosion is recorded in the
same document and is not re-derived here. New for this change is that the mechanism is not
tree specific: `zombie/erosion/obj/ErosionObj` is the shared object wrapper behind all four
nature categories and it is the class that carries the `name` an object is matched by, so the
same rename releases a grass or bush square.

The crowding numbers come from a census of the installed map data, read directly rather than
sampled in game. `media/maps/Muldraugh, KY/` holds 4065 authored cells as `*.lotheader` name
tables and `world_*.lotpack` tile placements, and a per cell `maps/biomemap_*.png` whose grey
value is the pixel `media/lua/server/metazones/BiomeMapConfig.lua` maps to a forage zone. The
census covers all 266403840 squares of the map. Two things it settles are recorded in
`design.md` in full: the density ordering between zones, and that the authored forage zones in
`objects.lua` are dead in B42, because `metazoneHandler.doMapZones` skips every zone type the
biome map also supplies.

## Non-goals

- Genetics and inherited timing. The local parent is chosen and then contributes only its
  species, because there is no trait to inherit yet. The parent slot is where inheritance will
  attach when `tree-management-and-genetics.md` is built, and nothing here has to move for it.
- Seed dispersal objects, pollination simulation and ancestry tracking. A single parent chosen
  from a bounded radius is sufficient and is all that is built.
- Thinning existing forests. The crowding ceiling limits what recovery may add. A stand that is
  already denser than its ceiling is left alone.
- Changing player planting. The eligibility test is shared, but the spacing rules apply to
  natural recovery only, and planting keeps working exactly where it works today.
- Detecting every kind of clearing. Chopping is observed because the mod already wraps it.
  Destruction by vehicle or by fire is the same coverage gap `fix-conifer-cone-drops` left open
  and is not closed here; such a square recovers on the world clock like any other unrecorded
  bare ground.
- The unplaced claim. Erosion can claim a square and place its object months later, and a
  square with nothing on it has nothing to rename. Succession puts objects on exactly such
  squares, so it meets the hole more often than correction does, but it does not close it.
- Trees above ground level, indoors, on water or on farmed ground. The existing plantable
  square test governs, unchanged.
- An exact trunk count. The census measures the tree slots the map authors placed, before
  worldgen rejects the ones whose footprint will not fit, so it establishes the ordering and
  the rough magnitude rather than a target the mod must hit.
- Street, wall and flowerbed erosion, which are untouched.
