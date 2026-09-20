# Tasks

Every task below was implemented. The unchecked ones were bundled with an in-game check that
was never run, so unchecked here means written but unwatched rather than unwritten. What is
unwatched is listed in `docs/future/carried-forward.md`.

## 1. Record the evidence

- [x] 1.1 Add the map census to `docs/reference/b42-tree-matrix.md` as a new section: the
  method, the per zone slot table, the realisation factor, and the clumping result that
  refuses to support a minimum spacing. Verify by checking the section resolves the trunk
  census that `docs/future/vegetation-succession.md` says is missing.
- [x] 1.2 Add to `docs/reference/b42-lua-notes.md` that `metazoneHandler.doMapZones` skips
  `Vegitation`, `DeepForest`, `Forest`, `TownZone`, `Farm`, `FarmLand` and `TrailerPark` from
  `objects.lua`, so every forage zone the mod reads comes from the biome map. Verify by
  grepping the installed `metazoneHandler.lua` for the skip list quoted in the note.
- [x] 1.3 Correct `docs/future/vegetation-succession.md` where the census contradicts it: the
  density ordering is now measured, plain `Forest` is lake and clay shore rather than an
  undocumented forest, Deep Forest has no procedural branch on this map, and `Vegitation` and
  `PHMixForest` exist by neither route. Verify by rereading the document for any remaining
  claim the census disproves.
- [x] 1.4 Add to `docs/reference/b42-lua-notes.md` that `ErosionObj` is the shared object
  wrapper behind all four nature categories and carries the matched `name`, so the rename that
  releases a tree square releases a grass or bush square too. Verify by confirming the note
  names the class and the `clearCatModData` consequence.

## 2. Measure before building

- [x] 2.1 Add a succession pass skeleton in a new
  `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua` that subscribes to
  `LoadGridsquare`, runs the intended early exit ordering and places nothing. Verify by
  reading the "succession loaded" print in the console at startup. Closed on 2026-09-17: the console prints "succession loaded" at startup.
- [x] 2.2 Add a timed measurement to that pass and a debug menu entry in
  `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua` that reports squares seen
  and microseconds a square. Verify in game by driving through unexplored ground and reading a
  per square cost of the same order as the boundary layer's 0.15 microseconds. Closed on 2026-09-17: 0.91 microseconds a square net of the timer on ground where nothing has aged into a rung, and 2.77 over a sample that placed an object on 1184 of 1216 squares. The timer itself measures 0.100, so the figures are the work and not the instrument. Against a frame that is about 6000 squares, which a chunk burst does not reach.
- [ ] 2.3 Measure the hourly tick against a large bin, using the same debug menu, and record
  the object count at which the tick becomes visible. Verify by reporting a figure for a bin
  of at least 10000 objects, which closes the risk carried forward from
  `add-erosion-boundary-layer`.

## 3. Ownership and the understory layer

- [x] 3.1 Add an understory module,
  `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`, holding the sprite sets for
  grass, groundcover, ferns and bushes and the mod name every placed object carries. Verify by
  a debug menu entry that places one of each on the square in front of the player. Closed on 2026-09-17: the startup line reads "understory holds 44 sprites", so all six grass, twenty two cover and sixteen bush sprites resolve, and the debug entry placed grass and a bush on demand.
- [x] 3.2 Implement placement and replacement in
  `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`: place the object, rename it,
  and recognise the mod's own name so re-evaluating a square replaces rather than stacks.
  Verify in game by loading and unloading a recovering area several times and confirming each
  square still holds exactly one object. Closed on 2026-09-17: after a save and reload of a recovered area the unchanged count rose to 15557 against 14292 placements, so revisited squares are recognised and not placed on a second time.
- [ ] 3.3 Confirm the rename releases a non tree square from erosion. Verify in game by
  placing a mod owned bush on a square erosion had assigned to grass, letting several in-game
  weeks pass, and confirming erosion has not put its own object back.

## 4. The clearing record

- [x] 4.1 Write the clearing time into the square's mod data when a tree the mod owns is
  chopped, from `42.20/media/lua/server/EeltsForestryRemastered_TreeDrops.lua`. Verify in game
  by chopping a tree and reading the stamped value from a debug menu entry. Closed on 2026-09-17: felling stamped 5618,5291 with a clearing time of 26.568 world age hours and the pickaxed stump left the square eligible.
- [x] 4.1a Record scything as a clearing too, by wrapping `ISScything.getGrass` from
  `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`. Without it a scythed square
  falls back to the world clock, reads as bare for years and puts its grass straight back.
  Verify in game by scything and reading the stamped value. Closed on 2026-09-17: 7327,5940
  reported cleared=24.538 against a world age of 24.7 hours, with no other growth left on it.
