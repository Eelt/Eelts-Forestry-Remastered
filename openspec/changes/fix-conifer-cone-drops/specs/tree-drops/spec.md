## Purpose

Governs what a tree yields when a player chops it down, and in particular which species
produce a propagule such as a cone. It exists to correct places where the base game's drop
table fails to give a species the propagule it should have, without changing any other part
of the yield.

## ADDED Requirements

### Requirement: Canadian Hemlock yields cones

Canadian Hemlock is a conifer and SHALL yield pine cones when chopped down, on the same
terms the base game already applies to Virginia Pine. The mod SHALL NOT change the number
of logs, branches, twigs, saplings or splinters a Canadian Hemlock yields.

The base game gives cones only to trees whose sprite name contains `pine`, which excludes
Canadian Hemlock. Matching Virginia Pine's terms means: the tree must be at least stage 3,
and one cone is rolled per log yielded, at a probability that rises with the tree's size and
becomes certain at the largest sizes.

#### Scenario: A mature Canadian Hemlock is chopped down

- **WHEN** a player fells a Canadian Hemlock of stage 3 or larger
- **THEN** one or more `Base.Pinecone` MAY appear on the tree's square, at the same
  per-log probability Virginia Pine uses at that size
- **AND** the logs, branches, twigs, saplings and splinters are exactly what the base game
  would have produced

#### Scenario: The largest Canadian Hemlocks always yield cones

- **WHEN** a player fells a Canadian Hemlock of stage 5, 6 or 7
- **THEN** at least one `Base.Pinecone` appears on the tree's square, because at those
  sizes the base game's per-log roll is certain

#### Scenario: A sapling-sized Canadian Hemlock is chopped down

- **WHEN** a player fells a Canadian Hemlock below stage 3
- **THEN** no `Base.Pinecone` appears, because the base game produces no species drop from
  a tree yielding fewer than three logs

### Requirement: No other species changes behaviour

The mod SHALL NOT add, remove or alter any drop for any species other than Canadian
Hemlock.

American Holly is modelled to look like a conifer but is an evergreen broadleaf that bears
drupes, and the base game already gives it a berry. Virginia Pine already yields cones
correctly. No tree in the base game can yield an acorn, and this capability does not give
one a source.

#### Scenario: Virginia Pine is unaffected

- **WHEN** a player fells a Virginia Pine of any size
- **THEN** its yield is exactly what the base game produces, with no duplicated or
  additional cone

#### Scenario: American Holly is unaffected

- **WHEN** a player fells an American Holly of any size, in any season
- **THEN** it yields no cone, and its berry behaviour is exactly what the base game
  produces

#### Scenario: Deciduous species are unaffected

- **WHEN** a player fells any of the eight deciduous species
- **THEN** its yield is exactly what the base game produces, with no cone and no acorn

### Requirement: The correction is switchable

The correction SHALL be controlled by a sandbox option that is on by default. When the
option is off, every tree SHALL yield exactly what the base game produces.

The option exists because the correction changes a base game drop table that other mods and
existing player expectations may depend on, so it must be possible to disable without
disabling the rest of the mod.

#### Scenario: The option is left at its default

- **WHEN** a world is created without touching the mod's sandbox options
- **THEN** the correction is active

#### Scenario: The option is turned off

- **WHEN** a player sets the option off and fells a Canadian Hemlock of any size
- **THEN** no cone appears, and the yield is exactly what the base game produces

### Requirement: Uncorrected fell paths are left alone

Trees destroyed other than by a player chopping them down, such as by a vehicle collision
or by fire, SHALL be left to the base game's behaviour and SHALL NOT gain a cone.

This is a known and accepted limitation rather than an oversight: those paths do not run
the chopping action, and intercepting them is not possible without modifying a base game
file.

#### Scenario: A Canadian Hemlock is destroyed by a vehicle

- **WHEN** a vehicle destroys a Canadian Hemlock
- **THEN** the yield is exactly what the base game produces, with no cone
