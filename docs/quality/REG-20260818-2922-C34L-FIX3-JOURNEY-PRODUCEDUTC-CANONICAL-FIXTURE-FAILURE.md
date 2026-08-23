# REG2922 — FIX3 journey producedUtc canonical fixture failure

## Observed event

After the journey adapter and fixture checker parsed successfully, the first fresh direct PowerShell 7 fixture exited 1 at the adapter with the sanitized class `gate producedUtc publicGuest must be one canonical UTC value.`

## Impact

- The REG2915 directory-resolver correction remains applied and parsed.
- Windows PowerShell was not run.
- No later diagnostic, correction, retry, real journey, device, private, build, browser, provider, or external action occurred.

## Root cause boundary

The positive fixture's UTC wire/runtime representation did not satisfy the adapter's canonical timestamp validator. The exact source of the mismatch was intentionally not diagnosed before registration.

## Mandatory prevention

1. After registration, inspect only the positive fixture's sanitized timestamp type, exact raw token cardinality, and validator grammar.
2. Preserve canonical raw `.fffZ` wire spelling and normalize PS7/Windows PowerShell DateTime/string runtime shapes for semantic comparison.
3. Add offset, precision, duplicate-token, stale, and replay negatives without weakening the exact wire contract.
4. Rerun one fresh PS7 fixture before the independent Windows PowerShell fixture.
