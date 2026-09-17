## 1. Measure the event before building on it

- [x] 1.1 Add a temporary `LoadGridsquare` handler in
  `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua` that does nothing but
  count squares and accumulate elapsed time, printing a summary every ten thousand squares
  with the "Eelt's Forestry Remastered:" prefix. Verify by walking and driving through
  unexplored forest and reading the counts in the console.
- [x] 1.2 Extend the temporary handler with the first two early-exit layers, the tree
  presence test and the `ADOPTED_NAME` test, and record the cost separately for first visits
  and revisits. Verify the revisit figure is measurably lower than the first-visit one. Closed
  on 2026-09-12: with correction live the pass reported 5388 squares taking the settled exit
  against 2092 corrections, so the layer 2 path is exercised, and the measured costs put a
  settled tree square at 0.16 microseconds against 2.29 for a first visit.
- [x] 1.3 Measure the third layer in isolation by running `getZones` and the sprite identify
  on every tree square without writing anything. Verify by comparing the per-square figure
  against 1.2 to see what the zone lookup actually costs.
- [x] 1.4 Record the three figures in the change's design notes and decide, against them,
  whether the zone weight cache and the deferred queue from design.md are needed. Verify by
  writing the decision and the numbers down before any of the following tasks start.

## 2. Split the species selection

- [x] 2.1 In `42.20/media/lua/shared/EeltsForestryRemastered_Propagules.lua`, promote the
  local `zoneSpeciesAt` to a public zone weight lookup and extract the weighted draw out of
  `rollSpecies` into a roll that takes a weight table and an optional eligibility list.
  Verify by reading `rollSpecies` back and confirming it is now built from the two.
- [x] 2.2 Rebuild `rollSpecies` on those two so that its item filtering and its uniform
  fallback for an unmatched zone are unchanged. Verified by exhaustive comparison of the old
  and new implementations rather than by spot planting: 364182 cases covering all twelve zone
  mixtures plus the no-zone case, all three propagule types, every reachable roll value and
  every uniform fallback outcome, with no mismatch. That proves the behaviour unchanged more
  completely than three in-game plants would.

## 3. Build the correction pass

Depends on task 4.1, which supplies the adoption entry point the correction calls.

- [x] 3.1 In `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua`, replace
  the temporary handler with the real one: the layered early exit from design.md, then the
  bin lookup, the zone weight lookup, the roll and the correction. Leave the square untouched
  when the zone has no recorded weights. Verify with a debug print naming the square, the old
  species and the new one.
- [x] 3.2 Do not add the zone weight cache or the deferred queue; task 1.4 measured the pass
  at 0.15 microseconds per square and neither is warranted. Verify by re-running the spike's
  report against the real handler and confirming the per-square figure has not moved.
- [x] 3.3 Add the file to the mod's load path alongside the other server files and confirm it
  is server-only. Nothing to register, since the game loads everything under `media/lua/server`
  and the file opens with the same `isClient` guard the growth system uses. Verify by starting
  the game and seeing no client-side error and no missing global in the console.
- [x] 3.4 Watch for trouble from correcting inside chunk loading, since the handler runs while
  the chunk is still being built. No trouble seen on 2026-09-12 over roughly 650000 squares and
  more than 20000 corrections across four biomes, with no error from the mod in the log. The
  drained queue stays designed but unused.

## 4. Adopt at any stage and decouple seasons

