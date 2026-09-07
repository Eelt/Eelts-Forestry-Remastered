## Purpose

Governs how an existing tree advances through its eight size stages over time, what
controls the pace and the ceiling, and where the mod takes over from the base game's own
erosion-driven growth. It exists because the base game's trees never mature past a small
size, and because a planting system needs somewhere for a planted tree to grow into.

## ADDED Requirements

### Requirement: Trees grow on their own elapsed time

A tree the mod has adopted SHALL advance one size stage at a time, on time elapsed since
that tree reached its current stage, until it reaches the ceiling in effect.

This is the behaviour the base game lacks: its growth is driven by a single world-wide
counter, so two trees of the same species are always the same size. Under this capability,
two trees adopted at different moments SHALL be able to differ in size.

#### Scenario: A small tree left alone grows

- **WHEN** an adopted tree below the ceiling is left for the time one stage takes
- **THEN** it advances exactly one stage
- **AND** its appearance changes to that stage's artwork for its species

#### Scenario: Two trees adopted at different times differ

- **WHEN** one tree is adopted, time passes, and a second tree of the same species is
  adopted at the same stage
- **AND** enough further time passes for the first to advance
- **THEN** the two trees are at different stages

#### Scenario: A tree at the ceiling stops

- **WHEN** an adopted tree reaches the ceiling in effect
- **THEN** it stops advancing and stays at that stage indefinitely

### Requirement: Growing changes the tree's size, not its identity

When a tree advances a stage it SHALL become the size that stage represents, so that
everything the base game derives from size, including how many logs it yields and how long
it takes to chop, follows automatically.

A growing tree SHALL remain the same species, SHALL remain a single object occupying a
single square at every stage, and SHALL NOT displace, clear or overwrite anything on
neighbouring squares.

#### Scenario: Yield follows size

- **WHEN** a tree grows from a small stage to a large one and is then chopped down
- **THEN** it yields what the base game yields for a tree of the larger size

#### Scenario: Species is preserved

- **WHEN** a tree of any species advances through every stage
- **THEN** it is the same species at each stage, never a different one

#### Scenario: Neighbours are untouched

- **WHEN** a tree grows into one of the sizes whose artwork is visually larger than one
  square
- **THEN** no object on any neighbouring square is removed or altered

### Requirement: A setting controls which trees grow and how far

Growth SHALL be controlled by a setting offering at least three choices: the base game's
behaviour unchanged, only player-planted trees may reach the largest size, and all trees
may reach the largest size. It SHALL default to all trees.

#### Scenario: Set to the base game's behaviour

- **WHEN** the setting is the base game's behaviour
- **THEN** no tree is adopted, nothing grows beyond what the base game does on its own, and
  the world behaves exactly as it would without the mod

#### Scenario: Set to all trees

- **WHEN** the setting is all trees and a player spends time near an undersized wild tree
- **THEN** that tree grows, and may in time reach the largest size

#### Scenario: Set to player-planted only, before planting exists

- **WHEN** the setting is player-planted only and no planting feature is available
- **THEN** no tree grows, because there are no player-planted trees to grow

### Requirement: A setting controls the pace

The time a tree takes to grow SHALL be adjustable through a numeric setting. At its default
a tree SHALL take roughly three in-game months to go from the smallest stage to the
largest. Raising the value SHALL make growth take longer and lowering it SHALL make growth
take less time, proportionally.

#### Scenario: Default pace

- **WHEN** the pace setting is left at its default
- **THEN** a tree starting at the smallest stage reaches the largest in roughly three
  in-game months

#### Scenario: Pace is doubled

- **WHEN** the pace setting is set to twice its default
- **THEN** each stage takes about twice as long as it would at the default

### Requirement: Only undersized trees are taken over

The mod SHALL adopt a tree only when the area around it is loaded, and only when that tree
is below the ceiling in effect. A tree already at or above the ceiling SHALL be left alone.

Adoption SHALL be based on the tree's current stage, so a tree already part-grown continues
from where it is rather than restarting.

#### Scenario: A full-size tree is ignored

- **WHEN** the area around a tree already at the largest size is loaded
- **THEN** that tree is not adopted and never changes

#### Scenario: A part-grown tree continues from its current stage

- **WHEN** a tree at a middle stage is adopted
- **THEN** its next change is to the following stage, not back to the smallest

#### Scenario: Unvisited areas are untouched

- **WHEN** an area of the map has never been loaded
- **THEN** no tree in it has been adopted or changed

### Requirement: Growth survives saving and is consistent for everyone

A tree's growth progress SHALL persist across saving and loading, so that unloading an area
and returning to it does not restart or skip its growth. In multiplayer every player SHALL
see the same tree at the same stage.

#### Scenario: Progress survives a reload

- **WHEN** a partly grown tree's area is unloaded and the game saved and reloaded
- **THEN** the tree is at the same stage, with its progress toward the next stage intact

#### Scenario: All players see the same tree

- **WHEN** a tree advances a stage in multiplayer
- **THEN** every player who can see that tree sees it at its new stage
