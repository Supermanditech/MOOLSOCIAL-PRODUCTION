# C27B preselection — uniform shared destination dock

Classification: `mvp_required`.

Customer outcome: every Social, Shop, Food, Travel, Care and Work destination
uses one legible, compact and reachable bottom dock without family theme
inheritance, text shrinkage, sparse-action drift or competing selection states.

## Reuse and duplicate search

- Reuse `MoolLocalNavigationTokens`, `MoolLocalNavigationRail`,
  `MoolDestinationNavigationV2`, `_MoolFamilyRootButton` and
  `_MoolHomeLauncher`.
- Reuse all six existing action projections without changing their routes,
  semantics, labels or feature state.
- No new screen, route, backend, session, controller or local navigation owner.
- One focused widget test and one source gate are necessary because predecessor
  tests measure nominal boxes but do not enforce a single render token set,
  leading sparse alignment, fixed labels or clean predecessor lifecycle.

## Minimum implementation

Centralize the shared dock tokens; render one neutral clear non-themed shell;
remove label scale-down; align sparse actions directly after the family context;
use one local selected state; strengthen semantics ownership; remove only the
proven-unused disclosure/anchor lifecycle. Keep 58px height, one tap, existing
motion and all feature owners.

Estimated impact is one day and remains within the 60–75-day lock. Build,
install, backend, external service and protected feature-content mutation remain
closed.
