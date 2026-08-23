# C16 regression-registry guessed-path lookup failure

## Incident

While registering the predecessor-capture incident, a read-only command guessed
`config/regression-test-registry.json`. That file does not exist; the durable
owner is `config/codex-development-regression-registry.json`. The failed read
produced no mutation and its output was discarded.

## Root cause and prevention

The registry basename was recalled instead of resolved from the repository.
Future regression registration uses the already reconciled durable owner path,
or performs an exact workspace-bounded filename discovery before the first
read. A failed guessed path is not retried until the authoritative owner has
been discovered.
