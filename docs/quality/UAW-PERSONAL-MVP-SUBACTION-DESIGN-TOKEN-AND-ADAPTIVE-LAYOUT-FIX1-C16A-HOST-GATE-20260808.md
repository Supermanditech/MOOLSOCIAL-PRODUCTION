# C16A shared sub-action design owner host gate

## Result

`UAW-PERSONAL-MVP-SUBACTION-DESIGN-TOKEN-AND-ADAPTIVE-LAYOUT-FIX1-C16A`
passes its applicable host gate. Build and install remain closed.

## Implemented owner

- Reused `MoolLocalNavigationRail`; no second rail owner was added.
- Added one `MoolLocalNavigationTokens` owner for six family accents, 16px
  icon geometry, 10.5px label geometry, 4px inter-item spacing, 20x2 selected
  indicator geometry, 44px targets and immediate reduced motion.
- Replaced scroll/even-distribution branches with one centered compact
  2/3/4-action LayoutBuilder composition.
- Preserved all existing actions, routes, sessions, callbacks and global-rail
  geometry/order/meaning.
- Connected `MoolDestinationFamilyWavePainter` to the adaptive cluster's exact
  selected-cell center.
- Corrected the shared outer semantics owner so available actions expose a tap
  action and selected actions remain inert.

## Evidence

- Required predecessor audit:
  `docs/quality/UAW-C16-R60-15-OPPO-PREDECESSOR-AUDIT-20260808.md`.
- Machine gate:
  `scripts/check-personal-subaction-professional-design-system-c16a.ps1` —
  passed.
- Focused test:
  `flutter test test/core/design/mool_adaptive_local_navigation_c16a_test.dart`
  — 7/7 passed.
- Existing six-family placement/motion test:
  `flutter test test/ui_v2/universal/uaw_personal_mvp_contextual_subaction_thumb_shelf_c11_test.dart`
  — 7/7 passed.
- Focused analysis of nine affected owner/test files — no issues found.
- Permanent regression-memory gate — passed with 314 entries.

## Sequential decision

C16A is closed for host implementation. C16B may now map Social's four
existing actions into this owner. Social provider, destination content, routes,
state, copy and commercial behavior remain outside C16B mutation scope.
