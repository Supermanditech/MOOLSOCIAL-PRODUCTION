# C30O Play tester dialog pre-confirmation foreground-read rejection — 2026-08-12

## Disposition

Rejected read-only UI check. The last trusted state remains the populated unsaved tester-list dialog.

## Mistake

A screenshot refresh was attempted before the founder confirmed the requested maximize action and failed because the foreground window did not report a process id.

## Root cause

UI inspection resumed while the explicit founder desktop handoff was still outstanding.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not poll the UI during a founder desktop handoff.
- Wait for the founder's exact confirmation.
- Re-list the live Play window and acquire one fresh state afterward.
