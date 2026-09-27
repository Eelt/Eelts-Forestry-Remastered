# Tasks

## 1. The bush palette and its looks

- [x] 1.1 In `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`, replace the sixteen
  bush sprite names with sixteen entries of `NatureBush` index and size, in the same order the
  old names map to (indices 3, 5, 6, 8, 9, 11, 12, 15 at size 0, then the same at size 1), each
  carrying its Kentucky window as year positions with the dates as trailing comments, and
  `NatureBush`'s own `bloomStart` and `bloomEnd`, both from the table in design.md. Done when the
  table has sixteen entries and each old sprite `64 + i + 32 * size` corresponds to the entry at
  its old position.
- [x] 1.2 In the same file, add a function taking an entry and a look and returning the base
  sprite name and the foliage and flower or fruit overlay names, using base `i % 8 + 8 * size`,
  spring base plus 32, autumn base plus 48, summer `64 + i + 32 * size`, and the flower or fruit
  layer `80 + i + 32 * size`,
  and the look to overlay table in design.md, including the `Late Summer` split by stagger mode.
  Done when the function exists and reads as that arithmetic.
- [x] 1.3 In the same file, make `spriteFor("bush", x, y)` return the entry's base sprite, and add
  a way to get the entry the hash picks for a square. Done when `spriteFor` for grass and cover
  is unchanged and for bush returns an index 0 to 15 name.
- [x] 1.4 In the same file, make `validateSprites` check each bush entry's base, dropping the entry
  if it does not resolve and reporting unresolved overlays without dropping. Done when
  the startup print counts bush entries and names any dropped.
- [x] 1.5 In the same file, add the mapping from an old sprite name (`f_bushes_1_64` to `79`,
  `96` to `111`) to its entry, `id % 16` at size 0 below 96 and size 1 from 96. Done when the
  function returns nil for any other name.
- [x] 1.6 In `42.20/media/lua/shared/EeltsForestryRemastered_TreeSeasons.lua`, add
  `inWindow(x, y, from, to, season, progress)`, which shifts both ends by the square's
  `(stagger - 0.5) * SPREAD` and tests its year position against them, and a base game variant
  following `currentBloom`: Early Summer only, over `bloomStart` and `bloomEnd`, half the window
  offset by the square's stagger. Done when both functions exist and the shift reads as the same
  expression `seasons.staggered` uses.
- [x] 1.7 In `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`, make the look
  function from 1.2 add the flower or fruit layer when the stagger setting is on and `inWindow`
  holds for the entry's window, or when it is off and the base game variant holds. Done when the
  layer is appended after the foliage overlay in both branches.

## 2. Placing, repairing and refreshing bushes

- [x] 2.1 In `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, add a function that
  applies a look to one of the mod's bush objects: build the wanted overlay names, compare them
  with the parent sprite names in its attached anim sprites, and only on a difference rebuild the
  list and, on a server, call `transmitUpdatedSpriteToClients`. Done when a call on an up to date
  bush reaches no transmit.
- [x] 2.2 In the same file, make `place` attach the overlays for the current look before
  `AddTileObject` when the rung is bush. Done when the attach precedes the add in the function.
- [x] 2.3 In the same file, add the repair: given the mod's object with an old sprite, set the
  entry's base sprite on it and apply the current look. Call it in `evaluate` straight after
  `inspect`, before the sprite comparison. Done when a repaired object is the same object and
  the comparison that follows reads the new base.
- [x] 2.4 In the same file, add the in memory table of loaded bush positions, add to it wherever
  the pass sees or places one of the mod's bushes, and add a `refreshBushes` function that walks
  it, drops positions whose square is unloaded or no longer carries the mod's bush, and applies
  the look to the rest. Done when the table is filled from `evaluate`, `place` and the check in
  2.5, and is never saved.
- [x] 2.5 In the same file, add the discovery check to the exits that skip `inspect` (succession
  off in `classify`, untouched and too soon in `evaluate`): when the square holds more than one
  object, find the mod's object, repair it if its sprite is old, and register it if it is a bush.
  Done when each of the three exits calls the check and a one object square returns after one
  `size()` call.
- [x] 2.6 In the same file, extend `sweepNearPlayers` so that with succession off it still runs
  the discovery check on the squares it walks. Done when the early return on `not enabled` no
  longer skips the check.
- [x] 2.7 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, call
  `succession.refreshBushes()` from `everyHour` and from `refreshAllOverlays`. Done when both call
  it after the tree refresh.
- [x] 2.8 In `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, extend `describe` to
  print a bush's entry, size, current look, overlay names it carries and wants, its window with
  this square's shift applied and whether it is inside it, and whether its square is in the
  loaded bush table. Done when the debug menu's
  describe option prints those lines on a bush square.
