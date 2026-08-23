# C30U Social owner inventory path-separator false zero

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

A bounded `rg --files` inventory successfully returned 2,710 current mobile
paths, but the exact C30U owner comparison returned zero. Windows emitted
backslash-separated paths while the comparison list used forward slashes. The
result is a false zero-owner diagnostic and authorizes no formatter or test.

## Root cause

The exact-owner comparison did not normalize current inventory paths to one
separator convention before testing membership.

## Prevention

Capture and validate the `rg --files` exit first, normalize every returned path
to forward slashes, then compare it with the exact repository-relative owner
list. Require exactly both C30U Social owners before any formatter, analyzer or
test invocation.

## Release effect

No runtime source changed during this failed inventory. No AAB, upload, Play
activation, installation or OPPO mutation occurred; counts remain zero.

## Bounded retry result

The normalized current-tree inventory passed with 2,710 paths and exactly two
C30U owners:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`
- `apps/mobile/test/ui_v2_social_continuous_batch_test.dart`

The formatter, analyzer and focused tests may use only these resolved literal
owners and remain separate authoritative actions.
