# C30O Play Chrome exact-handle off-monitor capture recurrence rejection — 2026-08-12

## Disposition

Rejected read-only capture. The Play form is not interpreted from this result and no input was dispatched.

## Mistake

Rehydrating and activating the previously exact Chrome window id still produced an off-monitor crop capture failure.

## Root cause

The prior Chrome binding was no longer sufficient after desktop focus and window state changed, even though `get_window` returned without error.

## Prevention before retry

- Pass the permanent regression-memory gate.
- List current windows without screenshots.
- Select the live Chrome window whose title matches the Play form.
- Activate that returned binding before requesting a fresh screenshot.
