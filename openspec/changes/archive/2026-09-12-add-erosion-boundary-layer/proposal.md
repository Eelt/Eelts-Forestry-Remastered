## Why

The base game decides which tree species grows on a square from erosion soil and position
noise, and never consults the forage zone or the authored biome that square belongs to. A
pine forest gets maples in it, and the species weights this mod already carries in
`zoneSpecies` describe what the map intended but govern nothing except planting.

That decision cannot be prevented. Lua cannot name `NatureTrees` or the erosion category
list, cannot subclass an abstract java class to replace the category, and always runs after
erosion on chunk load. What it can do is overwrite the result once, permanently, because
erosion takes the decision once per square and renaming a tree severs its ownership of that
square for good.

Nothing else in the planned forestry work can start until this exists. Vegetation succession
puts its own vegetation on squares that erosion would otherwise still be deciding, so the
boundary that takes a square away from erosion has to come first.

## What Changes

- A new correction pass runs on the lua `LoadGridsquare` event. On the first sight of a
  square carrying a tree the base game placed, the pass rerolls that tree's species from the
  local `zoneSpecies` weights, keeps its size stage, renames it so erosion relinquishes the
  square, and takes it into the mod's tree system.
- The pass records which squares it has settled, because `LoadGridsquare` fires on every
  chunk load rather than once per square.
- A new setting, on by default, controls whether the pass runs at all.
- The species weights move out of `EeltsForestryRemastered_Propagules.rollSpecies`, which
  answers only "what may this item become", into a selection that can be asked what belongs
  on a square with no item involved. Planting's observable behaviour does not change.
- **BREAKING** for the growth setting's base-game choice. That setting currently means the
  world behaves exactly as it would without the mod. Composition correction is independent
  of it, so under that choice species are still corrected. A corrected square is owned by the
  mod outright: the base game's growth of that tree ends and is not emulated, so under that
  choice a corrected tree stays the size it was corrected at.
- The hourly seasonal refresh runs under the base-game growth choice, which it currently
  skips. A renamed tree is off erosion's seasonal handling permanently, so without this the
  pass would leave trees showing stale foliage forever.
- A second new setting, also on by default, chooses which seasonal rule a tree the mod owns
  follows. On is the mod's rule, which staggers when trees turn and holds summer foliage into
  autumn. Off is the base game's rule, every tree in an area turning together the
  moment the game reports autumn. The mod keeps driving the appearance either way, because a tree it owns
  can never be handed back to erosion's seasons.
- Trees are taken over at any size stage, including the largest. Adoption currently refuses
  the largest stage, so without lifting that guard the pass could not correct the biggest
  trees in a forest at all. Trees adopted before reaching the largest stage already stay
  managed after they get there; the guard only affects trees first met at full size.
- The cost of the pass is measured before the rest is built on it, since it runs for every
  square of every chunk load and cannot be switched off at the source.

## Capabilities

### New Capabilities
- `forest-composition`: which tree species grow wild on a square, how the mod takes that
  decision away from the base game's erosion system permanently, and what it costs.

### Modified Capabilities
- `tree-growth`: the base-game growth choice no longer means the world is untouched, the
  largest size no longer exempts a tree from being taken over, seasonal appearance is
  maintained independently of which trees are allowed to grow, and a setting chooses which
  seasonal rule that maintenance follows.

## Impact

New: `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua` for the pass, and
a species selection shared by planting and the pass.

Changed: `EeltsForestryRemastered_TreeGrowthSystem.lua` for the largest-stage adoption guard
and the base-game-mode early return, `EeltsForestryRemastered_TreeGrowthObject.lua` for the
two seasonal rules, `EeltsForestryRemastered_Propagules.lua` for
the selection split, `42.20/media/sandbox-options.txt` and `Translate/EN/Sandbox.json` for
the two new settings.

### B42.20 files and tables this rests on

No vanilla file is edited or shadowed. The pass reads the lua `LoadGridsquare` event and
`getZones`, and writes only to trees it has renamed.

The engine behaviour it depends on was verified by disassembling the installed
`projectzomboid.jar`, version 42.20.4, revision `b0bbce05d5`, and is recorded in
`docs/reference/b42-lua-notes.md` under "Lua sees three erosion classes and no more",
"Erosion decides a square's trees once, at first init", "No lua runs before erosion on chunk
load", "Renaming a tree takes its square off erosion for good" and "`disableErosion` is a one
way switch for the whole square". The species weights come from the composition audit in
`docs/future/tree-management-and-genetics.md`, which resolves every tree feature in
`WorldGen/biomes/map/*.lua` through `WorldGen/features/tree/*.lua` to its actual sprite.
Neither is re-derived here.

## Non-goals

- Placing a tree on a square erosion left bare. The pass corrects what is there and adds
  nothing, so tree density is unchanged. Establishment belongs to succession.
- Correcting the size stage. A corrected tree keeps the stage erosion gave it. The scoping
  documents put stage distribution in the policy the boundary asks, and also say that what
  the policy decides belongs to vegetation succession; the only numbers for it are labelled a
  baseline needing a trunk census first. The boundary is built so stage can be added to the
  policy later without changing how the pass works.
- Grass, groundcover, ferns and bushes. Only `NatureTrees` squares are touched, and the
  other erosion categories are left alone entirely.
- Genetics and inherited autumn timing. The pass stores no trait, and the metadata model
  those need is separate work.
- The unplaced claim. Erosion can claim a square and place its tree months later, and a
  square with no object on it has nothing to rename. The pass cannot see the pending claim
  and does not try to; this is recorded as a known hole, not closed here.
- `disableErosion`, which gates every erosion category on a square, persists in the save and
  cannot be undone from lua.
- Crowding ceilings, density limits and the trunk census they would need. The composition
  audit is explicit that a species share says which species the trees are and not how closely
  they stand, and the succession scope is explicit that crowding limits apply to natural
  recovery and do not thin existing forests. Correction therefore leaves tree density exactly
  as the base game set it.
- Any change to street, wall or other non-tree erosion.
