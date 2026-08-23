# UAW C30W scope-transition patch stale assessment literal — 2026-08-14

The first C30W scope transition patch failed `apply_patch` verification before any mutation because one expected C30V selected-assessment sentence was stale.

Recovery is to serialize only the current selected assessment and tail owner subobjects, then apply small independently verifiable patches from exact current literals.
