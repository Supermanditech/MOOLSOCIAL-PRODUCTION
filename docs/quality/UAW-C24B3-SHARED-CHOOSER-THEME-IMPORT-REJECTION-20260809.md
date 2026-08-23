# C24B3 shared chooser theme import rejection — 2026-08-09

The first affected-source analyzer run rejected the shared chooser move with six errors because `mool_global_navigation_v2.dart` used `MoolColors` without importing `mool_theme.dart`. The source owner had previously needed only design-system symbols, while the moved Home components had both imports in their former file.

The correction is limited to importing the declaring theme owner. The affected-source analyzer and focused connected-navigation tests must pass before C24B3 can qualify.
