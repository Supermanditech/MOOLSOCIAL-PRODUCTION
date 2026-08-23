# Post-C30B filter-sheet Close tap no-state-change rejection

- Regression: `REG-20260811-1363-POST-C30B-FILTER-SHEET-CLOSE-TAP-NO-STATE-CHANGE-REJECTION`
- Date: 2026-08-11
- Failure: ADB reported a successful Close-coordinate input but the filter sheet remained in the fresh hierarchy.
- Prevention: require semantic disappearance after every dismissal and fall back to platform Back only after registration and gate replay.
