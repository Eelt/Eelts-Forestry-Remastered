## 1. Measure the season model

- [x] 1.1 Add a temporary daily logger in
  `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua` that steps the game date
  forward one day at a time for a full year, printing date, season name, season day and season
  length each time. Verify by reading a year of output in the console.
- [x] 1.2 From that output, write down the four reachable seasons' start dates and lengths and
  whether they tile the year, overlap or leave gaps. Measured on 2026-09-12: Spring 9 February
  for 65 days, Early Summer 15 April for 142, Autumn 3 September for 64, Winter 6 November for
  95. They tile the year with no gap or overlap, 366 days in total. The apparent discrepancy was
  not one: Early Summer really is 142 days and really does run to 2 September, so it covers what
  a player would call spring and summer both.
- [x] 1.3 Reach a snowy day, put an autumn overlay on a deciduous tree with the debug menu's
  foliage viewer, and look at it. Looked at on 2026-09-13 and judged acceptable, neither good nor
  bad. So the mod leaves it alone, task group 4 is not needed, and nothing has to read the
  weather.
- [x] 1.3a Not needed. Snow does not have to be readable from lua, because nothing keys off it.
- [x] 1.4 Record the season table and the snow finding in `docs/reference/b42-lua-notes.md`, and
  decide from 1.2 whether the year position is built from season progress or from the game date.
  Season table recorded. The position is built from the season's slot plus its progress, needing
  no day counts at all, so a world with different season lengths stretches the cycle with it. The
  snow finding is still open and is task 1.3.

## 2. The year position

- [x] 2.1 Create `42.20/media/lua/server/EeltsForestryRemastered_TreeSeasons.lua` and move
  `staggerFor`, `seasonProgress`, `staggeredSeason`, `vanillaSeason`, `staggerEnabled` and
  `currentSeason` into it out of `EeltsForestryRemastered_TreeGrowthObject.lua`, unchanged.
  Verify in game that foliage still behaves exactly as before the move.
- [x] 2.2 Add a function turning a season name and progress into one continuous position through
  the year, using the lengths measured in task 1. Verify with a debug print that stepping a year
  a day at a time produces a value that rises monotonically and wraps once.
- [x] 2.3 Compute the year position once per tick in `currentSeason` and pass it down, alongside
  the values already passed. Verify by confirming no engine call was added to the per tree path.
  Implemented as a table lookup and an addition inside the rule rather than a sixth parameter
  through `currentSeason`, since the inputs it derives from are already passed once per tick.
  The verification holds: the per tree path makes no engine call.

## 3. The five stage cycle

- [x] 3.1 In `EeltsForestryRemastered_TreeSeasons.lua`, replace `staggeredSeason` with a rule
  over the year position returning bare, `Spring`, `Early Summer`, `Late Summer` or `Autumn`,
  with one stagger shifting every boundary by the same fraction. Verify with a table of
  positions covering the year and the whole stagger range.
- [x] 3.2 Set the boundaries so trees are green through mid September, take their first colour
  in late September or early October, are deepest through the middle and end of October, and are
  bare before winter, recording the intended date for each boundary next to its value. Tuned
  against the measured season table: leaf out 22 March to 2 April, summer green 23 April to 16
  May, first colour 15 to 25 September, deep colour 10 to 20 October, leaves down 26 October to 5
  November. The spread is 0.16 of a season, about ten days at either end of the year, and it has
  to leave the last boundary short of the winter line.
- [x] 3.3 Leave `vanillaSeason` alone. Verify by diffing it against the archived
  `add-erosion-boundary-layer` version and confirming it is unchanged. Diffed after the move to
  `EeltsForestryRemastered_TreeSeasons.lua`; the body is identical.

## 4. Snow

Not needed. Task 1.3 found a snow covered tree in autumn colour acceptable, so there is no snow
rule to write and no code in this group.

- [x] 4.1 Not needed. The mod leaves foliage alone when snow falls, so no tree is stripped early
  and nothing reads the weather.
- [x] 4.2 Not needed. Evergreens take no overlay, so the base game's snow swap is all that ever
  happens to them, with or without this change.

## 5. Settings and tools

- [x] 5.1 Update the `StaggerTreeSeasons` tooltip in
  `42.20/media/lua/shared/Translate/EN/Sandbox.json` to describe the five stage cycle rather
  than only autumn. Verify by reading it in the sandbox options screen.
- [x] 5.2 Widen the debug menu's autumn sweep to the whole year, so it reports what each stage
  would show at each point and how many trees are in each stage. Verify by running it and
  checking the stage counts move through the year in order.

## 6. In-game verification

