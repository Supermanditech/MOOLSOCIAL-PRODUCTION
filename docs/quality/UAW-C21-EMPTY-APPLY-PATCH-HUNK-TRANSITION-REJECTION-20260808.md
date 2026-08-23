# C21 empty apply-patch hunk transition rejection — 2026-08-08

The combined C21A completion/C21B selection patch contained an extra empty `@@` update hunk. `apply_patch` rejected the complete patch atomically; no completion document, manifest or runtime file changed.

Transition patches must be split into bounded additions and updates, with every hunk containing explicit context and additions/removals. Each result is parsed before the next state transition.
