# Tasks

Every task below was implemented. An unchecked one in group 4 is a check that was never run,
not code that was never written; those are listed in `docs/future/carried-forward.md`.

## 1. The cursor

- [x] 1.1 Add `42.20/media/lua/server/EeltsForestryRemastered_PlantTreeCursor.lua` defining
  `Eelt_PlantTreeCursor = ISBuildingObject:derive(...)` with `new(character, kind)`
  setting `skipBuildAction`, `noNeedHammer` and the player number, and `isValid(square)`
  returning `planting.isPlantableSquare(square)`. Done when the file loads with no lua error and
  `Eelt_PlantTreeCursor` is a table in the debug console.
- [x] 1.2 Add `render` to the same file drawing `renderIsoRect` at radius 1 in the good or bad
  highlight colour according to `isValid`, and never hiding while an action runs. Done when the
  file reads as such; colour in play is checked in group 4.
- [x] 1.3 Walk to the square in `create` with `luautils.walkAdj(playerObj, square, true)` and
  set `skipWalk2` so the base `walkTo` does nothing. Done when the base `walkTo` is not reached.
  A `walkTo` override was tried first and skipped under the debug build cheat, which `tryBuild`
  tests before it calls `walkTo`.
- [x] 1.4 Add the kind fetch to the same file: a predicate matching full type and species
  through `EeltsForestryRemastered_Propagules.getSpecies`, excluding item ids the cursor has
  already handed out, run through `getFirstEvalRecurse`. Done when a claimed id table exists on
  the cursor and the predicate reads it.
- [x] 1.5 Add `create` to the same file: re-find the tool with the `DIG_PLOW` predicate, fetch
  the next item of the kind, queue `Eelt_PlantTreeAction` for the square, record the item id as
  claimed, and call `getCell():setDrag(nil, self.player)` when no further item of the kind is
  left. Done when a read of the function shows each of those steps in that order.

## 2. The menus

- [x] 2.1 In `42.20/media/lua/client/EeltsForestryRemastered_PlantTreeMenu.lua`, replace the
  `plant` callback with one that opens `Eelt_PlantTreeCursor` through `getCell():setDrag`, and
  drop the square from the option arguments. Done when the world submenu's options no longer
  reference the right clicked square anywhere but the suitability check that decides whether to
  show Plant Tree at all.
- [x] 2.2 In the same file, lift the per kind option building (label, tool reason, unfit reason,
  cursor callback) into one function used by the world handler. Done when the world handler's
  loop body is a single call to it.
- [x] 2.3 In the same file, add an `OnFillInventoryObjectContextMenu` handler that checks the
  tape gate, flattens `items` with `ISInventoryPane.getActualItems`, keeps plantable items whose
  container `isInCharacterInventory(playerObj)`, collapses them to distinct kinds with the world
  menu's key, and adds one option per kind directly on the menu through the function from 2.2.
  Done when the handler is registered and reads as described.
- [x] 2.4 Make sure the menu file can reach the cursor at option time. Done when the game loads
  with no lua error from either file. Closed with no require: the cursor moved to `server/`
  after a `client/` placement failed to find `ISBuildingObject` at parse time, and the menu
  reads the global at option time.
- [x] 2.5 Add any label the inventory option needs to
  `42.20/media/lua/shared/Translate/EN/ContextMenu.json`, reusing
  `ContextMenu_Eelt_PlantSpecies` and `ContextMenu_Eelt_PlantItem` if their wording already
  fits a flat entry. Done when every `getText` key the menu file uses resolves without a raw key
  showing in the menu. Closed with no new key: the existing "Plant %1" and "Plant %1 from %2"
  read correctly as flat entries.

## 3. Documentation

- [x] 3.1 Update the "You can plant trees" section of `README.md` to describe choosing a
  propagule, the green and red square, planting a stack, and planting from the inventory. Done
  when the section no longer implies the right clicked square is where the tree goes.
- [x] 3.2 Record in `docs/reference/b42-lua-notes.md` what a drag is, that `ISBuildingObject`
  subclasses are the cursors, that `DoTileBuilding` drives them, that the base `walkTo` clears
  the queue, and that right click on world or inventory clears the drag. Done when the note is
  present and cites the vanilla files by path.

## 4. Verification in game

- [x] 4.1 Right click open ground with a sapling and a shovel carried, choose a propagule from
  Plant Tree. Look for a one square outline under the mouse and no walking or planting yet.
  Closed on 2026-09-21: the outline appears and nothing happens until a square is clicked.
- [x] 4.2 Move the cursor over grass, a road, a square with a tree, a water square and a
  square inside a building. Look for green on the grass and red on the other four. Closed on
  2026-09-21: green on grass, red on the other four.
- [x] 4.3 Click a green square. Look for the character walking adjacent, the dig animation,
  the sapling gone and a smallest stage tree on that square, with the cursor still up.
  Closed on 2026-09-21: a distant green square, reached from either menu, walks the character
  over before the dig plays. A first build planted on the spot under the debug build cheat,
  fixed by walking in `create`.
- [x] 4.4 Click a red square. Look for nothing happening and the cursor staying up. Closed on
  2026-09-21: the click does nothing.
- [x] 4.5 With three saplings of one kind, click three green squares in quick succession. Look
  for three walks and three trees in order, no cancelled planting, and the cursor closing on
  its own after the third. Closed on 2026-09-21: three saplings went in in click order and the
  cursor closed itself on the third click.
- [x] 4.6 Open the cursor and right click. Then open it again and press Escape. Look for it
  closing both times with nothing planted. Record whether Escape closes it, since that is java
  behaviour not read from source. Closed on 2026-09-21: Escape closes an idle cursor, and
  pressed while the character is walking to a clicked square it cancels both the walk and the
  cursor. Kept as is.
- [x] 4.7 Open the cursor, then drop the shovel and click a green square. Look for no planting.
  Closed on 2026-09-21: with the shovel dropped the click does nothing.
- [x] 4.14 Open the cursor with the shovel carried, drop the sapling, and click a green square.
  Look for the cursor closing. Closed on 2026-09-21: nothing is planted and the cursor goes,
  the same as with the shovel dropped.
- [x] 4.8 Right click a sapling in the inventory with the tape setting off. Look for a flat
  Plant option with no submenu, and the cursor opening when it is chosen. Closed on 2026-09-21
  for the sapling: the flat option appears and opens the cursor.
- [x] 4.16 Run the cursor on a client joined to a dedicated server, from both menus. Record
  the result whether or not it passes, and whether the planted tree appears for a second
  client. Closed on 2026-09-21: verified on a multiplayer server.
- [ ] 4.13 Right click a foraged holly berry, then a sapling with no digging tool carried, in
  the inventory. Look for the option disabled with the unfit and tool reasons respectively.
- [ ] 4.9 Turn the tape setting on with a character who has not watched it and right click a
  sapling in the inventory. Look for no Plant option. Watch the tape and look for it appearing.
- [x] 4.10 Look into a crate holding a sapling and right click it there. Look for no Plant
  option. Closed on 2026-09-21: a sapling in a crate gets no option; the same sapling in the
  character's inventory does.
- [x] 4.15 Select a sapling and a pine cone together in the inventory and right click. Look for
  one Plant option per kind. Closed on 2026-09-21: "Plant Pine Cone" and "Plant Sapling" both
  appear.
- [ ] 4.11 Click a green square, then before the character arrives drop a large item on it.
  Look for no tree and the sapling still carried.
- [ ] 4.12 With a controller, open the cursor from the inventory and place with A, cancel with
  B. Record the result whether or not it passes.
