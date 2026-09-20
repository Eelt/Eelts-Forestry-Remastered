# B42 lua and engine notes

Engine-level findings that cost real debugging time, kept here so they are not rediscovered
the hard way. Every entry was observed in game or read out of the shipped files on the Steam
install reporting version `42.20.4`, revision `b0bbce05d5`.

Tree-specific facts live in [b42-tree-matrix.md](b42-tree-matrix.md). This file is about the
engine, the lua runtime, and the modding surface.

## The game's lua overflows `%` at 32 bits

The game runs Kahlua, not LuaJIT or PUC Lua, and its modulo operator truncates to
`Integer.MAX_VALUE` somewhere internally.

A coordinate hash written the ordinary way, multiplying by large primes before taking a
modulo, produced this:

```
operands            10,566,669,500,456
correct a % 1000    456
game returned       8,419,185,853,456   =  a - 2147483647 * 1000
```

The result was meant to land in `[0, 1)` and came back as 8.4 billion, which silently
disabled a comparison that then never changed behaviour.

**What to do:** treat any `%` whose left operand can exceed `2^31 - 1` as unsafe. Reduce the
operands first. Multiplying two world coordinates together is already enough to break it,
since map coordinates reach five digits.

```lua
-- Unsafe: operands reach 1e13
local h = (x * 374761393 + y * 668265263) % 1000

-- Safe: largest intermediate is about 252000
local h = (((x % 1000) * 73 + (y % 1000) * 179) % 997)
```

## `OnDeviceText` passes the line's translation key, not a uuid

The `_guid` argument that reaches `ISRadioInteractions.checkPlayer`, and therefore
`isKnownMediaLine` and `addKnownMediaLine`, is the `text` field of the `RecMedia` line, which
is the `RM_` prefixed translation key. Line 11 of the tree planting tape arrives as
`RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39`, not as the bare uuid, even though the media entry
itself is keyed on the unprefixed id. Confirmed in game 2026-09-09 by printing every guid
through a full playback of the tape.

`checkPlayer` also returns early, before calling `addKnownMediaLine`, when the listener is
asleep or on the other side of a wall from the source. So an unknown to known transition on
that guid is the engine's own once per player guard, and a wrapper can reuse it by reading
`isKnownMediaLine` either side of the delegated call rather than keeping its own record.

## `getPoisonPower` exists only on `Food`

It is not on `InventoryItem`, so calling it on a `HandWeapon` such as `Base.Sapling`, or on a
plain item such as `Base.Pinecone`, fails with the same `Object tried to call nil` shape as a
missing global. Vanilla always guards it, in `ISForageIcon.lua` with
`instanceof(item, "Food")` and in `ISInventoryPane.lua` with `item:IsFood()` plus a
herbalist type check.

```lua
local poison = instanceof(item, "Food") and item:getPoisonPower() or 0
```

Guard by type rather than by item id. Testing `getFullType() == "Base.HollyBerry"` happens to
be safe today because that item is Food, but it silently couples the guard to one id and
breaks the moment a second Food propagule is added.

This generalises: a Java method that lives on a subclass is simply absent on the parent, and
Kahlua reports the absence at the call site as a nil call rather than as an unknown method,
so the error names the enclosing lua function and not the method that is missing.

## `iterList` is not a global

Three vanilla files iterate Java lists with `iterList`, and all three declare it as a
**file-local**: `forageSystem.lua:48`, `ISSearchManager.lua:13` and `ISBaseIcon.lua:23` each
carry their own copy. There is no global of that name.

Calling it from a mod file parses cleanly and then fails at runtime with

```
java.lang.RuntimeException: Object tried to call nil in <function> at KahluaUtil.fail
```

which names the calling function rather than the missing one, so the stack trace points at
the loop and not at the cause. In debug the error opens the lua debugger overlay.

Iterate with an index instead, which is what most of the codebase does:

```lua
local objects = square:getWorldObjects()
for i = 0, objects and objects:size() - 1 or -1 do
    local item = objects:get(i):getItem()
end
```

The `or -1` arm covers both a nil list and an empty one, since `size() - 1` is then `-1` and
the loop body never runs.

