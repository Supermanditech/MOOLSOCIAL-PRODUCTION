# C30O Play tester-dialog title-bar maximize foreground-PID recurrence rejection — 2026-08-12

## Disposition

Rejected window-management input before dispatch. The populated tester-list dialog remains unsaved.

## Mistake

With the tester list fully populated, a fresh title-bar maximize click was again rejected because the foreground window did not report a process id.

## Root cause

The bridge still cannot validate foreground ownership for Chrome title-bar input even though page-level inputs and captures work.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not retry title-bar automation.
- Preserve the populated unsaved dialog.
- Ask the founder to click only Chrome's top-right maximize square.
- Reacquire the dialog and invoke Save changes once visibly reachable.
