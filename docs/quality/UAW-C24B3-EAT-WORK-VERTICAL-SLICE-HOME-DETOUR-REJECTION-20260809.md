# C24B3 Eat/Work vertical-slice Home-detour rejection — 2026-08-09

The combined Social, Eat, Ride, Book and Work feature batch passed 54 tests and failed two navigation assertions. Eat and Work still expected the old Home route after tapping the launcher and then used `mool-home-eat-table` / `mool-home-work-workspace`.

Both journeys now prove the current feature remains mounted under the connected chooser and route through `mool-navigator-eat-table` / `mool-navigator-work-workspace`. Ride, Book and Social required no navigation expectation change.
