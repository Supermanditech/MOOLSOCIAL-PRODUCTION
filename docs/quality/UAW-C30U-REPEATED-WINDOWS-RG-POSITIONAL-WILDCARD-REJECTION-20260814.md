# UAW C30U repeated Windows rg positional wildcard rejection

Date: 2026-08-14

## Incident

A lookup after cycle-1 attempt 7 repeated the already registered Windows path
error by passing `docs/quality/UAW-C30U*` as a positional ripgrep path. The
command returned nonzero after partial matches and is not accepted as complete
evidence.

## Escalated prevention

Before every multi-path ripgrep invocation on Windows, verify that every
positional path is a literal existing owner or directory. Filename patterns are
allowed only as `--glob` values. Reject a composed command that contains a
positional asterisk before running it.

No source, manifest, release artifact, Google Play state or OPPO state changed.
