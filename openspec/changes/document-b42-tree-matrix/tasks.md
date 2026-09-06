No task in this change edits a file under `42.20/media/lua/`, because nothing the game
loads changes. Each task names the file it does change. The in-game step in group 6 checks
the three findings `design.md` marks as needing verification and confirms the mod still
boots unchanged.

Reference build for every value written down: the Steam install at
`Project Zomboid.app/Contents/Java/`, reporting version `42.20.4`, revision `b0bbce05d5`.
Record that build string in the document header.

## 1. Document skeleton

- [x] 1.1 Create `docs/b42-tree-matrix.md` with the header (target build, reference build
      string, date read, and the one-line statement that this describes vanilla B42.20 and
      not anything the mod adds) and the section headings for groups 2 through 5. Verify by
      confirming the file exists and `README.md`'s link target in task 7.1 resolves to it.
- [x] 1.2 Add the "How to re-check this" section listing every source file from
      `proposal.md`'s Impact section against the finding it supports, so a 42.21 pass is
      mechanical. Verify each listed path exists in the reference install.

## 2. Species table

- [x] 2.1 In `docs/b42-tree-matrix.md`, add the species table with one row per species,
      keyed by base tileset name, with columns for `NatureTrees` array index, display name
      as returned by `IsoObject:getName()`, real-world species, and evergreen or deciduous.
      Verify all eleven rows match the `trees` array in the decompiled `NatureTrees`, in
      order: `e_americanholly_1`, `e_canadianhemlock_1`, `e_virginiapine_1`,
      `e_riverbirch_1`, `e_cockspurhawthorn_1`, `e_dogwood_1`, `e_carolinasilverbell_1`,
      `e_yellowwood_1`, `e_easternredbud_1`, `e_redmaple_1`, `e_americanlinden_1`.
- [x] 2.2 Add the macro category section covering conifer, deciduous broadleaf and
      evergreen broadleaf. State that `NatureTrees` carries a single `evergreen` flag with
      no conifer flag, that the three flagged evergreen are American Holly, Canadian
      Hemlock and Virginia Pine, and that only the latter two are conifers. Verify against
      the third constructor argument of each `TreeInit` in `NatureTrees`.
- [x] 2.3 Add the seasonal sprite note: an evergreen species has base sprites for the
      summer and snow variants only, a deciduous species has six seasonal variants
      addressed as `season * 4 + stage`. Verify against the `init` method's `snames` array
      and the `sheetid` switch in `NatureTrees`.

## 3. Size stages

- [x] 3.1 In `docs/b42-tree-matrix.md`, add the stage table from `design.md` mapping each of
      the eight stages to its `tree` sprite property, tileset family and footprint. Verify
      the `tree` values against `tiledefinitions_erosion.tiles.txt` (1 to 4),
      `jumbo_trees.tiles.txt` (5 and 6) and `jumbo_trees_big.tiles.txt` (7 for JUMBOXL, 8
      for JUMBOXXL).
- [x] 3.2 Add the log yield column from `IsoTree.LOGS_PER_SIZE`, which is
      `{1, 1, 2, 3, 4, 5, 6, 8}` indexed by size minus one, and note that
      `damage = max((logYield - 1) * 80, 40)` sets chopping time. Verify against the
      decompiled `IsoTree.initTree` and the static initialiser.
- [x] 3.3 Add the per-species stage availability table confirming all eleven species have
      all four tileset families present. Verify by listing the `file =` entries in the three
      tiles files: eleven base, eleven JUMBO, eleven JUMBOXL and eleven JUMBOXXL, plus the
      two `e_stumps_JUMBO*` sheets which are not a species.
- [x] 3.4 Add the worldgen feature cross-reference column mapping `<species>_sapling`,
      `<species>`, `<species>_jumbo`, `<species>_jumbo_xl` and `<species>_jumbo_xxl` to the
      stages each covers. Verify against
      `media/lua/server/WorldGen/features/tree/pine*.lua`, noting that `pine_sapling` uses
      sprites `_0` and `_1` (stages 0 and 1) and `pine` uses `_2` and `_3` (stages 2 and 3).

## 4. Forage zones and natural spawning

- [x] 4.1 In `docs/b42-tree-matrix.md`, add the forage zone to worldgen biome mapping table
      transcribed from `media/lua/server/metazones/BiomeMapConfig.lua`, including the pixel
      value per row. Call out that the `vegitation` and `phmix_forest` rows are commented
      out in that file, so the `Vegitation` and `PHMixForest` zones defined in
      `forageZones.lua` are not reachable from the biome map.
