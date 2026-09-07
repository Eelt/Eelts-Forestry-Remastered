Reference build for every claim: the Steam install at `Project Zomboid.app/Contents/Java/`,
reporting version `42.20.4`, revision `b0bbce05d5`. Tree facts come from
`docs/reference/b42-tree-matrix.md` and are not re-derived here.

## 1. Sandbox option plumbing

- [x] 1.1 Add `42.20/media/sandbox-options.txt` with `VERSION = 1,` and a single
      `option EeltsForestryRemastered.FixConiferConeDrops` block of `type = boolean`,
      `default = true`, `page = EeltsForestryRemastered` and
      `translation = EeltsForestryRemastered_FixConiferConeDrops`. Verify in game that the
      option appears in the sandbox settings screen when creating a world, on its own page,
      and is on by default.
      Confirmed 2026-09-06. Note the option only exists in worlds created after the mod was
      enabled, since sandbox settings are baked into a save at creation, and the page is only
      reachable through Custom Sandbox rather than a difficulty preset.
- [x] 1.2 Add `42.20/media/lua/shared/Translate/EN/Sandbox.json` giving the option a
      display name and a tooltip that says what it corrects. Verify the sandbox screen shows
      the readable name rather than the raw translation key.
      Confirmed 2026-09-06. B42.20 uses JSON translations, not B41's `Sandbox_EN.txt`; the
      reference mod LanternFix ships the same `Translate/EN/Sandbox.json` layout.
- [x] 1.3 Confirm the value reaches lua as
      `SandboxVars.EeltsForestryRemastered.FixConiferConeDrops`.
      Confirmed 2026-09-06: the game logs `FixConiferConeDrops true` to the console at world
      creation on its own, so no temporary print was needed.

## 2. The cone drop

- [x] 2.1 Create `42.20/media/lua/server/EeltsForestryRemastered_ConeDrops.lua` that
      captures `ISChopTreeAction.animEvent` into a local at parse time and replaces it with a
      wrapper that always delegates. Verify chopping any tree still behaves exactly as before
      with no lua error, since at this point the wrapper adds nothing.
- [x] 2.2 In that file, before delegating, capture the tree's sprite name, `getLogYield()`
      and `getSquare()` when the event is `ChopTree` and `not isClient()`. These are unusable
      after the delegated call because `toppleTree` resets the object and returns it to the
      cache. Verify by chopping a tree and printing the captured values.
- [x] 2.3 After delegating, detect that the tree fell using `getObjectIndex() == -1`, the
      same signal vanilla uses in the untouched branch of `animEvent`. Verify the detection
      fires exactly once per felled tree and never on a non-final axe swing.
- [x] 2.4 Add the species test: the captured sprite name starts with `e_canadianhemlock`,
      which covers the base, JUMBO, JUMBOXL and JUMBOXXL sheets. Verify it matches a Hemlock
      of each of those four size bands and does not match Virginia Pine or American Holly.
- [x] 2.5 Add the cone arithmetic replicating vanilla: skip entirely when the captured log
      yield is 2 or less, otherwise `roll = math.min(6 - yield, 4)` and one roll per
      iteration for `yield - 1` iterations, where the cone is certain if `roll <= 0` and
      otherwise lands on `ZombRand(roll) == 0`. Add each cone with
      `square:AddWorldInventoryItem("Base.Pinecone", 0, 0, 0)`. Verify cone counts against
      the table in `docs/reference/b42-tree-matrix.md`.
- [x] 2.6 Gate the whole addition on the sandbox option, treating a nil value as on so an
      existing save does not silently lose the correction. Verify by creating one world with
      the option off and one with it on, and chopping a large Hemlock in each.
      Confirmed 2026-09-06 by toggling the option in the in game sandbox editor and felling
      the same Hemlock both ways: on gave 4 cones, off gave 0, with every other drop
      identical. The first attempt failed because the gate read `SandboxVars`, which that
      editor never refreshes; it now reads the option object live. See `design.md`.

