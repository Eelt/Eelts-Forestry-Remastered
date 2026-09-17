## Purpose

Governs which tree species grow wild on a given square, and how the mod takes that decision
away from the base game's erosion system permanently. It exists because the base game picks
a species from soil and position noise without ever consulting the forage zone or the
authored biome, so a forest is routinely made of species its own map never intended.

## ADDED Requirements

### Requirement: A wild tree becomes a species its surroundings actually grow

When the mod first sees a square carrying a tree the base game placed, that tree SHALL become
a species chosen at random, weighted by the species the square's forage zone naturally grows.
The choice SHALL be made afresh rather than kept whenever the base game's own choice happens
to agree, so that a corrected forest matches the zone's weights rather than the base game's
soil noise.

Where the square belongs to no zone the mod has weights for, the tree SHALL be left exactly
as it is. A zone with no recorded species is not evidence that any species is suitable there.

The same weights SHALL govern both this correction and the species an unmarked propagule
plants, so that a forest and a tree planted in it draw on one description of what grows
where.

#### Scenario: A pine forest is all pine

- **WHEN** a player walks into an area whose zone grows only one species, and the base game
  had placed several other species there
- **THEN** every tree in that area is the one species the zone grows

#### Scenario: A mixed forest follows its weights

- **WHEN** a large area of a zone with several weighted species is loaded
- **THEN** the species found across it are drawn from that zone's species in roughly the
  proportions the zone's weights describe

#### Scenario: A zone with no recorded species is left alone

- **WHEN** a square carrying a tree belongs to no zone the mod has weights for
- **THEN** that tree keeps the species the base game gave it, and is not changed

### Requirement: A corrected tree keeps its size and its square

Correction SHALL change a tree's species and nothing else about it. The corrected tree SHALL
be the same size stage as the tree it replaced, SHALL stand on the same square, and SHALL NOT
displace, clear or alter anything on any neighbouring square.

Correction SHALL add no tree of its own. The number of trees SHALL be unchanged by it, a
square the base game left bare SHALL be left bare by it, and no square SHALL end up carrying
more than one tree as a result of it.

#### Scenario: Size is preserved

- **WHEN** a full-grown tree of the wrong species is corrected
- **THEN** the tree standing there is full grown, not a sapling

#### Scenario: Density is unchanged

- **WHEN** a measured area is loaded and corrected
- **THEN** it holds the same number of trees, on the same squares, as it did before

#### Scenario: Correction plants nothing

- **WHEN** an area holding cleared ground, fields and roads is loaded
- **THEN** correction puts no tree anywhere the base game had not placed one

### Requirement: Correction happens once per square and is permanent

A square SHALL be corrected at most once. Leaving an area and returning to it, saving and
reloading, or letting a great deal of in-game time pass SHALL NOT correct it again, and SHALL
NOT let the base game reassert a species or a size on it.

The record of which squares have been settled SHALL persist across saving and loading.

#### Scenario: Returning to a corrected area

- **WHEN** a player leaves a corrected area, travels far enough for it to unload, and comes
  back
- **THEN** the trees are the same species they were when the player left

#### Scenario: The base game does not take the square back

- **WHEN** several in-game months pass and a player revisits a corrected area
- **THEN** no tree in it has changed species or size other than by the mod's own growth

#### Scenario: Correction survives a reload

- **WHEN** a corrected area is unloaded and the game saved and reloaded
- **THEN** its trees are unchanged and none of them is corrected a second time

### Requirement: A corrected tree is managed by the mod from then on

Taking a square off the base game's erosion is what makes correction permanent, and it also
ends the base game's seasonal handling of that tree for good. Every corrected tree SHALL
therefore be taken into the mod's own tree system, at any size stage including the largest,
so that its seasonal appearance continues to be maintained.

A corrected tree SHALL count as wild. It SHALL NOT be recorded as player-planted, and
correcting it SHALL NOT by itself cause it to grow when the growth setting does not allow it.

#### Scenario: A full-grown corrected tree still turns in autumn

- **WHEN** autumn comes to an area of corrected full-grown deciduous trees
- **THEN** they colour and drop their leaves like any other tree the mod manages

#### Scenario: Correction does not make a tree player-planted

- **WHEN** the growth setting is player-planted only and an area is corrected
- **THEN** none of the corrected trees grows

### Requirement: Only trees are touched

Correction SHALL apply to squares carrying a tree and to nothing else. Grass, groundcover,
ferns, bushes, street and wall erosion SHALL be left entirely alone, on corrected squares and
everywhere else.

Turning the mod off SHALL leave those systems working as they always did.

#### Scenario: Undergrowth is unaffected

- **WHEN** an area thick with grass, ferns and bushes is loaded and corrected
- **THEN** the grass, ferns and bushes are exactly as they were

#### Scenario: Other erosion still runs

- **WHEN** a corrected area contains roads and walls
- **THEN** they continue to erode over time as they would without the mod

### Requirement: A setting controls whether composition is corrected

Correction SHALL be controlled by its own setting, on by default, independent of the setting
that controls which trees grow. Turning it off SHALL stop any further square being corrected.

Squares already corrected SHALL be left as they are. The mod cannot give a square back to the
base game's erosion once it has been taken, so turning the setting off SHALL be described as
stopping further correction rather than undoing it.

#### Scenario: Turned off before play

- **WHEN** the setting is off from the start of a world
- **THEN** every wild tree is the species the base game chose, everywhere

#### Scenario: Turned off partway through

- **WHEN** a world with corrected areas has the setting turned off
- **THEN** already corrected trees keep their species and the mod keeps their seasons, and no
  newly visited area is corrected

#### Scenario: Independent of the growth setting

- **WHEN** the growth setting is the base game's behaviour and the correction setting is on
- **THEN** wild trees are corrected to the right species and none of them grows

### Requirement: Correction is affordable on every chunk load

The correction pass runs for every square of every chunk load and cannot be prevented from
running, so its cost in the common case, where a square has already been settled or carries
no tree, SHALL be small enough not to be noticeable while moving through the world.

Loading unexplored ground SHALL NOT cause a stall a player would perceive as one, in single
player or on a dedicated server.

#### Scenario: Driving through unexplored forest

- **WHEN** a player drives at speed along a road through forest that has never been loaded
- **THEN** the game does not stutter noticeably more than it does with the mod's correction
  turned off

#### Scenario: Revisiting settled ground

- **WHEN** a player moves repeatedly through an area already corrected
- **THEN** the repeated chunk loads cost measurably less than the first one did
