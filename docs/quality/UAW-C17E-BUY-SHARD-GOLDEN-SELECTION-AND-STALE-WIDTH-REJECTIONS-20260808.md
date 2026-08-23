# C17E Buy shard golden selection and stale-width rejections — 2026-08-08

## Rejected cycle-1 shard

The first C17E Buy shard used the directory operand `test/ui_v2/buy` without filtering its golden-capture owners. The directory contains 18 Dart sources that call `matchesGoldenFile`. Two successor-visible candidate-capture tests rejected the intentional C17 pixels:

- `buy_v2_checkout_cart_return_continuity_test.dart`
- `buy_v2_scoped_cart_checkout_dock_continuity_test.dart`

Those predecessor image comparisons are not authorized for update under C17E. The complete failed shard is not counted.

## Stale C16 width expectations

Two non-golden Buy tests still expected the predecessor four-action cluster width of 304px at a 320px viewport:

- `buy_v2_navigation_motion_test.dart`
- `uaw_personal_mvp_buy_subaction_professional_conformance_c16c_test.dart`

The authorized C17 shared token correctly resolves the four-action cluster to 312px at 320px, preserving 4px insets on both sides and four individual 48px controls. Both tests must consume `MoolLocalNavigationTokens.clusterWidth(actionCount: 4, availableWidth: 320)` rather than duplicate 304.

## Prevention

- C17E Buy runtime shards are built only from verified `*.dart` sources that do not contain `matchesGoldenFile`.
- No predecessor golden is updated or deleted.
- All responsive cluster-width assertions derive from the shared owner token and separately retain no-scroll, no-Expanded, hit-target, semantics, navigation, and overflow checks.
- The static C17C gate rejects a reintroduced literal 304px Buy cluster expectation.

## Inspection working-directory rejection

The first parallel source inspection supplied `test/ui_v2/buy/...` paths while all commands were rooted at the repository rather than `apps/mobile`. The test reads were rejected as missing paths. That result was discarded, no mutation followed from it, and the retry uses exact absolute workspace paths for each source.

## Shared-token API and parallel replay rejection

The first test correction called `MoolLocalNavigationTokens.clusterWidth` with invented named arguments. The real shared API is positional: `clusterWidth(double maxWidth, int actionCount)`. Both focused replays were also launched through a fail-fast parallel aggregate, so the first compilation rejection discarded the sibling command's result from the retained output.

The correction uses the exact existing API `clusterWidth(320, 4)`, updates the static gate to require that expression, and runs each formerly rejected test in its own observable command.