## 3. In-game verification

Groups 1, 2 and 4 are written and their files parse clean, but every "verify in game"
clause in them is still outstanding and is covered by this group. Nothing below has run.

- [x] 3.1 Resolve the outstanding check from the previous change: chop a Canadian Hemlock
      with the mod's option **off** and confirm no cone drops, which is the last unverified
      claim in `docs/reference/b42-tree-matrix.md`. Record the result there and clear the
      `NEEDS IN-GAME CHECK` marker.
      Confirmed 2026-09-06 on `e_canadianhemlockJUMBO_1_1`, size 6, log yield 5. Verified
      with the mod not enabled rather than with the option off, which is a stronger test of
      the vanilla claim. Documented. The option-off path was exercised separately in 2.6.
- [x] 3.2 With the option on, fell a Canadian Hemlock at stage 3 or 4 and confirm cones can
      drop but do not always. Fell one at stage 6 or 7 and confirm at least one cone drops
      every time, which is where vanilla's roll becomes certain.
      Confirmed 2026-09-06 on `e_canadianhemlockJUMBO_1_1`, size 6, log yield 5, where the
      count is deterministic: exactly 4 cones, matching the predicted `logYield - 1` at
      `roll = 1`. A/B against the same tree on the same tile with the mod absent showed
      every other drop identical, so nothing but the cones changed.
- [x] 3.3 Fell a Canadian Hemlock below stage 3 and confirm no cone drops, matching vanilla's
      `numPlanks > 2` gate.
      Confirmed 2026-09-06 on `e_canadianhemlock_1_2`, size 3, log yield 2: yielded 1 Log,
      1 Sapling, 1 Twigs and 1 Wood Splinters, no cone, no lua error.
- [x] 3.4 Fell a Virginia Pine and confirm its cone yield is unchanged and not doubled, then
      fell an American Holly and confirm it yields no cone and its berry behaviour is
      unchanged. Then fell one deciduous species and confirm no cone and no acorn.
      Confirmed 2026-09-06. `e_virginiapineJUMBOXL_1_0`, size 7: 5 cones, not doubled, and
      every other drop matched the predicted counts exactly. `e_americanhollyJUMBO_1_1`,
      size 6: no cone, and no berry, correct outside Autumn and Winter; identical to the
      size 6 Hemlock apart from the cones. `e_dogwoodJUMBOXL_1_0`, size 7: no cone and no
      acorn, identical to the size 7 Pine apart from the cones.
- [x] 3.5 Confirm the console shows no lua error and the mod's expected prints across a full
      session. Note that the debug lua prints `Eelt's Forestry Remastered Mod:` with "Mod"
      before the colon, so search without the colon.
      Confirmed 2026-09-06 across a session including world creation and several fells: all
      three prints present, and no error or warning names the mod. The only lua error in the
      log is vanilla's `handleMannequinZone`.

## 4. Documentation

- [x] 4.1 Update the Canadian Hemlock row and the cone test defects section of
      `docs/reference/b42-tree-matrix.md` to record that the mod now corrects this behind
      `EeltsForestryRemastered.FixConiferConeDrops`, keeping the description of vanilla's
      behaviour intact so the document still describes the base game accurately.
- [x] 4.2 Move the propagule drop fix out of the carried-forward section of
      `docs/reference/b42-tree-matrix.md` now that it has shipped, leaving behind only the parts still
      outstanding: propagule items for the eight deciduous species, and the acorn's fate.
      Verify the carried-forward section still matches this change's `design.md` for
      everything not yet built.
- [x] 4.3 Replace `README.md`'s "Scope is still being defined" placeholder in "What it does"
      with the first real entry, describing the Hemlock cone correction and naming its
      sandbox option. Verify the link to `docs/reference/b42-tree-matrix.md` still resolves.
- [x] 4.4 Bump `modversion` in `42.20/mod.info` from `0.0.1`, since this is the first release
      with player-visible behaviour.
