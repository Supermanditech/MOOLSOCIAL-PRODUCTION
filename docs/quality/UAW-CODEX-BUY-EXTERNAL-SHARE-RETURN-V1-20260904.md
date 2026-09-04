# Android external-share return

Ticket: `UAW-CODEX-BUY-EXTERNAL-SHARE-RETURN-V1-20260904`

Defect: `UAT-BUY-021`

Baseline: `f94cfd4752dd73b58a69568475803d6cf25cb8d0`

## Outcome

Opening an Android share destination keeps MoolSocial in its own task so cancelling or finishing Gmail, WhatsApp or another destination returns to the exact preserved in-app screen.

## Scope

- Keep the accepted `share_plus` Dart API and all Buy call sites unchanged.
- Route the existing Android share channel through the app host and launch its text or link chooser in a separate task.
- Preserve the existing MoolSocial activity launch mode, task affinity, deep links and process-restoration behavior.
- Verify the native source contract, Android compilation and existing Buy product-action regressions.

## Exclusions

- No Buy catalogue, cart, checkout, order or product-view source edit.
- No backend, payment, authentication or customer-data change.
- No deployment or production-package action.
