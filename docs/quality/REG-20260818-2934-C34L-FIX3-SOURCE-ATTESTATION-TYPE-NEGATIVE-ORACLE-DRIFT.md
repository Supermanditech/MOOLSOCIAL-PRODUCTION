# REG2934 — FIX3 source-attestation type-negative oracle drift

## Observed event

After the v3 `missing` negative was aligned, the next direct PS7 source-attestation run exited 1 because the legacy `type` negative rejected outside its exact expected class.

## Impact

- The corrected missing negative advanced.
- WinPS and default combined suites were not run.
- No actual type rejection inspection, later-negative edit, retry, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause

Multiple v2-era direct-fixture oracles remain coupled to old validation order after contract v3 introduced mandatory authoritative receipt/type bindings.

## Mandatory prevention

1. Capture only the sanitized actual class for the exact type fixture and confirm it changes only the intended evidence type/receipt binding.
2. Before another behavior run, statically inventory every remaining negative label, mutation, and expected class against v3 validation order.
3. Separate mutations so each fixture preserves all earlier v3 invariants and reaches its intended validator.
4. Keep exact-class assertions; never weaken to `any rejection`.
5. Parse, run direct PS7 then WinPS, then default combined PS7/WinPS with cleanup and zero-action proof.
