## Why

Trees in B42.20 do not really grow. `docs/b42-tree-matrix.md` records why, and all three
reasons are independent:

- Growth is a function of one global `eTicks` counter rather than per-tree elapsed time, so
  every tree sharing a spawn time is the same size everywhere on the map.
- Once `eTicks` passes `spawnTime + cycleTime` a tree is at its maximum forever. Nothing
  grows after that, and `eTicks` itself stops at 100.
- `NatureTrees.validateSpawn` caps erosion-spawned trees at stage 3, so a wild forest never
  produces a JUMBO of any size.

Meanwhile every one of the eleven species has finished art for all eight stages, including
the 2x2, 3x3 and 5x5 sheets, and the authored map only ever places jumbo sizes. So the
world has mature trees placed by hand and small trees placed by erosion, with nothing ever
moving between the two.

This change makes trees grow on their own elapsed time, which is a visible feature by
itself: forests mature where the player spends time. It is also the backend the planting
system needs, so building it first means planting has somewhere to plant into rather than
inventing growth alongside items, recipes and a VHS gate.

## What Changes

- Add a server-side global object system, `Eelt_TreeGrowth`, that tracks a tree per square
  and advances it through stages 0 to 7 on accumulated in-game time, with a client-side
  counterpart for multiplayer.
- Add `42.20/media/sandbox-options.txt` entries: an enum choosing which trees may grow and
  how far, and a double controlling the pace.
- The enum has three values: stock erosion behaviour, player-planted trees may reach
  JUMBOXXL, and all growth may reach JUMBOXXL. It defaults to all growth.
- The double is a growth time multiplier defaulting to 1.0, where 1.0 is roughly three
  in-game months from stage 0 to stage 7.
- Under the default, the system adopts any tree below full size near a loaded player and
  grows it from whatever stage it is already at, taking over both its stage and its seasonal
  appearance.
- Add the option names and value labels to `42.20/media/lua/shared/Translate/EN/Sandbox.json`.
- Update `README.md` and `docs/b42-tree-matrix.md` to record the new behaviour and how it
  relates to vanilla erosion.

Selecting stock erosion behaviour leaves vanilla completely untouched.

## Non-goals

- **Planting.** Nothing here lets a player create a tree. This change only grows trees that
  already exist, which is what makes it testable with debug-placed trees. The enum's
  player-planted value is defined now so the option does not have to change later, but it
  behaves identically to stock until the planting change ships.
- **Propagule items, the VHS gate, and the acorn decision.** All still carried forward in
  `docs/b42-tree-matrix.md`.
- **Changing what a tree drops.** Growth changes a tree's size, and size already drives log
  yield through vanilla's own `LOGS_PER_SIZE`. No drop table is touched.
- **Growing trees the player has never been near.** Adoption is a bounded scan around
  loaded players, so unvisited areas stay untouched.
- **Species change or death.** A tree grows; it does not switch species, wither, or need
  water. Health and mortality belong to the planting change if anywhere.
- **Reclaiming squares.** A growing tree stays one object on one square, so nothing is
  cleared or displaced as it gets larger.

## Capabilities

### New Capabilities

- `tree-growth`: how an existing tree advances through its size stages over time, what
  controls the pace and ceiling, and what the mod does and does not take over from vanilla
  erosion.

### Modified Capabilities

None. `tree-drops` governs which species yield a propagule, and that is unaffected by a
tree's size changing.

## Impact

New files:

- `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`
- `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua`
- `42.20/media/lua/client/EeltsForestryRemastered_TreeGrowthClient.lua`
- `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, a debug-only right
  click submenu for inspecting a tree, forcing a stage, and skipping a month. Gated on
  `isDebugEnabled()`, or the `UseDebugContextMenu` capability in multiplayer, so it is
  invisible in normal play.

Modified files:

- `42.20/media/sandbox-options.txt`
- `42.20/media/lua/shared/Translate/EN/Sandbox.json`
- `README.md`
- `docs/b42-tree-matrix.md`

Persistence: the global object system writes `gos_Eelt_TreeGrowth.bin` into the save.

Verified against the installed build, version `42.20.4`, revision `b0bbce05d5`. Tree facts
come from `docs/b42-tree-matrix.md` and are not restated here.

- `media/lua/server/Map/SGlobalObjectSystem.lua` and `SGlobalObject.lua`. The server-side
  base classes, their persistence through `SGlobalObjects.registerSystem(name)` into
  `gos_<name>.bin`, `setModDataKeys` and `setObjectModDataKeys` for declaring saved fields,
  and `RegisterSystemClass` for wiring the object lifecycle events including
  `OnSGlobalObjectSystemInit`.
- `media/lua/client/Map/CGlobalObjectSystem.lua`. The client counterpart and the
  `sendCommand` and `OnServerCommand` pair used to push state to clients.
- `media/lua/server/Traps/STrapSystem.lua` and `STrapGlobalObject.lua`. The closest working
  reference: a small system registering through `RegisterSystemClass`, identifying its own
  objects by `getName()`, ticking on `Events.EveryHours`, and using
  `getGameTime():getWorldAgeHours()` as an absolute clock rather than its own counter.
- `zombie/iso/objects/IsoTree.class`, decompiled. `setSprite` re-runs `initTree`, which
  re-reads the `tree` sprite property and recomputes both `size` and `logYield`. Changing
  the sprite is therefore sufficient to change the tree's size.
- `media/lua/server/WorldGen/features/tree/*_jumbo_xl.lua` and `*_jumbo_xxl.lua`, plus
  `zombie/erosion/obj/ErosionObj.class`. A jumbo tree is a single object on a single
  square. The 3x3 and 5x5 patterns in worldgen fill the surrounding squares with
  `$subbiome` ground to reserve visual space; they do not place additional tree objects.
- `zombie/erosion/categories/NatureTrees.class`, decompiled. `update` reasserts its own
  stage sprite when its computed stage changes, which is the source of the conflict the
  design has to resolve.
- `zombie/sandbox/CustomSandboxOptions.class` and the shipped `fix-conifer-cone-drops`
  change. The sandbox file format and its lua access path are already proven.
