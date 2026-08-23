# C30O Chrome standalone activation foreground-PID rejection — 2026-08-12

## Disposition

Rejected window activation before any Play input. The visible form is preserved and no external state changed.

## Mistake

A standalone `activate_window` call for the exact Chrome binding was rejected because the current foreground window did not report a process id.

## Root cause

The bridge's current desktop-ownership state prevents even its supported activation escape hatch, independent of the requested Play action.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Stop UI retries while the ownership condition persists.
- Continue independent local and read-only qualification.
- Resume only after Chrome is visibly foregrounded or the bridge reports a valid process owner.
