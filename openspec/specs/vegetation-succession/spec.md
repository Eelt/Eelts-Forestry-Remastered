# vegetation-succession Specification

## Purpose
Governs how ground that has been cleared, burned or felled grows back over time, through
grass, groundcover and ferns, bushes and finally trees, up to a density ceiling that varies by
forage zone. It exists because the base game puts nothing back on a square that loses its
vegetation, so a clear cut is permanent and felling a forest can never be undone.

## Requirements

### Requirement: Cleared ground recovers through the whole ladder

Ground the mod has taken responsibility for SHALL recover in stages as time passes. Bare
ground SHALL gain grass, then groundcover and ferns, then bushes, and finally trees, and SHALL
NOT skip a stage or reach a later one before an earlier one.

A wildfire, a clear cut and a player levelling a field SHALL all leave the same starting
condition and SHALL all recover the same way. How the ground was cleared SHALL make no
difference to what grows back on it.

Recovery SHALL stop at the density ceiling in effect for that square's forage zone.

The three layers below the trees SHALL NOT cover the ground evenly. Grass SHALL end up on
every square that can grow anything at all, tall grass and ferns SHALL be common but not
universal, and bushes SHALL be occasional. No layer SHALL arrange itself in rows, lines or any
other pattern a player can read as regular.

A square that already carries something growing, whether the base game put it there or the mod
did, SHALL NOT have a second plant added to it, and what is on it SHALL NOT be removed to make
room. A forest floor already carrying the base game's own grass is left exactly as it is.

This SHALL NOT prevent a tree establishing there. A sapling comes up through grass the same
way a planted one does, and only then does the grass under it give way.

#### Scenario: A clear cut field grows back

- **WHEN** a measured area is cleared of everything and left for the full recovery time
- **THEN** grass appears first, then groundcover and ferns, then bushes, then trees, in that
  order
- **AND** the area ends at the density its forage zone supports rather than continuing to
  thicken

#### Scenario: Burned ground recovers like cut ground

- **WHEN** one area is cleared by fire and another of the same forage zone is cleared by
  felling, and both are left for the same time
- **THEN** both show the same stage of recovery

#### Scenario: Recovered ground does not look planted

- **WHEN** a large recovered area is looked at from above
- **THEN** grass covers it, ferns and tall grass are scattered through it, bushes are
  occasional, and none of them stands in rows or diagonals

#### Scenario: An existing forest floor is left alone

- **WHEN** a player walks through forest that has never been cleared, and whose ground already
  carries the base game's grass
- **THEN** no plant is added to any square of it, and none of its grass is removed

#### Scenario: A tree still establishes through grass

- **WHEN** a square carrying grass reaches the point where a tree may establish, and its area
  is under its ceiling
- **THEN** a tree establishes there, and the grass it replaces is removed only once the tree
  is standing

#### Scenario: A stage is not skipped

- **WHEN** a cleared square is watched from bare ground to its first tree
- **THEN** it carried grass, and then bushes, before it carried a tree

### Requirement: A setting controls the pace of recovery

The time recovery takes SHALL be adjustable through a numeric setting. Raising the value SHALL
make every rung take longer and lowering it SHALL make every rung take less time,
proportionally, so that the ladder keeps its shape at any setting.

At its default, a cleared square SHALL carry grass within days, bushes within weeks, and its
first sapling about a month after it was cleared, with the slowest squares taking about three
months to reach that rung. These defaults exist so that recovery runs at about the pace the
base game's own erosion places its first wild trees.

Squares SHALL NOT all reach a rung on the same day. Which day a given square crosses a rung
SHALL vary with its position, so a recovering area fills in unevenly rather than appearing at
once.

#### Scenario: Default pace

- **WHEN** an area is cleared with the pace setting left at its default
- **THEN** grass is on it within days, bushes within weeks, and the first saplings about a
  month after clearing

#### Scenario: Pace is doubled

