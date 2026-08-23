# C17E protected Social golden-suite selection rejection — 2026-08-08

## Rejection

C17E host-cycle shard 1 incorrectly included `test/screen04_social_operational_baseline_test.dart`. That test contains seven `matchesGoldenFile` captures against the preserved predecessor candidate-capture baseline. The authorized C17 clear-glass rail intentionally changes those pixels, and the test ended with seven asynchronous exceptions and exit code 1 after the remaining runtime and fitment coverage continued to pass.

Permanent registry entry `REG-20260807-066-PROTECTED-SOCIAL-GOLDEN-SUITE-SELECTION` already requires protected runtime cycles to exclude every golden owner unless the current ticket explicitly authorizes golden verification. C17 authorizes a later cumulative successor OPPO screenshot matrix, but it does not authorize overwriting or re-accepting predecessor host golden files.

## Prevention

- The failed shard is not counted.
- C17E Universal/Social/Screen04 host shards include the verified non-golden runtime owners only.
- `screen04_social_operational_baseline_test.dart` and all other sources containing `matchesGoldenFile` remain outside countable runtime cycles.
- Accepted predecessor goldens are preserved unchanged; no `--update-goldens` execution is allowed under C17E.

## Unrelated compound inventory rejection

The immediate diagnostic command combined a scoped `git status` with a later ripgrep search using a semicolon. The aggregate returned exit code 1 with empty output, so it could not independently prove either repository status or generated-diff inventory. That compound result is discarded. Each follow-up read must run separately with its own status.
