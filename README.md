# Eelt's Forestry Remastered

A Project Zomboid mod that overhauls forestry, without editing any vanilla files
directly.

**Targets Project Zomboid B42.20+.** Earlier B42 builds shipped different item and
recipe definitions, so this mod's wiring assumes B42.20.

## What it does

Everything the mod adds is layered on top of the game's own definitions at load time, so
vanilla entries are never modified in place.

- **Trees grow.** The base game caps naturally spawned trees well below full size and
  drives their growth from a single world-wide counter, so forests never mature. This mod
  grows a tree on its own elapsed time through all eight sizes, up to the largest. Adopted
  trees also stay green through July instead of taking on autumn colour in high summer, and
  turn once autumn actually begins. Controlled by the sandbox options "Tree growth", set to
  all trees by default, and "Tree growth time", where 1.0 is roughly three in-game months
  from sapling to full size.
- **You can plant trees.** Dig a hole with a shovel, a trowel or a hand shovel, and put a
  sapling, a pine cone or a holly berry in it. You can plant anywhere the base game would let
  you plow a furrow, which means grass, forest floor and bare earth, but not sand, clay,
  gravel or anything you have built on. The tree starts at the smallest size and grows from
  there. A propagule that fell from a tree you chopped down
  remembers which species that tree was and grows into the same one, so felling a Redmaple
  is how you get another Redmaple. A foraged one remembers nothing and grows whatever suits
  the forage zone you plant it in. Planting has to be learned from the base game's "Tree
  Planting Guide" home video, which the game defines but never spawns, so this mod puts
  copies of it back into the world. Controlled by the sandbox option "Require 'Tree
  Planting Guide' for planting", on by default.
- **Canadian Hemlock drops pine cones.** The base game only gives cones to trees whose
  sprite name contains "pine", so Hemlock never drops any despite being a conifer. This mod
  gives it cones on the same terms as Virginia Pine, which means from the third growth stage
  up, with the chance rising as the tree gets larger. Controlled by the sandbox option
  "Canadian Hemlock cone drop fix", on by default.

## Documentation

[docs/reference/](docs/reference/) is what the game and the mod actually do, verified
against B42.20's shipped files. It holds the tree matrix, covering the eleven species, their
size stages, which forage zones grow them and what each one can be propagated from, and the
lua and engine notes, covering the 32 bit overflow in the game's `%` operator, sandbox
option handling and which events fire.

[docs/future/](docs/future/) is design for work that is not implemented: the video tape
lines describing mechanics nothing has claimed yet, and the seed items the eight deciduous
species would need before they can be grown from anything other than a sapling.

## Installation

Copy the `42.20/` folder into your Project Zomboid `mods/EeltsForestryRemastered/`
workshop or local mods directory, then enable "Eelt's Forestry Remastered" from the
in-game mod list.

## License

AGPL-3.0-or-later, see [LICENSE](LICENSE).
