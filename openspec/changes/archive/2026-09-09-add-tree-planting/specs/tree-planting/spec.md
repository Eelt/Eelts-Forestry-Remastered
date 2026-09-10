## Purpose

Governs how a player turns a propagule into a growing tree: what may be planted, which
species results, where planting is allowed, what the player must have and know before they
can do it, and how the base game's unused tree planting tape becomes the thing that teaches
it.

## ADDED Requirements

### Requirement: A propagule may be planted into a growing tree

A player SHALL be able to plant a propagule on a suitable ground square, consuming it and
creating a tree of the smallest size on that square. The resulting tree SHALL be a tree in
every respect the base game recognises, so it may be chopped, yields what its size yields,
and blocks movement as any tree does.

Three propagules SHALL be plantable: the sapling, which can represent any of the eleven
species, the pine cone, which can represent only the species that bear cones, and the holly
berry, which represents American Holly alone. No other item SHALL be plantable.

#### Scenario: A sapling is planted

- **WHEN** a player plants a sapling on a suitable square
- **THEN** a tree of the smallest size appears on that square
- **AND** the sapling is removed from their inventory

#### Scenario: The planted tree is an ordinary tree

- **WHEN** a player fells a tree they planted earlier
- **THEN** it yields what the base game yields for a tree of that size and species

#### Scenario: An item that is not a propagule

- **WHEN** a player is holding any item other than a sapling, a pine cone or a holly berry
- **THEN** no planting option is offered for it

### Requirement: Planting requires a digging tool

Planting SHALL require the player to have a digging tool in addition to the propagule. Any
tool the base game already treats as capable of digging soil SHALL qualify, so shovels,
trowels and hand shovels all work and no new tool is introduced.

The tape line this capability is unlocked by is about digging a hole and firming the soil
back in, so requiring a tool keeps the action consistent with the fiction that teaches it.

#### Scenario: A digging tool is carried

- **WHEN** a player carrying a propagule and a shovel selects a suitable square
- **THEN** planting is offered

#### Scenario: No digging tool is carried

- **WHEN** a player carrying a propagule and no digging tool selects a suitable square
- **THEN** planting is not available, and the reason given names the missing tool

#### Scenario: A trowel is enough

- **WHEN** a player carries a trowel or a hand shovel rather than a shovel
- **THEN** planting is offered on the same terms

### Requirement: A propagule carries the species of the tree it came from

A propagule that a player obtains by chopping a tree SHALL record which species that tree
was, and SHALL plant that species. The species recorded SHALL be the species of the tree
that was felled, not one inferred from where the propagule later ends up.

This is what makes deliberate propagation possible. Eight of the eleven species have no
propagule item of their own, so a sapling that remembers its parent is the only way to
choose what to plant.

#### Scenario: A sapling from a known tree plants that species

- **WHEN** a player fells a Redmaple, collects a sapling it dropped, and plants it
- **THEN** the tree that appears is a Redmaple

#### Scenario: A cone from a known tree plants that species

- **WHEN** a player fells a Canadian Hemlock, collects a cone it dropped, and plants it
- **THEN** the tree that appears is a Canadian Hemlock, not a Virginia Pine

#### Scenario: The species survives storage and transport

- **WHEN** a propagule with a recorded species is dropped, stored in a container, carried
  across the map, and the area is unloaded and reloaded
- **THEN** planting it still produces the species that was recorded

### Requirement: An unmarked propagule plants a species suited to where it is planted

A propagule carrying no recorded species SHALL plant a species chosen at random, weighted
by the species the planting square's forage zone naturally grows, and restricted to the
species that propagule is capable of representing.

Propagules obtained by foraging carry no species, because the foraging tables have no
relationship to the trees actually growing in the zone. So do propagules from a save made
before this capability existed, and any from a fell path the mod does not intercept. Falling
back to the zone means those still plant something plausible rather than nothing.

Where the planting square's zone grows none of the eligible species, the choice SHALL be
made from the eligible species without weighting, so that planting never fails for want of a
local match.

#### Scenario: A foraged sapling in a birch forest

- **WHEN** a player plants a foraged sapling in a zone that grows only Riverbirch
- **THEN** the tree that appears is a Riverbirch

#### Scenario: A foraged cone stays a conifer

- **WHEN** a player plants a foraged pine cone in a zone whose trees are all deciduous
- **THEN** the tree that appears is one of the species that bear cones, never a deciduous
  species

#### Scenario: Planting in a zone with no trees of its own

- **WHEN** a player plants an unmarked propagule in a town or on bare dirt, where the zone
  grows no trees at all
- **THEN** a species is still chosen from those the propagule can represent, and a tree
  appears

#### Scenario: A holly berry is unaffected by the zone

- **WHEN** a player plants a holly berry anywhere
- **THEN** the tree that appears is an American Holly, because the berry represents one
  species only

### Requirement: Only an unpoisoned holly berry may be planted

A holly berry carrying poison SHALL NOT be plantable. A holly berry with no poison SHALL be
plantable, and planting SHALL NOT alter the poison state of any item.

The base game applies poison to a holly berry when it is foraged and not when it is dropped
by a chopped tree, so the two are otherwise identical items. Treating the clean one as the
viable seed makes felling a Holly the route to propagating one, and the base game already
restricts that to Autumn and Winter.

#### Scenario: A berry from a chopped Holly

- **WHEN** a player fells an American Holly in Autumn or Winter, collects a berry it
  dropped, and plants it
