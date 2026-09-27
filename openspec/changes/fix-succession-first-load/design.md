# Design

## Context

See `proposal.md` for the report, the evidence and the load order this rests on.

`EeltsForestryRemastered_Succession.lua` holds `enabled`, `pace`, `recoverUntouched`,
`worldHours`, `worldDays`, `minDay` and the season triple as upvalues, because they are read on
every square. `refreshOptions` fills them. It runs once at the bottom of the file inside a
`pcall`, on `OnGameStart`, on `EveryTenMinutes`, and at the start of `describe` and
`refreshBushes`. The load handler, `onLoadGridsquare`, reads the upvalues and never refreshes
them itself.

`Understory.validateSprites` filters the grass, cover and bush lists down to sprites the game
has, and is registered on `OnGameStart`. `spriteFor` and `bushFor` index those lists by a
coordinate hash, so the length of each list is part of every pick.

## Goals / Non-Goals

**Goals:**

- The first square the pass judges uses the loaded world's values, however the squares arrive.
- Validation happens before any square picks a sprite.
- One boolean test per square is the whole cost after the first.

**Non-Goals:**

- Reworking where or how often the settings are read after the first square.
- Any change to the ladder, the bush looks or the sweep.

## Decisions

### Refresh on the first square

A `ready` upvalue starts false. `onLoadGridsquare` tests it first; on the first call it sets it,
calls `refreshOptions` and `understory.validateSprites`, and prints one line naming the world
day it read, so the refresh can be seen in the console. Every later call pays only the test.

Tying the refresh to the first square makes it independent of event order: the first square
the pass sees is by definition the first one it judges, whether the squares arrive during
loading or are held back and replayed by a mod like LetMeDrive.

Alternative considered: refreshing on `OnGameTimeLoaded`. In both sessions observed, with and
without LetMeDrive, the lua `LoadGridsquare` events for the starting area arrived after that
event even though the chunks themselves had finished streaming before it, so it would have
worked there. It was not chosen because that order is an observation rather than something
the code guarantees, and it has not been seen on a dedicated server, while the first square
refresh costs one boolean test per square and does not depend on it.

Alternative considered: treating a world age of 0 as "not loaded yet" and refreshing whenever
it is seen. Rejected because a brand new world really is at hour 0 on its first square, and the
test would have to run a function call per square instead of reading a boolean.

The read at the bottom of the file stays. It gives the upvalues sensible defaults for anything
that reads them before the first square.

### Validation runs once, from whoever asks first

`validateSprites` gains a `validated` flag and returns at once if it is set. The succession pass
calls it on its first square, and the `OnGameStart` registration stays so that a client, which
never runs the server side pass, still validates its own copy. The startup prints then appear
once, before the first succession report rather than after it.

## Risks / Trade-offs

- A dedicated server loads its world through `ServerMap` rather than the single player path read
  here. The first square refresh does not depend on the order of the server's steps, only on
  the clock being loaded before any chunk is, which a server needs as much as single player.
  Checked on a dedicated server in the verification tasks.
- If any mod fired `LoadGridsquare` by hand before the world loaded, the refresh would read the
  empty world and stay stale until the ten minute tick. No such mod is known, and the result
  would be no worse than today.
