# C30R MVP scope-state reconstructed-context recurrence

Date: 2026-08-12

After registering the first monolithic patch rejection, a second block patch
again used a reconstructed exclusion line rather than the literal raw JSON
text. `apply_patch` rejected the complete patch before modification.

No repository machine state, device, Play, provider, build, upload, install,
runtime, email or quota state changed.

Prevention is strengthened: do not retry a block replacement. Apply only
single-property or single-array patches whose old text is copied directly from
bounded raw-file reads, parse the JSON after every patch group, then run the
manifest, delivery, scope and C30R gates before external action.
