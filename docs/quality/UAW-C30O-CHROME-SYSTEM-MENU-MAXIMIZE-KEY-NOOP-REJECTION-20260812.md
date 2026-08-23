# C30O Chrome system-menu maximize key no-op rejection — 2026-08-12

## Disposition

Rejected window-management no-op. The system menu remains open, an adjacent Google Play information tab is active, the Create app tab remains open, and no form state changed.

## Mistake

`Alt+Space` opened Chrome's system menu, but the following `x` keystroke did not activate Maximize.

## Root cause

The single-letter system-menu accelerator was not accepted by the Windows/Chrome menu state in this environment.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not repeat the accelerator.
- Close only the menu with Escape.
- Return to the already-open Create app tab using its fresh screenshot coordinate.
- Continue with the now-visible window without further window-management guessing.
