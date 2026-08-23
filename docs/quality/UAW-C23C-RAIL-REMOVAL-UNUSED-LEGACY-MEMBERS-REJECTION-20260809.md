# C23C unused legacy-member rejection

- Date: 2026-08-09
- Build/device mutation: none

Focused analysis found the old `_globalRailLayerLink` field and
`_toggleLocalNavigation` method became unused after C23C removed the rail render
path. Tests did not run. The correction removes those dead owners, then repeats
format, analysis and the focused C23B/C23C suite.