Any Java-side collection reached from lua behaves this way: `getWorldObjects`, `getItems`,
`getZones`, `getObjects` and the media lists are all `size()` and `get(i)`, zero indexed.

## `luajit` validates syntax, not the game's arithmetic

`luajit -bl file.lua` is a good syntax check and catches nothing about numeric behaviour.
Handed the broken expression above, LuaJIT returned the correct `0.456` while the game
returned garbage. A local check passing says the file parses, and no more.

**What to do:** keep using it for syntax, but verify anything numeric by printing values from
inside the running game. Three rounds of re-deriving a formula on paper found nothing; one
round of printing the intermediate values found it immediately.

## `SandboxVars` goes stale

`SandboxOptions.toLua()` is what populates the `SandboxVars` table, and only the new game
screen calls it, on Play. The in-game sandbox editor, `ISServerSandboxOptionsUI:onButtonApply`,
updates the Java options and never calls it. So changing a setting mid-game leaves
`SandboxVars` holding the old value until the world reloads.

**What to do:** read the option object rather than the table, which is what vanilla does for
its own settings, for example `PlantGrowingSeasons` in `SPlantGlobalObject.lua`.

```lua
local option = getSandboxOptions():getOptionByName("YourMod.YourOption")
local value = option and option:getValue()
```

`optionByName` is keyed on the **full** id, `Prefix.Name`, not the short name.

## Sandbox options: file, ids and translation keys

A mod's options are read from `<versionDir>/media/sandbox-options.txt`, falling back to the
common directory. The file needs `VERSION = 1,` and then `option` blocks.

An id of the form `Prefix.Name` is split by `initSandboxVars`, so the value also appears as
`SandboxVars.Prefix.Name`, subject to the staleness above.

Translation keys are all prefixed `Sandbox_`:

| Key | Source |
|---|---|
| `Sandbox_<page>` | the `page` field, used as the tab title |
| `Sandbox_<translation>` | the option name |
| `Sandbox_<translation>_tooltip` | the tooltip |
| `Sandbox_<valueTranslation>_option1` .. `N` | enum value labels |

Enum options need `numValues` and a **1-based** `default`.

## Translations are JSON in B42

`Translator` resolves `media/lua/shared/Translate/<LANG>/<File>.json` and reads each mod's
version directory. B41's `Sandbox_EN.txt` form is gone. Some workshop mods still ship the old
files alongside new ones, which makes the wrong pattern easy to copy.

## The debug console cannot see a mod's globals

`UIDebugConsole.ProcessCommand` evaluates in its own lua state, reported in stack traces as
`Lua(Vanilla).console`. A global a mod defined is not there, so
`YourMod_Something.field = true` fails with `attempted index of non-table` at
`KahluaThread.tableSet`, and reading one fails with `attempted index: <field> of non-table`.
The command is soft, it prints a stack trace and the game carries on.

This is not the same as client and server files being separated. In single player a client
file reads a global defined in a server file perfectly well, which is how
`EeltsForestryRemastered_TreeDebugMenu.lua` reaches `Eelt_STreeGrowthSystem`. Only the
console is walled off.

**What to do:** put anything you need to toggle or read at runtime behind a context menu
entry in a client file, not behind a console command. A mod also needs to print its own
evidence, since the game logs nothing when a lua file loads and a silent mod is
indistinguishable from one that never loaded.

## A tree is not in `worldobjects`

In `OnFillWorldObjectContextMenu`, the clicked square's tree is **not** in the `worldobjects`
list; only the ground blend is. Iterating the list looking for an `IsoTree` silently finds
nothing.

**What to do:** reach it through the square.

```lua
local square = worldobjects[i]:getSquare()
local tree = square and square:getTree()
```

Note also that the event sits behind two gates in `ISWorldObjectContextMenu.lua`: an early
return from the Java class `ISWorldObjectContextMenuLogic.createMenuEntries`, and a
`fetch.safehouseAllowInteract` check. Options added this way land at the **top level** of the
right click menu, not under Debug.

## `SGlobalObjectSystem:OnChunkLoaded` is not a discovery hook

Despite the name, it fires only for chunks that already contain objects belonging to that
system, and its body only removes orphans. It cannot be used to find new objects to adopt,
because on a fresh save there are none.