- [x] 4.2 Add the per-zone species table: for each forage zone, the species its biome may
      place and the vanilla probability, transcribed from the `TREE` blocks in
      `media/lua/server/WorldGen/biomes/map/*.lua`. Verify that `ph_forest` lists Virginia
      Pine only, `birch_forest` lists River Birch only, `pr_forest` lists Eastern Redbud,
      Cockspur Hawthorn and Carolina Silverbell, `organic_forest` lists Dogwood, Red Maple
      and American Linden, `farm_forest` lists Yellowwood, Red Maple and Carolina
      Silverbell, and `primary_forest` lists Canadian Hemlock and American Holly plus
      smaller shares of Red Maple, Dogwood and American Linden.
- [x] 4.3 Add the finding that the authored map's biomes only ever place the `_jumbo`,
      `_jumbo_xl` and `_jumbo_xxl` features, never the plain or `_sapling` ones, and that
      `pine_sapling` is the only sapling feature any biome references at all
      (`biomes/worldgen/sand_bank.lua`, a procedural biome). Mark this as needing the
      in-game check in task 6.3.
- [x] 4.4 Add a short section on the procedural biomes in
      `media/lua/server/WorldGen/biomes/worldgen/`, which register into `worldgen.biomes`
      rather than `worldgen.biomes_map` and are not reachable from `BiomeMapConfig.lua`.
      Note that `pine_forest` and `light_pine_forest` group Virginia Pine with American
      Holly and Canadian Hemlock, which is the closest thing the game has to a stated
      conifer grouping.
- [x] 4.5 Add the erosion respawn path as the second way a tree appears: `validateSpawn` in
      `NatureTrees` picks a species from the twelve-row `soilRef` table by soil value, and
      sets `maxStage = 2 + floor((eValue - 50) / 17) - 1`, so an erosion-spawned tree can
      never exceed stage 3. Transcribe the `soilRef` table and note that erosion ignores the
      forage zone entirely, so it is a separate and sometimes contradictory source of
      species. Verify against the decompiled `NatureTrees.validateSpawn`.
- [x] 4.6 Add the Kentucky context paragraph: Kentucky forest is roughly 76 percent
      oak-hickory with mixed mesophytic on moister eastern slopes, Virginia Pine and Eastern
      Hemlock favour acidic and cool north-facing sites respectively, and the game's
      `ph_forest` being pure Virginia Pine is consistent with that. State plainly that the
      game ships no oak or hickory tileset, so the vanilla palette is a stylised subset
      rather than a representative one, and that Project Zomboid's Knox County is a
      fictional county in the Louisville area rather than the real Knox County in
      south-eastern Kentucky. Cite the two USDA and Kentucky Energy and Environment Cabinet
      sources by URL.

## 5. Propagation items and the gaps

- [x] 5.1 In `docs/b42-tree-matrix.md`, add the propagation column to the species table with
      one of three values per species: cone, sapling only, or berry. Verify against
      `IsoTree.dropWood`: a pinecone drops when the sprite name lowercased contains `pine`,
      an acorn when it contains `oak` or the sprite is `vegetation_trees_01_13`, `_14` or
      `_15`, and a holly berry when it contains `holly` and the season is Autumn or Winter.
- [x] 5.2 Add the gaps section stating each limitation explicitly, since these constrain the
      planting change: no tileset name contains `oak` so `Base.Acorn` corresponds to no
      living tree in the game; `Base.Pinecone` drops only from Virginia Pine and never from
      Canadian Hemlock despite both being conifers; `Base.Sapling` is defined in
      `scripts/generated/items/weapon.txt` as an improvised blunt weapon with no species
      field; and none of the three items carries any species information. Verify each item
      definition in `scripts/generated/items/{food,normal,weapon}.txt`.
- [x] 5.3 Add a "cone test defects" subsection quoting the `pinecone` and `acorn`
      expressions from `IsoTree.dropWood` verbatim, and state both defects. First, the
      conifer test is a substring match on `pine`, so Canadian Hemlock never drops a cone
      despite `NatureTrees` flagging it evergreen and despite it being a true conifer;
      `e_virginiapine_1` is the only tileset name containing the substring. Second, the four
      legacy fallbacks are written `vegetation_trees_01_08`, `_09`, `_010` and `_011`, while
      `newtiledefinitions.tiles.txt` declares `vegetation_trees_01_8`, `_9`, `_10` and `_11`,
      so no equality test can match and legacy pines drop no cone either. Contrast with the
      acorn test's `_13`, `_14` and `_15`, which are written without padding and do match.
      Verify the literals against the decompiled `dropWood` and the declared sprite names
      against `newtiledefinitions.tiles.txt`.
