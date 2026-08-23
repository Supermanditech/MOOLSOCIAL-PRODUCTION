# REG2935 — FIX3 default combined OPPO ADB-negative oracle drift

## Observed event

After direct source-attestation suites passed on both PowerShell hosts, the full default PS7 combined gate yielded session `19965` and exited 1 after 33.51 seconds because the OPPO prohibited-ADB-install negative did not reach its old expected fail-closed class.

## Impact

- Direct source-attestation PS7 and WinPS suites are green.
- The full default combined PS7 suite is not qualification evidence; default WinPS was not run.
- No actual exception inspection, oracle edit, retry, cleanup probe, ADB command, install, OPPO action, private/account action, or other external action followed.

## Root cause boundary

Contract v3 authoritative receipt validation changes the preconditions/order for the legacy prohibited-install fixture, so its v2-era mutation or expected class is stale.

## Mandatory prevention

1. Capture only the sanitized actual rejection class and prove the fixture changes only the prohibited-install observation after constructing an otherwise valid authoritative OPPO receipt.
2. Keep install/uninstall/sideload/data-clear counts and authorities zero; do not run real ADB mutation commands.
3. Align one exact deterministic oracle and statically review remaining default combined negatives for v3 validation-order masking.
4. Rerun full default PS7 then WinPS with fixture cleanup and zero real/device/external actions.
