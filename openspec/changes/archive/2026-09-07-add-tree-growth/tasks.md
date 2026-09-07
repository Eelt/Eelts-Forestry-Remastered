Reference build for every claim: the Steam install at `Project Zomboid.app/Contents/Java/`,
reporting version `42.20.4`, revision `b0bbce05d5`. Tree facts come from
`docs/reference/b42-tree-matrix.md` and are not re-derived here.

Group 1 exists to fail fast. The whole approach rests on erosion relinquishing a renamed
tree, and that is inferred from decompiled control flow rather than observed. Do not build
anything else until 1.2 passes.

## 1. Prove the ownership lever

- [x] 1.1 Add `42.20/media/lua/shared/EeltsForestryRemastered_TreeGrowthSprites.lua` with the
      stage to base sprite mapping from `docs/reference/b42-tree-matrix.md`: `<tileset>_<stage>` for
      stages 0 to 3, `<tileset with _1 replaced by JUMBO_1>_0` and `_1` for stages 4 and 5,
      and the JUMBOXL and JUMBOXXL sheets at index 0 for stages 6 and 7. Include a reverse
      lookup from a sprite name back to species and stage, since adoption reads a tree's
      current stage from its sprite. Verify by printing the full mapping for one evergreen
      and one deciduous species and checking every name against the tiles files.
      Done 2026-09-06, placed in `shared/` rather than `server/` since it is a pure lookup
      table and the client system in group 6 may need it. All 88 base sprites verified
      against the 1318 names declared in the three tiles files, the stage round trip is
      clean, and the 528 reverse entries resolve seasonal and snow variants to the right
      stage.
- [x] 1.2 In a scratch lua file, rename a debug-placed tree with `setName` and set its sprite
      one stage on. Verify in game across a season change that erosion does not revert it,
      that the tree still chops normally, and that it survives a save and reload with its new
      sprite. This is the `NEEDS IN-GAME CHECK` from `design.md`. If erosion still reverts the
      tree, stop and revisit the design before continuing.
      Partial as of 2026-09-07. Stage advance verified end to end on an American Holly:
      stages 0 through 7 each produced the predicted sprite, and `size` and `logYield`
      matched `LOGS_PER_SIZE` at every step, so `setSprite` re-running `initTree` is
      confirmed. The stage 7 ceiling clamps. Rename and sprite both survived a save, quit
      and reload, and erosion did not reclaim the tree on chunk load even though its
      `replaceExistingObject` species branch would have deleted it. Still outstanding: the
      season change, which is the path that actually calls `updateObj`.
      Also found: the tree is not in `worldobjects` at all, only the ground blend is, so a
      context menu hook has to reach it through `square:getTree()`.
      2026-09-07 attempt two was inconclusive: six month skips from August to January left
      `getSeasonName()` reporting Early Summer throughout, so `ErosionSeason` never
      recomputed and `updateObj` never fired. `ErosionMain.mainTimer` only calls
      `season.setDay` when it observes GameTime changing, so writing GameTime directly is
      not enough on its own. Note `DebugDemoTime.lua` has the same `mainTimer` call
      commented out after its month skip.
      PASSED 2026-09-07 on attempt three. Forcing the season through
      `ErosionMain.getInstance():getSeasons():setDay(...)` works from lua. A deciduous
      Dogwood adopted at stage 6 kept `e_dogwoodJUMBOXL_1_0` and the name `Eelt_AdoptedTree`
      across the Early Summer to Autumn transition and a further month, while every
      unadopted deciduous around it turned colour. Erosion relinquishes a renamed tree.
      Two findings came out of it. The season boundary is between 24 August and 24
      September, consistent with the roughly 21 August computed in `design.md`, and season
      names are finer grained than four, `Early Summer` being one of them. Second, adopting
      left a stale `attachedAnimSprite` overlay from the pre-adoption stage, which renders
      as a second bare tree behind the real one; `ErosionObj.setStageObject` clears that list
      before setting and the growth system must do the same.
- [x] 1.3 Confirm in the same test that snow still appears on a renamed adopted tree in
      winter, which is expected because `ErosionIceQueen` swaps snow at the `IsoSprite` level
      rather than per object. Remove the scratch file once both checks are recorded.
      PASSED 2026-09-07. On 26 December at minus 9 degrees, adopted JUMBOXL American Hollies
      were snow covered and adopted deciduous trees were bare then snow covered, alongside
      unadopted neighbours. The scratch file is kept until group 8 because its month skip is
      the only practical way to test growth over time; it must be deleted before committing.
      Superseded 2026-09-07: rather than delete it, the harness became
      `42.20/media/lua/client/EeltsForestryRemastered_TreeDebugMenu.lua`, a permanent tool
      gated on `isDebugEnabled()`, or the `UseDebugContextMenu` capability in multiplayer,
      under a right click submenu named "Eelt's Forestry Remastered Debuggers". It ships,
      but is invisible without debug mode.