Its own comment says so, and it is easy to misread as a general chunk-load event.

What it is good for is the opposite job. `self.system:getObjectsInChunk(wx, wy)` returns
exactly that system's own objects in the chunk being loaded, with no scan and no radius, so
bringing already owned objects up to date on arrival is the one thing the hook answers
directly. The same property that makes it useless for discovery makes it right for this.

Two details for an override. The hook is invoked from java, by
`zombie.globalObjects.SGlobalObjectSystem.chunkLoaded(int, int)` calling the lua method by
name, so a derived method resolves normally and nothing has to be registered. And the base
body ends with `finishedWithList`, which returns the ArrayList to a pool for reuse, so an
override takes its own copy from `getObjectsInChunk` rather than holding the one the base
method is about to recycle.

## No lua event sees a world object being placed by the engine

`OnObjectAdded` is raised **only from lua**, in player-driven paths such as traps, rain
barrels, moveables and dropped items. No Java class raises it.

Everything the engine places arrives without an event: the authored map through `CellLoader`,
procedural generation through `WorldGenChunk`, and erosion respawns through
`NatureTrees.validateSpawn`. If a mod needs to notice those, it has to scan.

The corollary is useful: an object a **player** places does fire the event, so player-created
things can be tracked for free.

## The four seasons and their lengths

Stepped a day at a time through a full year on 2026-09-12, reading
`ErosionMain.getInstance():getSeasons()` after nudging it with `setDay` each day. The default
configuration gives four seasons of very unequal length:

| Season | Starts | Days | Ends |
|---|---|---|---|
| Spring | 9 February | 65 | 14 April |
| Early Summer | 15 April | 142 | 2 September |
| Autumn | 3 September | 64 | 5 November |
| Winter | 6 November | 95 | 8 February |

So "Early Summer" covers what a player would call spring, summer and the end of August, and is
more than twice the length of autumn. Spring is over before the middle of April. Anything
tuned per season needs that in front of it: an equal fraction of each season is not an equal
number of days, and two months of real spring sit inside the Early Summer season.

`getSeasonDay()` is zero based and `getSeasonDays()` is the season's length, so progress is
`getSeasonDay() / getSeasonDays()` and reaches but never quite equals one.

## `EveryTenMinutes` and `EveryHours` are in-game time

Both are driven by `GameTime.getTimeOfDay()`. At the default day length, ten in-game minutes
is roughly twenty five real seconds.

Note that `SFarmingSystem` subscribes to `EveryTenMinutes` and then discards five of every six
calls to get an hourly tick. `EveryHours` exists and is raised three lines away in the same
Java method, so prefer it if hourly is what you want.

Neither fires when the date is changed by hand, for example by a debug tool writing to
`GameTime` directly. `ErosionMain.mainTimer` also only recomputes the season when it observes
`GameTime` changing, so a forced date jump leaves the season stale until it next runs.

## `Rand.NextBool(n)` is true for any n at or below zero

`NextBool(n)` is `Next(n) == 0`, and `Next(max)` returns `0` when `max <= 0`. So a roll whose
computed bound reaches zero or goes negative is not rare, it is **certain**.

This is load bearing in `IsoTree.dropWood`, where `roll = min(6 - logYield, 4)` reaches 0 at
log yield 6 and -2 at log yield 8, making every drop on the largest trees guaranteed rather
than chance.

## A tree from `IsoTree.new` has no `attachedAnimSprite` list

`IsoObject:getAttachedAnimSprite()` returns `nil`, not an empty list, on an object the engine
did not place. A tree built in lua with `IsoTree.new(square, sprite)` is one of those, so any
code that does

```lua
local attached = isoObject:getAttachedAnimSprite()
if not attached then return end
```

silently skips it forever. On a deciduous species the base sprite is the bare winter tree and
every leafy look is an overlay, so the visible result is a planted tree that looks dead in
every season while an adopted wild tree beside it looks correct. Nothing is logged.

Create the list before adding to it, the way `ISDestroyStuffAction.lua:284` does:

```lua
isoObject:setAttachedAnimSprite(ArrayList.new())
```

