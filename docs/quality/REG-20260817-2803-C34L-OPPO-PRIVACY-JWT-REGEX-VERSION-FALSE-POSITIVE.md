# REG2803 — C34L OPPO privacy JWT regex version false positive

Date: 17 August 2026
State: registered first PS7 fixture rejection; zero real or external action

## Mistake

The first fresh PS7 OPPO evidence-transaction checker rejected its valid
fixture before the `before-journal` crash injection because the privacy scan's
broad unanchored three-segment JWT regex matched the allowed version name
`1.0.0-r60.76`. Fixture cleanup completed; only the unique temporary fixture
root was touched and no real or external action occurred.

## Prevention

Make JWT/token detection field-aware and require an anchored, plausible
base64url JWT shape and length. Preserve exact-schema and explicit private-value
negative fixtures while proving canonical public version/package identifiers
remain allowed.