- [x] 4.2 Read the record in the succession pass, falling back to the world's age when a
  square has none, in
  `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`. Verify in game by comparing
  a freshly cut square against an untouched field and confirming the field is further along. Closed on 2026-09-17: 5648,5283 reported cleared=nil and elapsed=32.02 days against a world age of 32.02, so an unrecorded square falls back to the world clock.
- [ ] 4.3 Reset the record when an already recovered square is cleared again. Verify in game by
  clearing a recovered square and confirming it returns to bare ground and recovers from there.
- [ ] 4.4 Confirm the record survives saving. Verify in game by clearing an area, saving and
  reloading before anything is visible, and confirming recovery continues from the original
  time.

## 5. The ladder

- [x] 5.1 Implement the stage function in
  `42.20/media/lua/shared/EeltsForestryRemastered_Understory.lua`: rung from position noise,
  elapsed time and local density, with the rung days as constants, defaulting to grass at 3,
  groundcover and ferns at 10, bushes at 21 and trees at 30 plus a per square offset reaching
  about 90. Verify with a debug menu entry that prints the rung a chosen square would be on at
  a range of elapsed times. Closed on 2026-09-17: 5648,5283 reported eagerness 0.274 with grass 4.6, cover 15.5, bush 32.5 and tree 46.4, and read as the cover rung at 32 days. The streamlined form was proved equivalent to the first against 2500 squares at days 30, 50 and 90.
- [ ] 5.1a Add the recovery pace multiplier to `42.20/media/sandbox-options.txt` and
  `42.20/media/lua/shared/Translate/EN/Sandbox.json`, scaling every rung together. Verify in
  game by halving it and confirming the first saplings arrive at about half the day they did
  at the default.
- [ ] 5.1b Confirm the default tree rung lands in the same window vanilla's own wild trees do.
  Verify in a fresh world by clearing ground on day 1 and confirming the first saplings appear
  around day 30 and the slowest squares by about day 90.
- [ ] 5.2 Drive the loaded case from the hourly tick in
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, so a watched square
  crosses a rung boundary without being unloaded. Verify in game by standing in a recovering
  area across a boundary and seeing it change.
- [ ] 5.3 Confirm elapsed time rather than loaded time drives it. Verify in game by clearing
  two equal areas, watching one and leaving the other unloaded for the same elapsed time, and
  confirming both are at the same rung.

## 6. Eligibility, species and parents

- [ ] 6.1 Share `isPlantableSquare` from
  `42.20/media/lua/shared/EeltsForestryRemastered_Planting.lua` as the eligibility test, with
  no behaviour change to planting. Verify in game by confirming a road, a building floor, a
  water square and a farmed plot all stay bare while the ground around them recovers.
- [ ] 6.1a Confirm the ladder climbs through that test, since a square the mod has already put
  grass on must stay eligible for a bush and then a tree. Verify in game by placing mod owned
  grass and then a bush on one square from the debug menu and confirming the square still
  reports as eligible at each step.
- [x] 6.2 Add the local species bias to
  `42.20/media/lua/shared/EeltsForestryRemastered_Propagules.lua`, bounded so a species with no
  zone weight cannot establish from a neighbour alone. Verify in game with a debug menu entry
  that prints the biased weights for the player's square. Closed on 2026-09-17: Riverbirch in Birch Mixed Forest read 0.560 from a base of 0.400 with two wild neighbours, and the three species with no neighbours were unchanged.
- [ ] 6.3 Add the plain `Forest` species pool, the Organic Forest mixture, to
  `EeltsForestryRemastered_Propagules.lua`. Verify by confirming a shoreline square now returns
  weights where it previously returned none.
- [ ] 6.4 Choose a parent of the rolled species from nearby eligible trees, leaving the slot
  unused beyond the choice. Verify with a debug menu entry that names the parent chosen for a
  given square, or reports that none was eligible.
- [ ] 6.5 Add the three value player planted parent setting to
  `42.20/media/sandbox-options.txt` and `42.20/media/lua/shared/Translate/EN/Sandbox.json`, and
  honour it in the bias. Verify in game by planting a foreign species beside recovering ground
  and confirming each of the three settings behaves as the spec describes.

## 7. Crowding

- [x] 7.1 Add the per zone ceiling table and the neighbourhood count to
  `42.20/media/lua/shared/EeltsForestryRemastered_Propagules.lua`, ordered by the census and
  scaled by the realisation factor, with a sandbox multiplier in
  `42.20/media/sandbox-options.txt` and `Translate/EN/Sandbox.json`. Verify with a debug menu
  entry that reports the ceiling and the current count for the player's square. Closed on 2026-09-17: the entry reported density 53.889 and a limit of 4 trees against a crowd of 0 for a Birch Mixed Forest square.
