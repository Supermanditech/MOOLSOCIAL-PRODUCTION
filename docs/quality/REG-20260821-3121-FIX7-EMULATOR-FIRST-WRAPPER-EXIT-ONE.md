# REG-20260821-3121 — FIX7 emulator first wrapper exit one

Date: 21 August 2026
State: registered; first emulator invocation produced no test result

## Failure

The first bounded FIX7 Firestore emulator invocation returned native exit 1,
zero pass/fail summary markers, 86 stdout bytes and zero stderr bytes. The
wrapper intentionally suppressed raw output, so the failure class is not yet
accepted as product-test evidence.

## Impact

- No emulator test result was counted.
- No source, deployment, build, provider, Play, OPPO or private state changed.

## Root cause

The first command boundary did not retain a bounded diagnostic field even
though its output was small, leaving command syntax/startup versus test failure
unclassified.

## Prevention

After registration, replay the exact read-only child once with the already
bounded 86-byte output visible and native exit retained. Classify command,
emulator-start or test failure before changing any source. A corrected test
attempt must again emit only bounded pass/fail/shutdown counts.
