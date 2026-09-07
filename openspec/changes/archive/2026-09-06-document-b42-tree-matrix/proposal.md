## Why

The mod's next feature is a player tree planting system, and every part of it depends on
facts about B42.20 that are not written down anywhere: which tree species exist, which
sprite stages each one has, which forage zone a species can naturally spawn in, and which
species have a seed-like item at all. Those facts were established by reading 42.20's own
shipped files, and they contradict the wiki and B41 knowledge in several places. Without a
checked reference the planting work would restate assumptions that are already known to be
wrong, and there is no test suite to catch that later.

Producing the reference first also settles the question the planting design turns on. Of
the eleven species, exactly one drops a seed-like item, so most trees can only be
propagated from a sapling. That has to be a documented, deliberate limitation rather than
something discovered halfway through implementation.

## What Changes

- Add `docs/reference/b42-tree-matrix.md`, a reference document covering the eleven tree species
  B42.20 ships, keyed by their erosion tileset names.
- Record for each species: display name, real-world species, tileset family, evergreen or
  deciduous, which of the eight size stages have sprites, and which propagation items
  exist for it.
- Record the deciduous and coniferous macro categories, and the third case the game
  actually has: American Holly is an evergreen broadleaf, not a conifer, and produces
  berries rather than cones.
- Record the forage zone to worldgen biome mapping from `BiomeMapConfig.lua`, and for each
  forage zone the species its biome may naturally spawn, with the vanilla weights.
- Record the propagation gaps explicitly, since these constrain the planting system:
  no oak tileset exists so `Base.Acorn` is orphaned, `Base.Pinecone` only drops from
  Virginia Pine, and `Base.Sapling` carries no species information.
- Record the two defects in `IsoTree.dropWood`'s cone test as defects rather than as
  intended behaviour, since the mod commits to correcting them behind a setting in a later
  change. Canadian Hemlock is a conifer that never drops a cone because the test is a
  substring match on `pine` rather than a species check, and all four legacy sprite
  fallbacks in the same test are dead because they are written with zero-padded indices
  that do not match any declared sprite name.
- Record the growth-stage findings that make the stock erosion system unsuitable as a
  planting backend, with the specific values and the file each came from.
- Update `README.md` to point at the new document.
- Add a Serena memory pointing at the document so later sessions find it without
  re-deriving it.

Nothing the game loads changes. No file under `42.20/` is touched.

## Non-goals

- The planting system itself. Items, recipes, the growth backend and the context menu are
  a separate change.
- The conifer cone drop fix. The mod commits to correcting Canadian Hemlock and the dead
  legacy sprite fallbacks behind a setting, and this change records that commitment and the
  evidence for it, but implements none of it.
- The VHS gate on `RecMedia["db7deaf2-ddbe-42c8-8fd3-9725d8fdeff3"]`, which is part of that
  same later change.
- Any sandbox or mod configuration option.
- Changing vanilla worldgen, erosion, foraging or item behaviour in any way.
- Documenting bushes, plants, ores or the other erosion categories. Trees only.
- Documenting the legacy `vegetation_trees_01_*` and `jumbo_tree_01*` sprite families
  beyond noting that erosion converts them into the eleven species on load.

## Capabilities

### New Capabilities

None. This change adds a reference document and changes no runtime behaviour, so
`skip_specs: true` is set in `.openspec.yaml`.

### Modified Capabilities

None.

## Impact

New files:

- `docs/reference/b42-tree-matrix.md`
- `.serena/memories/b42_trees.md` (gitignored, local tooling only)

Modified files:

- `README.md`

The document's claims come from these B42.20 files, all read directly from the installed
build at `Project Zomboid.app/Contents/Java/`:

- `zombie/erosion/categories/NatureTrees.class`, decompiled. Species list, evergreen flags,
  stage to tileset mapping, the natural spawn stage cap, the soil to species table.
- `zombie/erosion/ErosionMain.class` and `ErosionConfig.class`, decompiled. The global
  `eTicks` counter, `tickunit` of 144, and the `erosionDays` and erosion speed sandbox
  settings that scale it.
- `zombie/erosion/obj/ErosionObj.class` and `ErosionObjSprites.class`, decompiled. How an
  erosion tree becomes an `IsoTree` and how a stage resolves to a sprite.
- `zombie/iso/objects/IsoTree.class`, decompiled. The `tree` sprite property to size
  mapping, `LOGS_PER_SIZE`, and the `dropWood` drop table including the sprite name
  substring tests that decide acorn, pinecone and holly berry drops.
- `media/tiledefinitions_erosion.tiles.txt`, `media/jumbo_trees.tiles.txt`,
  `media/jumbo_trees_big.tiles.txt`. Tileset names, sheet sizes and the `tree` property
  per sprite.
- `media/lua/server/WorldGen/features/tree/*.lua` and
  `media/lua/server/WorldGen/biomes/{map,worldgen}/*.lua`. Which feature each biome places
  and at what probability.
- `media/lua/server/metazones/BiomeMapConfig.lua`. The forage zone to biome mapping.
- `media/lua/shared/Foraging/forageZones.lua` and `Foraging/Categories/*.lua`. Zone
  definitions and the zone weights for `Base.Pinecone`, `Base.Acorn` and `Base.Sapling`.
- `media/scripts/generated/items/{normal,food,weapon}.txt`. The three propagation item
  definitions.

Version note: the reference build read is the Steam install reporting version `42.20.4`,
revision `b0bbce05d5`. Where a value could plausibly have moved between 42.20.x point
releases it is called out in the document.
