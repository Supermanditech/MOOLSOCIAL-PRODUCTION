# C16A repository-gate working-directory path mismatch

## Incident

The first C16A compile fix had not yet been retested when a compound retry was
launched from `apps/mobile` while using repository-root-relative registry and
PowerShell gate paths. Those paths were not found and Flutter never launched.
No test result is claimed and no device, build or runtime state changed.

## Root cause and prevention

Two different path owners were combined under one working directory. C16 runs
repository governance from the production-repository root and Flutter commands
from `apps/mobile` in separate command boundaries. Relative paths are never
silently reinterpreted across those boundaries.
