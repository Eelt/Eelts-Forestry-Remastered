## Context

See `proposal.md` for motivation and `docs/b42-tree-matrix.md` for the tree facts this rests
on. The constraints that shape the approach:

- No vanilla file or vanilla table may be edited or shadowed, so the drop cannot be fixed
  where it is wrong. `IsoTree.dropWood` is Java, has no lua entry point, and no lua event
  fires when a tree topples.
- There is no test suite. The only verification is playing, so the design has to be
  arrangeable into a small number of observable in-game checks.
- This is the first change that ships lua the game actually runs, so it also establishes the
  sandbox option and translation plumbing every later change will reuse.

## Goals / Non-Goals

**Goals:**

- Canadian Hemlock yields cones on exactly Virginia Pine's terms, with nothing else about
  its yield altered.
- Vanilla behaviour is bit-identical when the setting is off.
- Establish the sandbox option, translation and server-lua patterns for later changes.

**Non-Goals:**

- Re-implementing `dropWood`. Only the missing cone is added; every other drop is left to
  vanilla.
- Generalising to a species-to-propagule table. With exactly one species to correct, a table
  would be speculative structure. The planting change can introduce one when it has real
  entries to put in it.

## Decisions

### Add the cone alongside vanilla rather than replacing the drop

The wrapper lets vanilla's `dropWood` run untouched and then adds the missing cone. It does
not suppress or re-implement any vanilla drop.

The alternative was intercepting before the topple and substituting a full custom drop
table. Rejected: it would mean maintaining a copy of `dropWood`'s logic, which changes
between builds, and any drift becomes a silent behaviour difference. Adding one item is the
smallest possible footprint and stays correct if vanilla's other drops change.

### Hook `ISChopTreeAction:animEvent`, wrapping the class method

`ISChopTreeAction` is a plain lua class, and mod lua parses after vanilla's, so the method
can be captured and replaced at parse time with no event wrapper:

```lua
local ISChopTreeAction_animEvent = ISChopTreeAction.animEvent
function ISChopTreeAction:animEvent(event, parameter) ... end
```

Vanilla's own `animEvent` already tests `self.tree:getObjectIndex() == -1` to detect that
the tree has just toppled, so that is the sanctioned signal for "it fell on this call"
rather than something invented.

Alternatives rejected: there is no `OnTreeChopped` or equivalent lua event, and
`toppleTree` ends by triggering only `OnContainerUpdate`, which carries no argument
identifying the tree. Polling squares would be both expensive and unreliable.

### Read the species, yield and square before delegating

`toppleTree` calls `reset()` and pushes the object into `CellLoader.isoTreeCache` for reuse,
so after the delegated call the sprite, the log yield and the square are all unreliable on
that object. The wrapper therefore captures the sprite name, `getLogYield()` and
`getSquare()` before calling through, then acts on the captured values afterwards if the
tree fell.

### Match on the tileset prefix, not the exact sprite

Species detection is `e_canadianhemlock` as a prefix of the sprite name. That single prefix
covers the base, JUMBO, JUMBOXL and JUMBOXXL sheets, since all four are named
`e_canadianhemlock*`. Matching on exact sprite names would need every stage and seasonal
index enumerated.

This is deliberately the same shape of test vanilla uses, a name match, but anchored as a
prefix rather than an unanchored `contains`, which is what made the vanilla test wrong in
the first place.

### Replicate vanilla's cone arithmetic exactly

Vanilla gates every species drop behind `numPlanks > 2` and rolls once per log iteration:

```
roll = min(6 - logYield, 4)
for i = 0 to logYield - 2:
    if NextBool(roll) then add cone
```

`NextBool(n)` is `Next(n) == 0`, and `Next(max)` returns `0` when `max <= 0`, so the roll is
certain once `roll` reaches 0 or below, which happens at log yields 6 and 8. The lua must
special-case that, because `ZombRand(0)` is not guaranteed to behave like the Java path.
The rule is: if `roll <= 0` the cone is certain, otherwise `ZombRand(roll) == 0`.

Copying the arithmetic rather than inventing a rate is what makes "on the same terms as
Virginia Pine" checkable instead of a matter of taste.

