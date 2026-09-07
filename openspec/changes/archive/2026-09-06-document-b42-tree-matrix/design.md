## Context

See `proposal.md` for motivation. The constraints that shape this change are that the mod
has no test suite, so a wrong assumption about a B42.20 table is only caught by playing;
that `openspec/` is tracked and read as ordinary project documentation; and that the
planting change which consumes this reference has already had four design questions
answered, so those answers need a durable home before that change is written.

The research behind the document is done. This design records how it is organised, what
the canonical key for a species is, and which findings are asserted as fact versus flagged
for an in-game check.

## Goals / Non-Goals

**Goals:**

- One document that answers "what can grow here, from what, and how big" without reopening
  the game files.
- A stable key per species that later lua can use directly.
- Every claim traceable to the file it came from, so a 42.21 upgrade can be re-checked
  file by file rather than wholesale.
- A clear separation between what was read out of the files and what still needs an
  in-game check.

**Non-Goals:**

- A lua data table. The document is prose and tables for humans; the runtime table is part
  of the planting change and may key differently once the planting code exists.
- Completeness on erosion categories other than trees.
- Deciding the planting system's mechanics. The carried-forward decisions below are
  recorded, not designed.

## Decisions

### The document lives at `docs/reference/b42-tree-matrix.md`, not under `openspec/`

The repo has no `docs/` directory yet, so this introduces one. The alternative was
`openspec/changes/document-b42-tree-matrix/`, which was rejected because change directories
get archived when the change completes and this reference has to stay easy to find and easy
to edit as later builds shift values. `openspec/specs/` was rejected too: specs describe
what the mod must do, and this describes what the game already does.

`README.md` gets a one-line pointer, and a Serena memory points at the file so a future
session finds it from `mem:core` without a search.

### The erosion tileset name is the canonical species key

Each species is keyed by its base tileset, `e_virginiapine_1`, `e_redmaple_1` and so on.
That string is what `NatureTrees` stores, what `ErosionObj` resolves sprites through, and
what `IsoTree.dropWood` substring-matches against, so it is the one identifier that appears
in every layer.

Two alternatives were rejected. The `NatureTrees.trees` array index (0 to 10) is compact
but is an implementation detail that would silently repoint if the array is reordered in a
later build. The display name (`"Virginia Pine"`) is what `IsoObject:getName()` returns on
an erosion tree and is worth recording, but it is a presentation string and two of them,
`"Riverbirch"` and `"Redmaple"`, are not spaced the way the real species names are, so it
makes a poor key. Both are recorded as columns alongside the tileset name.

### Size stages are documented by the `tree` sprite property, not by feature name

The worldgen feature names (`pine`, `pine_jumbo`, `pine_jumbo_xl`, `pine_jumbo_xxl`,
`pine_sapling`) do not line up one to one with either the eight erosion stages or the eight
`IsoTree` sizes. The `tree` property on the sprite is what actually drives
`IsoTree.initTree`, so the document is organised around a single stage table:

| Stage | `tree` property | Tileset family | Footprint |
|---|---|---|---|
| 0 to 3 | 1 to 4 | `e_<species>_1` | 1x1 |
| 4 to 5 | 5 to 6 | `e_<species>JUMBO_1` | 2x2 |
| 6 | 7 | `e_<species>JUMBOXL_1` | 3x3 |
| 7 | 8 | `e_<species>JUMBOXXL_1` | 5x5 |

Feature names are recorded as a cross-reference column so the biome tables stay readable.

### Findings that need an in-game check are marked, not asserted

Most of the document is read straight out of the files and is stated flatly. Three findings
are inferences that the files support but do not prove, and each is marked as needing an
in-game check:

- ~~Only sprite indices 0 to 7 of a base tileset carry the `tree` property, but
  `NatureTrees` addresses indices up to 23 for the seasonal variants of a deciduous species,
  so `IsoTree.initTree` may fall back to `size = 4`.~~ Resolved during implementation and
  withdrawn: every tree is constructed with `noSeasonBase = true`, so the base sprite is
  always the season 0 one and always carries the property. Seasonal variants are
  `attachedAnimSprite` overlays that never reach `setSprite`, and the snow variant is a
  render-time swap on the shared sprite. No in-game check was needed.
- `IsoTree.dropWood` decides a pinecone drop by testing whether the sprite name contains
  `pine`, so Canadian Hemlock should never drop one despite being a conifer. The same test
  falls back to four sprite equality checks written as `vegetation_trees_01_08`, `_09`,
  `_010` and `_011`, while `newtiledefinitions.tiles.txt` declares those sprites as `_8`,
  `_9`, `_10` and `_11`, so none of the four can ever match. The mismatch itself is provable
  from the files and is stated flatly; what needs the in-game check is the consequence, that
  a legacy pine drops no cone at all.
- The authored Knox County map places only jumbo and larger tree features, and only
  `pine_sapling` is referenced by any biome at all (in `sand_bank`, which is a procedural
  biome and not on the authored map). The conclusion that no sapling-stage tree exists on
  the authored map until erosion respawns one follows from that, but has not been observed
  in a save.

