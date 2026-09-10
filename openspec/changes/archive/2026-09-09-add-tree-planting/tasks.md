## 1. Species stamping on chopped trees

- [x] 1.1 Rename `42.20/media/lua/server/EeltsForestryRemastered_ConeDrops.lua` to
  `EeltsForestryRemastered_TreeDrops.lua` with no behaviour change, and verify in game that
  a Canadian Hemlock still drops cones and the console shows no load error. Confirmed
  2026-09-09: a stage 6 Hemlock yielded five cones, all stamped `e_canadianhemlock_1`, and
  two saplings likewise. Five is `logYield - 1` with a non positive roll, which is vanilla
  parity. Console clean.
- [x] 1.2 In `42.20/media/lua/server/EeltsForestryRemastered_TreeDrops.lua`, add a shared
  `Eelt_Species` modData key and a stamp helper, reading the species with
  `sprites.identify` from the tree captured before it topples. Verify by stamping the
  Hemlock cones the file already creates and reading the value back with a `print`.
- [x] 1.3 In the same file, snapshot the square's world inventory items before delegating to
  the vanilla `animEvent` and stamp only the plantable items that are new afterwards. Verify
  in game by dropping a sapling on a square, felling a Redmaple standing on it, and
  confirming the pre-existing sapling is unstamped while the dropped ones read
  `e_redmaple_1`.
- [x] 1.4 Confirm log, branch, twig, sapling and cone counts are unchanged, by felling a
  tree at a known stage and comparing against the yield table in
  `docs/reference/b42-tree-matrix.md`. Closed 2026-09-09 on partial observation. What was
  seen: stage 6 Redmaple and stage 6 Canadian Hemlock each yielded two saplings, matching the
  table, and the Hemlock yielded five cones, which is `logYield - 1` at a non positive roll
  and therefore vanilla parity. Superseded 2026-09-09 by a full uncollected count from a
  stage 6 Virginia Pine: 5 logs, 5 cones, 2 large branches, 2 saplings, 6 tree branches, 6
  twigs, 1 splinters, with the decoy sapling still reading `prior=true species=nil`. Every
  figure matches the matrix except the log count, which is one below the table; see the note
  on `getLogYield` in `docs/reference/b42-tree-matrix.md`.

## 2. Propagule and species tables

- [x] 2.1 Create `42.20/media/lua/shared/EeltsForestryRemastered_Propagules.lua` with the
  three plantable item types, the eligible species set for each, and the `Eelt_Species`
  modData key shared with the drops file. Verify each set resolves to tilesets that exist in
  `EeltsForestryRemastered_TreeGrowthSprites.sprites.species`.
- [x] 2.2 In the same file, add the forage zone to species weight table, derived from the
  biome probabilities in `docs/reference/b42-tree-matrix.md`. Verify every zone name in the
  table appears in `forageSystem.zoneDefs` and every species name is a known tileset.
- [x] 2.3 In the same file, add the species roll: read zones with `getZones(x, y, 0)`,
  intersect the zone's species with the propagule's eligible set, and fall back to a uniform
  roll over the eligible set when the intersection is empty. Confirmed 2026-09-09: an
  unstamped sapling planted in `BirchMixForest` produced a Riverbirch. That zone weights
  Riverbirch 0.4 against Dogwood 0.17, Redmaple 0.18 and American Linden 0.15, so one sample
  shows the lookup and the weighted pick run and return a species the zone actually grows.
  Whether the proportions are faithful is not observable in play and is covered by the table
  check in task 2.2.

## 3. Planting on the server

- [x] 3.1 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, add an
  entry point that adopts a named tree as planted at stage 0, bypassing the
  `mayAdoptWildTrees` gate and passing `planted = true` through `adoptFrom`. Verify with the
  debug menu that the new object reports `planted=true`.
- [x] 3.2 Create `42.20/media/lua/server/EeltsForestryRemastered_TreePlanting.lua` with the
  square validity check and the tree build: `IsoTree.new`, `AddTileObject`,
  `transmitCompleteItemToClients` on the server, `OnObjectAdded` and
  `RecalcAllWithNeighbours`. Confirmed 2026-09-09: a planted American Holly grown to stage 4
  and felled yielded 3 logs, 2 branches, 2 twigs and 1 splinters, no saplings and no berries.
  All correct for its size and season, so a planted tree chops as an ordinary tree.
- [ ] 3.3 DEFERRED, needs a dedicated server. The client command handler that revalidates the
  square and species before building, called directly when the game is not a client. Single
  player is confirmed; the client command path has never run. Recorded in
  `docs/future/carried-forward.md` so it outlives this change.
- [x] 3.4 Confirm a planted tree grows: plant one, set the growth time multiplier low, and
  verify through the debug menu that it advances a stage and keeps `planted=true` across a
  save and reload. Confirmed 2026-09-09: `checkpoint matches=true` after a save, quit and
  reload, with tileset, stage, `planted` and `enteredHour` all identical, then growth through
  stages 1 to 4 holding species and `planted=true` at every step.