- [ ] 7.2 Give plain `Forest` its own near zero ceiling rather than Organic Forest's. Verify in
  game by confirming a cleared shoreline grows back understory and almost no trees.
- [ ] 7.3 Confirm the ceiling never thins. Verify in game by finding a stand denser than its
  ceiling and confirming no tree is removed from it after several in-game months.
- [ ] 7.4 Confirm planting is unaffected. Verify in game by planting trees closer together than
  the ceiling allows and confirming every one is planted and grows.

## 8. Tree establishment

- [ ] 8.1 Add `adoptEstablishedTree` to
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, creating the tree at
  stage 0 with `planted` false and adopting it as it is created. Verify in game by forcing an
  establishment from the debug menu and confirming the new tree grows under the all trees
  setting.
- [x] 8.2 Roll establishment from the succession pass on squares that have reached the tree
  rung and are under their ceiling. Verify in game by clearing an area, advancing time, and
  confirming trees appear on it. Closed on 2026-09-17: a fresh world cleared in early May had 1579 trees established by 30 June, and the cleared ground shows saplings scattered through it.
- [ ] 8.3 Confirm an established tree is wild. Verify in game by setting growth to player
  planted only and confirming established trees do not grow while planted ones do.
- [ ] 8.4 Confirm establishment still happens under the base game's growth choice, with the
  new tree staying at stage 0. Verify in game with that setting and several in-game months.
- [ ] 8.5 Confirm no species appears outside its zone's pool. Verify in game with the existing
  survey tool over a recovered area in at least three different forage zones.

## 9. The succession setting

- [ ] 9.1 Add the succession setting and the recorded squares only setting to
  `42.20/media/sandbox-options.txt` and `42.20/media/lua/shared/Translate/EN/Sandbox.json`,
  with the succession tooltip stating that an unmodded world now needs all three settings off
  and that turning it off stops further recovery rather than undoing it. Verify by reading both
  entries in the sandbox screen.
- [ ] 9.2 Honour both settings in
  `42.20/media/lua/server/EeltsForestryRemastered_Succession.lua`. Verify in game by running a
  world with succession off and confirming cleared ground stays bare, then turning it on
  partway and confirming recovery starts.
- [ ] 9.3 Confirm turning succession off partway leaves placed vegetation alone. Verify in game
  by recovering an area, turning the setting off and confirming nothing is removed and nothing
  further appears.

## 10. Whole system verification

- [x] 10.1 Clear a measured area and follow it through the whole ladder, confirming grass, then
  groundcover and ferns, then bushes, then trees, in order and with none skipped. Closed on 2026-09-17: a clear cut watched from 9 May to 30 June carried grass, tall grass and ferns, bushes and fresh saplings, in that order, with 57871 understory objects placed and 1579 trees established.
- [ ] 10.2 Confirm the ceiling is reached and recovery stops, in all four of Deep Forest,
  Organic Forest, Primary Forest and plain Forest, and confirm the resulting order matches the
  census table rather than the ordering the scoping document guessed.
- [ ] 10.3 Watch a clear cut boundary that runs through the middle of a chunk and confirm the
  standing half is unaffected, which is the case the per square clearing record was chosen for.
- [ ] 10.4 Measure chunk load cost again with the understory layer active over a large
  recovering area, not just with the pass skeleton, and compare against the figure from 2.2.
- [x] 10.5 Confirm a recovering area looks the same after unloading, saving and reloading, with
  nothing stacked and nothing duplicated. Closed on 2026-09-17: the same reload, with the area looking as it did before it and nothing doubled on any square.
- [ ] 10.6 Run the whole feature on a dedicated server, including a late joining client, and
  confirm both players see the same vegetation on the same squares. Record the result whether
  or not it passes, since both existing features are server side and have never run on one.
- [ ] 10.7 Check succession against a raised erosion speed, a positive erosion days setting, a
  negative one, and a world with erosion switched off.
- [ ] 10.8 Confirm street, wall and flowerbed erosion still run normally inside a recovering
  area.

## 11. Close out

- [x] 11.1 Move whatever remains unverified into `docs/future/carried-forward.md` under a
  heading for this change, in the same form the two existing sections use. Verify by
  confirming every task above is either done or named there. Closed on 2026-09-17: every task left open above is named under "From add-vegetation-succession" there, grouped by what it would take to close.
- [x] 11.2 Update `docs/future/vegetation-succession.md` to say what shipped and what did not,
  the way `tree-management-and-genetics.md` was updated after the boundary layer. Verify by
  confirming the document no longer describes shipped behaviour as future work. Closed on 2026-09-17: the document now opens with what shipped and what did not, and points at the spec and at carried-forward.
