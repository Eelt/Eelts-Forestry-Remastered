# Spec Delta

## MODIFIED Requirements

### Requirement: Recovery is measured in elapsed world time

Recovery SHALL depend on how much in-game time has passed since the square was cleared, not on
how much of that time the square spent loaded. An area left unvisited SHALL show the recovery
its elapsed time has earned the first time a player returns to it.

The area that loads with a save, around the player, SHALL be judged on the loaded world's own
date and time, the same as any area that loads later in the session. Nothing about how a square
recovers or looks SHALL depend on whether it loaded with the save or afterwards.

#### Scenario: A region left alone for two years

- **WHEN** a player clears an area, stays away long enough for two in-game years to pass, and
  returns
- **THEN** the area shows two years of recovery, not the recovery of the hours the player
  spent near it

#### Scenario: Watching does not speed recovery

- **WHEN** one cleared area is watched continuously and another of the same forage zone is
  left unloaded for the same elapsed time
- **THEN** both are at the same stage when compared

#### Scenario: Loading a save beside recovering ground

- **WHEN** a save is loaded with the player standing in an area whose clearing is old enough
  to have earned recovery
- **THEN** that area shows the recovery its elapsed time has earned as soon as the game is
  running, the same as it would have if the player had walked into it later
- **AND** any recovered bush in it shows the current season's look on arrival
