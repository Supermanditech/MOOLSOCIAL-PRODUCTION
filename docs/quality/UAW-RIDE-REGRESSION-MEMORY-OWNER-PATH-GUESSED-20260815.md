# Ride regression-memory owner path was guessed

The first current-memory inspection guessed
`config/codex-regression-memory.json`. That path does not exist, and the
aggregate read failed. No repository file changed in that failed attempt.

REG-2307 records the error. An exact `rg --files` inventory resolved the
durable owner as `config/codex-development-regression-registry.json`. Future
reads use that literal owner and do not aggregate required reads with
unresolved paths.
