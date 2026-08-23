# C30O Play Test and release menu post-click capture rejection — 2026-08-12

## Disposition

Unverified read-only navigation. The sidebar click may have dispatched, but no release, upload, track or tester mutation was attempted.

## Mistake

The Test and release sidebar click and screenshot verification were combined; the follow-up capture failed because the window crop was outside the captured monitor.

## Root cause

Navigation input and screenshot verification were combined while desktop/window ownership remained sensitive to foreground changes.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Refresh semantic state without a screenshot.
- Determine whether Internal testing is already exposed.
- Do not repeat the click unless the menu remains closed.
