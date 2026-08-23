# UAW C33E Social authentication rollback sequential-cleanup escape

Date: 2026-08-15

The local authentication audit found that
`FirebaseSocialAuthGateway.signOut()` awaits Firebase sign-out and only then
awaits native Google sign-out. If the first cleanup throws, the second cleanup
is skipped. This path is used by `JourneySession` after provider identity has
succeeded but authoritative account bootstrap fails.

The existing session regression proves rollback when sign-out succeeds. The
existing Firebase gateway regression proves the successful call order. Neither
proves that both cleanup owners are attempted when one fails, nor that the
original bootstrap recovery, signed-out local state and protected-action return
context remain truthful under cleanup failure.

This is an MVP authentication recovery defect. The bounded repair must attempt
both cleanup owners independently, report cleanup failure without false
success, retain the original bootstrap failure in `JourneySession`, and add a
ticket-specific regression owner. Locked Screen 03 presentation and accepted
tests are excluded. No provider, build, Play, OPPO, credential or external
action is required.