`ArrayList.new()` with a dot is the form used in 50 places; the one `ArrayList:new()` with a
colon is the outlier.

## Clear `attachedAnimSprite` before changing a sprite

An `IsoObject` can carry overlay sprites in `attachedAnimSprite`. Changing the base sprite
without clearing them leaves the old overlay drawn on top of the new sprite, which looks like
a second object behind the real one.

`ErosionObj.setStageObject` calls `attachedAnimSprite.clear()` before setting, and anything
that assigns sprites has to do the same.

```lua
local attached = isoObject:getAttachedAnimSprite()
if attached then attached:clear() end
```

## Reaching erosion from lua

`ErosionMain.getInstance()` is available to lua even though vanilla passes the instance into
`DebugDemoTime` as an argument rather than fetching it. Useful for reading or forcing the
season:

```lua
local seasons = ErosionMain.getInstance():getSeasons()
seasons:getSeasonDay()      -- days into the current season
seasons:getSeasonDays()     -- length of the current season
seasons:setDay(day, month, year)
```

`getClimateManager()` is not an independent source of season data. `ClimateManager` sets its
season to `ErosionMain.getInstance().getSeasons()`, so both report the same values.

`ErosionSeason.names` lists six seasons, but `setSeasonData` only ever assigns `curSeason` 1,
2, 4 and 5. The reachable names are **Spring**, **Early Summer**, **Autumn** and **Winter**.
`Late Summer` and `Default` never appear.

## Lua sees three erosion classes and no more

`LuaManager$Exposer.shouldExpose` is a `HashSet.contains` against the set built by explicit
`setExposed` calls in `exposeAll`. There is no package scan and no transitive exposure of
return types, so a class absent from that list cannot be named from lua at all. From
`zombie.erosion` the list holds only `ErosionConfig` with its four nested classes,
`ErosionMain`, and `season/ErosionSeason`.

`ErosionRegions`, `ErosionRegions$Region`, `ErosionCategory`, `NatureTrees`, `ErosionWorld`
and `ErosionData` are all absent. That closes every route to the category list: `regions` is
a public static `ArrayList` and `Region.categories` is public, but neither can be reached.
Nor could a replacement be installed if they were, since the game's lua cannot subclass an
abstract java class, and `NatureTrees` keeps `soilRef`, `spawnChance` and `trees` private
final.

`ErosionConfig` is exposed but offers nothing here. Its `Seeds`, `Time` and `Season` fields
are package private with no getters, and none of them concern trees.

## Erosion decides a square's trees once, at first init

`ErosionMain.loadGridsquare` calls `ErosionWorld.validateSpawn` behind an
`if (!square.init)` guard, and `initGridSquare` sets `init`. `ErosionWorld.update` only
iterates the `ErosionCategory$Data` entries that `validateSpawn` already created. Nothing
else calls `validateSpawn`, and the periodic path reaches the same method: `updateMapNow`,
driven by `mainTimer` and `EveryTenMinutes`, calls `loadGridsquare` per square.

So natural tree establishment is one decision per square, taken the first time that square
is erosion loaded, and never revisited. There is no ongoing vanilla spawner competing with
a mod's own placement.

Within a region the first category to claim a square wins: `ErosionWorld.validateSpawn`
breaks out of the category loop as soon as one returns true. `NatureTrees` is category 0 of
region 0, so a square it takes is one `NatureBush`, `NaturePlants` and `NatureGeneric` can
never touch, and a square they take can never grow an erosion tree.

`NatureTrees.validateSpawn` refuses any square holding more than one object, reads the
species pool from `soilRef[square.soil]`, and spawns only when `square.rand(x, y, 101)` falls
under `spawnChance[square.noiseMainInt]`. The roll is deterministic from the square's
position and noise.

## No lua runs before erosion on chunk load

`IsoChunk.doLoadGridsquare` calls `ErosionMain.LoadGridsquare(square)` and then, on the same
square in the same loop iteration, fires the lua `LoadGridsquare` event:

```
847: invokestatic  zombie/erosion/ErosionMain.LoadGridsquare(IsoGridSquare)
880: ldc_w         "LoadGridsquare"
885: invokestatic  zombie/Lua/LuaEventManager.triggerEvent(String, Object)
```

