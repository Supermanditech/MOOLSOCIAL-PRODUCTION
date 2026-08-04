# R58.8.8 FIX7 category-journey identity harness root cause

- Observed failure: `AUDIT15 requires the checksum-matched R58.8.8 FIX7 OPPO profile.`
- Installed OPPO identity at diagnosis: `versionName=1.0.0-r58.23`, `versionCode=2026080419`.
- Root cause: the FIX7 inner-source correction still rewrote the inherited AUDIT15 version-name assertion to `r58.21`, while all other FIX7 identity fields correctly required `r58.23 (2026080419)`.
- Classification: evidence-harness configuration defect; no application-source regression and no device-install drift.
- Resolution: require `versionName=1.0.0-r58.23` in the generated journey harness, retain the failed run log, parse-check, and rerun into a new immutable output folder.
