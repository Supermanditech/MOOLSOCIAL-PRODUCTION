# REG-20260821-3058 C34P shared-auth gate pass stale external-writes-zero claim

## Observed failure

The repaired shared gate passed its assertions but the final message still
emitted `externalWrites=0`. Under FIX5, controlled external provider writes were
authorized and occurred earlier, so that message is not accepted as evidence.

## Root cause

The final output retained an original FIX1A action-history claim even though the
gate now validates FIX5 authority and does not inspect action-count history.

## Impact

- source assertions passed, but the overall result is rejected as semantically
  false evidence;
- no build, Play, OPPO, provider or device action occurred in this run.

## Prevention and authorized continuation

A source gate may report only facts it checks. Replace the action-history claim
with the selected external-authority boolean, then require identical truthful
PowerShell 7 and Windows PowerShell 5.1 output.
