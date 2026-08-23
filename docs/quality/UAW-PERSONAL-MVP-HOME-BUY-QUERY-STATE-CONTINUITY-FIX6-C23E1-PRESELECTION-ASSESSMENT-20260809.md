# C23E1 Home-to-destination route-state continuity preselection

## Customer outcome and classification

A target chosen from Mool Home keeps its exact route/query and visible state
when the same family already exists below Home, and Back restores the prior
destination context. This is `mvp_required` because C23's fast-access model
cannot qualify with visible state and URI divergence.

## Smallest complete implementation

- Reuse the existing `moolOrigin` signal in the Mool route.
- If Home was opened from Social, Buy, Eat, Ride, Book or Work, use the
  existing `pushReplacement` operation to replace only Home with a new exact
  target route entry; the prior destination remains below it for Back.
- If Home is the root with no origin, preserve the existing push behavior.
- Bind the shared main-destination page key to the complete URI so query-
  specific visible states cannot collapse onto an older same-path page.
- Add exact Buy query/visible-state and Back tests plus source policy coverage
  for all six families.

## Reuse, duplicate search and exclusions

The existing Home callback, GoRouter push/replace operations, six-family route
matrix and `moolOrigin` owner are reused. No screen, route, backend, state,
family or subaction is added. No screenbook mutation, build, install, uninstall,
data clear, downgrade, commit, push, deploy, promotion, provider or Production
action is authorized. r60.21 remains installed and preserved.