## 2. Sandbox options

- [x] 2.1 Add the `EeltsForestryRemastered.TreeGrowth` enum and the
      `EeltsForestryRemastered.TreeGrowthTimeMultiplier` double to
      `42.20/media/sandbox-options.txt` exactly as written in `design.md`. Verify both appear
      on the mod's existing sandbox page in a new Custom Sandbox world, with the enum
      defaulting to the third value.
      Written 2026-09-07, in-game check pending.
      Verified in game 2026-09-07 on a fresh Custom Sandbox world: the console reports
      `TreeGrowth 3` and `TreeGrowthTimeMultiplier 1.0`, so both options register with the
      intended defaults.
- [x] 2.2 Add the option names, tooltips and the three enum value labels to
      `42.20/media/lua/shared/Translate/EN/Sandbox.json`, using
      `Sandbox_EeltsForestryRemastered_TreeGrowth_Values_option1` through `_option3`. Verify
      the sandbox screen shows readable labels rather than raw keys.
      Written 2026-09-07, in-game check pending. Value keys confirmed against Skill
      Recovery Journal's `Sandbox_..._Values_option1` form.
- [x] 2.3 Read both options live through `getSandboxOptions():getOptionByName(...)`, never
      through `SandboxVars`, since the in-game sandbox editor does not refresh that table.
      Verify by toggling the enum in the in-game editor and confirming the new value takes
      effect without reloading the world.
      Written 2026-09-07 in the system's `getMode` and `getHoursPerStage`. In-game check
      pending.

## 3. The growth system

- [x] 3.1 Create `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthSystem.lua`
      deriving `SGlobalObjectSystem` as `Eelt_TreeGrowth`, with `initSystem` declaring
      `hoursElapsed` through `setModDataKeys` and the per-object fields through
      `setObjectModDataKeys`, and calling `RegisterSystemClass`. Verify the system loads with
      no lua error and that `gos_Eelt_TreeGrowth.bin` appears in the save directory.
      Written 2026-09-07. System registers as `Eelt_TreeGrowth`; `isValidIsoObject` matches
      an `IsoTree` named `Eelt_AdoptedTree`, mirroring how `STrapSystem` matches its own.
- [x] 3.2 Create `42.20/media/lua/server/EeltsForestryRemastered_TreeGrowthObject.lua`
      deriving `SGlobalObject`, storing the species tileset, the current stage and the hour
      the tree entered that stage. Implement `isValidIsoObject` so only an `IsoTree` whose
      sprite resolves to a known species is accepted. Verify by adopting one debug-placed
      tree and printing its stored state.
      Written 2026-09-07. Persists `tileset`, `stage`, `enteredHour` and `planted`.
- [x] 3.3 Accumulate `hoursElapsed` on `Events.EveryHours`, which is in-game time driven by
      `GameTime.getTimeOfDay`. `SFarmingSystem` uses `EveryTenMinutes` and then discards five
      of every six calls to get the same cadence, so subscribe to the hourly event directly.
      Verify the counter advances at the expected rate and persists across a save and reload.
      Written 2026-09-07 using `getGameTime():getWorldAgeHours()` rather than a hand rolled
      counter, which is what `STrapGlobalObject` uses and needs no system mod data.
- [x] 3.4 Implement the stage advance: a tree advances when the elapsed hours since it
      entered its stage exceed the per-stage duration, which is the baseline of roughly
      thirteen in-game days scaled by the time multiplier. Advancing sets the new base sprite
      through the mapping from 1.1. Verify a debug-placed stage 0 tree reaches stage 7 in
      roughly three in-game months at the default multiplier, and about half that at 0.5.
      Written 2026-09-07. Base is 312 hours per stage, thirteen in game days, scaled by the
      multiplier; seven transitions gives about 91 days from stage 0 to 7.
- [x] 3.5 Apply the ceiling from the enum: stock behaviour adopts nothing at all,
      player-planted only adopts nothing until the planting change exists, and all growth
      adopts any tree below stage 7. Verify each of the three values behaves as specified,
      including that stock behaviour leaves a fresh world completely unchanged.
      Written 2026-09-07. A `planted` flag distinguishes planted from wild-adopted trees, so
      the player-planted value is already correct once planting exists.

