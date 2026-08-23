# C24B3 C23F launcher Home-callback rejection

- Date: 2026-08-09
- Branch: `remediation/prototype-conformance-2026-07-20`
- Head: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Registry: `REG-20260809-637-C24B3-C23F-LAUNCHER-TEST-EXPECTED-HOME-CALLBACK`

## Rejection

The final combined C24B3 compatibility cycle passed 21 cases and two retained
evidence skips, then failed the C23F launcher-motion test because it expected
the obsolete `onOpenMool` callback to run once. C24B3 deliberately keeps the
current destination mounted and opens the connected action chooser instead of
returning the customer through Home.

## Root cause

The test's finite press-feedback assertion remained valid, but its post-tap
route expectation still encoded the superseded C23 Home-detour behavior.

## Permanent prevention

The C23F compatibility test continues to prove the finite pressed scale, then
asserts that one tap opens `mool-connected-action-navigator` and that the
retired Home callback remains unused. The focused C24B3 navigator suite remains
the authoritative direct-switching gate.
