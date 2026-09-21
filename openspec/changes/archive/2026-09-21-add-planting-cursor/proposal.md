## Why

Planting today is a world context menu action: right click a square, open Plant Tree, pick a
propagule, and the character walks to the square that was right clicked and plants there. The
square is chosen before the propagule, the menu gives no hint about which nearby squares would
have been accepted, and planting a stack of saplings means a right click and two menu levels
per tree.

The base game has a better fit for this already. A scythe, a shovel taking dirt, a seed being
sown or a tree being chopped all put a footprint under the mouse that reads green where the
action is allowed and red where it is not, and the click that follows is the one that commits.
Planting should work the same way, and it should also be reachable from the propagule itself in
the inventory, where a player looking at a sapling is most likely to want to plant it.

## What Changes

- Choosing a propagule from the Plant Tree submenu no longer plants on the square that was
  right clicked. It puts a one square planting cursor under the mouse, green on a square the
  existing suitability test accepts and red elsewhere, and a click on a green square walks the
  character over and plants there. A click on a red square does nothing.
- The cursor stays up after a planting so a stack can go in square by square. It closes when
  no propagule of that kind is left, or when the player right clicks or presses Escape, which
  is how every cursor in the base game closes.
- Right clicking a propagule in the inventory offers a Plant option for that propagule, with no
  submenu, whatever the mouse is near. The same gates apply as in the world menu: the tape has
  been watched if the setting demands it, a digging tool is carried, and a holly berry is not
  poisoned. Choosing it opens the same cursor.
- The world context menu itself is unchanged: same Plant Tree entry, same submenu of distinct
  propagules, same disabled entries and reasons.

## Capabilities

### Modified Capabilities
- `tree-planting`: choosing a propagule opens a planting cursor rather than committing to the
  square that was right clicked; ground suitability is shown on the cursor rather than by the
  menu's presence; and the propagule can be planted from the inventory.

## Impact

Changed: `42.20/media/lua/client/EeltsForestryRemastered_PlantTreeMenu.lua`, whose propagule
options open a cursor instead of queueing the action, and which gains the inventory hook.
`42.20/media/lua/shared/Translate/EN/ContextMenu.json` for any new label. `README.md` under
"You can plant trees".

Added: `42.20/media/lua/server/EeltsForestryRemastered_PlantTreeCursor.lua`, the cursor.

Unchanged: `TimedActions/EeltsForestryRemastered_PlantTreeAction.lua`,
`EeltsForestryRemastered_Planting.lua`, and the server side `EeltsForestryRemastered_TreePlanting.lua`.
The action, the suitability test and the server check are exactly what they were; only the way
the square is chosen moves.

### B42.20 files and tables this rests on

No vanilla file is edited or shadowed. Everything below was read from the lua shipped with
42.20.4 (`b0bbce05d5`), under `media/lua/`.

The footprint under the mouse is what the engine calls a drag. `IsoCell.setDrag(cursor,
playerNum)` installs one and `getDrag(playerNum)` reads it back; the lua side calls the objects
building cursors, every one an `ISBuildingObject` subclass in `server/BuildingObjects/`. While
one is installed the engine calls `DoTileBuilding(cursor, isRender, x, y, z, square)` in
`ISBuildingObject.lua` each frame, which tracks the hovered square, calls
`cursor:isValid(square)` and, on a release of the build button over a valid square, `tryBuild`.
`tryBuild` calls `cursor:walkTo` (by default `luautils.walkAdj`) and then `cursor:create`. With
`skipBuildAction` and `noNeedHammer` set the carpentry machinery is bypassed, which is how
`ISScytheGrassCursor`, `ISShovelGroundCursor` and `ISFarmingCursorMouse` are set up.

The scythe in `server/Animal/ISScytheGrassCursor.lua` draws its footprint with
`renderIsoRect(x + 1, y + 1, z, radius, r, g, b, 0.5, 1)`, in `getCore():getGoodHighlitedColor()`
or `getBadHighlitedColor()`, and hides it while an action is running. With a radius of 1 that is
the one square outline this change wants. The farming and shovel cursors draw a filled floor tile
through `getFloorCursorSprite():RenderGhostTileColor` instead; either is available.

`ISFarmingMenu.onSeed` in `client/Farming/ISUI/ISFarmingMenu.lua` is the nearest vanilla shape
to this change: a seed picked from a submenu installs `ISFarmingCursorMouse` with a validity
predicate and a square selected callback, the cursor records the seed type by name rather than
by item, and the callback fetches an item of that type at planting time. It stays installed after
a planting, and `dragNilAfterPlace` is the base class flag that would make it close instead.

A right click on the world clears the drag at the top of `ISWorldObjectContextMenu.createMenu`
(`client/ISUI/ISWorldObjectContextMenu.lua`), and a right click in the inventory does the same in
`ISInventoryPane` before it builds its menu, so dismissal needs nothing from this mod. The
controller B button clears it in `ISBuildingObject:onJoypadPressButton`, and the joypad path in
`DoTileBuildingJoyPad` gives a one square cursor controller support for free. Escape is handled
on the java side and is the base game's own behaviour for any cursor; it is listed for
confirmation in play rather than taken on trust.

The inventory hook is `Events.OnFillInventoryObjectContextMenu(player, context, items)`, fired
from `ISInventoryPaneContextMenu.createMenu`. `items` mixes bare items and stack tables, and
`ISInventoryPane.getActualItems(items)` flattens it. `ItemContainer.isInCharacterInventory`
tells whether an item's container is one the player carries.

## Non-goals

- Changing what may be planted, where, by whom, or what species results. Every gate and every
  suitability rule stays as it is; only how the square is picked changes.
- A footprint larger than one square, or any radius control. A tree is planted one square at a
  time.
- Walking to the cursor square before it is clicked, or auto planting a stack in a pattern.
- Planting from a propagule that is lying in a container on the ground or on the floor. The
  option is for propagules the player is carrying, as the world menu already is.
- Restyling the world context menu, its labels or its disabled reasons.