Lua always arrives after erosion has placed whatever it placed. Interception is impossible;
correcting the result on `LoadGridsquare` is the only option, and because the decision is
never revisited, correcting it once per square is permanent. Erosion is skipped entirely
when the chunk's `jobType` is `SoftReset`.

## Renaming a tree takes its square off erosion for good

`ErosionObj.getObject` walks the square's objects and matches on
`this.name.equals(object.getName())`, returning null when nothing matches. Once
`ErosionCategory$Data.hasSpawned` is set, `updateObj` calls it on any change of stage,
season or bloom, and a null result runs `clearCatModData(square)`, which drops the category
data from `square.regions`.

Renaming a tree therefore severs erosion ownership permanently, since `validateSpawn` cannot
run again to reclaim the square. The mod's `ADOPTED_NAME` rename already does this. The same
path should clear a chopped erosion tree that was never renamed, though that has not been
watched in game.

The relinquish is lazy. It happens on the first update where the displayed stage, season or
bloom actually changes; until then the stale data sits inert and `hasSpawned` keeps it from
placing anything.

## The rename releases grass and bushes too, not only trees

`ErosionObj` is one class, and all four nature categories build their objects from it.
`NatureTrees`, `NatureBush`, `NaturePlants` and `NatureGeneric` each construct `ErosionObj`
instances in their own `init`, and the `name` field that `getObject` matches on lives on
`ErosionObj` rather than on any category. `NatureBush` names its objects from `f_bushes_1_`
sprites and `NatureGeneric` from `e_newgrass_1_`.

So the relinquish above is an object mechanism, not a tree mechanism. Renaming a grass or
bush object makes `getObject` return null on the next update and `clearCatModData` drops that
square's category data exactly as it does for a tree.

One difference matters. A tree is decided once, but `NatureGeneric` and `NatureBush` cycle
their own objects on erosion's timer, so an understory square is contested until the rename
lands rather than being a one shot to overwrite.

## `disableErosion` is a one way switch for the whole square

`IsoGridSquare:disableErosion()` sets `ErosionData$Square.doNothing`, which `loadGridsquare`
checks before reaching `ErosionWorld.update`. That gates every erosion category on the
square, not only trees, and `Square.save` persists it as a flag bit. `reset()` clears it but
lives on the unexposed `ErosionData$Square`, so lua can never undo it and an uninstalled mod
would leave the square inert for good. Vanilla sets the same flag itself on any square no
category claimed.

`removeErosionObject` reads as a general escape hatch but compares its argument against
`"WallVines"` and silently ignores anything else.

Given the rename above, none of this is needed to take a tree from erosion.

## Erosion has no succession between its nature categories

Region 0 carries the whole vegetation ladder, and each category owns its own sprite families:

| Category | Places |
|---|---|
| `NatureGeneric` | `e_newgrass_1_`, `blends_grassoverlays_01`, ferns |
| `NaturePlants` | `d_plants_1_`, `vegetation_groundcover_01_` |
| `NatureBush` | `f_bushes_1_`, `vegetation_foliage` |
| `NatureTrees` | the eleven tree tilesets |

Exactly one of them owns a square. `ErosionWorld.validateSpawn` breaks out of the category
loop at the first claim, and `validateSpawn` never runs again for that square, so the
assignment is permanent. `clearCatModData` removes only the entry matching its own
`regionId` and `categoryId`, but since only one category ever claimed, dropping it empties
region 0 for that square with no way to refill it.

Nothing promotes a square from one category to the next. Grass never becomes bush, bush
never becomes tree, and a square that loses its object keeps nothing in its place. Felling a
tree is a permanent reduction in vegetation, and a cleared field stays cleared.

`IsoChunk.CheckGrassRegrowth` is not a general counterexample, but it is not only the animal
pasture mechanic either. It visits zones of type `GrassRegrowth`, and
`IsoGridSquare.removeGrass` registers one on any square it clears, so the player's own scythe
creates them as well as animals grazing. What it restores is narrow: it walks the floor's
attached anim sprites, finds the one named `blends_natural_01_87` that `removeGrass` put
there, and removes it. That returns the ground to its grass appearance and nothing else. The
`e_newgrass` tufts `removeGrass` deleted are not replaced, and no other vegetation is.

