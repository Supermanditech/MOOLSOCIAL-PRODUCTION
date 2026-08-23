# C30O computer-use get-window-state argument-shape rejection — 2026-08-12

## Disposition

Rejected as UI evidence. The bridge rejected the argument before capture; no click, key input, navigation, console write or account change occurred.

## Mistake

The fresh Chrome inspection passed the window object directly to `get_window_state` instead of the documented options object containing the window.

## Root cause

The list-windows result shape was correct, but it was not wrapped in the Windows-control method's required argument object.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Call `get_window_state({ window: exactWindow })`.
- Emit the fresh screenshot and inspect it before any navigation or input.
