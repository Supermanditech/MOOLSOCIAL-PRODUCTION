# C30O Play Create app off-view accessibility-click no-op rejection — 2026-08-12

## Disposition

Rejected no-op external write attempt. The Create app page, URL and title remained unchanged; no app container was created.

## Mistake

The accessibility click on the non-visible Create app button completed without an API error but did not navigate or create the app container.

## Root cause

The accessibility element existed in the tree while its action target was not visibly rendered in the current bottom viewport, so the generated click did not reach the effective control.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Keep the unchanged form and URL as authoritative.
- Use bounded keyboard focus inspection from the last visible declaration.
- Press Enter only after the focused element is exactly the Create app button.
