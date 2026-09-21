# tree-planting Specification

## Purpose
Governs how a player turns a propagule into a growing tree: what may be planted, which
species results, where planting is allowed, what the player must have and know before they
can do it, and how the base game's unused tree planting tape becomes the thing that teaches
it.

## Requirements

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

The tool SHALL be required at the moment planting is offered, from the world menu or from the
inventory, and again at the moment a square is clicked with the placement cursor, so that a
tool given away while the cursor is up does not let the planting go ahead.

#### Scenario: A digging tool is carried

- **WHEN** a player carrying a propagule and a shovel opens the planting menu on a suitable
  square
- **THEN** planting is offered

#### Scenario: No digging tool is carried

- **WHEN** a player carrying a propagule and no digging tool opens the planting menu on a
  suitable square
- **THEN** planting is not available, and the reason given names the missing tool

#### Scenario: A trowel is enough

- **WHEN** a player carries a trowel or a hand shovel rather than a shovel
- **THEN** planting is offered on the same terms

#### Scenario: The tool is lost while the cursor is up

- **WHEN** the placement cursor is up and the player drops their only digging tool
- **THEN** clicking a square plants nothing

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

Suitability SHALL be shown by the placement cursor, green where planting is allowed and red
where it is not, and SHALL be judged again when the square is clicked and again when the
planting action runs, so that a square that stops being suitable while the player walks to it
is not planted on. The world menu's Plant Tree entry SHALL continue to appear only on a
suitable square, as it does today.

#### Scenario: Open ground outdoors

- **WHEN** the cursor is over an empty outdoor square of natural ground within reach
- **THEN** it reads green and a click plants there

#### Scenario: Indoors

- **WHEN** the cursor is over a square inside a building
- **THEN** it reads red and a click does nothing

#### Scenario: A square that already has a tree

- **WHEN** the cursor is over a square holding a tree of any size
- **THEN** it reads red and a click does nothing

#### Scenario: Water

- **WHEN** the cursor is over a water square
- **THEN** it reads red and a click does nothing

#### Scenario: Grass and forest floor

- **WHEN** the cursor is over an outdoor square of grass or forest floor
- **THEN** it reads green, because the base game would allow a furrow there

#### Scenario: Sand, clay and gravel

- **WHEN** the cursor is over a square of sand, clay, gravel or road surface
- **THEN** it reads red, matching the base game's refusal to plow those

#### Scenario: A square holding a crop

- **WHEN** the cursor is over a square with a farm plant growing on it
- **THEN** it reads red and a click does nothing

#### Scenario: The square changes while walking

- **WHEN** a player clicks a green square and something is placed on it before they arrive
- **THEN** nothing is planted and the propagule is kept

#### Scenario: The world menu on an unsuitable square

- **WHEN** a player right clicks a road or a square inside a building
- **THEN** the world menu offers no Plant Tree entry, as before

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

This SHALL be controlled by a setting that is off by default. With the setting off, planting
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

### Requirement: A propagule is planted through a placement cursor

Choosing a propagule to plant SHALL NOT commit to a square. It SHALL put a one square
placement cursor under the mouse, drawn the way the base game draws its own ground cursors,
and the square SHALL be chosen by clicking with that cursor. The cursor SHALL read green over
a square where planting is allowed and red over one where it is not, and a click on a red
square SHALL do nothing.

Clicking a green square SHALL walk the player to it and plant the chosen propagule there, on
the same terms as before. The cursor SHALL remain after a planting so that further squares can
be chosen without returning to a menu, and SHALL close on its own once the player carries no
more propagules of the kind chosen. A right click, the Escape key, or the controller's cancel
button SHALL close it at any time, as they close every other cursor in the base game.

The cursor SHALL be usable from a controller on the same footing as the base game's own one
square cursors.

#### Scenario: A propagule is chosen from the world menu

- **WHEN** a player right clicks a square, opens Plant Tree, and chooses a propagule
- **THEN** a one square cursor appears under the mouse and nothing has yet been planted
- **AND** the square that was right clicked is not planted on unless it is later clicked
  with the cursor

#### Scenario: Hovering suitable and unsuitable ground

- **WHEN** the cursor is moved over open outdoor ground, then over a road, then over a
  square holding a tree
- **THEN** it reads green over the open ground and red over the other two

#### Scenario: Clicking a green square

- **WHEN** the player clicks a square the cursor shows green
- **THEN** the character walks to that square and plants the chosen propagule on it

#### Scenario: Clicking a red square

- **WHEN** the player clicks a square the cursor shows red
- **THEN** nothing happens and the cursor stays where it is

#### Scenario: Planting a stack

- **WHEN** a player carrying three saplings of one kind plants one with the cursor
- **THEN** the cursor is still up, and two more squares can be clicked without opening a menu
- **AND** after the third is planted the cursor closes on its own

#### Scenario: Cancelling

- **WHEN** the cursor is up and the player right clicks, or presses Escape
- **THEN** the cursor closes and nothing is planted

#### Scenario: The propagule is lost while the cursor is up

- **WHEN** the cursor is up and the player drops or transfers away every propagule of the
  chosen kind
- **THEN** the cursor closes rather than planting nothing

### Requirement: A propagule can be planted from the inventory

Right clicking a propagule the player is carrying SHALL offer to plant it, directly and with
no submenu, whatever the mouse is or is not near in the world. The offer SHALL be subject to
every gate the world menu applies: the player must know planting, must carry a digging tool,
and the propagule must be fit to plant. When a gate fails for a reason the player can be told,
the reason SHALL be shown as it is in the world menu. Choosing the option SHALL open the same
placement cursor.

A propagule that is not being carried, such as one lying in a container on the ground, SHALL
NOT be offered for planting from that container.

#### Scenario: A carried sapling is right clicked

- **WHEN** a player who can plant right clicks a sapling in their inventory
- **THEN** a Plant option naming that propagule is offered with no submenu
- **AND** choosing it puts the placement cursor under the mouse

#### Scenario: Several propagules are selected together

- **WHEN** a player selects a sapling and a pine cone together and right clicks
- **THEN** a Plant option is offered for each distinct kind

#### Scenario: No digging tool

- **WHEN** a player with no digging tool right clicks a sapling in their inventory
- **THEN** the Plant option is shown but cannot be chosen, and the reason names the tool

#### Scenario: A poisoned holly berry

- **WHEN** a player right clicks a foraged holly berry in their inventory
- **THEN** the Plant option is shown but cannot be chosen, and the reason identifies the berry
  as unfit

#### Scenario: Before the tape is watched

- **WHEN** the tape setting is on and a player who has not watched it right clicks a sapling
- **THEN** no Plant option is offered

#### Scenario: A sapling in a crate on the floor

- **WHEN** a player right clicks a sapling listed in a crate they are looking into
- **THEN** no Plant option is offered for it