`removeGrass` itself requires the floor to carry the `grassFloor` property, overlays
`blends_natural_01_87` on it, and deletes every object flagged `canBeRemoved`. Pacing is
`SandboxOptions.animalGrassRegrowTime`, in hours, which defaults to 48 and is the sandbox
option named "Grass Regrowth time".

The `animal` in that option's name is where it came from, not a condition on it.
`IsoGridSquare.removeGrass` is the only thing in the game that creates a `GrassRegrowth` zone
and `IsoChunk` is the only thing that reads one, so every caller gets the same treatment:
`AnimalData` and `AnimalEventPacket` in java, and `ISScything`, `ISPlowAction` and
`ISShovelAction` in lua. The method takes no arguments, so it cannot tell one caller from
another even in principle.

## How erosion eases vegetation into the world

All four nature categories share one shape, and it is worth copying rather than inventing.

Each stores three things per square in its `CategoryData`: `gameObj`, `spawnTime` and, except
for `NaturePlants`, `maxStage`. So every layer has its own start date and its own ceiling per
square, not a world-wide schedule.

`validateSpawn` decides whether the square is claimed at all:

| Category | Claim roll | `spawnTime` |
|---|---|---|
| `NatureGeneric`, grass | none, it takes every square offered | set without a roll |
| `NaturePlants`, groundcover | `rand(x, y, 101)` against `spawnChance[noiseMainInt]` | `100 - eValue` |
| `NatureBush` | the same roll | `100 - eValue` |
| `NatureTrees` | the same roll | `130 - eValue` |

Two consequences. Grass is not probabilistic: where grass owns the region entry for a square,
it always appears, which is why a vanilla forest floor is continuous rather than speckled. And
the layers are staggered by construction, since plants and bushes can begin at `eTicks` 0 on a
high noise square while trees cannot start before 30.

Each category builds its `spawnChance` table in `init` by interpolating with
`ErosionCategory.clerp` over the noise index, from a different starting point per category, so
density is a graded curve over one noise field rather than a flat share. One value per square
therefore decides both how rich it is and how early it starts.

Growth is in place. `ErosionCategory.updateObj` calls `ErosionObj.placeObject` only for the
first appearance and `setStageObject` after that, so an object matures by having its sprite
swapped rather than being removed and re-added.

## `placeObject` does not check whether the square is occupied

`ErosionObj.placeObject` calls `createObject`, then `setStageObject`, then adds the result
straight to the square. Nothing on that path asks what is already there. The occupancy test
lives in `NatureTrees.validateSpawn`, which refuses a square holding more than one object,
and that runs at claim time only.

`validateSpawn` sets `spawnTime` to `130 - noiseMainInt`, and `update` places nothing until
`eTicks` reaches it, so a claimed square can sit empty for a long stretch of a young world.
Anything placed there in the meantime does not stop erosion adding its own tree on top when
the tick arrives. Lua cannot see the pending claim, since `ErosionCategory$Data` is not
exposed.

## Forage zones come only from the biome map

`media/lua/server/metazones/metazoneHandler.lua`, `doMapZones`, reads each map's
`objects.lua` and skips every object whose type is `Vegitation`, `DeepForest`, `Forest`,
`TownZone`, `Farm`, `FarmLand` or `TrailerPark` before any of the registration branches are
reached. Those authored rectangles never become zones.

In Muldraugh that discards 1666 `Forest` rectangles covering 11255093 squares, along with all
the authored `DeepForest`, `Vegitation`, `Farm`, `FarmLand`, `TownZone` and `TrailerPark`
zones. Every forage zone `getZones` can return for those types comes from the per cell
`maps/biomemap_*.png` through `BiomeMapConfig.lua` instead.

Two consequences for anything keyed on zone type. `Vegitation` and `PHMixForest` are
commented out of the biome map and skipped from `objects.lua`, so they exist by neither
route. And plain `Forest` is only biome map pixels 59 and 79, `clay_shore` and `clay_lake`,
which is 204315 squares of shoreline rather than the large authored forest the `objects.lua`
rectangles suggest.
