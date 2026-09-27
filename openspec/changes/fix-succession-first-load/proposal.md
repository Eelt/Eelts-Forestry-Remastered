## Why

The succession pass keeps its settings, the world's age and the current season in local
variables, read once while the mod's lua loads and then on `OnGameStart` and every ten in-game
minutes. The area around the player streams in between those two reads, so every square of it
is judged against the values read before the save existed. On a long running save the first
report of a session read "20000 squares, 17795 too soon": nearly the whole starting area was
treated as freshly cleared ground and skipped. It only recovers when a player passes within the
hourly sweep or the area is loaded again.

The same stale values give bushes repaired or placed in the starting area the season look from
before the save loaded, until the first hourly refresh. And `Understory.validateSprites` runs on
`OnGameStart`, after those same squares have already picked sprites from the unvalidated lists,
so a sprite ever dropped at validation would shift the hash's picks between the first squares
and the rest.

## What Changes

- The succession pass refreshes its settings, world age and season once, on the first square it
  handles after the save has loaded, before judging that square. The starting area is then
  judged on the loaded world's own date and time, the same as every square that loads later.
- Sprite validation runs at that same moment, before any square uses the lists, and runs only
  once however many times it is asked.
- The read while the mod's lua loads, the refresh on `OnGameStart` and the ten minute refresh
  stay as they are.

## Capabilities

### New Capabilities

### Modified Capabilities
- `vegetation-succession`: squares that load with the save are judged on the loaded world's
  date and time, like squares that load later.

## Impact

Changed: `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, whose load handler
refreshes once before its first square. `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`,
whose `validateSprites` becomes safe to call more than once.

Unchanged: the ladder, its timing, what grows and where, and the hourly sweep and refresh.

### B42 files and tables this rests on

No vanilla file is edited or shadowed. Read on 2026-09-27 from the 42.20 stable install, from a
CFR 0.152 decompile of `zombie/iso/IsoWorld.class` and from `~/Zomboid/console.txt`.

- `IsoWorld.init` loads the save's clock with `GameTime.getInstance().load()`, boots erosion with
  `ErosionGlobals.Boot`, initialises `ClimateManager` and fires `OnLoadedMapZones`, all before
  `WorldStreamer.instance.create()` starts streaming chunks. Tile definitions are loaded earlier
  still. So by the first `LoadGridsquare` event the world's age, its season and every sprite are
  already correct; only the mod's cached copies are stale.
- The chunks finish streaming before `OnGameTimeLoaded` fires, but the lua `LoadGridsquare`
  events for them arrive after it. Two sessions on 2026-09-27 showed the same order, one with
  LetMeDrive and one without: `OnGameTimeLoaded`, then the first square the pass saw, then
  `OnGameStart`. A refresh on `OnGameTimeLoaded` would therefore also have worked in both. The
  refresh is tied to the first square instead because that holds whatever order the events come
  in, and the order on a dedicated server has not been observed.
- The same console, from a long running save, printed the succession report before
  `OnGameStart` with 17795 of 20000 squares counted too soon.
- A third party mod in that session, LetMeDrive, holds `LoadGridsquare` handlers back during
  loading and replays the starting area just before `OnGameStart`. A refresh tied to the first
  square the pass actually sees works whichever way the squares arrive.

## Non-goals

- Changing when the ten minute refresh runs, or what it reads.
- Moving the tree growth system's catch up, which reads the world's age live and is not
  affected.
- Any change to how a square decides what it should carry.
