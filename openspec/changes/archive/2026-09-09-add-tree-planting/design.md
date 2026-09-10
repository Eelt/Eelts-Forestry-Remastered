## Context

See `proposal.md` for motivation. What matters here is the shape of what already exists.

`Eelt_STreeGrowthSystem` is a server-side `SGlobalObjectSystem` that opens with
`if isClient() then return end`. It owns a lua object per tree square, keyed on the tree
having been renamed to `Eelt_AdoptedTree`, and it already saves a `planted` boolean that
nothing ever sets. Adoption today happens only through `adoptNearPlayers`, which is gated on
`mayAdoptWildTrees()` and so runs only under the all-trees setting. Planting therefore cannot
reuse that path: under the setting that exists to grow planted trees, the only adoption
routine in the mod is switched off.

`EeltsForestryRemastered_ConeDrops.lua` already wraps `ISChopTreeAction:animEvent` and
performs the one read that matters, capturing the tree, its square and its log yield before
delegating, because the tree is reset and pooled the instant it topples.

`EeltsForestryRemastered_TreeGrowthSprites.lua` is the shared species table. It maps every
sprite name the game addresses back to a tileset and stage through `sprites.identify`, and
back out through `sprites.getBase`. Both directions are needed here: identify to read a
felled tree's species, getBase to build a stage 0 sprite for a new one.

## Goals / Non-Goals

**Goals:**

- One wrapper on `ISChopTreeAction:animEvent`, not two.
- The species a propagule records is the tileset name, so it is the same key the growth and
  sprite tables already use.
- Planting works in single player and multiplayer through the same code path, with the
  authoritative work on the server.
- No new saved field on the global object system, so `gos_Eelt_TreeGrowth.bin` does not
  change shape and existing saves load unchanged.

**Non-Goals:**

- A cursor or placement preview. Planting is a context menu action on a square, like the
  base game's own ground interactions.
- Any change to how growth paces, adopts wild trees, or handles seasons.

## Decisions

### The species is stored as a tileset name in item modData

Key `Eelt_Species`, value the tileset such as `e_redmaple_1`.

The alternative was the display name from `IsoObject:getName()`. That is rejected for the
reason the tree matrix already records: `getName()` returns a display name, while the tileset
is what actually identifies the species, and it is what `sprites.byName` and
`sprites.base` are keyed on. Storing the tileset means planting is a table lookup with no
translation step, and a propagule from a future species needs no new mapping.

Item modData survives being dropped, stored, and unloaded with the chunk, which is what the
spec requires of a recorded species.

### Stamping identifies new items by diffing the square, not by trusting the drop

Vanilla's `IsoTree.dropWood` creates the saplings and cones itself inside the Java call, so
the wrapper cannot see them being made. It can only look at the square afterwards.

Looking afterwards and stamping every unmarked sapling would stamp items that were already
lying there, which the spec explicitly forbids. So the wrapper snapshots the square's world
inventory items into a set before delegating, and after delegating stamps only the plantable
items that are not in that set.

The alternative was stamping by count, taking the last N items added. That was rejected
because nothing guarantees ordering, and because the square's contents can change for
reasons unrelated to the chop.

The Hemlock cones the mod adds itself do not need the diff, since the mod creates them and
can stamp them directly. They are stamped at creation for clarity rather than being left to
the diff to catch.

### `_ConeDrops.lua` is renamed to `_TreeDrops.lua`

Species stamping and the Hemlock cone both need the pre-topple read and both hang off
`animEvent`. Two files each wrapping the same method would mean two saved originals and an
ordering dependency between two files that do not know about each other. One wrapper doing
both is the only sound option, and once the file does both, `_ConeDrops` is the wrong name
for it. It matches the `tree-drops` capability it implements.

### Planting is a client action that asks the server to create the tree

The context menu and the timed action are client-side; the tree creation and adoption are
server-side, because `Eelt_STreeGrowthSystem` refuses to load on a client.

On completion the action sends a client command carrying the square coordinates and the
chosen tileset. The server handler validates the square again, builds the tree, and adopts
it. In single player the server lua runs in the same process, so the handler is reachable
directly and the command hop is skipped.

Validating on the server as well as the client is not defensive dressing: the client picks
the species when the propagule is unmarked, and the square can change between the action
starting and finishing.

### Plantable ground is whatever vanilla will let you dig a furrow in

`ISShovelGroundCursor.GetDirtGravelSand(square) == "dirt"` is the test, which is exactly what
`ISFarmingMenu.canDigHereSquare` uses to decide where a furrow may be plowed.

The alternative was a whitelist of natural ground tilesets maintained by this mod. That was
written first and then thrown away, because vanilla's rule turns out to be better in three
ways. It is a prefix test on `blends_natural_01_` and `floors_exterior_natural`, so it
already covers grass and forest floor rather than only bare dirt. It walks every non-item
object on the square rather than just the floor, so it finds the ground blend when the floor
object is not it. And it names the gravel, sand and clay sprites as separate results, which
means those are excluded for free.

Excluding sand and clay is the right answer rather than a side effect worth working around.
Vanilla will let a player dig those and will not let them plow a furrow there, and a tree is
closer to a furrow than to a hole.

Water and standing crops are checked separately, since vanilla's function covers neither on
the server.

### The species roll reads zones directly rather than through the foraging system

