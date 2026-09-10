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

## No lua event sees a world object being placed by the engine

`OnObjectAdded` is raised **only from lua**, in player-driven paths such as traps, rain
barrels, moveables and dropped items. No Java class raises it.

Everything the engine places arrives without an event: the authored map through `CellLoader`,
procedural generation through `WorldGenChunk`, and erosion respawns through
`NatureTrees.validateSpawn`. If a mod needs to notice those, it has to scan.

The corollary is useful: an object a **player** places does fire the event, so player-created
things can be tracked for free.

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
