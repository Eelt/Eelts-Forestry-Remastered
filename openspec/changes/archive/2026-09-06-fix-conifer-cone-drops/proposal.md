## Why

Canadian Hemlock is a conifer and never drops a cone. `IsoTree.dropWood` decides that drop
with `name.toLowerCase().contains("pine")` against the sprite name, and `e_virginiapine_1`
is the only one of the eleven tilesets that matches. The species is flagged evergreen in
`NatureTrees` and is modelled as a conifer, so from a player's side it is a pine-shaped tree
that behaves as though it is not one.

This is the smallest useful piece of the forestry overhaul and it is worth doing first. It
is independent of the planting system, it needs only the species facts already established
in `docs/b42-tree-matrix.md`, and it exercises the whole pipeline once, a sandbox setting, a
lua hook and in-game verification, before anything larger depends on that pipeline working.

## What Changes

- Add `42.20/media/sandbox-options.txt` with one boolean option,
  `EeltsForestryRemastered.FixConiferConeDrops`, defaulting to on.
- Add `42.20/media/lua/server/EeltsForestryRemastered_ConeDrops.lua`, which wraps
  `ISChopTreeAction:animEvent` and drops a `Base.Pinecone` when a Canadian Hemlock topples,
  matching the chance and count vanilla already applies to Virginia Pine.
- Add `42.20/media/lua/shared/Translate/EN/Sandbox.json` for the option's display name
  and tooltip.
- Update `README.md`'s "What it does", which becomes the first entry there.
- Update `docs/b42-tree-matrix.md` so the Canadian Hemlock row and the cone test defects
  section record that the mod now corrects this, and so the outstanding in-game check is
  resolved by this change's verification step.

Vanilla behaviour when the setting is off is byte-for-byte unchanged.

## Non-goals

- **The acorn.** `Base.Acorn` cannot drop from any tree in B42.20 and there is no oak
  species to attach it to, so nothing here gives it a source. It keeps foraging and
  `RZSHermitCamp` as its only origins.
- **New propagule items.** Introducing `Eelt_` samaras, haws, drupes, pods and nutlets for
  the eight deciduous species is flagged for future work and is not started here. It is
  properly part of the planting change's item work.
- **The dead legacy fallbacks.** The four zero-padded `vegetation_trees_01_0*` equality
  tests never match, but the sprites they name are all `tree = 2`, so their log yield is 1
  and the block holding the cone line never runs for them regardless. Correcting the padding
  would change nothing observable, so it is not worth code.
- American Holly. It is modelled as a conifer but is an evergreen broadleaf that bears
  drupes, and vanilla already gives it a berry. It is deliberately left alone; see the
  design for why the visual similarity to Hemlock does not justify a cone.
- Trees felled by a vehicle or by fire. Those do not route through the timed action.
- The planting system, the VHS gate, and tree growth of any kind.
- Reconciling the debug lua's `Eelt's Forestry Remastered Mod:` print prefix with the
  `Eelt's Forestry Remastered:` prefix the project conventions describe. Real but unrelated.

## Capabilities

### New Capabilities

- `tree-drops`: what a tree yields when it is chopped down, and which species-specific
  propagules it produces. This is the first capability spec in the repository.

### Modified Capabilities

None.

## Impact

New files:

- `42.20/media/sandbox-options.txt`
- `42.20/media/lua/server/EeltsForestryRemastered_ConeDrops.lua`
- `42.20/media/lua/shared/Translate/EN/Sandbox.json`

Modified files:

- `README.md`
- `docs/b42-tree-matrix.md`

Every claim below was verified against the installed build, version `42.20.4`, revision
`b0bbce05d5`, at `Project Zomboid.app/Contents/Java/`. The tree facts are recorded in
`docs/b42-tree-matrix.md` and are not restated here.

- `zombie/iso/objects/IsoTree.class`, decompiled. `dropWood` gates every species drop behind
  `numPlanks > 2`, so a cone is only possible from log yield 3, which is size 4 and
  therefore stage 3. Cone chance per log iteration is `1 in roll` where
  `roll = min(6 - logYield, 4)`.
- `zombie/core/random/RandInterface.class` and `RandAbstract.class`, decompiled.
  `NextBool(n)` is `Next(n) == 0` and `Next(max)` returns `0` for `max <= 0`, so the roll is
  guaranteed at stages 5 and up.
- `media/lua/shared/TimedActions/ISChopTreeAction.lua`. `animEvent` handles the `ChopTree`
  event, calls `self.tree:WeaponHit`, and already tests `self.tree:getObjectIndex() == -1`
  to detect that the tree has toppled. Its drop-side work is guarded by `not isClient()`.
- `zombie/sandbox/CustomSandboxOptions.class`, `CustomSandboxOption.class` and
  `CustomBooleanSandboxOption.class`, decompiled. A mod's options are read from
  `<versionDir>/media/sandbox-options.txt`, needing `VERSION = 1,` and `option` blocks with
  `type`, `default`, and optional `page` and `translation`.
- `zombie/SandboxOptions.class`, decompiled. An option id of the form `Prefix.Name` is
  written into lua as `SandboxVars.Prefix.Name` by `initSandboxVars`.
