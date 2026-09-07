# Eelt's Forestry Remastered

A Project Zomboid mod that overhauls forestry, without editing any vanilla files
directly.

**Targets Project Zomboid B42.20+.** Earlier B42 builds shipped different item and
recipe definitions, so this mod's wiring assumes B42.20.

## What it does

Everything the mod adds is layered on top of the game's own definitions at load time, so
vanilla entries are never modified in place.

- **Canadian Hemlock drops pine cones.** The base game only gives cones to trees whose
  sprite name contains "pine", so Hemlock never drops any despite being a conifer. This mod
  gives it cones on the same terms as Virginia Pine, which means from the third growth stage
  up, with the chance rising as the tree gets larger. Controlled by the sandbox option
  "Conifers drop cones", on by default.

## Reference

[B42 tree matrix](docs/b42-tree-matrix.md) documents the eleven tree species B42.20 ships,
their size stages, which forage zones grow them and what each one can be propagated from.

## Installation

Copy the `42.20/` folder into your Project Zomboid `mods/EeltsForestryRemastered/`
workshop or local mods directory, then enable "Eelt's Forestry Remastered" from the
in-game mod list.

## License

AGPL-3.0-or-later, see [LICENSE](LICENSE).
