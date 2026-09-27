## Why

A player reported that a bush grown back by vegetation succession has no Remove Bush option on
its right click menu, and it was reproduced. A bush the base game placed on the square next to
it has one.

The cause is the sprite. Succession places each bush as a single object wearing one of sixteen
`f_bushes_1` sprites copied from the base game's `bush_regular` worldgen feature. Those sixteen
are not bushes. They are summer foliage overlays, indices 64 to 79 for a young bush and 96 to
111 for a grown one, which the erosion system's `NatureBush` category (package
`zombie.erosion`) attaches on top of a bare bush base. The base game's Remove Bush entry, its
cursor and its timed action all look for the `canBeCut` flag, and only the base sprites carry
it.

The base game reaches the same sprites from two places, worldgen features and the legacy bush
tiles in map data that `IsoChunk` converts on load, and in both cases `NatureBush` rebuilds the
object into a proper base and overlay bush on the square's first load. Succession places its
bushes after that first load, so nothing ever rebuilds them.

The same mistake freezes their appearance. A bush wearing its summer overlay as its own sprite
looks like midsummer in January, and never flowers or fruits.

Grass and groundcover are not affected. Every `e_newgrass_1` and `d_generic_1` sprite
succession places carries `canBeRemoved`, which is what Remove Grass looks for.

## What Changes

- A bush succession places is built the way `NatureBush` builds one: a bare base sprite from
  `f_bushes_1` 0 to 15 as the object's own sprite, which carries `canBeCut`, with the seasonal
  overlay attached on top. The base game's own Remove Bush entry, its cutting tool shortcut on
  the farming menu, its tool requirement, animation and branch and twig drops then apply to it
  unchanged, and the mod adds no menu entry of its own.
- The same eight `NatureBush` entries and two sizes stay in the palette, so recovered ground
  still matches the worldgen bushes beside it.
- A bush's foliage follows the season on the timing the mod already uses for trees: bare
  through winter, spring foliage from leaf out, summer foliage from the summer boundary,
  autumn colour from first colour, and bare again from leaves down, staggered per square. With
  the stagger setting off it follows the base game's split instead, as trees do. Snow needs no
  work, since the erosion system's `ErosionIceQueen` applies it to the shared base sprite.
- The layer `NatureBush` calls a flower shows at the time that plant does it in Kentucky, on
  calendar dates, whichever of the game's seasons they fall in. The art is blossom for three of
  the five species and ripe fruit for two:

  | Species | Layer shows | Kentucky window |
  |---|---|---|
  | Piedmont azalea | pink flowers | 1 April to 10 May |
  | New Jersey tea | white flowers | 1 June to 15 July |
  | Blueberry | ripe berries | 10 June to 31 July |
  | Shrubby St. John's wort | yellow flowers | 1 July to 15 August |
  | Red chokeberry | red berries | 15 September to 31 December |

  Each square shifts its window by the same stagger as its foliage. With the stagger setting
  off, the layer follows the base game's own timing.
- The stagger setting's tooltip says it times bushes as well as trees.
- A bush already placed in an existing save is repaired where it stands the next time its
  square loads or a player passes it: the same object is given its base sprite and overlay,
  keeping the species and size its old sprite showed. This runs whatever the succession
  setting is, since it repairs what is already there and grows nothing.
- Removing a plant with the base game's Remove Bush or Remove Grass is recorded as clearing the
  square, the same as scything or digging already is. Without this, succession would put the
  bush straight back on the next sweep, since the square's clock would still say it had earned
  one.
- A side effect: a grown recovered bush no longer gives zombies' close sneak cover. The base
  game lists sprites 96 to 111 for that bonus, which today's grown bushes happen to wear, and
  does not list the grown base sprites its own grown bushes wear. Recovered bushes end up
  matching the base game's.

## Capabilities

### Modified Capabilities
- `vegetation-succession`: bushes are built from a base sprite and a seasonal overlay, change
  with the season, flower or fruit at their Kentucky times, can be removed with the base game's
  own action, and bushes already placed are repaired. Removing vegetation through the base
  game's actions counts as clearing the square.

## Impact

