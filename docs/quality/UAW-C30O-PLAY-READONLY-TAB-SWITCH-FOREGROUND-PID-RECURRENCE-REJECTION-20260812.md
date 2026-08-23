# C30O Play read-only tab-switch foreground-PID recurrence rejection — 2026-08-12

## Disposition

Rejected read-only input before dispatch. The Create app tab remains active and no form state changed.

## Mistake

A screenshot-coordinate switch to the adjacent Google Play information tab was rejected because the foreground window again lacked a process id.

## Root cause

The Chrome binding was being asked to activate and click in one operation while another desktop window held foreground ownership that the bridge could not validate.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Activate the exact Chrome window as a separate operation.
- Refresh its state.
- Only then issue one bounded read-only tab switch.
