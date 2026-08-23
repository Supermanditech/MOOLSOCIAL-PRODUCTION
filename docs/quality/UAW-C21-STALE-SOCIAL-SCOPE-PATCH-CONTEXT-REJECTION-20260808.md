# C21 stale Social scope patch context rejection — 2026-08-08

The first C21C-to-C21D scope transition patch expected an obsolete generic Social minimum-scope line after the file had already been corrected to the actual Shorts/Videos/Feed/Create wording. `apply_patch` rejected the complete transition atomically; `mvp-scope-gate-state.json` did not change.

Sequential scope transitions use bounded hunks copied from the current file after every intervening correction. A failed atomic patch is registered before retry and cannot count as a selection transition.
