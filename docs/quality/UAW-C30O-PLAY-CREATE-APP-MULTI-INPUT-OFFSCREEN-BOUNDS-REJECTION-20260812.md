# C30O Play Create app multi-input offscreen-bounds rejection — 2026-08-12

## Disposition

Rejected multi-input attempt. The form was not submitted and no Play app was created. App/free selections may have been applied before the first offscreen declaration control was rejected; exact state must be refreshed before retry.

## Mistake

One Windows call attempted five sequential form inputs spanning the visible category controls and declarations below the viewport. The bridge rejected an offscreen coordinate at y=906 against a height-798 window.

## Root cause

Accessibility indexes were treated as directly clickable without first ensuring each control was visible in the current screenshot-backed viewport.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Refresh selected radio/checkbox state.
- Handle visible radio buttons separately.
- Scroll once to the declarations, refresh indexes and click each visible checkbox with a state refresh between groups.
- Submit only after a final complete form audit.