- [x] 2.9 Record in `docs/reference/b42-lua-notes.md`: how the erosion system's `NatureBush`
  category builds a bush (base, snow, spring, autumn, summer and `setFlower` indices, shared
  bases); that the `setFlower` layer is berries for Blueberry and Red chokeberry and blossom for
  the others; its season display and `currentBloom` rule; the update chain from `GameTime` and
  `IsoChunk` through `ErosionMain` to `setStageObject`, and that single player refreshes a square
  only on chunk load; that `replaceExistingObject` only runs from `validateSpawn` and that
  `IsoChunk` turns legacy bush tiles and `randBush` into summer overlays before it; that the right
  click menu's Remove Bush and Remove Grass entries are built in java from the `canBeCut` and
  `canBeRemoved` flags plus a `CUT_PLANT` tool; that `IsoZombie.closeSneakBonusCoeff` gives cover
  for `f_bushes_1_96` to `111` as an object's own sprite; and that all 128 `f_bushes_1` tiles
  register as sprites. Record the Kentucky windows and their sources in the same section. Done
  when the section is present and cites the classes by name.

## 3. Removal counts as clearing

- [x] 3.1 In `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, wrap
  `ISRemoveBush.complete` the way `ISShovelAction.complete` is wrapped: keep the square, call the
  original, and call `understory.markCleared(square)` when not on a client and the action is not
  removing a wall vine. Require `TimedActions/ISRemoveBush` at the top. Done when the wrapper is
  present and skips `self.wallVine`.
- [x] 3.2 In the same file, wrap `ISRemoveGrass.complete` the same way, requiring
  `TimedActions/ISRemoveGrass`. Done when the wrapper is present.
- [x] 3.3 Update the succession section of `README.md` to say recovered bushes change with the
  seasons, flower or fruit at their Kentucky times and can be removed like any other bush, and
  that removing a plant starts that square's recovery again. Done when the section says so.
- [x] 3.4 In `42.20/media/lua/shared/Translate/EN/Sandbox.json`, extend
  `Sandbox_EeltsForestryRemastered_StaggerTreeSeasons_tooltip` to say the setting also times
  recovered bushes, their foliage, flowers and fruit, and that unchecking it gives the base game's
  timing for them too. Done when the tooltip mentions bushes and still reads as one paragraph.

## 4. Verification in game

- [ ] 4.1 Load a save made before this change that holds bushes grown back by recovery. Look for
  the console print naming sixteen bush entries and no dropped ones, then for those bushes
  showing the current season's look rather than full summer leaf. Console half closed on
  2026-09-27: a long running save printed "understory holds 16 bushes" with none dropped or
  missing, and "294 repaired from the first build, 294 tracked in loaded ground". The season
  look is still to be checked.
- [x] 4.2 Right click one of those bushes with a cutting tool carried. Look for Remove Bush, and
  the bush gone after choosing it. Closed on 2026-09-27: in a long running save, bushes grown
  back before this change that had no Remove Bush now offer it and can be removed.
- [ ] 4.15 Right click a recovered bush and a newly placed one from the debug menu's Bush rung
  with a knife carried. Look for exactly one Remove Bush entry under Gardening on each, and for
  possible branches and twigs after removing them.
- [x] 4.3 Right click a recovered bush with no cutting tool carried. Look for no Remove Bush,
  matching a base game bush. Closed on 2026-09-27: with no cutting tool carried, Remove Bush is
  not offered.
- [ ] 4.4 Remove a recovered bush and stay beside the square for a day. Look for it staying bare,
  and for describe reporting a fresh clearing time. Do the same with Remove Grass on recovered
  grass.
- [ ] 4.5 Use the debug menu to step a bush square through the year with stagger on. Look for
  bare, spring, summer and autumn foliage in that order, turning with a deciduous tree beside
  it, and for the autumn overlay arriving at first colour rather than midsummer.
- [ ] 4.6 Repeat 4.5 with the stagger setting off. Look for summer foliage through all of summer
  and autumn colour only in the first half of autumn.
- [ ] 4.7 With stagger on, step one bush of each palette species through the year with the
  debug menu. Look for azalea flowers from early April into early May, on bare or opening
  branches; New Jersey tea flowers through June into mid July; blueberries from mid June through
  July; St. John's wort flowers through July into mid August; chokeberry berries from mid
  September through December, on bare and snowy branches after leaf fall; and none of them outside
  those dates, allowing a week or two either side for the square's stagger.
- [ ] 4.14 With stagger off, repeat 4.7 beside a base game bush of the same species. Look for the
  recovered bush's layer appearing within the base game bush's early summer window.
- [ ] 4.8 Stand still across a season boundary with a recovered bush 40 or more squares away in
  loaded ground, then walk to it. Look for the new look, and for describe showing the square in
  the loaded bush table.
- [ ] 4.9 Let it snow in winter. Look for snow on recovered bushes as on the base game's.
- [ ] 4.10 Load the old save with succession off. Look for its recovered bushes repaired and no
  square gaining anything.
- [ ] 4.11 Try to pick up a grown recovered bush with a shovel. Record whether the pickup is
  offered and whether a bush comes back on that square on the next hourly sweep.
- [ ] 4.12 With succession timing on, drive the same route past recovering ground and untouched
  forest on a build with and without task 2.5. Record the microseconds a square for both, and
  whether the difference is noticeable in play.
- [ ] 4.13 On a client joined to a dedicated server, watch a recovered bush through a season
  change and remove one. Record whether the second client sees the new look and the removal.
