# UAW C30T Chat router guessed-path rejection — 2026-08-13

## Outcome

The first bounded Chat audit referenced the nonexistent path
`apps/mobile/lib/navigation/journey_router.dart`. The repository-owned router is
`apps/mobile/lib/features/journey01/journey_router.dart`.

The failed query is rejected as incomplete evidence. No product, provider,
device, build, upload, or release state changed.

## Permanent prevention

Discover route-owner files with `rg --files` before a bounded content query and
use only the returned exact path. A partial ripgrep result accompanied by a path
error cannot prove a complete audit result.
