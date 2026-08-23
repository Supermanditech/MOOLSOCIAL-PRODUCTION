# C27D stale scope-gate command path rejection

After all C27B/C27C/C27D and C26D/C26E/C26F gates plus permanent regression
memory passed, the combined qualification command called
`scripts/check-mvp-scope-gate.ps1`. That stale filename does not exist; the
durable owner is `scripts/check-mvp-scope-gate-state.ps1`.

Qualification commands must resolve the exact repository path before
invocation. No Flutter source, test result, product behavior or device state
was affected.
