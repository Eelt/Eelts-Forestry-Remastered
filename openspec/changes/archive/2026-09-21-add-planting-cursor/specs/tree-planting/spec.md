# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

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
