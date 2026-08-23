# UAW C33K in-app-browser provider-dialog Cancel dispatch recurrence

Date: 2026-08-15

Regression: `REG-20260815-2524-C33K-IAB-PROVIDER-DIALOG-CANCEL-DISPATCH-RECURRENCE`

## Finding

After authoritative readback proved Email/Password and passwordless Email Link
enabled, the semantic Cancel action for the unchanged read-only edit dialog
failed at coordinate translation. The dialog stayed open, no provider value
changed and the authorized-domain flow did not start.

## Resolution rule

- For this Firebase inline editor, use the fresh visible DOM node for dialog
  actions after any coordinate-backed failure.
- Verify the dialog closed before navigating to another settings panel.
- Never conflate an interaction-layer failure with provider-state failure; the
  successful provider readback remains authoritative.

No domain, Hosting, email, build, Play or device action was performed.

## Resolution

After scrolling the unchanged editor into the visible DOM, exact node `Cancel`
was clicked and a zero-switch readback proved that the dialog closed. The same
fresh-DOM technique also closed the final provider verification dialog without
changing either enabled switch.
