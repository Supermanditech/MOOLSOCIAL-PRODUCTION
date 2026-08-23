# UAW C33K in-app-browser email-link switch dispatch failure

Date: 2026-08-15

Regression: `REG-20260815-2519-C33K-IAB-EMAIL-LINK-SWITCH-DISPATCH-FAILURE`

## Finding

In Firebase's Email/Password provider dialog, the semantic action selected the
first switch in the unsaved form, but the in-app browser could not dispatch the
second switch click at its translated coordinate. The Save button was not
pressed, so no Firebase provider configuration changed.

## Resolution rule

- Do not blindly repeat the failed coordinate-backed action.
- Inspect the fresh visible DOM, retarget the exact switch node through the DOM
  interaction surface, and verify both switch states and enabled Save state
  before the one authorized submission.
- Count the provider write only after the provider table is re-read and shows
  Email/Password enabled.

No email, Hosting, build, Play or device action was performed.
