# Design

## Context

See `proposal.md` for motivation and for the vanilla files the approach rests on.

`EeltsForestryRemastered_PlantTreeMenu.lua` does three things in one handler: it gathers the
distinct propagule kinds the player carries, applies the gates (tape knowledge, a `DIG_PLOW`
tool, a fit propagule) to decide what to offer and what to disable, and, when a propagule is
picked, walks the character to the right clicked square and queues `Eelt_PlantTreeAction`. The
action's `isValid` re-checks the square and the propagule, and the server re-checks the square,
distance and knowledge on the command. None of that changes.

A cursor is an `ISBuildingObject` subclass that the engine drives through `DoTileBuilding`.
The subclass supplies `isValid(square)`, `render(x, y, z, square)` and `create(x, y, z, ...)`,
and can override `walkTo`. `ISBuildingObject:walkTo` calls `luautils.walkAdj` without
`keepActions`, which clears the timed action queue first.

## Goals / Non-Goals

**Goals:**

- One suitability function. The cursor's colour, the menu's presence and the action's
  `isValid` all ask `planting.isPlantableSquare`, so they can never disagree.
- One gate function. The world menu and the inventory menu decide availability and the reason
  text through the same code.
- The cursor survives its own success. Planting consumes the item it was opened with, so the
  cursor must not hold that item.

**Non-Goals:**

- Any change to the timed action, the server command or the species roll.
- Rendering a ghost sapling sprite under the cursor. The outline is enough and is what the
  scythe does.

## Decisions

### The cursor holds a propagule kind, not an item

The cursor is opened with the player, the tool and a kind: the propagule's full type plus the
species it carries, or nil for an unmarked one. That is the same key `gatherPropagules` already
builds to collapse a stack into one menu line. On each click it fetches the next carried item
matching that kind with `getFirstEvalRecurse` and hands that item to the action.

The farming seed cursor works the same way, storing `seedName` and fetching at planting time,
and for the same reason: the item that was clicked will be gone by the next click.

Alternative considered: holding the item and closing after one placement with
`dragNilAfterPlace`. Rejected in favour of repeat planting, decided at proposal time.

### Items already handed to a queued action are skipped

A click queues a walk and a plant, and the item is only removed when the plant performs. Two
quick clicks would otherwise fetch the same sapling twice, and the second action would fail its
`isValid` on arrival. So the cursor keeps the ids of the items it has handed out and its fetch
predicate excludes them. When the fetch finds nothing the cursor calls `setDrag(nil)` on itself,
which is also how it closes after the last of a stack.

Trade-off: a queued planting that is cancelled leaves its item claimed for the life of that
cursor. Reopening the cursor from either menu clears the claims, so the cost is one extra menu
trip in an unusual case.

### The cursor walks in `create`, not in `walkTo`

`ISBuildingObject:tryBuild` calls `walkTo` only when `ISBuildMenu.cheat` is false, and that flag
is `false or getDebug()`, so in debug mode every cursor skips the walk and plants from wherever
the character stands. The base `walkTo` also calls `luautils.walkAdj` without `keepActions`,
which would clear a planting still walking to its square. `ISShovelGroundCursor` sidesteps both
by walking inside `create` with `luautils.walkAdj(playerObj, square, true)`; the cursor does the
same and sets `skipWalk2` so the base `walkTo` returns true without walking. A first version
overrode `walkTo` instead and planted on the spot under the debug build cheat.

### The tool is fetched when the cursor opens and checked again on click

The tool is found once when the option is chosen, so the cursor can be refused with a reason at
that point, and found again on each click so that a tool dropped while the cursor is up does
not plant. The action already re-resolves the item by id on start.

### Rendering follows the scythe

`render` calls `renderIsoRect(x + 1, y + 1, z, 1, r, g, b, 0.5, 1)` in the good or bad
highlight colour from `getCore()`. That is the outline the player already knows from the
scythe, at a radius of one. The farming and shovel cursors' filled floor tile would also work;
the outline was chosen because it is what was asked for and because it does not obscure the
ground being judged.

Unlike the scythe, the cursor stays drawn while an action is running, so a player planting a
row can see where the next click will land while the character is still walking.

### Menus share one option builder

`PlantTreeMenu` gains a function that, given a context menu, a propagule kind and the player,
adds the labelled option, disables it with the tool or unfit reason where a gate fails, and
otherwise wires it to open the cursor. The world handler calls it once per kind under the Plant
Tree submenu, exactly as today; the inventory handler calls it once per distinct kind among the
right clicked items, directly on the menu. The tape gate is checked before either builds
anything, because vanilla deliberately gives no reason for that one.

The inventory handler flattens `items` with `ISInventoryPane.getActualItems`, keeps the ones
`propagules.isPlantable` accepts and whose container `isInCharacterInventory(player)`, and
collapses them to distinct kinds with the same key the world menu uses.

### File placement

The cursor lives in `42.20/media/lua/server/` as `EeltsForestryRemastered_PlantTreeCursor.lua`,
beside vanilla's own cursors. It was first written under `client/` on the reasoning that nothing
about a cursor runs on a dedicated server, and failed to load: the game parses a mod's `client/`
lua before vanilla's `server/` lua, so `ISBuildingObject` does not yet exist when
`ISBuildingObject:derive` runs at parse time. That is the reason vanilla keeps every cursor
under `server/BuildingObjects/`. The menu file stays under `client/` and reaches the cursor as a
global at option time, by which point everything has loaded.

## Risks / Trade-offs

- The controller path: `DoTileBuildingJoyPad` drives a one square cursor from the character's
  facing, and the base class maps A to place and B to cancel. Nothing in this change is joypad
  specific, but it has not been exercised. → Listed as a verification task; a failure there
  would be a base class matter, not a design change.
- Escape closing the cursor is java behaviour that was not read from source. → Verified in
  play on 2026-09-21: it closes an idle cursor, and while the character is walking to a clicked
  square it cancels the walk and the cursor together. Right click is read from the lua.
- Two menus can now open a cursor, and opening one replaces any cursor already up, including a
  vanilla one. → That is what `setDrag` does for every cursor in the game; no special handling.
- `ISBuildingObject:init` sets a dozen carpentry fields the cursor never reads. → Harmless,
  and every vanilla ground cursor carries them too.

## Open Questions

None that affect the specs or the tasks.
