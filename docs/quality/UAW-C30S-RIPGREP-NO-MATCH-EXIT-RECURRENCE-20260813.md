# C30S ripgrep no-match exit recurrence — 2026-08-13

A narrow read-only `rg` query under `scripts` found no `apksigner`, `aapt2` or `build-tools` references. The expected no-match exit code `1` was not normalized and surfaced as a shell-command failure.

No file, artifact, Google Play state or OPPO state changed. The recurrence is resolved by not retrying the search: the next step uses the exact SDK root declared by `apps/mobile/android/local.properties` and a bounded build-tools directory lookup. Optional future `rg` searches must accept exit code `1` as an empty result.
