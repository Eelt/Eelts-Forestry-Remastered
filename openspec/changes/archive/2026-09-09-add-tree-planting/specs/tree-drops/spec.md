## ADDED Requirements

### Requirement: A chopped tree marks its propagules with its species

When a player fells a tree, every propagule that fell from it SHALL carry a record of which
species that tree was. This applies to the saplings and cones a tree yields, and the record
SHALL name the felled tree's species rather than anything inferred afterwards.

The species SHALL be read from the standing tree, before it falls. A tree is reset and
reused the moment it topples, so anything read after that point no longer describes the tree
that was chopped.

Only propagules produced by that felling SHALL be marked. Propagules already lying on the
square, whether dropped by the player or left by an earlier tree, SHALL be left as they are.

This exists so that a propagule can be planted as the species it came from. Eight of the
eleven species have no propagule item of their own, so a sapling that remembers its parent
is the only way to propagate them deliberately.

#### Scenario: Saplings from a felled tree

- **WHEN** a player fells a Redmaple large enough to yield saplings
- **THEN** each sapling it drops records Redmaple

#### Scenario: Cones from a felled tree

- **WHEN** a player fells a Virginia Pine large enough to yield cones
- **THEN** each cone it drops records Virginia Pine

#### Scenario: Cones from a Canadian Hemlock

- **WHEN** a player fells a Canadian Hemlock with the cone correction active
- **THEN** each cone it drops records Canadian Hemlock rather than Virginia Pine

#### Scenario: Items already on the square

- **WHEN** a player drops a sapling on a square, then fells a Dogwood standing on it
- **THEN** the sapling the player dropped records nothing, and only the ones the Dogwood
  yielded record Dogwood

#### Scenario: A tree felled some other way

- **WHEN** a tree is destroyed by a vehicle or by fire rather than by a player chopping it
- **THEN** whatever it drops records no species, as with any other uncorrected fell path

## MODIFIED Requirements

### Requirement: No other species changes behaviour

The mod SHALL NOT add, remove or alter any drop for any species other than Canadian
Hemlock. Recording which species a propagule came from is not an alteration of a drop: it
changes nothing about which items appear, how many appear, or what the base game does with
them.

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

#### Scenario: A marked propagule is otherwise an ordinary item

- **WHEN** a player uses a sapling or cone that records a species for anything the base game
  allows, such as crafting, burning or eating
- **THEN** it behaves exactly as an unmarked one would
