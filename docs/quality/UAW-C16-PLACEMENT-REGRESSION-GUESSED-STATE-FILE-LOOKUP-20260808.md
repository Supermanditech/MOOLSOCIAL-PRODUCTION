# C16 placement-regression guessed state-file lookup

During C16 placement-gate reconciliation, a command tried to read
`config/personal-subaction-placement-regression-state.json`. That filename was
inferred and does not exist. The authoritative checker already declares its
real machine contract as
`config/mvp-personal-subaction-reachability-promotion-zone-regression.json`.

The correction follows that exact checker-owned path. Any additional bounded
config discovery uses `rg --files`; no companion state filename is guessed.
