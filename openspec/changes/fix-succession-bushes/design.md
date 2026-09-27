# Design

## Context

See `proposal.md` for the report, the cause and the vanilla behaviour this rests on.

Succession runs server side from `EeltsForestryRemastered_Succession.lua`. `classify` rejects
squares off ground level or holding a tree, then `evaluate` rejects untouched and too soon
squares before walking the square's objects with `inspect`, which returns the mod's own object
(named `Eelt_Recovering`) and whether anything else growing is there. A square carrying the
sprite it should is left alone; otherwise the old object is removed and `place` adds a new
`IsoObject` with the wanted sprite. `Understory.spriteFor(rung, x, y)` picks the sprite from a
per rung list with a coordinate hash, so every player and every reload gets the same one.

Trees already carry seasonal foliage the way this change needs. `TreeGrowthObject.applyOverlay`
clears the object's attached anim sprites and adds one overlay for the look
`TreeSeasons.lookFor(x, y, ...)` returns, and the hourly tick in `TreeGrowthSystem` refreshes
every adopted tree through the global object system.

Base game bushes get their overlays from the erosion system's `NatureBush` category, which
recomputes a square's display when it loads and, on a dedicated server, when the date changes.
In single player a base game bush beside a player who never leaves the area keeps its display
until its chunk reloads. Recovered bushes are refreshed hourly instead, as trees are.

## Goals / Non-Goals

**Goals:**

- Build a recovered bush exactly the way `NatureBush` does, so the base game's removal code
  and its snow handling apply to it with no code from the mod.
- One season clock. A bush reads its look from `TreeSeasons`, so a bush and a tree on
  neighbouring squares turn together and the stagger setting governs both.
- Repair in place. An old bush is the same object afterwards, so nothing is ever stacked or
  briefly missing, and the ladder never sees a change.

**Non-Goals:**

- Adding bushes to the global object system. There is nothing to grow, and a bin record per
  bush would cost save size for state that is derivable from the square.
- Seasonal grass or groundcover, bush growth between sizes, or a mod owned removal entry.

## Decisions

### A palette entry is a `NatureBush` index and a size

The bush list leaves `Understory.sprites`, which keeps only the grass and cover sprite names, and
becomes `Understory.bushes`: sixteen entries, each a `NatureBush` index `i` and a size, 0 for
young and 1 for grown, in the same order as today's sprite list: indices 3, 5, 6, 8,
9, 11, 12 and 15 at size 0, then the same eight at size 1. One function turns an entry and a
look into sprite names, using `NatureBush.init`'s arithmetic: base `i % 8 + 8 * size`, spring
overlay base plus 32, autumn overlay base plus 48, summer overlay `64 + i + 32 * size`, and the
flower or fruit layer `80 + i + 32 * size`. Each entry also carries its Kentucky window and
`NatureBush`'s own bloom fractions, described below.

`Understory.bushFor(x, y)` picks the entry with the same hash and salt the old sprite list used,
and `spriteFor("bush", x, y)` returns that entry's base. Keeping the order means the pick is, for
any square, the same entry that square's old bush was given. So a repaired bush and the bush `evaluate` wants agree without any stored
record, and repair never turns into a replacement.

`validateSprites` checks each entry's base and drops the entry if the base does not resolve; a
missing overlay or flower or fruit layer only costs that one look. All 128 `f_bushes_1` indices resolve today.

Alternative considered: recording the entry on the object's mod data. Rejected because the hash
already determines it, and the spec requires the same result for every player and reload,
which the hash gives for free.

### The look comes from the tree clock, mapped per mode

A bush asks `TreeSeasons.lookFor(x, y, season, progress, staggered)`, the same call trees make,
and maps the answer to an overlay:

| Look | Staggered | Stagger off |
|---|---|---|
| `nil` | none, bare base | none, bare base |
| `Spring` | spring overlay | spring overlay |
| `Early Summer` | summer overlay | summer overlay |
| `Late Summer` | autumn overlay | summer overlay |
| `Autumn` | autumn overlay | autumn overlay |

The two columns differ on `Late Summer` because the look means different things in the two
modes. Staggered, it starts at `FIRST_COLOUR` in mid September, which is where a bush should
turn. With the stagger off it is the base game's second half of summer, where `NatureBush`
still shows summer foliage. The bush has no separate late summer art.

