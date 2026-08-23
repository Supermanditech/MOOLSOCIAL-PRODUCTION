# REG2925 — FIX3 journey WinPS precision-negative class drift

## Observed event

After the offset negative was redesigned as a host-invariant raw-wire-only defect, the fresh WinPS fixture advanced past it and then exited 1 because the precision negative did not fail with the expected sanitized class. The fixture used a non-`.fff` timestamp whose runtime grammar validation is host ordered.

## Impact

- The raw-wire redesign is proven to advance on WinPS.
- Checker bytes changed, so PS7 refresh remains pending.
- No later diagnosis, edit, retry, real journey, device, private, build, browser, provider, or external action occurred.

## Root cause

The precision negative still used a semantically/grammatically noncanonical decoded timestamp, allowing WinPS string validation to reject before the intended raw-wire class.

## Mandatory prevention

1. Replace the precision fixture with a semantically canonical decoded `.fffZ` value and a raw-wire-only precision/cardinality defect.
2. Require the same exact sanitized raw-wire rejection class on both hosts.
3. Audit all remaining timestamp negatives for decoded-value invalidity that could mask raw-token validation.
4. Parse and run fresh WinPS, then refresh PS7 because checker bytes changed.
