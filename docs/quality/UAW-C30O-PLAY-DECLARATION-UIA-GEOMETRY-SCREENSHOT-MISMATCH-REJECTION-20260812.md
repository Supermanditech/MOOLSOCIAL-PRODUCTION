# C30O Play declaration UIA geometry/screenshot mismatch rejection — 2026-08-12

## Disposition

Rejected declaration input. The Free radio may have been selected; the policy checkbox was not clicked and the form was not submitted.

## Mistake

After scrolling, the programme-policy checkbox was visibly inside the screenshot near the lower viewport, but its accessibility-index click resolved to y=843 outside the height-798 window and was rejected.

## Root cause

Chrome's UIA geometry for the lower declaration control did not match the fresh screenshot's visible position.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Refresh and verify the Free selection.
- Use the fresh screenshot ID with one exact in-bounds checkbox coordinate from the visible square, then refresh immediately.
- Continue with additional scrolling for later declarations; do not reuse the mismatched accessibility geometry.
