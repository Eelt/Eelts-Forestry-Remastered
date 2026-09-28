# Spec Delta

## ADDED Requirements

### Requirement: The hourly upkeep does not stall play

The work the mod does on the hour, bringing loaded trees up to date, adopting wild trees near
players, the succession sweep near players and the refresh of recovered bushes, SHALL NOT cause
a stall a player would perceive as one, in single player or on a dedicated server, however
long the world has been played.

Its cost SHALL depend on the loaded area around the players, not on how many trees the mod has
adopted across the whole save.

The upkeep SHALL reach the same results it would if done all at once, in the same order, and
SHALL be finished well before the next hour begins.

#### Scenario: The hour turns over on a lower end PC

- **WHEN** a player stands in a forest on a long running save and the in-game hour turns over
- **THEN** the game does not stutter noticeably more than it does in the minutes either side

#### Scenario: An old save does not hitch harder

- **WHEN** the same area is loaded in a young save and in one where the mod has adopted many
  times more trees elsewhere in the world
- **THEN** the hourly upkeep costs about the same in both

#### Scenario: The same results as before

- **WHEN** a tree falls due for its next stage, or a season boundary passes, during a given hour
- **THEN** the tree grows, or changes its look, within that hour, as it did before the upkeep
  was spread out

## MODIFIED Requirements

### Requirement: A setting controls the pace

The time a tree takes to grow SHALL be adjustable through a numeric setting. At its default
a tree SHALL take roughly three in-game months to go from the smallest stage to the
largest. Raising the value SHALL make growth take longer and lowering it SHALL make growth
take less time, proportionally.

A separate setting SHALL choose when a tree is brought up to date: when its area loads, which
SHALL be the default, or only while the area is loaded, which is the older behaviour and
SHALL advance a tree no more than one stage at a time. Under the older behaviour a tree SHALL
NOT advance while its area is unloaded. The pace setting SHALL apply to both.

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

#### Scenario: The older timing leaves unloaded trees alone

- **WHEN** the timing setting is set to the older behaviour and a tree's area is unloaded for
  long enough that several stages would have fallen due
- **THEN** the tree is the same size when its area loads again as when the player left it,
  and is drawn at that size
