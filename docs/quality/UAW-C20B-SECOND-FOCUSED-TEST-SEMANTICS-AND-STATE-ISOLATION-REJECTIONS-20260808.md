# C20B second focused-test semantics and state-isolation rejections

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

## Preserved rejection

The second invocation of
`flutter test test/ui_v2/universal/uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart`
rejected eight cases and passed the session-only disclosure restoration case.
No build, install or OPPO mutation occurred.

The preceding `48.0` geometry assertions passed. Each of the six family cases
then found the exact selected-family Hide semantics label but found no
`SemanticsAction.tap` on the control. The shared action wrapper declared
`button`, `enabled`, `label` and `excludeSemantics`, but did not provide its own
semantic `onTap`; exclusion therefore discarded the InkWell child's tap action.
The overflow cue used the same pattern, and its enclosing semantics container
did not set `explicitChildNodes`, so the exact `Next main actions` node was not
independently discoverable. Visual pointer taps were not missing; the failure
was accessibility action ownership and child-node isolation.

The reduced-motion half reset the static disclosure-session map and pumped a
new widget configuration without first unmounting the existing destination.
Flutter correctly retained the same State, which was already collapsed after
the normal-motion half. The subsequent selected-main tap therefore expanded
the rail to `52.0` rather than collapsing it to `0.0`. Independent motion
scenarios must unmount the prior owner before resetting process-only memory and
remounting.

## Retry rule

No retry is allowed until the semantics and test-isolation failures are
registered. The correction must expose exact tap semantics without adding a
route or another control, and reduced motion must still settle on the first
post-tap frame.
