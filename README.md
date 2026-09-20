# Eelt's Forestry Remastered

A Project Zomboid mod that makes the forests of Knox Country grow, recover and change with
the seasons, without editing any vanilla files directly.

**Targets Project Zomboid B42.20+.** Earlier B42 builds shipped different item, recipe and
erosion definitions, so this mod's wiring assumes B42.20.

## What it does

The base game's forests are static. Every wild tree is held well below full size and moved
by a single world-wide counter, so two trees of a species are always the same size. A square
that loses its vegetation to an axe or a fire stays bare forever. The species on a square
comes from soil noise rather than from the biome the map was drawn with, so a pine forest
fills up with maples. And foliage takes on autumn colour from the start of July. This mod
replaces each of those with a living version. Everything it adds is layered on top of the
game's own definitions at load time, and vanilla entries are never modified in place.

### Trees grow

A tree the mod has taken over grows on its own elapsed time, one size stage at a time
through all eight, up to the largest. Time counts while you are away: when an area loads,
every tree in it is brought up to the size it has earned, so a wood you come back to after
a season has actually grown in the meantime. Two trees taken over at different moments end
up different sizes, which is how a forest gets an age structure instead of being a field of
identical clones.

Controlled by "Tree growth", which chooses between the base game's behaviour, only trees
you plant, and all trees, with all trees the default; "Tree growth time", where 1.0 is
roughly three in-game months from sapling to full size; and "Tree growth timing", which
either catches a tree up when you arrive or advances it only while the area is loaded.

### Seasons timed for Kentucky

The base game colours trees from around the start of July and leaves them bare from the
middle of autumn. Trees this mod owns follow the year Kentucky actually has. They come into
leaf in late March, are full green from late April through the middle of September, take
their first colour in the second half of September, are at their deepest colour with a
visibly thinning canopy through the middle of October, and are bare by early November. Each
tree runs a little ahead of or behind its neighbours, so a wood turns as a wood over a
couple of weeks rather than flipping overnight, and the same tree keeps its own habit from
one year to the next. Longer or shorter seasons in the sandbox settings stretch the whole
cycle with them. Snow falls on whatever foliage is there, and evergreens are left alone.

Controlled by "Stagger autumn colour", on by default. Turned off, the mod's trees show the
base game's timing instead.

### Forests are made of the right species

The first time the mod sees a wild tree, it redraws that tree's species from what the
square's forage zone naturally grows, keeping the tree's size and its square. No tree is
added or removed and the forest is exactly as dense as it was; it is simply made of the
species its own map intended. A zone the mod has no species recorded for is left as it is.
A corrected square belongs to the mod from then on, which is what lets the mod manage that
tree's growth and seasons: the base game's erosion never takes it back.

Controlled by "Correct forest composition", on by default. Turning it off stops further
correction and does not undo what is already corrected.

### Cleared ground grows back

The base game puts nothing back on a cleared square, so felling a forest is permanent.
Under this mod, ground cleared by an axe, a fire or a player levelling a field recovers in
stages on elapsed world time. At the default pace grass returns within days, tall grass and
ferns and the occasional bush fill in over the following weeks, and the first saplings come
up about a month after clearing. Nothing arranges itself in rows, and squares cross each
rung on different days, so recovered ground reads as wild rather than planted.

What grows back suits the place. Tree species are drawn from the same forage zone weights
that correct wild trees, biased toward the trees already standing nearby so a stand reseeds
as itself. Recovery stops at a crowding ceiling set per zone from a census of the shipped
map, so deep forest recovers denser than a farm woodlot. It never thins an existing stand,
never displaces anything already on a square, and never touches roads, crops or anything
you have built.

Controlled by "Vegetation grows back", which chooses between off, only ground you cleared,
and all open ground including fields that were open when the world began, with all open
ground the default; "Regrowth time"; "Regrowth density", where 0 gives grass and bushes but
no trees; and "Trees you planted as parents", which decides whether trees you planted
influence what seeds in near them.

### You can plant trees

Dig a hole with a shovel, a trowel or a hand shovel, and put a sapling, a pine cone or a
holly berry in it. You can plant anywhere the base game would let you plow a furrow, which
means grass, forest floor and bare earth, but not sand, clay, gravel or anything you have
built on. The tree starts at the smallest size and grows from there. A propagule that fell
from a tree you chopped down remembers which species that tree was and grows into the same
one, so felling a Redmaple is how you get another Redmaple. A foraged one remembers nothing
and grows whatever suits the forage zone you plant it in.

Planting can be gated behind the base game's "Tree Planting Guide" home video, which the
game defines but never spawns, so this mod puts copies of it back into the world. Controlled by "Require 'Tree Planting Guide' VHS for planting", off by default.

### Canadian Hemlock drops pine cones

The base game only gives cones to trees whose sprite name contains "pine", so Hemlock never
drops any despite being a conifer. This mod gives it cones on the same terms as Virginia
Pine, which means from the third growth stage up, with the chance rising as the tree gets
larger. Controlled by "Canadian Hemlock cone drop fix", on by default.

## Performance

Catching trees up on arrival and regrowing every open field both do their work when a
chunk loads. On a low end PC, set "Tree growth timing" to only while the area is loaded
and "Vegetation grows back" to only ground you cleared.

## Documentation

[docs/reference/](docs/reference/) is what the game and the mod actually do, verified
against B42.20's shipped files. It holds the tree matrix, covering the eleven species, their
size stages, which forage zones grow them and what each one can be propagated from, and the
lua and engine notes, covering the 32 bit overflow in the game's `%` operator, sandbox
option handling, the sprite overlay rules and which events fire.

[docs/future/](docs/future/) is design and decision records: the video tape lines
describing mechanics nothing has claimed yet, the seed items the eight deciduous species
would need before they can be grown from anything other than a sapling, and the design work
behind composition correction, seasonal management and vegetation succession, including the
forest audit the species weights come from.

## Installation

Copy the `42.20/` folder into your Project Zomboid `mods/EeltsForestryRemastered/`
workshop or local mods directory, then enable "Eelt's Forestry Remastered" from the
in-game mod list.

## License

AGPL-3.0-or-later, see [LICENSE](LICENSE).
