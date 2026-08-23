# C30O Chrome title-bar maximize foreground-PID rejection — 2026-08-12

## Disposition

Rejected window-management input before dispatch. No Chrome window or Play form state changed.

## Mistake

The fresh screenshot-coordinate click on Chrome's visible maximize button was rejected because the foreground window did not report a process id.

## Root cause

The computer-use bridge could not validate foreground ownership for the title-bar input despite the saved Play window binding.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not repeat title-bar geometry attempts.
- Preserve the visible exact form.
- Continue with read-only account/form diagnosis.
- Use a founder-visible manual action only if the bridge remains unable to invoke the exact enabled control.
