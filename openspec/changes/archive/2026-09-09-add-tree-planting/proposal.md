## Why

The mod can grow a tree but cannot make one. `add-tree-growth` shipped a per-tree elapsed
time system that carries a tree through all eight stages, and it left a hole in the middle
of its own sandbox option: `EeltsForestryRemastered.TreeGrowth` offers "Only trees you plant
grow", and nothing in the game can ever satisfy it. `planted` is written into the global
object's saved keys and is set to `false` at every call site, so that setting currently
grows nothing at all and is indistinguishable from the base game option next to it.

The base game has no way to plant a tree either. It has the fiction for one and none of the
mechanism: `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]`, "Home VHS: Tree Planting
Guide", is twenty two lines of correct arboriculture advice attached to no feature. Its
`spawning = 0` means it cannot even be found in loot by the media system's own rules, so
the tape is unreachable content describing an unimplemented one.

Everything planting needs to land on now exists. Growth provides the destination, the tree
matrix records which species live in which forage zone, and `fix-conifer-cone-drops`
established the wrapper that reads a tree before it topples.

## What Changes

- Add a plant action reachable from the ground square's context menu, requiring a propagule
  and a digging tool. It creates a stage 0 tree of the propagule's species, hands it to
  `Eelt_TreeGrowth` already flagged `planted`, and consumes the propagule.
- Three propagules ship. `Base.Sapling` covers all eleven species, `Base.Pinecone` covers
  the two conifers that bear cones, and `Base.HollyBerry` covers American Holly.
- Chopping a tree stamps the felled tree's species onto the saplings and cones it drops, so
  a propagule taken from a known tree plants that tree's species. The species is read from
  the standing tree's sprite in the same pre-topple read the cone fix already performs.
- A propagule carrying no stamp, which means one that was foraged, one from a save that
  predates this change, or one dropped by a fell path the mod does not intercept, plants a
  species rolled from the planting square's forage zone, restricted to the species that
  propagule can represent.
- Only an unpoisoned `Base.HollyBerry` may be planted. A berry that has been foraged carries
  poison power and is rejected; a berry from a chopped Holly is clean and plants.
- Add `EeltsForestryRemastered.RequireTreePlantingTape`, a boolean defaulting to on. While it
  is on, planting is unavailable until the player has watched the tape's eleventh line.
- Unlock planting by wrapping `ISRadioInteractions`'s `checkPlayer` and recording the unlock
  on the player when the line with translation key
  `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39` plays. `RecMedia` is not mutated.
- Give the tape a way into the world. `spawning = 0` keeps it out of loot and the tape is
  the gate, so planting would otherwise be unreachable with the option at its default. A
  VHS's recording is per-item data rather than a separate item type, so the change spawns
  ordinary `Base.VHS_Home` copies with the Tree Planting Guide already recorded on them and
  places those in the loot tables. Neither the vanilla item nor the `RecMedia` entry is
  touched.
- Rename `EeltsForestryRemastered_ConeDrops.lua` to `_TreeDrops.lua`. Species stamping and
  the Hemlock cone hang off the same `ISChopTreeAction:animEvent` wrapper, and installing a
  second wrapper on one method to keep the filename would be worse than the rename.

`Base.Acorn` is left exactly as it is, and the tree-growth setting's meaning does not change,
only its reachability.

## Non-goals

- **Propagule items for the eight deciduous species.** Still unbuilt and still out of scope,
  for the reasons in `docs/future/propagule-items.md`. Those eight plant from a stamped
  sapling, which is why the sapling has to carry a species at all.
- **The acorn.** `Base.Acorn` stays foraging-only and plants nothing. There is no oak in
  B42.20, and adding real propagules later weakens the case for reusing it, so binding it to
  a species now would only have to be undone.
- **Everything the tape describes beyond the hole.** Pot tiers, bare-root seasonal
  restriction, soil moisture and root rot, planting depth, air pockets, minimum spacing,
  proximity to structures, markers, and animal damage are all still carried forward. Line 11
  is the only line this change claims.
- **Survival, mortality and watering.** A planted tree is a tree. It does not fail to take,
  wither, or need tending, and it is chopped and grown by the same rules as any other.
- **Germination time and dormancy tiers.** The ripening table in `propagule-items.md` needs
  the eight items to exist before it means anything. Every propagule here plants
  immediately.
- **A seasonal gate on planting.** Vanilla's Autumn and Winter gate on the Holly berry drop
  already restricts when a clean berry can be obtained. Nothing further is imposed on when
  it may be put in the ground.
- **Changing drop counts.** Stamping writes to items the base game already produced. No
  species gains or loses a sapling, cone, log or branch.
- **Foraging changes.** The foraging tables keep no relationship to the species growing in
  the zone, and this change does not give them one. It only reads the zone when a propagule
  arrives with no species of its own.

## Capabilities

### New Capabilities

- `tree-planting`: how a player turns a propagule into a tree. What may be planted, which
  species results, where planting is allowed, what it requires the player to have and know,
  and how the tape unlocks it.

### Modified Capabilities

- `tree-drops`: chopping a tree now records the felled tree's species on the saplings and
  cones it yields. The existing guarantee that yields are unchanged in number and kind still
  holds, and a new one is added that the recorded species matches the tree that was felled.
- `tree-growth`: the "only player-planted trees" setting gains real behaviour. A planted tree
  is adopted at the moment it is created rather than by the proximity scan, is flagged as
  planted for the life of the save, and grows under that setting while wild trees do not.
  The requirement named "A setting controls which trees grow and how far" is retired for
  "A setting controls which trees grow": nothing about the shipped option changes, but the
  old name promised a size ceiling control that does not exist, and it carried a scenario
  describing the player-planted setting in a world where planting was impossible.

