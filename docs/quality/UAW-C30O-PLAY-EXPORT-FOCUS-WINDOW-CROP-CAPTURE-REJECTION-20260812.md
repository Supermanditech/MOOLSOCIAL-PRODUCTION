# C30O Play export focus window-crop capture rejection — 2026-08-12

## Disposition

Rejected unverified focus maneuver. A checkbox click and compensating space toggle may have dispatched, but the follow-up capture failed; no form submission occurred.

## Mistake

The export-checkbox focus maneuver's follow-up screenshot could not be encoded because the window crop was outside the captured monitor.

## Root cause

Chrome was not rehydrated and activated immediately before the screenshot-backed verification sequence after keyboard focus had moved into browser chrome.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not repeat the toggle sequence.
- Rehydrate and activate the exact Chrome window.
- Capture a fresh state and visibly verify all three declarations before any further form action.