Changed: `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`, whose bush palette
becomes `NatureBush` entry and size pairs carrying their flowering or fruiting windows, with a
function giving the base and overlay sprites for a look.
`42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`, which places, repairs and
refreshes bushes and hooks the two removal actions.
`42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, whose hourly tick and
forced refresh also refresh bushes. `42.20/media/lua/shared/EeltsForestryRemastered_TreeSeasons.lua`,
which gains a window test built on its existing year position and stagger.
`42.20/media/lua/shared/Translate/EN/Sandbox.json` for the stagger tooltip. `README.md` under
the succession section. `docs/reference/b42-lua-notes.md` for the findings below.

Unchanged: the ladder, its timing, the pace and density settings, the crowding ceiling and tree
establishment. What rung a square reaches, and when, is exactly what it was.

### B42 files and tables this rests on

No vanilla file is edited or shadowed. Read on 2026-09-27 from the 42.20 stable Steam install.
Java behaviour was read from CFR 0.152 decompiles of `projectzomboid.jar` run on the game's
bundled JRE; tile data from the shipped files; art from `media/texturepacks/Tiles1x.pack`. The
erosion classes below are byte identical in the B42.21 preview, and the menu reads the same
flags there. The Kentucky dates and their sources are in design.md.

- The world right click menu is built in java. `ISWorldObjectContextMenuLogic.fetch` records a
  square as `canBeCut` when an object's sprite has `IsoFlagType.canBeCut` and the player
  carries an unbroken `CUT_PLANT` item, and as `canBeRemoved` when the sprite has
  `IsoFlagType.canBeRemoved`. `doGardeningSubmenu` then adds Remove Bush and Remove Grass under
  Gardening, calling the lua callbacks `ISWorldObjectContextMenu.onRemovePlant` and
  `onRemoveGrass`. No lua adds either entry.
- Downstream every step keys on the same flags, read from the shipped lua:
  `ISRemovePlantCursor:getRemovableObject` and `ISRemoveBush:getBushObject` and `complete`
  (`canBeCut`), `CFarming_Interact.lua`'s cutting tool path through the same cursor, and
  `ISRemoveGrass` (`canBeRemoved`).
- Base game bushes take their seasons from the erosion system and nothing else. `GameTime`
  calls `ErosionMain.EveryTenMinutes`, whose `mainTimer` advances a day counter whenever the
  date changes, and `IsoChunk` calls `ErosionMain.LoadGridsquare` as each square loads. Both
  reach `ErosionWorld.update`, then `NatureBush.update`, which picks the display from
  `currentSeason` and `currentBloom` and applies it through `ErosionObj.setStageObject`. The day
  counter advances whatever the erosion speed setting is. In single player a square is
  refreshed only when its chunk loads; the walk over loaded cells in `mainTimer` runs only on a
  dedicated server. No class outside `zombie.erosion` sets bush overlays.
- `NatureBush.init` builds sixteen entries over eleven species. For entry `i`, with
  `trunk = i % 8`, the young base is `f_bushes_1_<trunk>` and the grown base `trunk + 8`; snow
  is base plus 16, spring overlay base plus 32, autumn overlay base plus 48; summer overlay is
  `64 + i` young and `96 + i` grown; the layer it registers with `setFlower` is `80 + i` young
  and `112 + i` grown. Entries `i` and `i + 8` share a base and their spring and autumn
  overlays, and differ in summer foliage and that layer. Every entry has an overlay and every
  one but Spicebush has the extra layer, so none is evergreen.
- Viewed from `Tiles1x.pack`, the `setFlower` layer is dark blue berries for entry 3
  (Blueberry) and small red berries for entry 8 (Red chokeberry), and blossom for entries 5, 11
  and 15 (Piedmont azalea, New Jersey tea, Shrubby St. John's wort). It sits cleanly over the
  bare base, the snow base and every foliage overlay at both sizes.
- `NatureBush.replaceExistingObject` turns any `f_bushes_1_<id>` object into entry `id % 16`
  at the grown size. It runs only from `ErosionWorld.validateSpawn`, which runs once per square
  before the lua `LoadGridsquare` event, so it never sees what succession places.
  `IsoChunk` maps legacy bush tile ids and the `randBush` placeholder to a random
  `f_bushes_1_64` to `79` before that happens.
- `NatureBush`'s season display, over `ErosionSeason`'s numbering (1 spring, 2 early summer,
  3 late summer, 4 autumn, 5 winter): winter bare, spring overlay in spring, summer overlay in
  early summer, autumn overlay for the first half of autumn then bare. `currentBloom` shows the
  extra layer only in early summer, between the entry's `bloomStart` and `bloomEnd` fractions
  of it, for half that window offset by the square's `magicNum`.
- `ErosionObj.setStageObject` puts the overlay, then the extra layer, into the object's
  attached anim sprites, the same list the mod already fills for tree foliage.
- `tiledefinitions_erosion.tiles` declares `f_bushes_1` as 16 by 8 with 128 tiles, and
  `IsoWorld.LoadTileDefinitions` registers a sprite for every one, so the overlay indices that
  have no properties in the text export still resolve. In the text export, 0 to 31 carry
  `canBeCut` and `vegitation`, 64 to 79 carry only `MoveWithWind`, and 96 to 111 carry the
  moveable Hedge properties with no `canBeCut`.
- `IsoZombie.closeSneakBonusCoeff` checks the own sprite of each object on a square, not its
  attached overlays, against a fixed table of sprites that give close sneak cover. The table
  lists `f_bushes_1_96` to `111` and none of 0 to 15.

## Non-goals

- A Remove Bush entry of the mod's own. With the base sprite in place the base game's entry
  appears on its own.
- Seasonal grass, ferns or groundcover. They carry `canBeRemoved` and are removable today;
  their look through the year is a separate change.
- Growing a bush from its young size to its grown size over time. Each bush keeps the size it
  was placed at, as now.
- Changing which species or how many bushes succession places, or the ladder's timing.
- Harvesting or foraging the berries the fruit layer shows.
- Restoring close sneak cover to grown bushes.
- Flowering or fruiting for trees, or Kentucky windows for `NatureBush` entries outside the
  palette.
