# C24I Android-bounds center string-concatenation rejection

Date: 2026-08-09

The reusable UIAutomator bounds-center helper parsed the verified `Close` node correctly but concatenated its string captures before division. The resulting coordinate was outside the display, so Android performed no in-app action and the profile sheet remained open.

No unrelated control or app state was mutated. The corrected helper casts all four captures to integers before arithmetic, validates the center against the node bounds and 720x1442 display, and confirms the resulting hierarchy transition before any next tap.
