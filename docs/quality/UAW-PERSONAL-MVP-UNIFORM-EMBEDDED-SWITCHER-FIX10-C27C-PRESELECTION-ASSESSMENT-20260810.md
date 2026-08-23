# C27C preselection — uniform embedded Mool switcher

Classification: `mvp_required`.

Customer outcome: the accepted six-family vertical glass Mool switcher looks
and behaves like an embedded part of the same navigation system on every
destination, with legible neutral glass and one icon, type, accent and selected
state standard.

## Reuse and duplicate search

- Reuse `MoolConnectedActionNavigator`, `MoolMainDomainMenu`,
  `_MoolMainDomainButton`, `MoolGlobalNavigationV2` and the C27B shared tokens.
- Preserve the exact six existing families, order, routes, 56px rows,
  tap/swipe/outside/Back behavior, 180ms finite motion and immediate reduced
  motion.
- No new screen, route, menu, dialog, backend, action or feature state.
- Add one focused switcher test and one source gate because C26C proves
  interaction but not uniform icon/type/accent/neutral-glass tokens.

The work affects one existing shared Flutter file plus the shared token owner,
fits in one day, and remains inside the 60–75-day lock. Build, install, backend,
external service and feature-content mutation remain closed.
