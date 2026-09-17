## Context

See proposal.md for motivation. The overlay layout and the July problem are in
`docs/reference/b42-tree-matrix.md`; do not re-derive them.

What exists today, in `EeltsForestryRemastered_TreeGrowthObject.lua`:

- `staggerFor(x, y)` gives a stable value in `[0, 1)` per square, computed so the operands stay
  inside 32 bits because the game's lua overflows `%` past `Integer.MAX_VALUE`.
- `seasonProgress()` returns `getSeasonDay() / getSeasonDays()` for the current season.
- `staggeredSeason` and `vanillaSeason` each take a season name, a progress and a stagger, and
  return one of `"Spring"`, `"Early Summer"`, `"Late Summer"`, `"Autumn"` or nil for bare.
- `currentSeason()` reads the season name, the progress and the setting once per hourly tick and
  passes them down, because the object bin holds a tree for every square a player has walked
  past and reached 10247 entries in a few hours of play.
- `EeltsForestryRemastered_TreeGrowthSprites.getOverlay` maps those names onto sheet positions
  2, 3, 4 and 5, and returns nil for evergreens.

So the names are already in place and position 4 is already reachable. What is missing is a rule
that uses it, and windows that land in the right months.

## Goals / Non-Goals

**Goals:**
- Establish the season model by measurement before tuning anything against it.
- Express the cycle so that crossing from autumn into winter needs no special case.
- Keep one normalised per tree value driving the whole cycle, so inherited timing can replace it
  later without touching the windows.
- Keep the per tree cost of the rule to arithmetic, no engine calls.

**Non-Goals:**
- Changing the unstaggered rule, which stays as per season midpoints.
- Splitting the growth system's file layout beyond moving the seasonal code out.

## Decisions

### Measure the season model before tuning against it

Early Summer reports 142 days and Autumn 64, yet autumn was observed to begin in early
September, and a reading of Early Summer day 117 of 142 was seen on a date that the same session
also reported as autumn. Those cannot all be true of a simple four season partition of the year.

Nothing is tuned until a full year has been stepped through, logging date, season name, season
day and season length every day. That produces the four seasons' real start dates and lengths,
and shows whether they tile the year or overlap. It is the same shape of task as the cost
measurement in the boundary layer change, which paid for itself, and the alternative is tuning
against numbers that do not add up.

### A continuous year position, not a per season fraction

Leaf fall now ends at the autumn boundary, so the cycle no longer has to cross a season, and
per season fractions would technically work. The continuous position is kept anyway, because
the cycle spans four seasons and one stagger has to shift every boundary by the same amount;
expressing that as five separate per season fractions means five places to get the stagger
wrong. It also leaves the boundary crossing available if the tuning ever wants it back.

So map `(season name, season progress)` onto one continuous position through the year
using the measured lengths, and define every stage boundary as a position on that line. Crossing
from autumn into winter then needs no special case: the deep fall window simply ends at a
position that happens to fall inside winter.

This keeps the property the genetics work depends on. What genetics needs is one normalised per
tree value that shifts a tree earlier or later, and that is unchanged; only what the value shifts
is different. Fixed month and day pairs are still avoided, because the boundaries are positions
on a line built from the season lengths, so changing a season's length moves them with it.

### One stagger, applied to every boundary

Today the stagger only affects autumn, and it scales the two autumn thresholds by different
amounts. With a whole year cycle, the same single value shifts every boundary by the same
fraction of the year, which is both simpler and what a real tree does: a tree that leafs out
early also turns early.

The magnitude is tuning, and it must stay small enough that a wood turns as a wood.

### Snow is left alone

The base game covers a tree by swapping its base sprite, globally, at the `IsoSprite` level. The
mod's foliage is an attached overlay on top of that, so a tree can be snow covered and leafy at
once, and the mod cannot opt a tree out of the swap.

Ending leaf fall inside autumn narrows this to the last week of October and the first few days of
November. It was looked at in game on 2026-09-13, using the foliage viewer the tint question had
already paid for, and judged acceptable: neither good nor bad, and not an error.

So nothing is built. The mod does not strip a tree early on account of snow and does not read the
weather at all, which also retires the question of whether `ClimateManager` exposes snow to lua.
An autumn snow on a tree still in colour is a real thing, and now it can happen.

## Risks / Trade-offs

- **The season model may not be a clean partition of the year.** → That is exactly why it is
  measured first. If the seasons overlap or leave gaps, the continuous position needs building
  from the game date instead of from season progress, which is a different implementation of the
  same idea rather than a different design.

- **Snow may not be readable from lua.** → Retired. Nothing keys off the weather, so it does not
  matter whether it is readable.

- **Every managed tree changes appearance.** → Trees that coloured in early September will stay
  green a month longer. This is the point of the change, but it is visible in existing saves and
  belongs in the release notes rather than being discovered.

- **The rule runs for every tree in the bin every hour.** → Keep it to arithmetic on values the
  tick already computed once. The season name, the progress, the setting and now the year
  position are all read or derived once per tick, never per tree.

- **Tuning has no ground truth in the game.** → The windows come from Kentucky, not from
  anything the files say. Record the dates each boundary is meant to produce alongside the
  numbers, so a later reader can tell a deliberate value from a typo.

## Migration Plan

No save data changes, no setting is renamed, and no tree changes species or size. An existing
save picks up the new look on the next hourly tick. Rolling back is turning the stagger setting
off, which gives the base game's own timing, or uninstalling.

## Open Questions

Both questions this design opened are answered. The year position is built from the season's slot
plus its progress, needing no day counts, and the season table that confirmed the tuning is in
`docs/reference/b42-lua-notes.md`. Snow needs no rule and no detection.
