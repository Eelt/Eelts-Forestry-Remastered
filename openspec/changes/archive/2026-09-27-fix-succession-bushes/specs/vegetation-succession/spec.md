# Spec Delta

## ADDED Requirements

### Requirement: A recovered bush can be removed like any other bush

A bush placed by recovery SHALL offer the base game's own Remove Bush entry on its right click
menu, and SHALL be removable through it on the same terms as a bush the base game placed: the
same tool requirement, the same action and animation, and the same branch and twig drops.
Clicking one with a cutting tool through the farming menu SHALL remove it as it removes the base
game's bushes.

The mod SHALL NOT add a removal entry of its own, so a recovered bush SHALL show exactly one
Remove Bush entry.

#### Scenario: Removing a recovered bush

- **WHEN** a player carrying a knife right clicks a bush that grew back on cleared ground
- **THEN** Remove Bush is offered under Gardening, and choosing it removes the bush and may drop
  branches and twigs

#### Scenario: One entry only

- **WHEN** a player right clicks a recovered bush
- **THEN** the menu shows one Remove Bush entry

### Requirement: A recovered bush changes with the season

A bush placed by recovery SHALL change its foliage through the year on the same timing the mod
uses for deciduous trees on that square: bare before leaf out, spring foliage from leaf out,
summer foliage from the summer boundary, autumn colour from first colour, and bare from leaves
down until the next leaf out. The stagger setting SHALL apply to bushes as it does to trees,
and with it off a bush SHALL follow the base game's own split.

A bush SHALL keep its species and size through the year. Snow SHALL appear on it in winter
as it does on the base game's bushes.

The change SHALL reach every bush in loaded ground, including bushes no player is standing
near, without waiting for its area to be unloaded and loaded again.

#### Scenario: A bush through one year

- **WHEN** a recovered bush is watched from midwinter to the following midwinter
- **THEN** it is bare, then carries spring foliage, then summer foliage, then autumn colour,
  then is bare again, turning within a few days of a deciduous tree beside it

#### Scenario: A bush far from the player

- **WHEN** a player stays in one place across a season boundary while a recovered bush further
  away than the player's immediate surroundings, but still in loaded ground, crosses it
- **THEN** that bush has changed when the player walks over to it

#### Scenario: A bush after a reload

- **WHEN** a recovered bush is unloaded in summer and its area is reloaded in autumn
- **THEN** it shows autumn colour on arrival

### Requirement: A recovered bush flowers or fruits at its Kentucky time

A bush placed by recovery SHALL show its flowers or its ripe fruit, whichever the base game draws
for its species, at the time of year that plant does so in Kentucky, by calendar date and
regardless of which of the game's seasons that date falls in:

- Piedmont azalea flowers from the start of April to about 10 May, as its leaves open.
- New Jersey tea flowers from the start of June to about mid July.
- Blueberry carries ripe berries from about 10 June to the end of July.
- Shrubby St. John's wort flowers from the start of July to about mid August.
- Red chokeberry carries red berries from about mid September to the end of December, through
  leaf fall and into winter.

Outside its window a bush SHALL show neither. Each square's window SHALL move earlier or later by
the same stagger that moves its foliage, so neighbouring bushes of one species do not all change
on one day. With the stagger setting off, flowering and fruiting SHALL follow the base game's own
timing.

#### Scenario: An azalea flowers as it leafs out

- **WHEN** a recovered Piedmont azalea is watched through April
- **THEN** it carries pink flowers while its first leaves open, and none by the middle of May

#### Scenario: The summer bushes follow one another

- **WHEN** a recovered New Jersey tea, blueberry and shrubby St. John's wort stand together
  from May to September
- **THEN** the New Jersey tea flowers first in June, the blueberry carries berries from mid June
  through July, the St. John's wort flowers in July into August, and none shows either in May or
  September

#### Scenario: Chokeberry fruit in winter

- **WHEN** a recovered red chokeberry is looked at in December, after its leaves have fallen
- **THEN** it carries red berries on bare branches, with snow if it is snowing, and none by the
  following February

#### Scenario: The base game's timing

- **WHEN** the stagger setting is off
- **THEN** each of these bushes flowers or fruits when the base game's own bushes of that species
  do

### Requirement: Bushes placed before the fix are repaired

A bush recovery placed before this requirement existed SHALL be rebuilt where it stands the
first time its square is loaded or passed by a player afterwards, keeping the species and size
it showed. It SHALL then be removable and change with the season like a bush placed afterwards.

The repair SHALL alter only the bush's own appearance. It SHALL NOT add a plant, remove one, or
move a square along the ladder, and it SHALL run whatever the succession setting is, including
off.

#### Scenario: An old save

- **WHEN** a save made before this change, holding bushes grown back by recovery, is loaded in
  winter
- **THEN** each of those bushes shows bare and snow covered rather than in full summer leaf, and
  offers Remove Bush

#### Scenario: Succession off

- **WHEN** the same save is loaded with the succession setting off
- **THEN** its recovered bushes are still repaired, and no square gains anything

## MODIFIED Requirements

### Requirement: A square remembers when it was cleared

When the mod observes a square being cleared, it SHALL record the time, and that record SHALL
persist across saving and loading. Recovery on that square SHALL be measured from it.

Removing vegetation with the base game's Remove Bush or Remove Grass SHALL count as clearing the
square, whether the base game or the mod placed what was removed. A plant a player removes SHALL
NOT be put straight back by recovery; the square SHALL start again from bare ground.

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

#### Scenario: A removed bush does not come straight back

- **WHEN** a player removes a recovered bush with Remove Bush and stays beside the square for a
  day
- **THEN** the square stays bare for that day, and later recovers from grass upwards
