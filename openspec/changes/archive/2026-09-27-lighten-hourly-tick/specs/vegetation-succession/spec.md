# Spec Delta

## MODIFIED Requirements

### Requirement: Succession is affordable on every chunk load

Deciding what a square should carry runs during chunk loading, for every square of a
recovering area, so its cost SHALL be small enough not to be noticeable while moving through
the world.

A square that is not recovering SHALL be rejected more cheaply than one that is. Loading a
large recovering area SHALL NOT cause a stall a player would perceive as one, in single player
or on a dedicated server.

The hourly sweep of the squares near each player, and the hourly refresh of recovered bushes in
loaded ground, SHALL be held to the same limit.

#### Scenario: Driving past a large clear cut

- **WHEN** a player drives at speed past an area of several thousand recovering squares
- **THEN** the game does not stutter noticeably more than it does with succession turned off

#### Scenario: Untouched ground costs little

- **WHEN** a player moves through ground that has never been cleared
- **THEN** the cost of succession is measurably lower than in a recovering area

#### Scenario: The hour turns over beside recovering ground

- **WHEN** a player stands in a recovering area with many recovered bushes in loaded ground and
  the in-game hour turns over
- **THEN** the game does not stutter noticeably more than it does with succession turned off
