## Why

A deciduous sprite sheet carries four foliage looks. The mod asks for three. The one it never
asks for, overlay position 4, was put on a tree and looked at on 2026-09-12: it reads as an
early fall look, already coloured but not yet thinned, and position 5 is deeper with the leaves
partly gone. So the base game has a two stage fall and the mod has a one stage fall, which
makes a tree jump from full summer green to half bare in a single step.

The timing is worse than the missing stage. Autumn runs 64 days from about 1 September, and the
mod currently shows that deep thinned look from `stagger * 0.35`, which is the first three weeks
of September. A tree observed in game turned on 2 September. The mod exists because vanilla
tints from 2 July, which is far too early for Kentucky; it replaced that with a date that is
still too early, just less so.

Kentucky sits around 37 to 39 degrees north. Green through mid September, first colour late
September into early October, peak mid to late October, leaves down through early to mid
November. None of the mod's current windows land there.

## What Changes

- The mod's seasonal rule uses all four looks. A tree goes bare, then spring foliage, then
  summer green, then the early fall tint, then deep autumn colour, then bare again.
- Every window is retuned against Kentucky rather than against the season boundary that happens
  to be nearest. Windows stay fractions of their season, never fixed month and day pairs.
- Leaf fall finishes by the end of the autumn season, around 4 November. The mod does not hold
  foliage into the winter season.
- Snow falling on a tree still in colour is left alone. Ending leaf fall inside autumn narrows
  that to the last days of October, and it was looked at and judged acceptable, so the mod does
  not strip a tree early and does not read the weather.
- **BREAKING** for the look of every managed tree. Trees that currently colour in early
  September will stay green a month longer, and the intermediate tint will appear where nothing
  appeared before. No save data changes and no tree changes species or size.
- The seasonal requirements move out of `tree-growth`, which is about size, into a capability of
  their own. No behaviour moves with them beyond what is described above.

## Capabilities

### New Capabilities
- `tree-seasons`: what foliage a tree the mod owns shows through the year, which rule decides
  it, and how that interacts with snow.

### Modified Capabilities
- `tree-growth`: loses its two seasonal requirements to `tree-seasons`. Nothing about size,
  pace, adoption or the growth setting changes.

## Impact

Changed: `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua` for the rule
itself, `42.20/media/lua/shared/EeltsForestryRemastered_TreeGrowthSprites.lua` if the bare
season needs naming, and `Translate/EN/Sandbox.json` for the setting's description.

`42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua` already carries the foliage
viewer and the autumn sweep that this change is tuned with; the sweep needs widening to the
whole year.

### B42.20 files and tables this rests on

No vanilla file is edited or shadowed. The mod reads the season from
`ErosionMain.getInstance():getSeasons()` and paints overlays onto trees it has renamed.

The overlay layout comes from `docs/reference/b42-tree-matrix.md`, "Seasonal sprites" and "The
July problem", derived from the installed `projectzomboid.jar`, version 42.20.4, revision
`b0bbce05d5`. Position 2 is spring, 3 summer green, 4 the tint, 5 autumn colour, and bare is the
absence of an overlay. Snow is not an overlay: `ErosionIceQueen` maps a base sprite to a winter
counterpart at the `IsoSprite` level and swaps it globally. What position 4 and 5 actually look
like was established by inspection in game rather than from the files.

The season lengths this change tunes against are not yet established. Early Summer reports 142
days and Autumn 64, and those do not reconcile with autumn being observed to begin in early
September. Measuring them is the first task and everything else waits on it.

## Non-goals

- The unstaggered rule that reproduces the base game. It splits summer and autumn at their
  midpoints, tints from around 2 July and stands bare from mid autumn, and that is correct
  because it is what an unmodded tree does. It does not change.
- Evergreens. American Holly, Canadian Hemlock and Virginia Pine take no overlay at all and are
  untouched, snow swap included.
- Inherited timing. The windows stay fractions of their season precisely so that genetics can
  map through them later, but nothing is stored on a tree here.
- Species, size, growth pace, adoption and composition correction. This change alters
  appearance only.
- The snow sprites themselves, and any attempt to opt a tree out of the swap. The swap is
  global and at the sprite level, so the mod can only choose what it puts on top of it.
- Tuning per species. Every deciduous species shares one set of windows, as it does today.
