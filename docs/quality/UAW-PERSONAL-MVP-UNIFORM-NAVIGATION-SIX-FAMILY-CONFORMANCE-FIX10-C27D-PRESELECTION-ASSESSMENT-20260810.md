# C27D preselection — six-family uniform-navigation conformance

Classification: `mvp_required`.

Customer outcome: real Social, Shop, Food, Travel, Care and Work routes and
their relevant subaction states all project the completed C27 dock and Mool
switcher consistently without route, content, state or one-tap regression.

## Reuse and duplicate search

- Reuse the completed C27B/C27C shared runtime owners without further runtime
  mutation.
- Reuse `MoolSocialApp` route fixtures and existing signed-in memory session.
- Reuse C26D, C26E and C26F pair-conformance suites.
- Add one cross-family test and one static projection gate because component
  tests cannot prove each production route uses the shared shell and truthful
  action order.
- No new screen, route, backend, session, controller, action or feature state.

C27D is test/gate-only, one day, and remains within the 60–75-day lock. Build,
install, backend and external writes remain closed; C26H r60.25 stays installed.
