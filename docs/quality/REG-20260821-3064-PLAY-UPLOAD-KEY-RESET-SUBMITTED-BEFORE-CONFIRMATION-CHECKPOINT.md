# REG-20260821-3064 Play upload-key reset submitted before confirmation checkpoint

## Observed failure

The founder accidentally pressed the final Play upload-key reset request before
the planned action-time confirmation checkpoint. Play now reports one pending
reset request. No cancellation or second request was attempted.

## Root cause

The browser workflow placed the final request control within the same task flow
as certificate upload, and the manual stop boundary was crossed accidentally.

## Impact

- one external Play upload-key reset request is pending;
- the new private key remains local and only its public PEM was intended for
  submission;
- no AAB build/upload, production rollout, OPPO mutation or repository Git
  action occurred;
- new-key AAB upload remains blocked until Play approves the reset.

## Prevention and continuation

Do not cancel or duplicate the request unless Play identifies the submitted
certificate as wrong. Wait for the authoritative Play/email outcome. Future
irreversible browser steps require a separate screen/turn after form preparation
and an explicit final-action marker.
