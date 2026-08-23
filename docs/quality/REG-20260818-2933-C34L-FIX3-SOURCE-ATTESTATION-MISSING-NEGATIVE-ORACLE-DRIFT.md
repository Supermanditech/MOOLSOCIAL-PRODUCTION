# REG2933 — FIX3 source-attestation missing-negative oracle drift

## Observed event

After the source-attestation checker was claimed and propagated to capture contract v3, its first direct PS7 suite exited 1 because the legacy `missing` negative rejected outside the checker's old exact expected class. The integrated authoritative-receipt-only PS7 and WinPS suites were already green.

## Impact

- The production receipt-only integration remains green on both hosts.
- The direct source-attestation suite is not qualification evidence yet.
- WinPS direct suite was not run; no observed exception inspection, oracle edit, retry, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause boundary

Contract v3 changes validation order and the mandatory production receipt boundary, while the legacy negative still expects its v2 rejection text.

## Mandatory prevention

1. Capture only the actual sanitized rejection class for the exact missing input fixture.
2. Confirm the fixture removes only its intended required v3 receipt/binding field and preserves every earlier invariant.
3. Align the oracle to the deterministic v3 class; do not accept arbitrary failure.
4. Review all remaining direct-suite negatives for validation-order masking against the v3 schema.
5. Parse, rerun fresh direct PS7 then WinPS, followed by default combined PS7/WinPS; verify cleanup and zero real actions.
