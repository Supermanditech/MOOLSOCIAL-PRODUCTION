# REG-20260821-3057 C34P shared-auth gate stale source-only execution authority

## Observed failure

After authorized ticket lineage was repaired, the shared C34P gate rejected the
current execution vector because it requires build authority to remain false.
The founder has since explicitly advanced to the pre-AAB audit/build stage.

## Root cause

The shared source-contract gate hardcodes the original FIX1A source-only
authority instead of validating authority against the currently selected
authorized descendant ticket and retaining external/private/device boundaries.

## Impact

- the ticket-lineage repair is present but the gate remains unqualified;
- no build, Play, OPPO, provider or device action occurred;
- no shared-gateway pass is claimed.

## Prevention and authorized continuation

Read the exact current execution vector and selected ticket. Preserve required
runtime/test/backend authority and always forbid secret/private and unapproved
external/device actions. Permit build authority only for the explicit current
pre-AAB authorized ticket state; add negative fixtures for unauthorized widening.
