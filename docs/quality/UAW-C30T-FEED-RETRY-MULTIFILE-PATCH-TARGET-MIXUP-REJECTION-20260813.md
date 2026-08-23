# C30T Feed retry multi-file patch target-mix-up rejection — 2026-08-13

## Rejection

A combined session/UI/test patch accidentally placed a test-context line under
the Social consumer file section. Apply-patch could not find that line and
rejected the full operation atomically.

No source, test, machine state, backend, device, release or external state
changed.

## Permanent prevention

Cross-layer Feed corrections now use one owner file per patch. Session, visible
UI and tests are applied and verified separately with exact current context.
