# C26H machine-state patch malformed escaped-minus rejection

The first C26H APK machine-state authorization patch contained an escaped minus marker before one existing evidence line. `apply_patch` could not match the JSON and rejected the entire mutation before any machine authority changed.

The retry is split into bounded top-level sections. Each section is applied separately and JSON-validated before the next. This preserves the exact one-build authorization boundary.