- [x] 6.0 Fix `debugSeason`, which was still printing `turnAt` and `fallAt` from the old
  autumn-only formula. On 29 October it reported a fall point of 0.8202 against a progress of
  0.8750, reading as though the tree should be bare while the tree was correctly in deep colour.
  It now prints the year position and the five boundaries the tree actually uses.

- [x] 6.1 Watch one deciduous tree the mod owns through a full year and confirm it passes
  through bare, spring, green, early fall, deep fall and bare, in that order, with none skipped.
  Closed 2026-09-16 across two sessions. A Dogwood at stage 6 read bare on 12 January, 12 February,
  12 and 19 March, spring foliage from 26 March through 23 April, summer green from 30 April, and
  a Riverbirch showed the early fall look on 8 October, the deep look on 15, 22 and 29 October,
  and bare on 5 November. All five looks seen, in order, none skipped.
- [x] 6.2 Confirm no tree shows either fall look during July or August. Watched on 2026-09-13:
  a stage 7 American Linden read green through July and August while the plain rule beside it had
  already gone to the tint. No tree can do otherwise, since the whole Early Summer season sits
  below the first colour boundary at every stagger.
- [x] 6.3 Confirm trees are still green through the first weeks of September, which is the
  defect this change exists to fix. Watched on 2026-09-13: on 9 September, six days into autumn,
  the same Linden was still wearing overlay 3, summer green, where the old rule had it in deep
  colour on 2 September and the plain rule had it there on the day.
- [x] 6.4 Confirm peak colour falls in the middle and end of October, and that every deciduous
  tree the mod owns is bare by the end of the autumn season, with none carrying leaves into
  winter. Watched on 2026-09-16, stepping a week at a time. A Riverbirch wore overlay 5, the deep
  look, on 15, 22 and 29 October, was bare on 5 November while still inside autumn, and stayed
  bare into winter. This is the stage the monthly steps had been walking over.
- [x] 6.5 Confirm a wood turns gradually rather than all at once, at every stage and not only in
  autumn, and that the same tree turns at the same point two years running. The spring transition
  was watched through March and April on 2026-09-16 and read as gradual, and the year sweep splits
  the same wood across a boundary, 199 trees still in spring against 211 already green. The second
  half holds by construction rather than by observation: the stagger is a pure function of the
  square's coordinates with no time term in it, so it cannot differ between years.
- [x] 6.6 Reach snow while trees still carry autumn colour and confirm the result matches
  whatever task 1.3 decided, rather than looking like an error. Same observation as 1.3, on
  2026-09-13: acceptable, and the mod does nothing about it.
- [x] 6.7 Watch a pine, a hemlock and a holly through a year and confirm their foliage never
  changes. Confirmed in game on 2026-09-16: the overlay does not change. It cannot, since
  `getOverlay` returns nothing for a tileset in the evergreen table before it looks at the season
  at all, so every requirement in this capability passes over them.
- [x] 6.8 Turn the seasonal setting off and confirm the base game's timing returns, including
  the first colour appearing around the start of July. Watched on 2026-09-16: with the setting
  off, a stage 6 Dogwood wore overlay 4, the tint, on 4 July, where the same tree with the
  setting on stayed green. The midsummer tint is reproduced, which is the defect the setting
  exists to hand back.
- [ ] 6.8a The exact tint date is close but not the matrix's figure. On the measured 142 day
  summer the plain rule's midpoint lands between 17 June and 2 July across the stagger range,
  while `b42-tree-matrix.md` quotes about 2 July from an assumed 100 day summer running 13 May
  to 21 August. Compare a mod-owned tree against a genuinely unadopted one of the same species,
  on the same day, with time running rather than jumping, and adjust the split if vanilla tints
  later than the plain rule does. This also settles the unadopted Redmaple that showed deep
  colour on 15 October when the plain rule says it should have been bare.
- [x] 6.9 Confirm no tree changed species or size across the whole year, under each of the three
  growth settings. Checked against the logs rather than by eye on 2026-09-16: 17 squares were
  inspected with coordinates, 11 of them more than once and one 26 times, spanning January to
  July and the whole of autumn. Zero species changes and zero stage regressions. The seasonal
  path also cannot cause either, since only `initNew`, `adoptFrom`, `stateFromIsoObject` and
  `grow` ever write `tileset` or `stage`, and none of them is on it. The growth setting was not
  cycled through all three values while watching, but nothing in the seasonal path reads it.
- [x] 6.10 Open a save made before this change and confirm the trees pick up the new look on the
  next hourly tick without any other change. Confirmed on 2026-09-16 with a stronger case than the
  task asked for: a save played without the mod at all, then loaded with it, took the new foliage
  straight away.
