## ADDED Requirements

### Requirement: A planted tree is taken over the moment it is created

A tree created by the planting capability SHALL be adopted for growth as it is created,
rather than waiting for the proximity scan that finds wild trees. It SHALL be recorded as
player-planted, and that record SHALL persist for the life of the tree across saving and
loading.

Adoption at creation matters because the proximity scan only runs when the setting allows
wild trees to be taken over. Without this, a planted tree would never be adopted under the
setting that exists specifically to grow it.

A tree SHALL be recorded as player-planted only if the player planted it. A wild tree taken
over by the proximity scan SHALL NOT become player-planted, however small it is or however
long it has been growing.

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

### Requirement: A setting controls which trees grow

Growth SHALL be controlled by a setting offering at least three choices: the base game's
behaviour unchanged, only player-planted trees grow, and all trees grow. It SHALL default to
all trees.

Every tree the setting allows to grow SHALL be able to reach the largest size. The setting
chooses which trees grow, not how large they may become, and there SHALL be no separate
control over the size a tree may reach.

#### Scenario: Set to the base game's behaviour

- **WHEN** the setting is the base game's behaviour
- **THEN** no tree is adopted, nothing grows beyond what the base game does on its own, and
  the world behaves exactly as it would without the mod

#### Scenario: Set to all trees

- **WHEN** the setting is all trees and a player spends time near an undersized wild tree
- **THEN** that tree grows, and may in time reach the largest size

#### Scenario: Set to player-planted only

- **WHEN** the setting is player-planted only
- **THEN** trees the player has planted grow and may in time reach the largest size, and no
  wild tree is adopted or grows however long a player spends near it

#### Scenario: Set to the base game's behaviour after planting a tree

- **WHEN** the setting is the base game's behaviour and a player plants a tree
- **THEN** that tree stays at the size it was planted at, because this setting stops all
  growth regardless of how a tree came to exist

## REMOVED Requirements

### Requirement: A setting controls which trees grow and how far

**Reason**: The name promised a control over how far a tree may grow, and no such control
exists or is wanted. Growth always runs to the largest size, and the setting only ever chose
which trees it runs for. The requirement also carried a scenario describing the
player-planted setting in a world where planting was not yet possible, which this change
makes obsolete.

**Migration**: Replaced by "A setting controls which trees grow", which keeps the same three
choices and the same default and states plainly that the size ceiling is not configurable.
Nothing about the shipped setting changes, so no world, save or configuration is affected.
