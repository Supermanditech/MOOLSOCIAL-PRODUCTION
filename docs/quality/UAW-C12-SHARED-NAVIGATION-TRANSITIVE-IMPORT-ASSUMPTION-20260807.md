# C12 shared navigation transitive import assumption

- Regression: `REG-20260807-265-C12-SHARED-NAVIGATION-TRANSITIVE-IMPORT-ASSUMPTION`
- Phase: implementation analysis

The first C12 analyzer run rejected `_familyAccent` because
`mool_global_navigation_v2.dart` referenced `MoolColors.navy` while importing
only `mool_design_system.dart`. Dart imports are not transitive, so the private
import used by the design-system library did not make `MoolColors` visible.

Prevention: shared navigation uses its already established explicit navy
constant for the fallback accent. Every newly referenced symbol must be
visible from a direct import or replaced by an existing public token available
through the file's current imports, and full analysis remains mandatory.
