# C30O Play Cloud-project dialog accessible-name stale locator rejection

Date: 2026-08-12

## Observed mistake

The exact Dev project-number search was scoped to the dialog name shown in the preceding snapshot, but the live accessibility tree no longer exposed that dialog name and the textbox fill timed out with zero matches.

## Root cause

The locator treated a transient snapshot dialog label as stable across Play Console overlay transitions.

## Prevention

- Do not repeat the stale dialog-name locator.
- Reacquire a fresh page snapshot before another action.
- If the search textbox is still uniquely visible, target its exact textbox role/name without depending on the transient parent-dialog label.

## Retained evidence

The Browser locator diagnostics record zero matches and confirm that no fill or external write occurred.
