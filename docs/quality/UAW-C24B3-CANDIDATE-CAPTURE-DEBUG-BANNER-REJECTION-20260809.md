# C24B3 candidate capture debug-banner rejection — 2026-08-09

The first OPPO-class connected-navigator PNG is rejected as evidence because its reused test `MaterialApp` retained the default debug banner. The diagonal top-right debug chrome is a harness artifact, not production UI, but an evidence image containing it cannot qualify the design.

The shared test host now disables the debug banner explicitly. The candidate PNG must be regenerated and visually inspected before citation.