Snow needs nothing. `ErosionIceQueen` swaps the shared base sprite, so every object using it
shows snow, the mod's included.

### Flowering and fruiting run on Kentucky dates

The layer `NatureBush` registers with `setFlower` is not always a flower. Viewed in
`Tiles1x.pack` it is ripe berries for Blueberry and Red chokeberry and blossom for the other
three palette species, so each species' window is the time its own art belongs to: fruit ripening
for the two berry species, flowering for the rest.

`NatureBush`'s own fractions put every species inside the game's Early Summer season, which runs
from 15 April to 2 September. That starts Piedmont azalea's flowers no earlier than mid April,
after its leaves have opened, and puts red chokeberry's berries in the last fortnight of August
and gone by September, when they ripen from mid September and hold into winter.
So the windows are taken from Kentucky sources instead and placed on the mod's year position,
which already maps to calendar dates through the season table in
`docs/reference/b42-lua-notes.md` (Spring 9 February for 65 days, Early Summer 15 April for 142,
Autumn 3 September for 64, Winter 6 November for 95):

| Entry | Species | Layer | Window | Year position | Source |
|---|---|---|---|---|---|
| 5, 6 | Piedmont azalea | flowers | 1 Apr to 10 May | 0.785 to 1.176 | [Lady Bird Johnson Wildflower Center](https://www.wildflower.org/plants/result.php?id_plant=rhca7): March to May, usually before the leaves; native to Kentucky |
| 11, 12 | New Jersey tea | flowers | 1 Jun to 15 Jul | 1.331 to 1.641 | [Backyard Ecology, southcentral Kentucky](https://www.backyardecology.net/new-jersey-tea/): June to July in Kentucky, clusters last about a month |
| 3 | Blueberry | berries | 10 Jun to 31 Jul | 1.394 to 1.754 | [University of Kentucky HO-60](https://publications.mgcafe.uky.edu/files/ho60.pdf): harvest from early June in the west and mid June in central and eastern Kentucky to early August |
| 15 | Shrubby St. John's wort | flowers | 1 Jul to 15 Aug | 1.542 to 1.859 | [Backyard Ecology](https://www.backyardecology.net/shrubby-st-johns-wort/): primarily July in Kentucky, sometimes into August |
| 8, 9 | Red chokeberry | berries | 15 Sep to 31 Dec | 2.188 to 3.579 | [NC State Extension](https://plants.ces.ncsu.edu/plants/aronia-arbutifolia/): fruit matures September to November and may persist through winter |

The positions are stored on the palette entry, with the dates as trailing comments the way
`TreeSeasons` keeps its own boundaries. The chokeberry window runs into the Winter slot, which
`yearPosition` already covers up to 4.0, so no window has to wrap past the end of the year.

`TreeSeasons` gains `shiftFor(x, y)`, the same `(stagger - 0.5) * SPREAD` that
`seasons.staggered` applies to the foliage boundaries, and `inWindow(x, y, from, to, season,
progress)`, which shifts both ends by it and tests the square's year position against them. A bush shows its layer for the whole shifted window.
This differs from `currentBloom`, which shows each bush for half its species' window offset by
the square's `magicNum`, and is chosen so that one stagger moves every boundary on a square
together, which is the rule the tree timing already follows.

With the stagger setting off, the layer follows `currentBloom` exactly through
`TreeSeasons.vanillaBloom`: only in the game's Early Summer season, over `NatureBush`'s own `bloomStart` and `bloomEnd`, which the palette entries
also carry, with the square's stagger standing in for `magicNum`. That keeps the setting's
promise that unchecking it gives the base game's behaviour.

The layer is added after the foliage overlay, the order `ErosionObj.setStageObject` uses. It
was viewed over the bare base, the snow base and each foliage overlay at both sizes; azalea
flowers on bare branches before leaf out and chokeberry berries on bare or snowy branches both
read correctly.

The stagger setting's tooltip in `Translate/EN/Sandbox.json` describes trees only, so it gains
bushes, their foliage and their flowers and fruit.

### Overlays are compared by name before anything is sent

Applying a look builds the one or two overlay names the bush should carry, dropping any the game
cannot resolve, and compares them with the parent sprite names already in its attached anim
sprites. Only a difference clears and
rebuilds the list and, on a server, calls `transmitUpdatedSpriteToClients`. A refresh that finds
nothing to change costs a few lookups and sends nothing.

A newly placed bush gets its overlays before `AddTileObject`, so the complete item the server
sends already carries them.

### Old bushes are recognised by sprite and repaired first

A bush the old code placed is an `Eelt_Recovering` object whose sprite is `f_bushes_1_64` to
`79` or `96` to `111`. Its entry is `id % 16` and its size is 1 from 96 up, which is the same
mapping `NatureBush.replaceExistingObject` uses. Repair sets the base sprite on the same object,
applies the current look, and recalculates the square and its neighbours, since the base
sprite's flags differ from the overlay's.

Repair runs as soon as the pass has the object in hand, before `evaluate` compares sprites, so
the comparison sees the repaired base and leaves the square alone.

### Every mode finds the mod's bushes, cheaply

The pass reaches `inspect` only on squares that are recovering. Squares rejected earlier,
because succession is off, the square is untouched under the cleared only choice, or it is
too soon, never have their objects read, and a bush can stand on any of them after a setting
change. Those exits gain one check: when the square holds more than one object, look for the
mod's object and, if one is found, repair it and register it. A bare square holds only its
floor, so it still costs one `size()` call.

Cost is measured with the existing timing instrument in the verification tasks rather than
assumed.

Alternative considered: gating the check on a world flag the mod sets when it first places a
bush. Rejected because saves from before the flag, which are exactly the saves needing repair,
would not have it.

### Loaded bushes are kept in a table the hourly tick walks

The spec requires a bush in loaded ground to turn without being revisited by a chunk load. The
pass already sees every bush that loads, so it records each one in an in memory table keyed by
position. The hourly tick in `TreeGrowthSystem`, and the debug menu's forced refresh, walk that
table: a position whose square is no longer loaded, or no longer carries the mod's bush, is
dropped, and the rest get their look applied.

The table is never saved. Every bush that can be seen reached it through a chunk load, so an
empty table after a reload fills itself as the world loads. Positions found stale during a walk
are collected and removed after it, so the table is never changed while it is being traversed.

The season, its progress and the stagger setting are read with the other settings on the ten
minute tick, and read again at the start of each refresh, so the per square work never calls
out to the climate or erosion objects.

Alternative considered: widening the hourly sweep from its 20 square radius to all loaded
ground. Rejected because it pays for every loaded square to find a handful of bushes.

### Removing through the base game's actions records a clearing

`ISRemoveBush.complete` and `ISRemoveGrass.complete` are wrapped the way `ISShovelAction.complete`
already is: take the square, call the original, and call `understory.markCleared(square)` when
not on a client. The wrapper skips `ISRemoveBush` when it removes a wall vine, which is not
ground vegetation.

This applies to the base game's bushes and grass as well as the mod's, as scything already
does, which is what the spec's "how the ground was cleared makes no difference" asks for.

## Risks / Trade-offs

- Every bush base carries `BlocksPlacement`, which the young summer overlays the first build
  placed did not. It does not stop a tree establishing through a bush: `isPlantableSquare` asks
  `IsoGridSquare.isFree`, which looks only at `solid`, `solidtrans`, a tree and `solidfloor`.

- A grown bush's base, `f_bushes_1_8` to `15`, is a moveable Hedge that can be picked up with a
  shovel, as it is on the base game's grown bushes. Picking one up does not pass through either
  wrapped action, so the square is not recorded as cleared and succession will put a bush back
  on its next visit. Checked in play below. If it proves to matter, hooking the moveable pickup
  is a follow up.
- `transmitUpdatedSpriteToClients` is trusted to carry attached anim sprites to clients because
  tree foliage already depends on it. Bushes are plain `IsoObject`s rather than `IsoTree`s, so
  this is checked on a dedicated server below.
- The discovery check on early exits adds a `size()` call to every rejected square and an
  object walk to rejected squares that hold something. Mitigation: measured against a build
  without it on the same route. If it is noticeable, the check can be limited to squares with a
  recorded clearing plus a one time full pass per chunk.
- Entries 3 and 11, blueberry and New Jersey tea, share a young base and its spring and autumn
  overlays, as they do in the base game. Only their summer foliage and their berries or flowers
  tell them apart.
- A grown recovered bush stops giving zombies' close sneak cover, since
  `IsoZombie.closeSneakBonusCoeff` lists the summer overlays today's grown bushes wear as their
  own sprite and not the grown bases. This is how the base game's own grown bushes already
  behave, so it is accepted rather than worked around.
