# C30O computer-use window title method-surface rejection — 2026-08-12

## Disposition

Rejected as UI evidence. No click, key input, navigation, console write or account change occurred.

## Mistake

The resumed computer-use preflight called `c30oChromeWindow.title()` as a function even though the saved Windows-control object exposes title through its current state/property surface.

## Root cause

The saved object was reused without reapplying the exact API shape from the computer-use guidance.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Reuse the existing saved Chrome state or inspect the window object through the documented property/snapshot surface.
- Do not dispatch any input until a fresh screenshot-backed state identifies the Play Console control.
