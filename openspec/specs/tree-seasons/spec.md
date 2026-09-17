# tree-seasons Specification

## Purpose
Governs what foliage a tree the mod owns shows through the year, which rule decides it, and how
that reconciles with snow. It exists because the base game turns trees in early July, which is
wrong for Kentucky, and because taking a tree off the base game's erosion makes the mod
responsible for its appearance from then on.

## Requirements

### Requirement: A tree passes through five looks in a year

A deciduous tree the mod owns SHALL show, in order: bare through winter and early spring, spring
foliage, summer green, an early fall look, a deep fall look, and bare again.

The two fall looks SHALL be distinct stages, not alternatives. The early one is coloured but
full, the deep one is coloured and visibly thinner, so a tree reads as turning gradually rather
than changing in one step.

Each change SHALL be driven by how far through its season the year has got, never by a fixed
calendar date, so that changing the length of a season moves the whole cycle with it.

#### Scenario: A year watched from one spot

- **WHEN** a player watches one deciduous tree the mod owns through a full year
- **THEN** it is bare in winter, comes into leaf in spring, is green through summer, colours
  while still full, thins while coloured, and is bare again before winter

#### Scenario: Both fall looks are used

- **WHEN** autumn passes over an area of deciduous trees the mod owns
- **THEN** there is a stretch where trees are coloured and full, and a later stretch where they
  are coloured and thinning, and neither stretch is skipped

#### Scenario: Season length changes

- **WHEN** a world is configured with longer or shorter seasons
- **THEN** the whole cycle stretches or compresses with them, and no stage is lost

### Requirement: Foliage follows Kentucky rather than the season boundaries

The timing SHALL follow the region the game is set in, not whatever boundary the season model
puts nearest. Trees SHALL be green through mid September, take their first colour in late
September or early October, be at their deepest around the middle and end of October, and have
lost their leaves by the middle of November.

In particular no tree SHALL show a fall look during summer, and none SHALL show the deep thinned
look in the first weeks of September, both of which the base game and earlier versions of this
mod respectively did.

Leaf fall SHALL finish by the end of the autumn season. The mod SHALL NOT hold foliage into the
winter season, so no tree is still carrying leaves once the game reports winter.

#### Scenario: Nothing turns in summer

- **WHEN** a player watches a deciduous tree the mod owns through July and August
- **THEN** it is green, and shows neither fall look

#### Scenario: September stays green

- **WHEN** the first weeks of September pass
- **THEN** trees the mod owns are still green, and none is showing the deep thinned look

#### Scenario: Peak colour in October

- **WHEN** the middle and end of October pass over an area of deciduous trees the mod owns
- **THEN** they are at their deepest colour

#### Scenario: Bare by the end of autumn

- **WHEN** the autumn season ends
- **THEN** every deciduous tree the mod owns has lost its leaves, and none is carrying foliage
  into winter

### Requirement: Trees in one area do not change together

Trees standing near each other SHALL change at slightly different times from one another, at
every stage of the cycle rather than only in autumn. The difference SHALL be stable for a given
tree, so that a tree which turns early one year turns early the next.

The spread SHALL be small enough that a wood reads as turning as a wood, and large enough that
no two neighbours change on the same day.

#### Scenario: A wood turning

- **WHEN** the first fall colour arrives in a wood of trees the mod owns
- **THEN** some trees have turned and others have not, rather than all of them turning at once

#### Scenario: The same tree two years running

- **WHEN** one tree is watched through two consecutive autumns
- **THEN** it turns at the same point in the season both times, relative to its neighbours

### Requirement: Snow is left to fall on whatever foliage is there

The base game covers a tree in snow by swapping its base sprite, globally and at the sprite
level, so the mod cannot opt a tree out. Leaf fall finishes inside autumn, so this can only
arise when snow falls before the last leaves are down, in the last week of October or the first
few days of November.

The mod SHALL leave that alone. A snow covered tree still carrying autumn colour is what an
early snow produces, and it was looked at in game on 2026-09-13 and judged acceptable. The mod
SHALL NOT strip a tree early on account of snow, and SHALL NOT read the weather to decide what
foliage to show.

#### Scenario: Snow before the last leaves are down

- **WHEN** snow falls in late October while trees the mod owns still carry autumn colour
- **THEN** they keep that colour until their own leaf fall is due, and the snow sits on them

#### Scenario: Evergreens in snow

- **WHEN** snow falls on a pine, hemlock or holly the mod owns
- **THEN** it looks exactly as it does without the mod, because the mod puts no overlay on it

### Requirement: A setting controls which seasonal rule is used

Seasonal appearance SHALL be controlled by its own setting, on by default, separate from the
setting that controls which trees grow and from the setting that controls composition
correction.

Turned on, a tree the mod owns SHALL follow the mod's rule as described by the requirements
above.

Turned off, a tree the mod owns SHALL be shown the seasonal appearance the base game would have
shown it: green for the first half of summer, the early fall look for the second half, the deep
fall look for the first half of autumn, and bare for the second half and for winter, with each
midpoint staggered per square as the base game staggers it. The mod SHALL continue to drive that
appearance rather than stopping, because a tree it owns is off the base game's erosion
permanently and would otherwise keep one appearance all year.

Changing this setting SHALL change appearance only. It SHALL NOT change any tree's species, size
or ownership, and SHALL NOT be a way to return a tree to the base game.

#### Scenario: Turned off

- **WHEN** the setting is off and a year passes over an area of deciduous trees the mod owns
- **THEN** they look as unmodded trees look at every point in that year, including taking their
  first colour from around the start of July, which is the timing this mod exists to defer

#### Scenario: Turned off partway through autumn

- **WHEN** the setting is turned off while trees the mod owns are showing autumn foliage
- **THEN** their appearance changes to what the base game would show on that day, rather than
  staying as it was

#### Scenario: Appearance only

- **WHEN** the setting is changed in either direction
- **THEN** no tree changes species or size, and every tree the mod owned before the change is
  still owned by it after

### Requirement: Seasonal appearance is maintained independently of growth

A tree the mod has taken over SHALL have its seasonal appearance maintained whatever the growth
setting allows, including the base game's behaviour. Taking a tree over ends the base game's
seasonal handling of it permanently, so a setting that stopped the mod maintaining it would
leave it showing whatever foliage it was wearing at the time, for good.

Seasonal maintenance SHALL NOT advance a tree's size, and SHALL NOT depend on whether the tree
is player-planted.

Evergreen species take no foliage overlay at all and SHALL be left alone by every requirement in
this capability.

#### Scenario: Seasons under the base game's growth behaviour

- **WHEN** the growth setting is the base game's behaviour and autumn comes to an area of
  deciduous trees the mod has taken over
- **THEN** they colour and later drop their leaves, and none of them changes size

#### Scenario: Seasons for a wild tree under player-planted only

- **WHEN** the growth setting is player-planted only and a wild tree the mod has taken over goes
  through a year
- **THEN** its foliage follows the seasons and it stays the size it was

#### Scenario: An evergreen through a year

- **WHEN** a pine, hemlock or holly the mod owns is watched through a full year
- **THEN** its foliage never changes
