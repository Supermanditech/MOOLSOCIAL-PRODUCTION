# C20C preselection assessment

Date: 2026-08-08

## Outcome and classification

`C20C` is `mvp_required`. Every existing Social, Buy, Eat, Ride, Book and Work
subaction will use one readable, background-preserving, neutral Mool identity
glass grammar instead of six custom family-selected colour systems. This
repairs the already approved MVP navigation and adds no customer feature.

## Smallest complete implementation

- Reuse `MoolBrand`, `MoolLocalNavigationTokens`,
  `MoolLocalNavigationRail` and `_MoolLocalNavigationCell` in the existing
  shared design-system file.
- Remove the custom family accent maps. Use `MoolBrand.identityNavy` for light
  selection/connector signals and `MoolBrand.identityWhite` for media signals.
- Keep the rail surface fully transparent and background visible between and
  behind individual controls. Use neutral light/media glass fills only; state
  may change neutral opacity, border and indicator but never introduce a
  family-tinted fill, band, panel or trapezoid.
- Normalize every control to 48px height, 16px radius, 20px optical icon box,
  13px/700 label typography, 4px inter-control gap, one restrained selected
  indicator and a finite neutral press response. Selected and inactive labels
  keep the same weight.
- Reuse the existing two/three/four compact cluster owner. Do not add scroll,
  filler actions, sparse expansion, routes, screens or state owners.
- Add one focused C20C shared-token/control test and one static gate. Reconcile
  C17B/C17C/C17D only by exact C20 successor branching that runs C20C instead
  of accepting the superseded custom accent contract.

## Reuse and duplicate search

The actual runtime owners are
`apps/mobile/lib/core/design/mool_design_system.dart::MoolBrand`,
`MoolLocalNavigationTokens`, `MoolLocalNavigationRail` and
`_MoolLocalNavigationCell`, plus
`apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart::MoolDestinationNavigationV2`
for the noninteractive connector. All six family scaffolds already consume
this shared owner. No second renderer, theme owner, brand owner, route, screen,
backend owner, provider owner, subaction or persistent state is needed.

## Dependencies and exclusions

C20C depends on completed C20A–B, the preserved r60.18 installed identity, the
MVP delivery lock, permanent regression memory, protected UI/brand/copy locks
and focused host qualification. C20D and C20E separately qualify four-action
and adaptive family screenshots/fitment. Build and install remain closed until
C20H after C20G.