- [x] 4.1 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`, add a
  second adoption entry point that takes a target tileset and stage explicitly and applies no
  stage ceiling, leaving `adoptTree` and its ceiling alone for the proximity scan. Verify by
  correcting a full-grown tree and confirming it gains a lua object.
- [x] 4.2 In the same file, remove the stock-mode early return from `everyHour`. Verify by
  reading `mayGrow` and `mayAdoptWildTrees` back to confirm both still gate correctly, then
  in game by setting growth to the base game's behaviour and confirming corrected trees
  change with the seasons and no tree changes size.
- [x] 4.3a Move the `overlaySeason` write in `refreshOverlay` to after the reachability
  check, so a tree whose chunk is unloaded is not recorded as having changed season without
  its sprite changing. Pre-existing, but correction owns trees far outside any loaded chunk
  and turns it from rare into routine. Verify by refreshing overlays with a corrected area
  unloaded, then returning to it and confirming the foliage matches the season.
- [x] 4.3 In `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua`, let
  `displaySeason` and `refreshOverlay` take the season name and season progress as arguments,
  and compute them once per tick in `updateAdoptedTrees` in the growth system. Leave the two
  autumn window formulas and the coordinate stagger exactly as they are, including the
  endpoints, since the genetics work is specified to map through them unchanged. Verify by
  checking the debug menu's season readout reports the same stagger, turn and fall values it
  did before.
- [x] 4.4 Identify which sheet position carries the base game's early-July colouring. It is
  position 4, reached through the display split rather than through the season name.
  `b42-tree-matrix.md`, "The July problem", records that `seasonDisp[2]` splits summer with
  `season2 = 3`, so past summer's midpoint, staggered per square, a tree moves to position 4
  while the season still reads Early Summer. Summer runs about 13 May to 21 August, so tinting
  starts around 2 July. My earlier reading of this task, that position 4 was unused art, was
  wrong and is retracted.
- [x] 4.5 Add `Late Summer` at overlay position 4 to `SEASON_POSITION` in
  `42.20/media/lua/shared/EeltsForestryRemastered_TreeGrowthSprites.lua`, leaving the three
  existing entries alone. Verify by asking `getOverlay` for it on every species and stage and
  confirming none returns nothing.
- [x] 4.6 In `EeltsForestryRemastered_TreeGrowthObject.lua`, add the base game's seasonal rule
  alongside the mod's. Built, and confirmed in game to diverge from the mod's rule inside
  autumn, but incomplete: see 4.6a.
- [x] 4.6a Make the plain rule actually reproduce the base game. Both midpoints are in, split
  at `0.45 + stagger * 0.1` for summer and for autumn, so the plain rule tints from the middle
  of summer and goes bare from the middle of autumn while the mod's rule stays green through
  summer, colours through the middle of autumn and drops late. Checked across every season and
  the whole stagger range; the two agree in spring and winter and differ everywhere it matters.
- [x] 4.7 Confirm every species has artwork at stage 7 by asking
  `EeltsForestryRemastered_TreeGrowthSprites.getBase` for each tileset at that stage. Verify
  by printing any tileset that returns nothing; the list should be empty.

## 5. The settings

- [x] 5.1 Add the correction setting to `42.20/media/sandbox-options.txt`, defaulting to on,
  following the form of the existing `FixConiferConeDrops` entry. Verify it appears in the
  sandbox options screen.
- [x] 5.2 Add its label and tooltip to `42.20/media/lua/shared/Translate/EN/Sandbox.json`,
  saying plainly that turning it off stops further correction and does not undo what is
  already corrected, and that a corrected tree is off the base game's erosion so it no longer
  grows on its own under the base game's growth setting. Verify by reading the text in the
  sandbox options screen rather than the raw key.
- [x] 5.3 Gate the pass on the setting in
  `42.20/media/lua/server/EeltsForestryRemastered_ErosionBoundary.lua`. Verify by starting a
  world with it off, walking into unexplored forest and confirming no tree is corrected and
  nothing is printed.
- [x] 5.4 Add the seasonal rule setting to `42.20/media/sandbox-options.txt`, defaulting to
  on, with its label and tooltip in `Translate/EN/Sandbox.json` saying that off shows trees
  as the base game would and that the mod still maintains them either way. Verify by reading
  it in the sandbox options screen.
- [x] 5.5 Select the seasonal rule from that setting in
  `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua`, reading the option
  once per hourly tick rather than per tree. Verify in game by turning it off mid-autumn and
  confirming the trees in view change on the next hour.

## 6. In-game verification

- [x] 6.1 Walk into unexplored Acidic Forest and confirm every tree is Virginia Pine, which
  is the pool that zone has exactly one entry for and the clearest signal the pass is working.
  Surveyed 2026-09-12 at 6217,5922: 443 PHForest squares carrying 443 Virginia Pine, and the
  31 squares of the survey that fell in OrganicForest carried 31 Organic species. Exact.
- [x] 6.2 Load a large area of a mixed zone and count species across it, confirming the
  proportions roughly follow that zone's weights rather than erosion's. Surveyed 2026-09-12.
  Organic Forest, 747 in-pool trees, observed 34.4/33.3/32.3 against an expected 35/35/30.
  Birch Mixed, 358 in-pool trees, observed 43.6/22.3/18.2/15.9 against an expected
  44.4/20/16.7/18.9. No tree in any of the three surveys was wrong for its own square.
- [x] 6.3 Leave a corrected area, travel far enough to unload it, save, quit, reload and
  return. Confirm the trees are the same species and that nothing is corrected a second time.
  Closed on 2026-09-12 from two sessions either side of a save and quit. The same survey at
  6156,6045 returned 793 trees, 793 taken over, and 257 Dogwood, 249 Redmaple, 241 Linden, 31
  Silverbell and 15 Yellowwood in both. A second correction would have rolled fresh species
  and could not have reproduced those counts, so neither half of the claim is in doubt. This
  proves the pair of records holds together; isolating them is task 6.14.
- [ ] 6.4 Let several in-game months pass over a corrected area, then revisit it and confirm
  no tree has changed species or size other than by the mod's own growth.
- [ ] 6.5 Find a fully grown wild deciduous tree, correct it, and confirm its seasons under
  every growth setting with the seasonal rule both on and off. All six combinations. Half done
  on 2026-09-12: a stage 7 American Linden the mod owns carried overlay
  `e_americanlindenJUMBOXXL_1_3` in autumn, which is the guard removal working on the largest
  size. Still to do is switching the seasonal rule off and the growth setting across its three
  values while standing in an autumn wood.
- [ ] 6.6 Follow one corrected deciduous tree through a full year with the seasonal rule off,
  beside an unadopted tree of the same species, and confirm the two look the same at every
  point. The rule's arithmetic is confirmed, since the debug readout prints both rules and they
  agreed outside autumn and diverged inside it, but nothing has yet been rendered with the rule
  actually switched off.
- [ ] 6.7 Under the base game's growth setting, correct a small tree and confirm over
  several in-game months that it stays the size it was, which is the intended result of the
  mod owning the square outright.
- [ ] 6.8 Confirm grass, ferns, bushes, roads and walls in a corrected area are untouched,
  and that roads and walls still erode over time.
- [ ] 6.9 Drive at speed along a road through unexplored forest with correction on and then
  off, and confirm the difference in stutter is not perceptible.
- [ ] 6.10 Open a heavily explored save, check the size the global object bin has reached and
  time the hourly tick against it.
- [ ] 6.11 Run the pass on a dedicated server. Confirm `LoadGridsquare` fires there at all,
  that corrected sprites reach clients, and that a late-joining client sees the corrected
  species.
- [ ] 6.12 Chop an erosion tree the mod never adopted, in a zone the pass leaves alone or with
  correction off, and confirm the base game clears its category data rather than regrowing the
  tree there. This is read from bytecode only and has never been watched.
- [ ] 6.13 Run the pass against a raised erosion speed, a positive erosion days setting, a
  negative one, and a world with erosion switched off entirely. Confirm correction behaves
  sanely in each and that street and wall erosion is untouched in all of them.
- [ ] 6.14 Delete the growth system's global object bin from a save holding corrected trees,
  reload, and confirm the trees recover without being rerolled into different species.
- [ ] 6.15 Run two players through the same unexplored forest at once, on a dedicated server,
  and confirm overlapping loads correct each square once rather than twice.
- [ ] 6.16 Plant a tree on bare ground early in a fresh world, near squares the pass has
  settled, and watch over several in-game months for an erosion tree appearing on the same
  square. This is the unplaced claim, which this change does not fix; record what is seen for
  the change that will.