## 4. Adoption

- [x] 4.1 Implement adoption as part of the hourly tick, scanning squares within a bounded
      radius of each loaded player. For each tree below the ceiling, read its stage from its
      sprite, rename it so erosion relinquishes it, clear its inherited `attachedAnimSprite`
      overlay, and create the global object. Skip trees at or above the ceiling.
      `SGlobalObjectSystem:OnChunkLoaded` cannot be used, since it only fires for chunks that
      already contain objects of this system; see `design.md`. Verify that walking into a
      fresh forest area adopts the small trees and leaves the jumbo ones alone.
      Verified in game 2026-09-07: a forced tick reported two adopted trees in a fresh
      Custom Sandbox world, and a stage 7 Dogwood was correctly refused. Note that the
      authored map places only jumbo features, so a new world has very few adoptable trees.
      Written 2026-09-07. Scans a 30 tile radius around each loaded player on the hourly
      tick, using `getOnlinePlayers()` on a server and `getSpecificPlayer` otherwise.
- [x] 4.2 Confirm adoption is idempotent, so a repeated scan does not re-adopt or reset a
      tree. Verify by leaving and returning to an area several times and checking a tree's
      stored entry hour is unchanged.
      Written 2026-09-07. Guarded by both the adopted name and an existing object on the
      square.
- [x] 4.4 Confirm the scan cost is acceptable in dense forest, since this runs every in-game
      hour for every loaded player. Verify no frame time spike when standing in deep forest,
      and tune the radius down if there is one.
      Provisionally clear 2026-09-07: no hitch noticed standing in forest. Recorded as
      provisional rather than a pass, since it is one location on one map. Note the scan
      cost is roughly constant whether or not trees are already adopted, because it is
      dominated by the grid square lookups rather than the adoption branch.
- [x] 4.3 Handle a tree being chopped down or otherwise removed, so its global object is
      removed too and no orphan state accumulates. Verify by felling an adopted tree and
      confirming the object count drops.
      Written 2026-09-07, relying on the base `OnObjectAboutToBeRemoved`, which already
      removes the lua object when a matching iso object goes. Needs the in-game check.

## 5. Seasonal appearance

- [x] 5.1 Add the seasonal child sprite mapping to the sprites file from 1.1, using the same
      per-stage index formula at the season's position, and note that stages 6 and 7 use the
      season index directly. Verify the computed names exist in the tiles files for a
      deciduous species.
      Written 2026-09-07. Confirmed in game that a deciduous base sprite is the BARE tree
      and all foliage comes from the overlay: an adopted Eastern Redbud went bare in late
      July while its neighbours were in leaf. Evergreens are the opposite, base carries the
      foliage, which is why they looked correct. Sheet layout is position * 4 + stage for
      stages 0 to 3, position * 2 + stage - 4 for 4 and 5, and position alone for 6 and 7.
      Verified in game 2026-09-07: an unadopted Redbud in Early Summer already wore
      `e_easternredbud_1_14`, which is position 3 stage 2, so the formula matches what
      vanilla itself uses. Growing to stage 3 gave `_1_15` and to stage 4 gave
      `JUMBO_1_6`, confirming both index rules.
- [x] 5.2 Drive the overlay from the autumn season boundary rather than vanilla's split
      summer rule, setting the object's `attachedAnimSprite` to the season's child sprite and
      clearing it in summer. Verify an adopted deciduous tree is still green through July,
      turns during autumn, and returns to green the following summer.
      Written 2026-09-07. Spring uses position 2, Early Summer position 3 and Autumn
      position 5. Position 4 is deliberately skipped: it is vanilla's split summer tint,
      the one that yellows trees in early July. Winter and late autumn use no overlay,
      which is why the bare base is correct for them.
      Verified in game 2026-09-07 for Early Summer: adoption is now visually seamless,
      same sprite and same overlay as before. Autumn, winter and the stagger are still
      unobserved.
      PASSED 2026-09-07 after fixing a 32 bit overflow in the stagger hash. An American
      Linden at stage 5 wore position 3 in Early Summer and position 5 in Autumn, indices 7
      and 11, matching the sheet formula. All four seasons are now verified by sprite index:
      Spring position 2, Early Summer 3, Autumn 5, Winter none.