### Server lua, guarded on `not isClient()`

The file goes in `42.20/media/lua/server/`. Vanilla's drop-side branch in `animEvent` is
already guarded by `not isClient()`, because on a multiplayer client the topple happens
server-side through `serverStart` and `emulateAnimEvent`. The wrapper uses the same guard so
the cone is added exactly once, on the authority that runs `dropWood`.

Server lua also loads in single player, so this covers both.

### One boolean sandbox option, defaulting on

`42.20/media/sandbox-options.txt`, which is where `CustomSandboxOptions.init` looks, under
the version directory:

```
VERSION = 1,

option EeltsForestryRemastered.FixConiferConeDrops
{
    type = boolean,
    default = true,
    page = EeltsForestryRemastered,
    translation = EeltsForestryRemastered_FixConiferConeDrops,
}
```

`SandboxOptions.initSandboxVars` splits an id of the form `Prefix.Name` into a table, so the
value also appears as `SandboxVars.EeltsForestryRemastered.FixConiferConeDrops`. The wrapper
does **not** read it there.

`SandboxVars` is only refreshed by `SandboxOptions.toLua()`, which the new game screen calls
on Play but which `ISServerSandboxOptionsUI:onButtonApply`, the in game sandbox editor, never
calls. Changing the option mid-game therefore updates the Java option while leaving the lua
table stale, and a gate reading `SandboxVars` keeps the old value until the world reloads.
This was found in testing: the option was unchecked and applied in game, and cones kept
dropping.

The wrapper instead reads the option object live, via
`getSandboxOptions():getOptionByName("EeltsForestryRemastered.FixConiferConeDrops")`, which
is keyed on the full id and always reflects the current value. That is how vanilla reads its
own boolean options, for example `PlantGrowingSeasons` in `SPlantGlobalObject.lua`. A missing
option is treated as on, so a world saved before the option existed keeps the corrected
behaviour.

Translations are JSON in B42.20, not the `Sandbox_EN.txt` that B41 used. `Translator`
resolves `media/lua/shared/Translate/<LANG>/<File>.json` and reads the version directory of
each mod, so the file is `42.20/media/lua/shared/Translate/EN/Sandbox.json`. Three keys are
needed, and all of them are prefixed `Sandbox_`: the page name from `page`, the option name
from `translation`, and that same key with `_tooltip` appended. This was corrected during
implementation; the original plan named the B41 file.

A single boolean rather than one per defect: there is only one defect being corrected, since
the legacy padding is unobservable and the acorn has no correct target.

### American Holly is deliberately left without a cone

Holly is modelled as a dense conical evergreen and reads as a conifer more strongly than
either real conifer, so a player may well expect a cone from it. It is an evergreen
broadleaf that bears drupes, and vanilla already gives it a berry, so a cone would be wrong.

This is called out because it is the most likely thing to be reported as a bug against this
change. The reasoning belongs in `docs/b42-tree-matrix.md`, which already carries it, rather
than in a code comment.

## Risks / Trade-offs

- Another mod wrapping `ISChopTreeAction:animEvent` could break the chain if it replaces
  rather than delegates. Mitigation: capture and call through, never assume we are the only
  wrapper, and keep the wrapper free of early returns so a later wrapper still runs.
- Vanilla's cone arithmetic is copied, so if a future build changes `dropWood`'s rates
  Hemlock and Pine will diverge. Mitigation: the arithmetic is recorded in
  `docs/b42-tree-matrix.md` with the source class, so a version bump has a place to check.
- `getObjectIndex() == -1` is an inference about "it fell on this call" borrowed from
  vanilla's own use. If a tree could report that without having toppled, cones would appear
  without a felled tree. Mitigation: the in-game verification chops trees of several sizes
  and confirms cone counts, which would surface a false positive.
- Multiplayer is untested. The `not isClient()` guard is reasoned from the vanilla source,
  not observed. Mitigation: recorded as a known gap; the verification steps are single
  player, and the guard mirrors vanilla's own.

## Migration Plan

Additive, with no persisted state. The sandbox option gains a default on existing saves and
the wrapper reads nil as on. Rolling back is removing the three new files; nothing has been
written to a save that would linger.
