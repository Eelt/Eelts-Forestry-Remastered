## REMOVED Requirements

### Requirement: Seasonal appearance is maintained independently of growth

**Reason**: Moved to the `tree-seasons` capability. This capability governs the eight size
stages and what controls their pace and ceiling, and seasonal appearance was only put here
because the code that drives it lives alongside the growth system. Keeping it here would have
meant a whole-year foliage cycle growing inside a capability about size.

**Migration**: The requirement is carried into `tree-seasons` unchanged apart from an added
statement that evergreens are left alone, which was already true. No behaviour changes and no
setting is renamed.

### Requirement: A setting controls which seasonal rule is used

**Reason**: Moved to the `tree-seasons` capability, for the same reason as above. The setting
itself, `EeltsForestryRemastered.StaggerTreeSeasons`, is unchanged.

**Migration**: The requirement is carried into `tree-seasons`. Its description of the rule when
the setting is on is replaced by the new whole-year requirements there; its description of the
rule when the setting is off is carried over word for word, because the base game's own timing
is not changing.