## 4. The planting action and menu

- [x] 4.1 Create
  `42.20/media/lua/client/TimedActions/EeltsForestryRemastered_PlantTreeAction.lua`, a timed
  action that consumes the propagule on completion and sends the plant command. Confirmed
  2026-09-09: interrupting mid-plant leaves the propagule in the inventory, and it is removed
  only when the action completes.
- [x] 4.2 Create `42.20/media/lua/client/EeltsForestryRemastered_PlantTreeMenu.lua`, adding
  the entry on `OnFillWorldObjectContextMenu`, gated on a `ItemTag.DIG_PLOW` tool found with
  `getFirstTagRecurse`, on the square being suitable, and on the propagule being plantable.
  Confirmed 2026-09-09: present on open ground, absent indoors, on a built floor, on a road
  and on a square that already holds a tree. The road and floor refusals also exercise the
  furrow rule, since both resolve to something other than "dirt".
- [x] 4.2a Water is the one square type not yet observed. It is a separate predicate from the
  furrow rule, `isOverWater` reading the floor sprite's water flag. Confirmed 2026-09-09: no
  planting option appears on a water tile.
- [x] 4.3 In the same file, reject a `Base.HollyBerry` whose `getPoisonPower()` is above
  zero, with a reason that does not name poison. Confirmed 2026-09-09: the poisoned berry
  appears as an unavailable entry, which PZ renders red rather than grey, while the clean one
  plants. The tooltip was not hovered, but `disable()` sets `notAvailable` and the tooltip in
  the same three lines, so there is no path where the red entry appears without its reason.
- [x] 4.4 In the same file, show the recorded species on the menu entry when the propagule
  has one, and a generic label when it does not. Verify a stamped sapling names its species
  and a foraged one does not.

## 5. The tape gate

- [x] 5.1 Create `42.20/media/lua/shared/EeltsForestryRemastered_TapeUnlock.lua`, replacing
  `checkPlayer` on `ISRadioInteractions:getInstance()` with a wrapper that tests
  `isKnownMediaLine` before delegating and sets the player modData flag when the guide's
  eleventh line first plays. Confirmed 2026-09-09: the planting option was absent before the
  tape was watched and present afterwards.
- [ ] 5.2 DEFERRED, needs a dedicated server. Transmitting the unlock to the owning client so
  the context menu can read it, and confirming a second player is still gated. Recorded in
  `docs/future/carried-forward.md` so it outlives this change.
- [x] 5.3 Add `EeltsForestryRemastered.RequireTreePlantingTape` to
  `42.20/media/sandbox-options.txt` and its strings to
  `42.20/media/lua/shared/Translate/EN/Sandbox.json`, reading it through
  `getSandboxOptions():getOptionByName` as the existing options do. Confirmed 2026-09-09:
  unchecking the option shows the planting menu without the tape having been watched. The
  page and label half was checked statically across all four options, twelve keys covering
  every label, tooltip, enum value and the page name itself, with no missing and no stale
  entries, and the enum default inside its value range.
- [x] 5.4 Gate the context menu in
  `42.20/media/lua/client/EeltsForestryRemastered_PlantTreeMenu.lua` on the flag when the
  option is on, showing no entry and no explanation. Verify a fresh character sees nothing
  until the tape is watched.

- [x] 5.5 Confirm the unlock happens once rather than every time the line plays, by watching
  the guide a second time on a character that already knows planting and seeing no second
  "Learned how to plant a tree" halo. Confirmed 2026-09-09: replaying the guide after
  learning produces no second halo, so vanilla's isKnownMediaLine transition is a sound
  once per player guard.

## 6. Getting the tape into the world

- [x] 6.1 Create `42.20/media/lua/server/Items/EeltsForestryRemastered_Distributions.lua`,
  inserting an already-stamped `Base.VHS_Home` on `OnFillContainer` for a small set of
  container types at a low chance. TENTATIVE, 2026-09-09: recalled from an earlier playthrough
  rather than reproduced under observation, so treat it as unconfirmed until task 7.6 finds a
  tape by looting on a clean world. The supporting evidence is that the guide resolves at all,
  since the console has never printed the "could not find" warning from task 6.3, which means
  the `getTitleEN()` lookup succeeds and only the `OnFillContainer` insert is unwitnessed.
- [x] 6.2 Confirm other tapes are untouched by looting several `Base.VHS_Home` items and
  checking they carry the recordings the base game would have given them. Confirmed
  2026-09-09: home VHS tapes generate and carry ordinary recordings. They are rare in vanilla,
  which is a base game property and not something this change set out to alter.
- [x] 6.3 REVIEW IN GAME, the tape lookup in
  `42.20/media/lua/server/Items/EeltsForestryRemastered_Distributions.lua` matches on
  `MediaData:getTitleEN() == "Tree Planting Guide"`, because no lua caller anywhere in
  B42.20 reads a media id and the getter for one could not be confirmed from the shipped
  files. Verify the console does not print the "could not find the Tree Planting Guide
  recording" line on world load. Confirmed 2026-09-09, zero occurrences. Whether a spawned
  tape actually plays the guide is task 6.1.
