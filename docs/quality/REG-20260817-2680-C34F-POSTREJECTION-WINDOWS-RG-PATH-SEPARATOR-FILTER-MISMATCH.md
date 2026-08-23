# REG2680 — Windows `rg --files` path separator mismatch

## Outcome

The bounded resolver for the active handoff and regression memory rejected valid Windows backslash paths because its filter accepted only forward slashes. No path-resolution result from that command is counted.

## Prevention

Use a separator-tolerant filter, require each exact filename once, then read the exact owners separately. This record does not change the rejected C34F lifecycle or create successor, build, Play or device authority.
