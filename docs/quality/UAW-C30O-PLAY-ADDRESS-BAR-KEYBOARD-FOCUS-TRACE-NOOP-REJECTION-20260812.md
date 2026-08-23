# C30O Play address-bar keyboard focus trace no-op rejection — 2026-08-12

## Disposition

Rejected keyboard route. No page control was reached or activated and the Play form was not submitted.

## Mistake

A bounded 25-Tab trace reported Chrome's address bar as the focused element after every step.

## Root cause

Keyboard events were sent while the exact Chrome window remained in the stale off-monitor/capture-failing state, so toolbar focus did not transition into page content.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not repeat keyboard focus tracing.
- Use the exact window's system menu to maximize it onto the captured monitor.
- Acquire a visible fresh state before any page input.