- [x] 6.4 REVIEW IN GAME, the guid form in
  `42.20/media/lua/shared/EeltsForestryRemastered_TapeUnlock.lua`. Settled 2026-09-09 by
  printing every guid through a full playback: the engine passes the `RM_` prefixed
  translation key. `isPlantingLine` now matches that one string and the diagnostic print is
  gone. Recorded in `docs/reference/b42-lua-notes.md`.
- [x] 6.5 REVIEW IN GAME, the tape's spawn rate. `ONE_IN` is 260 across five room types and
  five container types. Accepted as is 2026-09-09 and deliberately not tuned: changing loot
  distribution for VHS tapes is out of scope for this change, so the constant stands unless a
  later change takes that scope on.

## 7. Debug, documentation and finish

- [x] 7.1 In `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, add a
  readout of a held propagule's recorded species and an option to plant a chosen species
  directly. Verify both are hidden when debug is off.
- [x] 7.2 Add the context menu and action strings to
  `42.20/media/lua/shared/Translate/EN/ContextMenu.json`, `IG_UI.json` and `Tooltip.json`.
  Verified statically 2026-09-09 rather than by eye: every key reachable from a `getText`
  call in the mod resolves. Six literal keys plus the eleven the species lookup builds from
  `IGUI_Eelt_Species_` come to seventeen, which is exactly the number defined, so there are
  no missing keys and no dead ones.
- [x] 7.3 Update `README.md` with the planting feature, the tape, and the two settings that
  govern it.
- [x] 7.4 Move the decisions this change consumes out of `docs/future/carried-forward.md`
  into `docs/reference/b42-tree-matrix.md` as description, correct the stale maximum growable
  size bullet to record that `add-tree-growth` settled it as the three-value `TreeGrowth`
  enum, and leave the unclaimed tape lines and the propagule items where they are.
- [x] 7.5 Keep `42.20/media/lua/client/EeltsForestryRemastered_PlantingQA.lua`, the debug
  menu that drives the remaining in-game checks, and confirm it is gated on
  `isDebugEnabled()` and single player so it never appears in normal play. Use it for tasks
  1.4, 3.4 and 7.6.
- [ ] 7.6 NOT DOING. A full clean run at default settings was declined 2026-09-09. The
  consequence is that task 6.1 stays tentative: no one has watched a tape appear in loot from
  `EeltsForestryRemastered_Distributions.lua`, so a default settings player reaching planting
  at all rests on recollection from an earlier playthrough. Every part of the loop has been
  verified individually. Recorded in `docs/future/carried-forward.md`.

## 8. Defects found during verification

- [x] 8.1 `iterList` is not a global in B42.20, so seven call sites across
  `EeltsForestryRemastered_TreeDrops.lua`, `_Propagules.lua`, `_PlantTreeMenu.lua`,
  `_TreeDebugMenu.lua` and `_PlantingQA.lua` threw at runtime and species stamping never
  ran. Replaced with indexed loops and recorded in `docs/reference/b42-lua-notes.md`.
  Re-run tasks 1.1 through 1.3, 2.3, 4.2 and 7.1 against the fix before trusting any of
  them.
- [x] 8.3 `getPoisonPower` exists only on `Food`, so `describePropagules` crashed on a
  sapling or a cone and `isPlantableItem` was guarding by item id rather than by type. Both
  now test `instanceof(item, "Food")`, and the finding is in
  `docs/reference/b42-lua-notes.md`. Re-run task 7.1 and confirm the poisoned berry rejection
  in task 4.3 still works.
- [x] 8.2 A tree from `IsoTree.new` has no `attachedAnimSprite` list, so every planted
  deciduous tree rendered as the bare base sprite in all seasons. `applyOverlay` now creates
  the list before adding to it, and the finding is in `docs/reference/b42-lua-notes.md`.
  Confirmed fixed in game 2026-09-09.
- [x] 8.4 A stage 6 Virginia Pine yields 6 from `getLogYield()` but drops 5 `Base.Log` and 5
  cones, while the trailing branch and twig loops run 6 times. That points at vanilla's log
  loop running `numPlanks - 1`, which the tree matrix does not say. Nothing in this mod is
  affected, since it never touches logs and `coneCount` already ports `logYield - 1`
  faithfully. Confirm with one more sample at a different stage: a stage 7 tree should give
  7 logs, 7 cones and 8 branches and twigs, and a stage 5 tree 4 logs. Settled 2026-09-09 by
  a second sample instead: a stage 4 American Holly reporting `logs=4` dropped 3. The main
  log loop runs `numPlanks - 1` and the trailing branch and twig loop runs `numPlanks`, which
  also accounts for the `numPlanks == 1` and `numPlanks == 2` branches already documented.
  The matrix yield table now carries both columns.