- **WHEN** the pace setting is set to twice its default
- **THEN** every rung takes about twice as long to arrive as it would at the default, and the
  order of the rungs is unchanged

#### Scenario: An area fills in unevenly

- **WHEN** a large cleared area is watched across the month its first trees are due
- **THEN** trees appear on different squares on different days rather than all at once

### Requirement: Recovery is measured in elapsed world time

Recovery SHALL depend on how much in-game time has passed since the square was cleared, not on
how much of that time the square spent loaded. An area left unvisited SHALL show the recovery
its elapsed time has earned the first time a player returns to it.

#### Scenario: A region left alone for two years

- **WHEN** a player clears an area, stays away long enough for two in-game years to pass, and
  returns
- **THEN** the area shows two years of recovery, not the recovery of the hours the player
  spent near it

#### Scenario: Watching does not speed recovery

- **WHEN** one cleared area is watched continuously and another of the same forage zone is
  left unloaded for the same elapsed time
- **THEN** both are at the same stage when compared

### Requirement: A square remembers when it was cleared

When the mod observes a square being cleared, it SHALL record the time, and that record SHALL
persist across saving and loading. Recovery on that square SHALL be measured from it.

A square the mod never saw cleared SHALL be treated as having been bare since the world began,
so long abandoned ground recovers rather than staying bare because nobody watched it happen.
Fields that were already open when the world started are the common case and SHALL recover on
the same terms as ground the mod watched being cleared.

Whether untouched ground recovers SHALL be one of the choices on the succession setting rather
than a separate control. Limiting recovery to squares the mod recorded SHALL also cost less to
run, since the rest of the world is then rejected before anything is read from the square.

Clearing a square that has already recovered SHALL reset its record, so the same ground can be
cleared and recover repeatedly.

#### Scenario: The record survives a reload

- **WHEN** an area is cleared, and the game is saved and reloaded before any recovery is
  visible
- **THEN** recovery continues from when the area was cleared, not from when it was reloaded

#### Scenario: Ground bare since the world began

- **WHEN** a player finds a field that was already bare when the world started and the setting
  is at its default
- **THEN** that field recovers on the world's own age like any other cleared ground

#### Scenario: Untouched ground is not regrown

- **WHEN** the setting for regrowing untouched ground is turned off
- **THEN** ground the mod never saw cleared stays exactly as it is, and ground the mod saw
  cleared still recovers

#### Scenario: Clearing the same ground twice

- **WHEN** a recovered area is cleared a second time
- **THEN** it starts again from bare ground and recovers at the same pace as the first time

### Requirement: Only ground that could hold a tree recovers

A square SHALL recover only where the mod would let a player plant a tree: outside, at ground
level, on diggable ground, with no building, no existing tree, no water and no farmed crop,
and with the square otherwise free.

This test SHALL be the same one player planting uses, so that a player cannot see a tree
establish somewhere they would be refused one.

Recovery SHALL NOT displace, clear or alter anything already on the square or on any
neighbouring square.

#### Scenario: A road stays a road

- **WHEN** a road, a car park and a building floor are left for the full recovery time
- **THEN** nothing grows on any of them

#### Scenario: A tended crop is left alone

- **WHEN** a player has a farming plot inside an area that is otherwise recovering
- **THEN** the plot is untouched and the ground around it recovers

#### Scenario: Recovery never displaces anything

- **WHEN** an established tree reaches a size whose artwork is larger than one square
- **THEN** nothing on any neighbouring square is removed or altered

### Requirement: What grows back suits the place

The species of a tree that establishes SHALL be drawn from the same forage zone weights the
mod uses to correct a wild tree and to plant an unmarked propagule, not from any one
propagule's filtered list.

Trees already standing within a bounded distance SHALL bias those weights toward themselves,
so that a stand reseeds as itself rather than redrawing the zone mixture each time. The bias
SHALL be bounded: a species with no weight in the zone SHALL NOT establish there merely
because one tree of it stands nearby, unless the setting for player planted parents allows it.