## Impact

New files:

- `42.20/media/lua/shared/EeltsForestryRemastered_Propagules.lua`, the propagule to species
  mapping, the per-item eligible species sets, and the forage zone weights used when a
  propagule carries no stamp.
- `42.20/media/lua/shared/EeltsForestryRemastered_TapeUnlock.lua`, the `checkPlayer` wrapper.
  Shared rather than client, because `ISRadioInteractions` lives in `lua/shared/RadioCom/`
  and `OnDeviceText` runs on the server in multiplayer.
- `42.20/media/lua/client/EeltsForestryRemastered_PlantTreeMenu.lua`, the context menu entry
  and its validity checks.
- `42.20/media/lua/client/EeltsForestryRemastered_PlantingQA.lua`, a debug-only menu for
  working through the in-game checks this change cannot verify any other way: ground item
  snapshots either side of a chop, a kit of tools and propagules including a deliberately
  poisoned berry, stage 6 fixtures of four species, and a tree state checkpoint that survives
  a save so growth can be compared across a reload. Gated on `isDebugEnabled()` and single
  player, so it is inert in normal play and in multiplayer.
- `42.20/media/lua/client/TimedActions/EeltsForestryRemastered_PlantTreeAction.lua`.
- `42.20/media/lua/server/EeltsForestryRemastered_TreePlanting.lua`, which creates the tree
  and adopts it.
- `42.20/media/lua/server/Items/EeltsForestryRemastered_Distributions.lua`, which adds
  `Base.VHS_Home` to a small set of containers and stamps the Tree Planting Guide onto the
  copies it spawns.
- `42.20/media/lua/shared/Translate/EN/IG_UI.json` and `ContextMenu.json`, the action and
  menu strings.

Modified files:

- `42.20/media/lua/server/EeltsForestryRemastered_ConeDrops.lua`, renamed to
  `EeltsForestryRemastered_TreeDrops.lua` and extended with species stamping.
- `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, which gains an entry
  point that adopts a specific tree as planted, bypassing the wild adoption gate.
- `42.20/media/sandbox-options.txt` and `42.20/media/lua/shared/Translate/EN/Sandbox.json`.
- `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, to show a propagule's
  stamped species and to plant without the tape.
- `README.md`.
- `docs/future/carried-forward.md` and `docs/reference/b42-tree-matrix.md`. The decisions this
  change consumes move to reference as description. The maximum growable size bullet is
  wrong as written and is corrected: `add-tree-growth` already settled it as the three-value
  `TreeGrowth` enum, and there is no separate size ceiling option.

Persistence: the species stamp is item modData on the propagule, and the planted flag is an
existing saved key on the global object, so `gos_Eelt_TreeGrowth.bin` gains no new field. The
tape unlock is per character.

Verified against the installed build, version `42.20.4`, revision `b0bbce05d5`. Tree facts
come from `docs/reference/b42-tree-matrix.md` and are not restated here.

- `media/lua/shared/RadioCom/ISRadioInteractions.lua`. `getInstance` builds a closure table,
  assigns it to the file-local `instance` in `Init`, and registers `self.OnDeviceText` on
  `Events.OnDeviceText`. `OnDeviceText` resolves `self.checkPlayer` by field lookup at call
  time, so replacing that field on the instance takes effect for an already registered
  handler. `checkPlayer` returns early on `player:isKnownMediaLine(_guid)` and calls
  `addKnownMediaLine` before doing any work, so a wrapper that tests the guid before
  delegating reuses vanilla's once-per-player guard instead of keeping its own. This is
  cheaper than `docs/future/carried-forward.md` assumed.
- `media/lua/shared/RecordedMedia/recorded_media.lua`, line 8906. The tape's eleventh line
  carries `codes = "FRM+1"` and the guid the unlock hangs on, confirming both.
- `media/lua/shared/Moveables/ISMoveableSpriteProps.lua`, around line 1989, and
  `media/lua/client/Tests/TimedActionsTests.lua`, line 678. Both build a tree the same way:
  `IsoTree.new(square, sprite)`, then `square:AddTileObject`, then
  `transmitCompleteItemToClients` on the server. The test builds `e_americanholly_1_3`, which
  is one of the eleven species this change plants, so the constructor is proven against the
  exact sprite set involved.
- `media/lua/shared/Foraging/Categories/Berries.lua` and `forageSystem.lua` line 2225.
  `Base.HollyBerry` is the sole entry in the `poison` group, and `doPoisonItemSpawn` is what
  applies `setPoisonPower`. `IsoTree.dropWood` does not run it, which is why a chopped berry
  is clean. `getPoisonPower` is readable from lua, used that way in `ISInventoryPane.lua` and
  `ISForageIcon.lua`.
- `media/scripts/generated/items/weapon.txt`. `base:digplow` is the existing tag on shovels,
  trowels and hand shovels, so the tool requirement reuses a vanilla tag rather than naming
  items.
- `media/scripts/generated/items/weapon.txt` line 9094. `Base.Sapling` is an improvised
  two-handed blunt weapon with no species field of any kind, which is why the species has to
  be carried in modData.
- `media/scripts/generated/items/normal.txt` line 4989 and
  `media/lua/shared/RecordedMedia/ISRecordedMedia.lua`. `Base.VHS_Home` carries
  `MediaCategory = Home-VHS` and nothing more; which recording a tape holds is per-item,
  set through `setRecordedMediaData` or `setRecordedMediaIndexInteger` as
  `InvContextMedia.lua` and `ClientCommands.lua` line 1186 both do. The `spawning` value is
  passed straight to Java's `RecordedMedia:register` and is the only thing keeping the guide
  out of loot, which confirms the tape is unreachable rather than merely rare.
