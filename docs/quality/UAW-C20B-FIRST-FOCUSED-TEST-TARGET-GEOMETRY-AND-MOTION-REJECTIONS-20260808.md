# C20B first focused-test target geometry and motion rejections

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

## Preserved rejection

The first focused C20B widget-test invocation was:

`flutter test test/ui_v2/universal/uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart`

It rejected eight cases and passed the session-only disclosure restoration
case. No build, install or OPPO mutation occurred.

Six family cases measured the keyed selected main-action control at `46.0`
logical pixels high instead of the ticket-locked `48.0`. The overflow case
also measured the reserved next-control region at `46.0`. Source inspection
then found that the outer dock is exactly `48.0`, while the one-pixel
`BoxDecoration` border owned by `MoolGlassSurface` contributes decoration
padding on both vertical edges and therefore constrains its child to `46.0`.
The successor must paint this dock border without deflating the child. The
outer rail height, position, order and meaning remain unchanged.

The normal-motion case tapped the selected main action and immediately pumped
`80ms`. That pump established the first animation frame; it did not establish
a frame and then advance the controller. The disclosure region therefore
truthfully remained at its initial `52.0` height in that sampled frame. The
focused test must first pump the state-change frame, then advance `80ms`, while
still proving a finite midpoint and zero-height completion. Reduced motion
continues to require immediate settlement.

## Retry rule

No focused retry is allowed until both failures are registered in the
permanent regression registry. The correction must preserve the fixed outer
global rail geometry and may not authorize an APK build or device install.
