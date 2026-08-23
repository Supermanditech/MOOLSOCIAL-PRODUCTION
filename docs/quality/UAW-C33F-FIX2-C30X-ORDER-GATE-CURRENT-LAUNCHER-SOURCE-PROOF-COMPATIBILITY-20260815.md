# UAW C33F FIX2 C30X order-gate current-launcher compatibility

Date: 2026-08-15

## Finding

The preserved C30X preflight-order gate requires the historical
`sourceReleaseControlsPassed` launcher literal. The current C33F launcher uses
the stronger exact two-cycle and whole-mobile-analyzer facts instead, so the
preserved gate rejects before the current gate can be counted.

## Authorized repair

Keep the historical proof valid, add only the exact current source-proof form,
and continue rejecting any launcher dependency on the wrapper-owned generated
`releasePreflightPassed` result. Source must be resealed and both full cycles
must restart after this change.
