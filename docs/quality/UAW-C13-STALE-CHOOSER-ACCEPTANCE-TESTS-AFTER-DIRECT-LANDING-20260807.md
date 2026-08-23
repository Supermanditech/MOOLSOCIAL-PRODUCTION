# C13 stale chooser acceptance tests after direct landing

Date: 2026-08-07

Regression:
`REG-20260807-273-C13-STALE-CHOOSER-ACCEPTANCE-TESTS-AFTER-DIRECT-LANDING`

## Failure

The first six-file connected C13 navigation batch ended with 15 failures after
52 passes. The visible failures mounted `/app/eat`, `/app/ride`, `/app/book`
or `/app/work`, then tried to tap `mvp-action-choice-*`. C13 correctly resolved
those retired roots directly to their default family owner, so the obsolete
chooser keys were absent. The dedicated C13 eleven-case one-tap and stale-root
suite still passed in the same batch.

## Root cause and prevention

The production route contract was updated before inherited FIX2 tests were
migrated from the superseded chooser acceptance model. Tests that exercise
retired production roots must now assert the first default family owner and
use its local rail for a non-default choice. Component-only chooser tests may
remain solely for the explicit legacy-test boundary, but can never establish
production navigation acceptance.

The corrected connected batch must restart in full; a reduced failure count or
the passing C13 file alone cannot seal host qualification.