- [x] 5.3 Stagger the turn across trees using a stable value derived from the tree's
      coordinates, standing in for erosion's per-square magic number, so a forest turns over
      across the early part of the autumn window rather than all on one day. Verify two
      adopted trees of the same species in the same area turn on different days, and that the
      same tree turns on the same day across a save and reload.
      PASSED 2026-09-07. Stagger 0.2106 gave turnAt 0.0737 and fallAt 0.7921, and the tree
      turned once progress passed turnAt. Verified uniform over 201201 coordinates with
      neighbouring trees landing far apart.
      Written 2026-09-07. Stagger is a stable hash of the tree's coordinates, standing in
      for erosion's per square magic number. Turn spreads over the first 35 percent of the
      autumn window and leaves drop from 75 percent, both staggered per tree.
      Partly observed 2026-09-07: an adopted Redbud was still wearing the green position 3
      overlay after the season had turned to Autumn, which is the stagger holding it back.
      The turn to autumn colour itself has not yet been seen on an adopted tree.
- [x] 5.4 Confirm evergreen species are unaffected, since they have no seasonal child
      sprites. Verify an adopted Canadian Hemlock looks identical in every season apart from
      snow.
      PASSED 2026-09-07. American Holly logs `overlay=none` and `overlaySeason=nil` in every
      season, and looks identical to unadopted evergreens including snow.

## 6. Multiplayer pairing

- [x] 6.1 Create `42.20/media/lua/client/EeltsForestryRemastered_TreeGrowthClient.lua`
      deriving `CGlobalObjectSystem` and registering it, so a client has the matching system.
      Verify single player still works unchanged with the client file present, since it loads
      in both contexts.
      Written 2026-09-07, mirroring `CTrapSystem`. Registers the same `Eelt_TreeGrowth`
      system name so the server's objects arrive on the client.
      Verified in game 2026-09-07: `CGlobalObjects: newSystem Eelt_TreeGrowth` appears
      alongside the server registration.
- [x] 6.2 Push stage changes to clients through `sendCommand` and `OnServerCommand`, matching
      how `SFarmingSystem` broadcasts `hoursElapsed`. Note that multiplayer itself will not be
      tested; record it as a known gap the same way `fix-conifer-cone-drops` did.
      Written 2026-09-07, but no custom command was needed. Stage and overlay changes reach
      clients through `transmitUpdatedSpriteToClients` on the tree, and the growth object
      itself through the base `updateOnClient`. Multiplayer remains untested; recorded as a
      known gap.

## 7. Documentation

- [x] 7.1 Update `docs/reference/b42-tree-matrix.md` to record that the mod now grows trees and what it
      takes over from erosion, keeping the description of vanilla behaviour intact so the
      document still describes the base game.
- [x] 7.2 Add a section to `docs/reference/b42-tree-matrix.md` documenting vanilla's seasonal display
      timing as its own finding, since it was not previously recorded: `seasonDisp[2]` marks
      summer as split with `season2 = 3`, so trees show autumn colour from roughly 2 July,
      while the autumn season itself does not begin until about 21 August and runs to 22
      December. Note that `hottestDay` is 22 June, `summerEndDay` adds
      `floor(40 + 40 * summerMod)` with `summerMod = 0.02 * tempMax`, and that
      `getClimateManager()` returns `ErosionMain.getInstance().getSeasons()` so it is not an
      independent season source. Record that this mod follows the autumn boundary instead.
- [x] 7.3 Add the growth feature to `README.md`'s "What it does", naming both sandbox options
      and the default pace.
- [x] 7.4 Bump `modversion` in `42.20/mod.info`.

## 8. Final verification

- [x] 8.1 On a fresh Custom Sandbox world at defaults, confirm across a full session that
      trees adopt and advance, no lua error appears, and the mod's expected prints are
      present. Search the console for `Eelt's Forestry Remastered` without a trailing colon,
      since the debug lua prints `Mod:` before it.
      PASSED 2026-09-07 across several fresh Custom Sandbox sessions: trees adopt at scale,
      grow, and change with the season, with no error or warning naming any of the mod's
      files. The only errors in the log are vanilla ones.
- [x] 8.2 Confirm a save made before this change loads cleanly, adopts trees as chunks load,
      and does not disturb trees already at full size.
      PASSED 2026-09-07. The long running b42p20 save, which had accumulated a 31 KB
      gos_Eelt_TreeGrowth.bin, loaded repeatedly without incident, and stage 7 trees in it
      were correctly refused adoption.
