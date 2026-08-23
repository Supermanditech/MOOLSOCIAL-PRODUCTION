# Post-C30B Git long-path status warning reconciliation rejection

- Regression: `REG-20260811-1361-POST-C30B-GIT-LONG-PATH-STATUS-WARNING-RECONCILIATION-REJECTION`
- Date: 2026-08-11
- Failure: ordinary Windows Git traversal could not enumerate long retained browser-profile paths and flooded the bounded result with warnings.
- Prevention: use `git -c core.longpaths=true` per invocation, capture output and errors separately, require no warnings, and seal only the successful inventory.
