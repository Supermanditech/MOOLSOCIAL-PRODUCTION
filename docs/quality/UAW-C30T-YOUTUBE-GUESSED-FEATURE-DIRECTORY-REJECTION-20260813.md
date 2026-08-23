# UAW C30T YouTube guessed-feature-directory rejection — 2026-08-13

## Outcome

The first YouTube source inventory included the nonexistent directory
`apps/mobile/lib/features/youtube`. The current YouTube client/runtime owners
are under `apps/mobile/lib/core/youtube` and the Social UI directory. Ripgrep
returned partial results plus a path error, and the output was also truncated.

The combined result is rejected as incomplete. No state changed.

## Permanent prevention

Discover YouTube source roots from `rg --files apps/mobile/lib` before bounded
queries, use the returned exact directories, and read active router ownership
before classifying similarly named historical/share screens.