A square in a zone the mod has no weights for SHALL grow understory but SHALL NOT establish a
tree, because a zone with no recorded species is not evidence that any species suits it.

#### Scenario: A pine forest reseeds as pine

- **WHEN** an area of a zone that grows only one species is cleared and left to recover
- **THEN** every tree that establishes there is that species

#### Scenario: A mixed stand reseeds as itself

- **WHEN** a gap inside a stand of one species in a mixed zone recovers
- **THEN** the trees that fill it are more often that species than the zone's weights alone
  would give

#### Scenario: An unweighted zone grows no tree

- **WHEN** cleared ground belongs to a zone the mod has no species weights for
- **THEN** grass and bushes return to it and no tree establishes

### Requirement: Density stops at the zone's ceiling

Each forage zone SHALL have its own ceiling on how densely trees may stand, expressed as a
minimum spacing between established trees and a limit on how many stand within a wider
neighbourhood. Recovery SHALL stop adding trees to a square once either limit is reached.

The ordering of the ceilings between zones SHALL follow the density the shipped map actually
carries in each zone. The absolute numbers are the mod's own tuning and SHALL be adjustable
through a setting.

Trees the ceiling excludes as seed parents SHALL still count toward crowding, because they
occupy the ground whether or not they may breed.

This ceiling SHALL apply to natural recovery only. An existing stand already denser than its
ceiling SHALL be left alone, and a player SHALL NOT be prevented from planting where the
ceiling would refuse to establish a tree.

#### Scenario: Recovery stops thickening

- **WHEN** a cleared area of any forage zone is left far longer than it takes to recover fully
- **THEN** the number of trees in it stops rising and settles at the ceiling

#### Scenario: Deep forest recovers denser than farm forest

- **WHEN** equal areas of Deep Forest and Managed Forestry are cleared and left to recover
  fully
- **THEN** the Deep Forest area ends with noticeably more trees than the Managed Forestry area

#### Scenario: An existing dense stand is not thinned

- **WHEN** a player finds an untouched stand standing denser than its zone's ceiling
- **THEN** no tree in it is removed

#### Scenario: Planting is not limited by the ceiling

- **WHEN** a player plants trees closer together than the ceiling allows recovery to
- **THEN** every one of them is planted and grows

### Requirement: An established tree is a wild tree

A tree that establishes naturally SHALL be created at the smallest size stage and SHALL be
taken into the mod's tree system as it is created, so it grows and keeps its seasons without
waiting to be discovered.

It SHALL count as wild. It SHALL NOT be recorded as player planted, however it came to be
there, and SHALL NOT grow under the setting that grows player planted trees only.

Under the setting that stops growth altogether, a tree SHALL still establish, and SHALL stay
at the smallest stage.

#### Scenario: An established tree grows

- **WHEN** the growth setting is all trees and a tree establishes on cleared ground
- **THEN** it begins at the smallest size and grows through the stages like any wild tree

#### Scenario: An established tree is not player planted

- **WHEN** the growth setting is player planted only and trees establish on cleared ground
- **THEN** none of them grows

#### Scenario: Establishment under the base game's growth choice

- **WHEN** the growth setting is the base game's behaviour and succession is on
- **THEN** trees still establish on cleared ground and stay at the smallest size

### Requirement: A setting controls whether player planted trees are parents

Whether a directly player planted tree may influence what establishes near it SHALL be
controlled by a setting with three choices: disabled, native species only, and all species.
It SHALL default to disabled.

Under native species only, a player planted tree SHALL contribute only where its species
already has weight in the destination square's zone. Where the zone has no recorded species
pool, it SHALL NOT contribute. Under all species, it SHALL contribute outside its normal zone,
subject to the same ground and crowding limits as any other parent.

A tree that established naturally SHALL count as wild from the moment it exists, even when its
parent was player planted. It SHALL contribute as a wild tree whatever the setting says, and
SHALL still do so after the setting is returned to disabled.

