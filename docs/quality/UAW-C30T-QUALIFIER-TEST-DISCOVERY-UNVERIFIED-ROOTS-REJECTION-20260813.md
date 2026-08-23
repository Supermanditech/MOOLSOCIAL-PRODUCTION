# C30T qualifier test-discovery unverified-roots rejection — 2026-08-13

## Rejection

A bounded discovery command passed guessed root-level `test` and `tests`
directories to `rg --files`. Those roots were not first proven to exist, so the
command exited without a useful inventory.

## Prevention

Further qualifier-test discovery uses only exact verified repository paths. An
empty pattern result is distinguished from invalid search roots before any
retry. No source, provider, build, Play, OPPO, Hosting or communication state
was changed by the rejected read-only command.