- **THEN** an American Holly appears

#### Scenario: A foraged berry

- **WHEN** a player attempts to plant a holly berry obtained by foraging
- **THEN** planting is refused, and the reason given identifies the berry as unfit to plant

#### Scenario: Poison is left alone

- **WHEN** a player carries both a poisoned and an unpoisoned holly berry and plants the
  unpoisoned one
- **THEN** the poisoned berry is still poisoned afterwards

### Requirement: Planting is restricted to suitable ground

Planting SHALL be allowed only on an outdoor square with natural ground that has no tree on
it already and nothing on it that a tree would occupy the same space as. It SHALL NOT be
allowed indoors, on a floor the player has built, on water, on a square already holding a
tree, or on a square holding a crop.

Ground counts as suitable exactly where the base game would let a player plow a furrow. That
includes grass and forest floor as well as bare dirt, and excludes sand, clay, gravel and
road surfaces, which the base game lets a player dig but never plow.

The square SHALL be within reach of the player, on the same footing every other square
interaction in the base game uses.

#### Scenario: Open ground outdoors

- **WHEN** a player selects an empty outdoor square of natural ground within reach
- **THEN** planting is offered

#### Scenario: Indoors

- **WHEN** a player selects a square inside a building
- **THEN** planting is not available

#### Scenario: A square that already has a tree

- **WHEN** a player selects a square holding a tree of any size
- **THEN** planting is not available

#### Scenario: Water

- **WHEN** a player selects a water square
- **THEN** planting is not available

#### Scenario: Grass and forest floor

- **WHEN** a player selects an outdoor square of grass or forest floor
- **THEN** planting is offered, because the base game would allow a furrow there

#### Scenario: Sand, clay and gravel

- **WHEN** a player selects a square of sand, clay, gravel or road surface
- **THEN** planting is not available, matching the base game's refusal to plow those

#### Scenario: A square holding a crop

- **WHEN** a player selects a square with a farm plant growing on it
- **THEN** planting is not available

### Requirement: A planted tree grows as a planted tree

A tree created by planting SHALL begin growing immediately, at the smallest size, and SHALL
be recorded as player-planted for as long as it exists. That record SHALL survive saving and
loading, and SHALL be what the growth setting means by a tree the player planted.

#### Scenario: A planted tree starts growing without being revisited

- **WHEN** a player plants a tree and walks away
- **THEN** that tree is already growing, without needing the area to be reloaded or a
  proximity scan to find it

#### Scenario: A planted tree is still planted after a reload

- **WHEN** a player plants a tree, saves, quits, and returns
- **THEN** that tree is still recorded as player-planted

#### Scenario: Growth restricted to planted trees

- **WHEN** the growth setting is set to only player-planted trees
- **THEN** a tree the player planted grows, and a wild tree beside it does not

### Requirement: The tape teaches planting, and a setting controls whether that is required

Planting SHALL be unavailable until the player has watched the base game's tree planting
tape, specifically the line instructing the viewer to firm the soil around the base of the
tree. Watching that line SHALL teach planting to that player permanently, and SHALL do so
once rather than every time the line plays.

This SHALL be controlled by a setting that is on by default. With the setting off, planting
SHALL be available from the start with no tape required.

The requirement is per player rather than per world, so in multiplayer one player watching
the tape does not teach it to anyone else.

#### Scenario: Before the tape is watched

- **WHEN** a player who has not watched the tape carries a propagule and a shovel
- **THEN** planting is not available, and no explanation naming the tape is given, because
  the player has no way to know the tape exists

#### Scenario: The line plays

- **WHEN** a player watches the tree planting tape through to the line about firming the
  soil
- **THEN** planting becomes available to that player, and they are told they have learned it

#### Scenario: Watching the tape again

- **WHEN** a player who already knows planting watches the same line a second time
- **THEN** nothing further happens and they are not told again

#### Scenario: The requirement is switched off

- **WHEN** the setting is off
- **THEN** planting is available to every player without the tape

#### Scenario: One player watches in multiplayer

- **WHEN** one player watches the tape and another does not
- **THEN** only the player who watched it can plant

### Requirement: The tape can be found

The tree planting tape SHALL be obtainable in an ordinary playthrough. It SHALL appear as
a recording on ordinary home video tapes found in the world, in places consistent with where
the base game puts domestic and gardening tapes.

The base game defines this tape but excludes it from its own tape spawning, so nothing in an
unmodified game can produce it. Since the tape gates planting, leaving it unobtainable would
make the default setting an unreachable feature.

#### Scenario: Looting for the tape

- **WHEN** a player searches the containers the tape is placed in
- **THEN** they can eventually find a home video tape carrying the tree planting guide

#### Scenario: Other tapes are unaffected

- **WHEN** a player finds any other home video tape
- **THEN** it carries whatever recording the base game would have given it

### Requirement: Nothing the base game does is altered to achieve any of this

This capability SHALL be built by adding to the base game rather than changing it. The tape
and its lines SHALL NOT be modified, no vanilla item SHALL be redefined, and turning the
mod off SHALL leave a world with no trace of it beyond trees that already exist.

#### Scenario: The tape's own content

- **WHEN** a player watches the tree planting tape with the mod active
- **THEN** every line reads exactly as the base game wrote it, in the same order

#### Scenario: Existing propagules keep working

- **WHEN** a player uses a sapling, cone or holly berry for anything the base game allows,
  such as crafting or eating
- **THEN** it behaves exactly as it would without the mod
