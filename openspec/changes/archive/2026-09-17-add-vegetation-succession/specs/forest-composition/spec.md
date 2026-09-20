# Spec Delta

## MODIFIED Requirements

### Requirement: A corrected tree keeps its size and its square

Correction SHALL change a tree's species and nothing else about it. The corrected tree SHALL
be the same size stage as the tree it replaced, SHALL stand on the same square, and SHALL NOT
displace, clear or alter anything on any neighbouring square.

Correction SHALL add no tree of its own. The number of trees SHALL be unchanged by it, a
square the base game left bare SHALL be left bare by it, and no square SHALL end up carrying
more than one tree as a result of it.

This describes the correction pass alone. Vegetation succession does establish trees on bare
ground, on its own setting and on its own schedule, so tree density is unchanged by correction
rather than unchanged by the mod. A square that gains a tree has gained it from succession,
never from correction, and correction still refuses to touch a bare square whatever succession
is doing.

#### Scenario: Size is preserved

- **WHEN** a full-grown tree of the wrong species is corrected
- **THEN** the tree standing there is full grown, not a sapling

#### Scenario: Density is unchanged

- **WHEN** a measured area is loaded and corrected, with succession turned off
- **THEN** it holds the same number of trees, on the same squares, as it did before

#### Scenario: Correction plants nothing

- **WHEN** an area holding cleared ground, fields and roads is loaded, with succession turned
  off
- **THEN** correction puts no tree anywhere the base game had not placed one

#### Scenario: Correction still plants nothing when succession is on

- **WHEN** an area of bare ground is loaded for the first time with both settings on
- **THEN** any tree that appears on it appears through succession over time, and none appears
  at the moment the ground is loaded

### Requirement: Only trees are touched

Correction SHALL apply to squares carrying a tree and to nothing else. Grass, groundcover,
ferns, bushes, street and wall erosion SHALL be left entirely alone by it, on corrected squares
and everywhere else.

Vegetation succession is the exception, and only for what grows: it places grass, groundcover,
ferns, bushes and trees on ground it has taken responsibility for, under its own setting.
Street, wall and flowerbed erosion SHALL be left alone by every part of the mod.

Turning the mod's settings off SHALL leave every one of those systems working as it always did.

#### Scenario: Undergrowth is unaffected

- **WHEN** an area thick with grass, ferns and bushes is loaded and corrected, with succession
  turned off
- **THEN** the grass, ferns and bushes are exactly as they were

#### Scenario: Other erosion still runs

- **WHEN** a corrected area contains roads and walls
- **THEN** they continue to erode over time as they would without the mod

#### Scenario: Succession does not touch street or wall erosion

- **WHEN** a recovering area contains roads and walls
- **THEN** they continue to erode over time as they would without the mod