`forageSystem.getForageZoneAt(x, y)` returns exactly what is wanted, but it falls through to
`forageSystem.createForageZone`, which registers a zone as a side effect. Planting should not
create foraging state.

So the roll calls `getZones(x, y, 0)` and reads the zone type itself, which is the same thing
`getForageZoneAt` does first. The weights live in
`EeltsForestryRemastered_Propagules.lua`, derived from the biome tables in
`docs/reference/b42-tree-matrix.md`: a species' weight in a zone is the sum of its jumbo, xl
and xxl probabilities there, because only relative presence matters and the size a biome
would have placed is irrelevant to a stage 0 planting.

Where the square is in no zone, or in a zone that grows none of the species the propagule can
represent, the roll is uniform over the propagule's eligible set. That covers `TownZone`,
`ForagingNav` and `Forest`, all of which grow nothing, and it covers planting a cone in a
purely deciduous zone.

### The unlock is a flag on the player, not a learned recipe

`docs/future/carried-forward.md` assumed `learnRecipe`. In B42.20 the known-recipe list is
tied to `craftRecipe` definitions, and planting is a world action rather than a craft, so
using it would mean declaring a recipe that exists only to be a flag and that would then
appear in the crafting UI as something uncraftable.

The flag goes in `player:getModData()`. The halo text that tells the player they have learned
something is emitted directly, which is what the vanilla `RCP=` path does anyway once
`learnRecipe` returns true.

### The wrapper checks the media guid before delegating

`checkPlayer` calls `player:addKnownMediaLine(_guid)` before it does any work, so a wrapper
that delegates first can no longer tell whether this was the first time. Testing
`player:isKnownMediaLine(_guid)` before delegating reuses vanilla's own once-per-player guard
rather than keeping a parallel record, which is what `carried-forward.md` expected to have to
do.

The instance is reachable: `Init` assigns the closure table to the file-local `instance`, and
`OnDeviceText` resolves `self.checkPlayer` by field lookup at call time, so replacing the
field on `ISRadioInteractions:getInstance()` takes effect for the handler already registered
on `Events.OnDeviceText`. `RecMedia` is untouched, which keeps the no-vanilla-mutation rule.

In multiplayer `OnDeviceText` runs on the server and iterates online players, so the grant
happens server-side and the flag has to reach that player's client before the context menu
can read it.

### The tape is placed by a container fill hook rather than the distribution tables

The recording a tape carries is per-item data set through `setRecordedMediaData`, so a loot
table entry alone cannot produce the guide: it would produce an ordinary `Base.VHS_Home` with
a randomly assigned recording, and the guide is excluded from that assignment by its own
`spawning = 0`.

That leaves either adding the item through the distribution tables and then finding it again
to stamp it, or doing both in one place. `Events.OnFillContainer` for a small set of
container types, rolling a low chance and inserting an already-stamped `Base.VHS_Home`, does
both and keeps the whole concern in one file. It also avoids a merge against
`ProceduralDistributions`, which is the part most likely to conflict with another mod.

## Risks / Trade-offs

- **The `animEvent` wrapper is now load-bearing for two features.** A future third consumer
  will want to wrap it too, and the file will keep growing. Mitigation: the wrapper stays a
  thin capture-delegate-then-act shell, with the cone logic and the stamping logic as
  separate local functions it calls.

- **Renaming `_ConeDrops.lua` is a rename of a file that ships in a released mod.** A player
  updating in place gets the old file removed and a new one added. Mitigation: nothing
  persists under the old filename, the sandbox option name does not change, and the global
  object system is untouched, so there is nothing to migrate.

- **The square diff assumes vanilla drops land on the tree's square.** If `dropWood` ever
  scatters to neighbours, those items go unstamped. Mitigation: unstamped is the safe
  failure, since an unmarked propagule still plants by the zone roll. It degrades rather
  than breaks.

- **`getZones` returning nothing on an unzoned square.** Rather than refusing to plant, the
  roll falls back to uniform. The trade-off is that planting far from any zone gives no
  local flavour, which is preferable to an action that silently fails in some places.

- **The tape is the only route to planting under the default setting, and it is random
  loot.** A player can play a long time without finding it. Mitigation: the setting exists
  and is one click away, the container set is chosen to be places a player searches early,
  and the chance is tuned so the tape is uncommon rather than rare.

- **Stamped propagules from a chopped tree make foraged ones strictly worse.** That is
  intended, and it is the mechanic that makes felling a tree the way to propagate it, but it
  does mean a foraged sapling is now a lesser item than it looks. Mitigation: the item
  tooltip shows the recorded species when there is one, so the difference is visible before
  planting rather than after.

- **A poisoned holly berry is refused with no obvious reason.** A player below Foraging 5
  cannot see that a berry is poisoned, so the refusal will look arbitrary. Mitigation: the
  refusal text says the berry is not fit to plant rather than naming poison, which is true
  without leaking information the foraging skill is supposed to gate.

## Migration Plan

No save migration. The species stamp is absent on every propagule in an existing save, which
is exactly the unmarked case the spec already defines, so those plant by the zone roll. The
`planted` key already exists in `setObjectModDataKeys` and already defaults to false, so
existing global object data loads unchanged and every tree already adopted stays a wild tree.

Rollback is removing the mod version, which leaves planted trees in the world as ordinary
trees at whatever size they had reached.
