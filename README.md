# Eelt's Forestry Remastered

A Project Zomboid mod that overhauls forestry, without editing any vanilla files
directly.

**Targets Project Zomboid B42.20+.** Earlier B42 builds shipped different item and
recipe definitions, so this mod's wiring assumes B42.20.

## What it does

**Scope is still being defined.** This section will list each change once the first
feature set lands. Everything the mod adds is namespaced `Eelt_*` and layered on top of
the game's own definitions at load time, so vanilla entries are never modified in place.

## Reference

[B42 tree matrix](docs/b42-tree-matrix.md) documents the eleven tree species B42.20 ships,
their size stages, which forage zones grow them and what each one can be propagated from.

## Installation

Copy the `42.20/` folder into your Project Zomboid `mods/EeltsForestryRemastered/`
workshop or local mods directory, then enable "Eelt's Forestry Remastered" from the
in-game mod list.

## License

AGPL-3.0-or-later, see [LICENSE](LICENSE).
