# Propagule items for the deciduous species

Design record for items that do not exist yet. **Nothing here is implemented.** It was
written down so the shape of the work is known when it is picked up, and so that
`add-tree-planting` could be scoped around it rather than into it, which is what happened:
planting shipped on the sapling, the cone and the berry.

Everything about vanilla behaviour that this leans on is in
[b42-tree-matrix.md](../reference/b42-tree-matrix.md), chiefly the
[per-species propagule check](../reference/b42-tree-matrix.md#per-species-propagule-check) and
[what chopping a tree yields](../reference/b42-tree-matrix.md#what-chopping-a-tree-yields). Vanilla file
paths below are relative to `Project Zomboid.app/Contents/Java/media/` on the Steam install
reporting version `42.20.4`, revision `b0bbce05d5`.

## Why it is out of scope

Nine of the eleven species have no propagule item in B42.20. Two of those nine are covered
without new art: Virginia Pine has `Base.Pinecone`, and Canadian Hemlock now drops the same
cone behind `EeltsForestryRemastered.FixConiferConeDrops`. American Holly has
`Base.HollyBerry`. That leaves the eight deciduous broadleaves with nothing.

Growing those eight from seed needs eight new items to exist first, and an item is not a
script block on its own. It needs an inventory icon, a world model, and a model definition
before it can be dropped on the ground. That is art work with a binary asset pipeline and
Git LFS behind it, and it has no bearing on whether planting works. Planting ships first
using the sapling graft, which already covers all eleven species, plus the cone and the
berry for the two species that have one.

## What one propagule item costs

Taken from how vanilla defines the three items this mod already relies on.

`Base.Pinecone`, in `scripts/generated/items/normal.txt`:

```
item Pinecone
{
    DisplayCategory = Junk,
    ItemType = base:normal,
    Weight = 0.1,
    Icon = Pinecone,
    WorldStaticModel = PineCone,
    Tags = base:isfirefuel;base:isfiretinder,
}
```

`WorldStaticModel` names a model block, not a mesh. `PineCone` resolves in
`scripts/generated/models_items.txt`:

```
model PineCone
{
    mesh = WorldItems/PineCone,
    texture = WorldItems/PineCone,
    scale = 0.6,
}
```

So each item needs four things, of which three are assets:

| Piece | Where it lives | New per item |
|---|---|---|
| Item block | mod `media/scripts/` | yes |
| Model block | mod `media/scripts/` | yes |
| Mesh | `media/models_X/WorldItems/<name>.fbx` | only if no vanilla mesh fits |
| Mesh texture | `media/textures/WorldItems/<name>.png` | only if no vanilla mesh fits |
| Inventory icon | `media/textures/Item_<Icon>.png` | yes, every item |

Eight species with fully bespoke art is 24 binary files. Eight species reusing vanilla
meshes is 8, one icon each.

## The matrix

Proposed ids carry the `Eelt_` prefix and are declared into `module Base`, which adds
entries rather than touching a vanilla one. Display names reproduce the tree's own
`getName()` so a player can connect item to tree, which means `Riverbirch` and `Redmaple`
stay unspaced the way vanilla writes them.

| # | Species | Real propagule | Proposed item | Display name |
|---|---|---|---|---|
| 3 | Riverbirch | Winged samaras in a strobile | `Base.Eelt_BirchStrobile` | Riverbirch Catkin |
| 4 | Cockspur Hawthorn | Pome, a haw | `Base.Eelt_Haw` | Hawthorn Haw |
| 5 | Dogwood | Red drupe | `Base.Eelt_DogwoodDrupe` | Dogwood Berry |
| 6 | Carolina Silverbell | Four-winged dry drupe | `Base.Eelt_SilverbellDrupe` | Silverbell Drupe |
| 7 | Yellowwood | Legume pod | `Base.Eelt_YellowwoodPod` | Yellowwood Seed Pod |
| 8 | Eastern Redbud | Legume pod | `Base.Eelt_RedbudPod` | Redbud Seed Pod |
| 9 | Redmaple | Paired samara | `Base.Eelt_MapleSamara` | Redmaple Samara |
| 10 | American Linden | Nutlet on a papery bract | `Base.Eelt_LindenNutlet` | American Linden Nutlet |

The index column is the `NatureTrees` array position, so it lines up with the species table
in the tree matrix. Species 0, 1 and 2 are absent because Holly, Hemlock and Pine are
already served.

### Art, and what vanilla can cover

Three of the eight can take an existing mesh with no new modelling. The rest cannot.

| Item | Mesh | Source |
|---|---|---|
| `Eelt_BirchStrobile` | `WorldItems/PineCone` | Reuse. A birch strobile is cone shaped and reads correctly at item scale |
| `Eelt_Haw` | `WorldItems/BerryGeneric` | Reuse, with `BerriesGeneric*` textures for the red |
| `Eelt_DogwoodDrupe` | `WorldItems/BerryGeneric` | Reuse, same family as the haw |
| `Eelt_LindenNutlet` | `WorldItems/Acorn` | Reuse, a nutlet is a small hard nut. The papery bract is lost |
| `Eelt_YellowwoodPod` | `WorldItems/CoffeetreePod` | Reuse, see below |
| `Eelt_RedbudPod` | `WorldItems/CoffeetreePod` | Reuse, see below |
| `Eelt_SilverbellDrupe` | none | New mesh. A four-winged dry drupe has no vanilla analogue |
| `Eelt_MapleSamara` | none | New mesh. Nothing winged exists anywhere in `WorldItems/` |

`CoffeetreePod.fbx` and `textures/WorldItems/CoffeetreePod.png` both ship in B42.20 and are
referenced by no model block and no item. Kentucky coffeetree, *Gymnocladus dioicus*, is a
legume, so the mesh is already the right shape for both Redbud and Yellowwood. Using it
means declaring a new model block that points at the vanilla mesh, which adds an entry
rather than editing one.

Every item still needs its own inventory icon regardless, so the floor is eight icons, and
two meshes on top of that.

## Ripening and dormancy

Real behaviour, which maps onto two mechanics the mod already has a use for: a seasonal drop
gate, of the kind vanilla already applies to `Base.HollyBerry`, and a germination time.

| Item | Ripens | Persists | Germination |
|---|---|---|---|
| `Eelt_MapleSamara` | 4 to 6 | no | Immediate, no dormancy |
| `Eelt_BirchStrobile` | 5 to 6 | no | Immediate, little to no dormancy |
| `Eelt_DogwoodDrupe` | 9 to 10 | no | One season, cold stratification |
| `Eelt_YellowwoodPod` | 9 to 10 | no | One season, hard seed coat needs scarifying |
| `Eelt_RedbudPod` | 8 to 10 | into winter | One season, scarify then cold stratify |
| `Eelt_SilverbellDrupe` | 9 to 10 | yes | Multi-year, warm then cold stratification |
| `Eelt_Haw` | 9 to 10 | into winter | Multi-year, one to three years |
| `Eelt_LindenNutlet` | 9 to 10 | into winter | Multi-year, deep double dormancy |

Months are game month numbers. Red maple and river birch are the outliers and are worth
keeping as such: both ripen and drop in late spring, and both germinate on the spot with no
dormancy at all, while everything else is an autumn seed that has to overwinter.

That spread supports the split already recorded in the tree matrix, where the sapling graft
is the fast route and seed is the slow one. It also means the tiers are not invented for
game balance. Holly sits in the multi-year tier on the same grounds as hawthorn and linden.

## How a drop would be wired

The existing drop wrapper is the pattern. `IsoTree.dropWood` is Java and cannot be extended,
so `EeltsForestryRemastered_TreeDrops.lua` wraps `ISChopTreeAction:animEvent`, reads the
species, square and log yield before the tree topples and is pooled, and both adds items and
stamps the ones vanilla added afterwards.

Two constraints carry over unchanged. Species is identified by the sprite tileset prefix,
since `IsoObject:getName()` is the display name and the tileset is what actually says what
the tree is. And nothing below a log yield of 3, which is stage 3, can drop a species item
in vanilla, because the cone, acorn and berry lines all sit inside the `numPlanks > 2`
block. A deciduous propagule that wants to match vanilla's feel should respect the same
gate. Whether it should is a design question and not settled here.

Trees felled by a vehicle or by fire do not route through the chopping action and would
stay uncorrected, exactly as they are for the Hemlock cone today.

## Open questions

- **The acorn.** `Base.Acorn` matches no living tree and grows nothing. Folding it in as one
  of these eight, most plausibly as a stand-in rather than a botanically correct fit, is one
  of the three options in the tree matrix. Adding real propagules weakens the case for it,
  because the reason to reuse the acorn was that nothing else existed.
- **Foraging.** Cones, acorns and saplings are all forageable, with no relationship to the
  species actually growing in the zone. Whether these eight join the foraging tables, and
  whether they respect the ripening months above when they do, is unresolved.
- **Item category.** `Base.Pinecone` is Junk with fire tags, `Base.HollyBerry` is Food with
  a full evolved recipe list. The eight are edible in varying degrees and mostly not
  pleasantly, so a plain Junk item is the safer default, with anything edible handled per
  species rather than as a rule.
- **Hemlock.** Canadian Hemlock bears a small seed cone, not a pine cone, and currently uses
  `Base.Pinecone`. An `Eelt_HemlockCone` would be more correct and is the lowest priority
  item on this page, since the shared cone already works.

## Unverified

- That a mod supplies inventory icons as loose `Item_<name>.png` files under
  `media/textures/`. Vanilla's own icons ship inside the `.pack` texture packs, so the loose
  path has not been confirmed against a running game here.
- That a mod model block may name a mesh under `WorldItems/` that no vanilla model block
  references. The `CoffeetreePod` files exist and are unreferenced, which is what makes the
  reuse attractive, but nothing has loaded them yet.
