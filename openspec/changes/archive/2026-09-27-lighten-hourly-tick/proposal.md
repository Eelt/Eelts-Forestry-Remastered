## Why

Everything the mod does on the hour runs in a single frame, and on a lower end PC the frame
the hour turns over is a visible hitch. That work is the tree update, the adoption scan
around each player, the succession sweep around each player and the recovered bush refresh.
The tree update is the largest part and the part that keeps growing: it visits every tree the
mod has ever adopted in the save, loaded or not, so the hitch gets worse the longer a world is
played.

Visiting unloaded trees is duplicated work. Under the default timing, a tree whose area loads
is brought up to the exact size its elapsed time earned, so growing it on the hour while it is
away changes nothing the player can see. Under the older timing, "Only while the area is
loaded", growing unloaded trees is the opposite of what the setting's name, its tooltip and the
tree growth spec promise: a tree is already grown when the player returns, and it comes back
drawn at its old size until its next stage redraws it.

## What Changes

- The hourly tree update visits only trees whose area is loaded, in both timing modes. Under
  the default timing nothing changes for the player, since arrival catch-up already covers
  every tree that was away. Under the older timing, a tree now advances only while its area
  is loaded, which is what that setting has always said it does.
- The mod keeps an in memory list of the adopted trees in loaded ground, filled when a chunk
  of theirs loads and when a tree is adopted, and pruned as trees unload or are removed. The
  hourly update walks that list instead of every tree in the save, so its cost follows the
  loaded area instead of the save's age.
- The rest of the hourly work is spread over the following frames under a small time budget
  per frame, in the same order as today: tree update, adoption scan, succession sweep, bush
  refresh. It finishes within seconds of the hour, with the same results it has now.
- The spreading is written first with a Lua coroutine, which the game's Lua supports, and
  timed against a plain cursor over the same work. Whichever costs less per frame is kept.
- The debug menu's hourly timing measures the whole hourly job, by part, and reports the
  worst single frame of a spread run.

## Capabilities

### New Capabilities

### Modified Capabilities
- `tree-growth`: under the older timing a tree does not advance while its area is unloaded,
  and the hourly upkeep does not stall a frame.
- `vegetation-succession`: the hourly sweep near players is held to the same stall limit as
  chunk loading.

## Impact

Changed: `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, which gains the
loaded tree list, the hourly job and its per frame driver.
`42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, whose hourly sweep and bush
refresh become steps the job can run a slice at a time.
`42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, whose hourly timing covers
the whole job. `42.20/media/lua/shared/Translate/EN/Sandbox.json` only if the older timing's
tooltip needs to change to match.

Unchanged: what grows, when a stage falls due, arrival catch-up, the chunk load passes, and
every setting's meaning under the default timing.

### B42 files and tables this rests on

No vanilla file is edited or shadowed. Read on 2026-09-27 from the 42.20 stable install: CFR
0.152 decompiles of `projectzomboid.jar` and the shipped lua.

- `zombie/globalObjects/GlobalObjectSystem` keeps every object in one `objects` list and
  removes one only through `removeObject`. Nothing removes an object when its chunk unloads,
  so `getObjectCount` and `getObjectByIndex` cover every adopted tree in the save.
- The shipped `SGlobalObject:getIsoObject` looks the object up at its square, and
  `SGlobalObjectSystem:OnChunkLoaded` only checks that each object in the loading chunk still
  has its tree and removes the record if not. It does not redraw anything, which is why a tree
  grown while unloaded under the older timing comes back at its old size.
- `se/krka/kahlua/j2se/J2SEPlatform.newEnvironment` registers `CoroutineLib`, and
  `zombie/Lua/LuaManager` builds its environment through it, so `coroutine.create`,
  `coroutine.resume` and `coroutine.yield` are available to mod lua. No shipped lua uses them,
  so they are checked in game before anything relies on them.
- LetMeDrive's source states that `OnTick` fires on a dedicated server as it does on a
  client, and its own per frame drain depends on it there. That was not read from the jar, so
  it is confirmed on a server in the verification tasks before the job relies on it.

## Non-goals

- Round robin across the ten minute ticks.
- Any change to what the hourly work decides, or to arrival catch-up.
- A sandbox setting for the per frame budget.
- Threads. The game runs all mod lua on one thread, and a mod cannot start another.
- The cost of the chunk load passes, which LetMeDrive already spreads for players who run it.
