# C25F Screen04 owner-key assumption rejection

Date: 2026-08-09

## Observed rejection

The bounded Screen04 conformance rerun passed 23 of 26 cases. The three
failures all requested `social-local-shorts`, `social-local-feed` or
`social-local-videos`. Those keys belong to the real Social destination. The
retained Screen04 compatibility rail truthfully owns the same four direct
actions under `screen04-rail-*` keys.

## Corrective boundary

- Preserve Screen04 runtime, Social media/business behavior and action IDs.
- Correct only the compatibility test finders to its actual key namespace.
- Rerun the complete 26-case file, then regenerate and verify the protected
  Social successor seal before resolving this regression.

No build, install or runtime-device authority was opened.
