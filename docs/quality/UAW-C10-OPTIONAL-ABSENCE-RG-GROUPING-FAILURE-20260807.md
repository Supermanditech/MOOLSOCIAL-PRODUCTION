# UAW C10 optional absence rg grouping failure

## Incident

A required search for `MvpActionChoiceRootV2` constructors and an optional
absence probe for retired navigation owners were placed in one shell command.
The constructor search matched, while the clean absence probe returned normal
`rg` exit 1. The grouped command was therefore reported as failed and all of
its output was discarded.

## Prevention

Required-presence and optional-absence searches run separately. Absence probes
map exit 0 to surviving matches, exit 1 to verified no matches, and reject only
exit greater than 1. Partial output from a grouped command is never reused.

No product, build or OPPO state changed during this read-only verification.
