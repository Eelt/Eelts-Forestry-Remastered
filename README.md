# Eelt's Forestry Remastered

A Project Zomboid mod that makes the forests of Knox Country grow, recover and change with the
seasons. It does not edit any of the game's own files.

**Requires Project Zomboid B42.20 or later.**

## What it does

In the base game, forests never change. Wild trees stop growing well before full size, cleared
ground stays bare forever, pine forests fill up with the wrong species, and trees start turning
autumn colours in July. This mod fixes each of those.

### Trees grow

Trees grow through all eight sizes, from sapling to full grown. They keep growing while you are
away, so a wood you come back to after a season has grown in the meantime. Trees that started
at different times end up at different sizes, so a forest has young and old trees in it.

Settings: **Tree growth** chooses which trees grow (all trees by default, only the ones you
plant, or the base game's behaviour). **Tree growth time** sets how long it takes; at 1.0 a
sapling reaches full size in about three in-game months. **Tree growth timing** chooses whether
trees catch up when you arrive or only grow while you are nearby.

### Seasons on Kentucky time

Trees this mod manages come into leaf in late March, stay green through summer, start turning
in mid September and are bare by early November. Each tree turns a little before or after its
neighbours, so a wood changes gradually over a couple of weeks. If you change the season
lengths in the sandbox settings, the cycle stretches to match. Evergreens stay green.

Setting: **Kentucky seasons**, on by default. Turn it off to use the base game's timing.

### Forests have the right species

The first time the mod sees a wild tree, it changes the tree's species to one that suits the
area, so a pine forest is made of pines. The tree keeps its size and its spot, so the forest is
just as thick as before. Areas the mod has no species list for are left alone. From then on,
the mod handles that tree's growth and seasons.

Setting: **Correct forest species**, on by default. Turning it off stops new corrections but
does not undo old ones.

### Cleared ground grows back

Ground cleared by chopping, fire or digging slowly recovers. Grass comes back within about a
week, tall grass, ferns and the odd bush follow over the next few weeks, and the first saplings
appear after about a month. Everything comes back unevenly, so it looks wild, not planted.

Trees that grow back are species that suit the area, with a lean towards the trees already
standing nearby. Each area stops filling in once it reaches its natural density, so deep forest
grows back thicker than farm woodland. Nothing that is already there is removed, and nothing
grows on roads, crops or anything you have built.

Bushes that grow back change with the seasons like the trees do, and flower or fruit when their
species does in Kentucky:

- Piedmont azalea flowers in April.
- New Jersey tea flowers in June.
- Blueberries ripen from mid June through July.
- St. John's wort flowers in July.
- Red chokeberry carries berries from mid September into winter.

You can cut them down with a knife or other cutting tool, the same as any other bush, and pull up
grass by hand. Removing a plant this way counts as clearing the ground, so it starts growing back
from scratch.

Settings: **Vegetation grows back** chooses what recovers (all open ground by default, only
ground you cleared, or off). **Regrowth time** sets how fast. **Regrowth density** sets how
thickly trees come back; at 0, only grass and bushes grow back. **Planted trees spread seed**
chooses whether the trees you planted affect what grows back near them.

### You can plant trees

Carry a shovel, trowel or hand shovel, then either right click the ground and choose a sapling,
pine cone or holly berry under Plant Tree, or right click the sapling, cone or berry in your
inventory. A one square cursor appears: green where a tree can go, red where it cannot. Click
to plant. The cursor stays up until you run out, right click or press Escape, so you can plant a
whole stack one click at a time.

You can plant anywhere you could dig a furrow: grass, forest floor and bare earth, but not sand,
clay, gravel or anything you have built. New trees start at the smallest size.

A sapling, cone or berry dropped by a tree you chopped down grows into the same species, so
chopping a red maple is how you get more red maples. One found while foraging grows whatever
suits the area you plant it in.

Setting: **Planting needs the VHS tape**, off by default. When on, you have to watch the "Home
VHS: Tree Planting Guide" tape first. The base game never spawns this tape, so this mod adds it
as a rare find in houses, sheds, garages and storage units.

### Canadian Hemlock drops pine cones

In the base game, Canadian Hemlock never drops cones. With this mod it drops them the same way
Virginia Pine does: once the tree is about half grown, with bigger trees dropping more.

Setting: **Hemlock drops pine cones**, on by default.

## Performance

Catching trees up and regrowing open ground both run when an area loads. On a low end PC, set
**Tree growth timing** to "Only while the area is loaded" and **Vegetation grows back** to "Only
ground you cleared".

## Documentation

[docs/reference/](docs/reference/) describes what the game and the mod actually do, checked
against B42.20's files: tree species, sizes and drops, where each species grows, and technical
notes on the game's Lua and engine.

[docs/future/](docs/future/) holds design notes and decisions for work that has not shipped yet.

## Installation

Copy the `42.20/` folder into `mods/EeltsForestryRemastered/` in your Project Zomboid mods
directory, then enable "Eelt's Forestry Remastered" in the in-game mod list.

## License

AGPL-3.0-or-later, see [LICENSE](LICENSE).
