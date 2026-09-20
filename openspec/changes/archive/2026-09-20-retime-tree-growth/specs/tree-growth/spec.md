# Spec Delta

## MODIFIED Requirements

### Requirement: Trees grow on their own elapsed time

A tree the mod has adopted SHALL advance one size stage at a time, on time elapsed since
that tree reached its current stage, until it reaches the ceiling in effect.

This is the behaviour the base game lacks: its growth is driven by a single world-wide
counter, so two trees of the same species are always the same size. Under this capability,
two trees adopted at different moments SHALL be able to differ in size.

Elapsed time SHALL count whether or not the tree's area was loaded. A tree SHALL be brought up
to date when its area loads, advancing every stage that has fallen due while it was away
rather than one stage at a time after the player arrives. Any part of a stage not yet earned
SHALL be carried forward, so that a tree repeatedly left and returned to ends up at the same
size as one that was watched throughout.

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

#### Scenario: Returning after a long absence

- **WHEN** a player plants a tree, travels far enough for its area to unload, stays away long
  enough for several stages to fall due, and returns
- **THEN** the tree is already at the size that time earned it when the area comes into view
- **AND** it does not visibly climb through the stages after the player arrives

#### Scenario: Leaving and returning does not cost growth

- **WHEN** one tree is watched continuously and another of the same species and pace is left
  and returned to repeatedly over the same elapsed time
- **THEN** both are at the same stage

### Requirement: A setting controls the pace

The time a tree takes to grow SHALL be adjustable through a numeric setting. At its default
a tree SHALL take roughly three in-game months to go from the smallest stage to the
largest. Raising the value SHALL make growth take longer and lowering it SHALL make growth
take less time, proportionally.

A separate setting SHALL choose when a tree is brought up to date: when its area loads, which
SHALL be the default, or only while the area is loaded, which is the older behaviour and
SHALL advance a tree no more than one stage at a time. The pace setting SHALL apply to both.

#### Scenario: Default pace

- **WHEN** the pace setting is left at its default
- **THEN** a tree starting at the smallest stage reaches the largest in roughly three
  in-game months

#### Scenario: Pace is doubled

- **WHEN** the pace setting is set to twice its default
- **THEN** each stage takes about twice as long as it would at the default

#### Scenario: The older timing is chosen

- **WHEN** the timing setting is set to the older behaviour and a player returns to a tree
  that has been away long enough for several stages to fall due
- **THEN** the tree advances one stage at a time while the player stays near it