Marking these keeps the document usable as a reference without overstating what reading
class files proves.

### Carried-forward decisions for the planting change

These were settled while researching this change and belong somewhere durable before the
planting proposal is written. They are recorded in the document's closing section as
constraints on the follow-up work, not as anything this change implements.

- The VHS unlock wraps `ISRadioInteractions`'s `checkPlayer` and grants the recipe when the
  line whose translation key is `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39` plays.
  `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]` is not mutated, which keeps the
  no-vanilla-mutation rule intact. Appending an `RCP=` code to that line's `codes` would
  have been the smaller change and would have reused vanilla's own once-per-player
  `isKnownMediaLine` guard, so the wrapper has to provide that guard itself.
- Maximum growable size is a mod configuration dropdown, not a constant. At least three
  options: stock erosion behaviour, player-planted trees may reach JUMBOXXL, and all growth
  may reach JUMBOXXL. The default is all growth may reach JUMBOXXL.
- Requiring the tape before planting is also a configuration option, defaulting to on.
- Species is stamped onto `Base.Pinecone`'s modData when a cone is harvested from a known
  tree. Cones from vanilla `dropWood` and from foraging stay untagged and fall back to a
  roll weighted by the forage zone they are planted in.
- Correcting which species drop a propagule is a committed feature behind its own setting,
  defaulting to on. It covers Canadian Hemlock, which is a conifer that vanilla never gives
  a cone; the four dead legacy sprite fallbacks; and the acorn, which no tree in the game
  can drop because `contains("oak")` matches no sprite name and the three working equality
  tests point at size 2 sprites whose log yield never reaches the block holding the acorn
  line. The setting exists because the fix changes a vanilla drop table that other mods and
  player expectations may depend on, so it has to be switchable off without disabling the
  rest of the mod.

  One question is deliberately left to that change: with no oak species in B42.20, an acorn
  drop has no correct target, so it must decide between leaving `Base.Acorn` foraging-only,
  attaching it to a deciduous species as a stand-in, or introducing propagule items for the
  eight deciduous species. That choice does not affect this documentation change.

  The hook point is `ISChopTreeAction:animEvent`, wrapped rather than replaced. Vanilla
  already tests `self.tree:getObjectIndex() == -1` there to detect that the tree has just
  toppled, so the wrapper can capture the sprite name before delegating and add the cone to
  the square after. No lua event fires on topple, and `toppleTree` and `dropWood` are
  Java-side with no lua entry point, so this is the only interception that does not require
  editing a vanilla file. The known gap is that trees felled by a vehicle or by fire do not
  route through the timed action and so will not be corrected; that is acceptable and is
  recorded rather than worked around.

  This is deliberately independent of the planting system. It needs the species table this
  change produces and nothing else, so it can ship first.

### Visual claims are checked against the Blender asset library

Some questions about a species cannot be answered by reading files, most obviously what a
tree actually looks like. Where a visual call is needed, the reference is
[Paddlefruit's Blender asset library](https://github.com/Paddlefruit/ProjectZomboid_BlenderAssets),
which mirrors the game's tree meshes and carries a rendered thumbnail per species.

This was not a hypothetical. American Holly is botanically an evergreen broadleaf, and the
document originally classified it that way and left it there. The model is a dense conical
evergreen with foliage to the ground and no visible trunk, and it reads as a conifer more
strongly than either of the two actual conifers do. Both the code flag and the art group it
with the conifers and only the botany separates it, which is a distinction no player can
make in game. The document now records all three axes rather than asserting one.

The repository states no license, so it is cited as something to look at and never as a
source of assets to reuse.

### Non-goal recorded, not designed: the rest of the tape's language

The tape describes potting and transplanting, bare-root stock only being plantable in
winter, soil saturation and root rot, clearing overshadowing growth, hole depth, spacing of
five to ten yards, planting away from structures, using local species as a guide, marking
trees, and protecting them from animals. Every one of those is a plausible future mechanic
and none is in scope. The document lists them in a flagged section so the planting change
can decide which to honour, quoting the line each came from.

## Risks / Trade-offs

- The document goes stale when the game updates, and nothing enforces a re-check.
  Mitigation: every claim carries the file it came from and the build it was read on
  (`42.20.4 b0bbce05d5`), so a re-check is mechanical rather than a fresh investigation.
- The decompiled findings come from CFR output, which can misread control flow. Mitigation:
  the values used are field initialisers and constant arrays, which decompile reliably, and
  the three inferences that depend on control flow are marked as needing an in-game check.
- Introducing `docs/` sets a precedent for where reference material lives, and if later
  work puts findings in Serena memories instead the two will drift. Mitigation: the memory
  added by this change is a pointer at the document, not a copy of it.
- Recording the planting decisions here means they are stated twice once the planting
  proposal exists. Mitigation: that proposal should reference this section rather than
  restate it, and this section is explicitly labelled as carried-forward context.

## Migration Plan

Not applicable. No file under `42.20/` changes, so there is nothing to load, roll back or
verify in game for this change beyond confirming the mod still boots unchanged.