Changing the setting SHALL govern later establishment only. It SHALL NOT remove or alter any
tree that already exists.

#### Scenario: Disabled by default

- **WHEN** a player plants an orchard of a species foreign to the zone and leaves cleared
  ground beside it to recover
- **THEN** none of the trees that establish is that species

#### Scenario: Native species only

- **WHEN** the setting is native species only, and a player planted tree of a species the zone
  does grow stands beside recovering ground
- **THEN** that species establishes more often there than the zone's weights alone would give

#### Scenario: A planted tree's offspring is wild

- **WHEN** a tree establishes next to a player planted parent, the setting is returned to
  disabled, and more ground nearby recovers
- **THEN** that offspring still influences what establishes near it, and does not grow under
  the player planted only growth setting

#### Scenario: Changing the setting leaves existing trees alone

- **WHEN** the setting is changed in a world that has already grown trees under it
- **THEN** every tree that exists is still there and unchanged

### Requirement: A setting controls whether ground recovers at all

Succession SHALL have its own setting, independent of the growth setting and of the composition
correction setting, offering three choices: off, ground the mod recorded being cleared only,
and all open ground. It SHALL default to all open ground. Choosing off SHALL stop any further
recovery.

Vegetation already placed SHALL be left where it is. The mod cannot give a square back to the
base game's erosion once it has been taken, so turning the setting off SHALL be described as
stopping further recovery rather than undoing it.

A player wanting the world to behave as it would without the mod SHALL need this setting off
as well as the growth setting on the base game's behaviour and correction off. This SHALL be
stated in the setting's own description.

#### Scenario: Turned off from the start

- **WHEN** a world runs with the setting off from the beginning
- **THEN** cleared ground stays bare exactly as it does without the mod

#### Scenario: Limited to ground the player cleared

- **WHEN** the setting is on its middle choice
- **THEN** ground the player clears recovers and old fields that were open from the start do
  not

#### Scenario: Turned off partway through

- **WHEN** a world with recovering areas has the setting turned off
- **THEN** the vegetation already there stays, and no square gains anything further

#### Scenario: Independent of the other settings

- **WHEN** the growth setting is the base game's behaviour and correction is off, and
  succession is on
- **THEN** cleared ground still recovers

### Requirement: Recovery is consistent for everyone and survives saving

What stands on a recovering square SHALL be the same after unloading and reloading the area,
and SHALL be the same for every player who can see it. Two players arriving at the same
recovering ground SHALL see the same vegetation on the same squares.

Recovery SHALL NOT place two things on one square, and reloading SHALL NOT add a second copy
of anything it already placed.

#### Scenario: The same ground after a reload

- **WHEN** a recovering area is unloaded and the game saved and reloaded
- **THEN** the same squares carry the same vegetation at the same stage

#### Scenario: Two players see one forest

- **WHEN** two players arrive separately at the same recovering area
- **THEN** they see the same vegetation on the same squares

#### Scenario: Reloading does not stack vegetation

- **WHEN** a recovering area is loaded and unloaded repeatedly
- **THEN** no square ends up carrying more than one plant, bush or tree

### Requirement: Succession is affordable on every chunk load

Deciding what a square should carry runs during chunk loading, for every square of a
recovering area, so its cost SHALL be small enough not to be noticeable while moving through
the world.

A square that is not recovering SHALL be rejected more cheaply than one that is. Loading a
large recovering area SHALL NOT cause a stall a player would perceive as one, in single player
or on a dedicated server.

#### Scenario: Driving past a large clear cut

- **WHEN** a player drives at speed past an area of several thousand recovering squares
- **THEN** the game does not stutter noticeably more than it does with succession turned off

#### Scenario: Untouched ground costs little

- **WHEN** a player moves through ground that has never been cleared
- **THEN** the cost of succession is measurably lower than in a recovering area
