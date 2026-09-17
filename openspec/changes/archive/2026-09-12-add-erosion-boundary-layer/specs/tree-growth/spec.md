## ADDED Requirements

### Requirement: Seasonal appearance is maintained independently of growth

A tree the mod has taken over SHALL have its seasonal appearance maintained whatever the
growth setting allows, including the base game's behaviour. Taking a tree over ends the base
game's seasonal handling of it permanently, so a setting that stopped the mod maintaining it
would leave it showing whatever foliage it was wearing at the time, for good.

Seasonal maintenance SHALL NOT advance a tree's size, and SHALL NOT depend on whether the
tree is player-planted.

#### Scenario: Seasons under the base game's growth behaviour

- **WHEN** the growth setting is the base game's behaviour and autumn comes to an area of
  deciduous trees the mod has taken over
- **THEN** they colour and later drop their leaves, and none of them changes size

#### Scenario: Seasons for a wild tree under player-planted only

- **WHEN** the growth setting is player-planted only and a wild tree the mod has taken over
  goes through a year
- **THEN** its foliage follows the seasons and it stays the size it was

### Requirement: A setting controls which seasonal rule is used

Seasonal appearance SHALL be controlled by its own setting, on by default, separate from the
setting that controls which trees grow and from the setting that controls composition
correction.

Turned on, a tree the mod owns SHALL follow the mod's seasonal rule: green summer foliage is
held until well into autumn rather than tinting in early July, leaves fall late in autumn
rather than at its midpoint, and trees in one area change at slightly different times.

Turned off, a tree the mod owns SHALL be shown the seasonal appearance the base game would
have shown it: green for the first half of summer, tinted for the second half, autumn colour
for the first half of autumn, and bare for the second half and for winter, with each midpoint
staggered per square as the base game staggers it. The mod SHALL continue to drive that appearance rather than stopping, because a
tree it owns is off the base game's erosion permanently and would otherwise keep one
appearance all year.

Changing this setting SHALL change appearance only. It SHALL NOT change any tree's species,
size or ownership, and SHALL NOT be a way to return a tree to the base game.

#### Scenario: Turned on

- **WHEN** autumn comes to an area of deciduous trees the mod owns
- **THEN** they do not all turn on the same day, and they keep summer foliage later into the
  season than an unmodded tree would

#### Scenario: Turned off

- **WHEN** the setting is off and a year passes over an area of deciduous trees the mod owns
- **THEN** they look as unmodded trees look at every point in that year, including tinting
  from around the start of July, which is the timing this mod exists to defer

#### Scenario: Turned off partway through autumn

- **WHEN** the setting is turned off while trees the mod owns are showing autumn foliage
- **THEN** their appearance changes to what the base game would show on that day, rather than
  staying as it was

#### Scenario: Appearance only

- **WHEN** the setting is changed in either direction
- **THEN** no tree changes species or size, and every tree the mod owned before the change is
  still owned by it after

## MODIFIED Requirements

### Requirement: Only undersized trees are taken over

The proximity scan that finds wild trees SHALL adopt a tree only when the area around it is
loaded, and only when that tree is below the ceiling in effect. A tree already at or above the
ceiling SHALL be left alone by that scan, because there is no size left for it to grow into.

Composition correction is not bound by this. A tree it corrects SHALL be taken over at any
size stage, including the largest, since correction hands the mod responsibility for that
tree's seasons whatever size it is.

Adoption SHALL be based on the tree's current stage, so a tree already part-grown continues
from where it is rather than restarting.

#### Scenario: A full-size tree is ignored

- **WHEN** the area around a tree already at the largest size is loaded, and composition
  correction is turned off
- **THEN** that tree is not adopted and never changes

#### Scenario: A full-size tree is taken over by correction

- **WHEN** composition correction settles a square carrying a tree already at the largest size
- **THEN** that tree is taken over, its seasons are maintained, and it does not grow

#### Scenario: A part-grown tree continues from its current stage

- **WHEN** a tree at a middle stage is adopted
- **THEN** its next change is to the following stage, not back to the smallest

#### Scenario: Unvisited areas are untouched

- **WHEN** an area of the map has never been loaded
- **THEN** no tree in it has been adopted or changed

### Requirement: A setting controls which trees grow

Growth SHALL be controlled by a setting offering at least three choices: the base game's
behaviour unchanged, only player-planted trees grow, and all trees grow. It SHALL default to
all trees.

Every tree the setting allows to grow SHALL be able to reach the largest size. The setting
chooses which trees grow, not how large they may become, and there SHALL be no separate
control over the size a tree may reach.

The setting governs growth alone. It SHALL NOT control whether wild species are corrected to
suit their surroundings, and it SHALL NOT control whether the mod maintains a tree's seasonal
appearance.

A square the mod has corrected SHALL be owned by the mod outright. The base game's own growth
of that tree SHALL end and SHALL NOT be emulated, because correction exists to replace that
system rather than to imitate it. Under the base game's growth choice a corrected tree
therefore stays the size it was corrected at. This SHALL be stated in the correction
setting's own description, so a player choosing that combination knows their wild trees will
not change size at all.

#### Scenario: Set to the base game's behaviour

- **WHEN** the setting is the base game's behaviour and composition correction is off
- **THEN** no tree grows beyond what the base game does on its own

#### Scenario: A corrected tree under the base game's behaviour

- **WHEN** the setting is the base game's behaviour and a tree is corrected
- **THEN** that tree stops changing size altogether, because the mod owns its square and the
  base game's growth of it has ended rather than being carried on by the mod

#### Scenario: Set to all trees

- **WHEN** the setting is all trees and a player spends time near an undersized wild tree
- **THEN** that tree grows, and may in time reach the largest size

#### Scenario: Set to player-planted only

- **WHEN** the setting is player-planted only
- **THEN** trees the player has planted grow and may in time reach the largest size, and no
  wild tree grows however long a player spends near it

#### Scenario: Set to the base game's behaviour after planting a tree

- **WHEN** the setting is the base game's behaviour and a player plants a tree
- **THEN** that tree stays at the size it was planted at, because this setting stops all
  growth regardless of how a tree came to exist

#### Scenario: An unmodded world needs both settings off

- **WHEN** a player wants the world to behave as it would without the mod
- **THEN** the growth setting must be the base game's behaviour and composition correction
  must be turned off, because the growth setting alone no longer stops the mod changing
  anything
