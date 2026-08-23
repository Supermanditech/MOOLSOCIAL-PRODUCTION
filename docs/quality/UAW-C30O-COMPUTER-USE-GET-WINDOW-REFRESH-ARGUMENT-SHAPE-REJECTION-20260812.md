# C30O computer-use get-window refresh argument-shape rejection — 2026-08-12

## Disposition

Rejected as UI evidence. The bridge rejected the refresh argument; no navigation, click, key input, console write or account change occurred.

## Mistake

After the minimized-window response requested a refreshed window handle, the retry called `get_window({ window: existingWindow })`, which is not the documented `get_window` argument shape.

## Root cause

The state-capture and window-refresh methods were assumed to share the same options shape.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Re-read the exact computer-use API owner before another UI method call.
- Use the documented `get_window` identifier arguments only; do not infer shapes across methods.