- [x] 5.4 Note alongside 5.3 that `NatureTrees.replaceExistingObject` converts
      `vegetation_trees` sprites into one of the eleven erosion species on chunk load, so on
      a save with erosion running the legacy branch is close to unreachable regardless of
      the padding defect. Verify against the `startsWith("vegetation_trees")` branch in the
      decompiled `replaceExistingObject`.
- [x] 5.5 Add the conclusion that follows: nine of the eleven species have no seed-like item
      at all, Virginia Pine is the only one with a cone, and American Holly's berry is a
      food item rather than a seed, so sapling propagation is the only route available for
      every species. State that this is an accepted limitation for the first planting
      release.
- [x] 5.6 Add the foraging availability table for `Base.Pinecone`, `Base.Acorn` and
      `Base.Sapling`, transcribing the `zones` weights and the `months` and `bonusMonths`
      from `Foraging/Categories/Firewood.lua` and `Foraging/Categories/WildPlants.lua`. Note
      that forageable cones and acorns have no relationship to the species growing in that
      zone.

## 6. Growth system findings and in-game verification

- [x] 6.1 In `docs/b42-tree-matrix.md`, add the erosion growth section: growth is driven by
      the single global `eTicks` counter, one tick per `tickunit` of 144 in-game hours by
      default, scaled by the erosion speed and `erosionDays` sandbox settings; a tree's
      stage is `floor((eTick - spawnTime) / (cycleTime / (maxStage + 1)))` with `cycleTime`
      fixed at 60 for every species; and `spawnTime` is `130 - eValue`. Verify against
      `NatureTrees.update`, `NatureTrees.init` and `ErosionMain.mainTimer`.
- [x] 6.2 Add the consequences that make erosion unsuitable as a planting backend: growth is
      a function of world age rather than per-tree elapsed time, so every tree of a given
      spawn time is the same size everywhere; once `eTicks` passes `spawnTime + cycleTime`
      nothing grows further; and the stage 3 cap from task 4.5 means erosion alone never
      produces a jumbo tree. Cross-reference the configuration decision recorded in
      `design.md`.
- [ ] 6.3 Load the mod in game on a fresh save and check the three marked findings. Confirm
      the console shows the expected `Eelt's Forestry Remastered:` prints from
      `42.20/media/lua/client/EeltsForestryRemastered_Debug.lua` and no lua error, since
      this change must leave loading behaviour untouched. In an unvisited forest area,
      check whether any stage 0 to 3 tree is present on the authored map, chop a Canadian
      Hemlock and confirm no pinecone drops, and chop a deciduous tree in autumn and in
      summer to compare log yields. Record each result in the document, replacing the
      "needs an in-game check" marker with what was observed.
      Status: finding 1 was resolved from the files during implementation and withdrawn, no
      in-game check needed. Finding 3 is confirmed in game as of 2026-09-06. The boot check
      passed on 2026-09-06 against version 42.20.4, revision b0bbce05d5: the mod loads, the
      parse-time and main menu prints both appear, and no error or warning names the mod.
      Still open: finding 2, the Canadian Hemlock cone drop.
- [x] 6.4 Add the carried-forward decisions section from `design.md` as the document's
      closing section, covering the VHS unlock approach, the maximum growable size
      configuration dropdown and its default, the tape requirement toggle, the pinecone
      modData species stamping, and the conifer cone drop fix with its own setting, its
      `ISChopTreeAction:animEvent` hook point and its known gap for trees felled by vehicle
      or fire. Verify each matches `design.md` so the two do not drift.
- [x] 6.5 Add the flagged tape language section listing each mechanic the transcript
      describes that is not in scope, quoting the line it came from, and naming
      `RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39` as the line the planting unlock hangs on.
      Verify the quoted English text against
      `media/lua/shared/Translate/EN/Recorded_Media.json`.

## 7. Repository wiring

- [x] 7.1 Add a one-line pointer to `docs/b42-tree-matrix.md` in `README.md`. Keep the
      "What it does" section's "scope is still being defined" wording, since this change
      adds no player-visible feature. Verify the link resolves from the repo root.
- [x] 7.2 Write `.serena/memories/b42_trees.md` pointing at the document and summarising
      only what a future session needs to decide whether to open it. Add the `mem:b42_trees`
      reference to `.serena/memories/core.md`. Verify `core.md` lists it alongside the
      existing memory references.
- [x] 7.3 Confirm `docs/` needs no `.gitattributes` entry, since the document is markdown
      and markdown is already pinned to LF, and confirm `git status` shows only
      `docs/b42-tree-matrix.md`, `README.md` and the `openspec/changes/` artifacts as
      additions. `.serena/` stays untracked.
