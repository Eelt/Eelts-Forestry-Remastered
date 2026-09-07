# Documentation

Two folders, split by whether the thing described exists.

## `reference/`

What Project Zomboid B42.20 and this mod actually do, verified against the shipped game
files or observed in game. Anything stated here should be checkable, and a version bump
means walking it again.

- [b42-tree-matrix.md](reference/b42-tree-matrix.md) covers the eleven tree species, their
  size stages, which forage zones grow them and what each one can be propagated from.
- [b42-lua-notes.md](reference/b42-lua-notes.md) collects engine-level findings that cost
  real debugging time: the 32 bit overflow in the game's `%` operator, sandbox option
  handling, which events do and do not fire, and the sprite overlay rules.

## `future/`

Design for work that is not implemented, and decisions settled ahead of the change that
will use them. Nothing here describes shipped behaviour, and none of it is a commitment
to build the thing.

- [carried-forward.md](future/carried-forward.md) holds the decisions taken while the
  reference documents were written, plus the VHS tape lines that are still unclaimed.
- [propagule-items.md](future/propagule-items.md) is the item by item design for the seed
  items the eight deciduous species would need, with the art each one costs.

## Which folder

If it is implemented or it is vanilla, it is reference. If it is planned, speculative or
a design record, it is future. A document that starts in `future/` and then ships should
move, with the parts that are now true rewritten as description rather than intent.
