# Spec Delta

## MODIFIED Requirements

### Requirement: Seasonal appearance is maintained independently of growth

A tree the mod has taken over SHALL have its seasonal appearance maintained whatever the growth
setting allows, including the base game's behaviour. Taking a tree over ends the base game's
seasonal handling of it permanently, so a setting that stopped the mod maintaining it would
leave it showing whatever foliage it was wearing at the time, for good.

A tree the mod has taken over that is found without the mod's record of it SHALL be taken back
when its area loads, whatever the settings, so that no such tree is ever left unmaintained. It
SHALL show the current season's foliage as soon as it is taken back, and SHALL grow on from its
current size.

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

#### Scenario: A tree that lost its record

- **WHEN** a save holds a tree the mod took over whose record has been lost, frozen on its summer
  foliage in autumn, and the tree's area loads
- **THEN** the tree shows autumn foliage straight away, keeps its size, and follows the seasons
  from then on
- **AND** reloading the area does not take it back a second time

#### Scenario: Composition correction turned off

- **WHEN** composition correction is off and a tree the mod took over earlier loads without its
  record
- **THEN** it is taken back all the same
