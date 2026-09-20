# Spec Delta

## MODIFIED Requirements

### Requirement: A planted tree is taken over the moment it is created

A tree created by the planting capability SHALL be adopted for growth as it is created,
rather than waiting for the proximity scan that finds wild trees. It SHALL be recorded as
player-planted, and that record SHALL persist for the life of the tree across saving and
loading.

Adoption at creation matters because the proximity scan only runs when the setting allows
wild trees to be taken over. Without this, a planted tree would never be adopted under the
setting that exists specifically to grow it.

A tree created by vegetation succession SHALL likewise be adopted as it is created, for the
same reason, and SHALL NOT be recorded as player-planted.

A tree SHALL be recorded as player-planted only if the player planted it. A wild tree taken
over by the proximity scan SHALL NOT become player-planted, however small it is or however
long it has been growing, and neither SHALL a tree that established naturally, whatever stood
next to it when it did.

#### Scenario: A tree is planted under the player-planted setting

- **WHEN** the setting is player-planted only and a player plants a tree
- **THEN** that tree is adopted immediately and begins growing

#### Scenario: A planted tree is not confused with a wild one

- **WHEN** a player plants a tree next to a wild tree of the same species and size, and the
  setting is player-planted only
- **THEN** the planted tree grows and the wild one does not

#### Scenario: The record survives a reload

- **WHEN** a planted tree's area is unloaded and reloaded
- **THEN** it is still recorded as player-planted and still growing

#### Scenario: An adopted wild tree is not player-planted

- **WHEN** the setting is all trees, a wild tree is adopted and grows, and the setting is
  then changed to player-planted only
- **THEN** that tree stops growing, because it was never planted by a player

#### Scenario: An established tree is not player-planted

- **WHEN** the setting is player-planted only and a tree establishes on cleared ground beside
  a tree the player planted
- **THEN** the established tree does not grow, because no player planted it

### Requirement: A setting controls which trees grow

Growth SHALL be controlled by a setting offering at least three choices: the base game's
behaviour unchanged, only player-planted trees grow, and all trees grow. It SHALL default to
all trees.

Every tree the setting allows to grow SHALL be able to reach the largest size. The setting
chooses which trees grow, not how large they may become, and there SHALL be no separate
control over the size a tree may reach.

The setting governs growth alone. It SHALL NOT control whether wild species are corrected to
suit their surroundings, it SHALL NOT control whether the mod maintains a tree's seasonal
appearance, and it SHALL NOT control whether cleared ground recovers. Under the base game's
growth choice a tree SHALL still establish on recovering ground, and SHALL then stay at the
smallest size.

A square the mod has corrected SHALL be owned by the mod outright. The base game's own growth
of that tree SHALL end and SHALL NOT be emulated, because correction exists to replace that
system rather than to imitate it. Under the base game's growth choice a corrected tree
therefore stays the size it was corrected at. This SHALL be stated in the correction
setting's own description, so a player choosing that combination knows their wild trees will
not change size at all.

#### Scenario: Set to the base game's behaviour

- **WHEN** the setting is the base game's behaviour, composition correction is off and
  succession is off
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

- **WHEN** a player wants wild trees to behave as they would without the mod
- **THEN** the growth setting must be the base game's behaviour and composition correction
  must be turned off, because the growth setting alone no longer stops the mod changing
  anything

#### Scenario: Cleared ground needs succession off as well

- **WHEN** a player wants the whole world, and not only its standing trees, to behave as it
  would without the mod
- **THEN** succession must be turned off too, because neither of the other two settings stops
  cleared ground recovering
