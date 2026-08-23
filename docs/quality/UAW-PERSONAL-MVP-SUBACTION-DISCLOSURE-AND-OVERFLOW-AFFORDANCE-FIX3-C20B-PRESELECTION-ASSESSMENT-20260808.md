# C20B preselection assessment

Date: 2026-08-08

## Outcome and classification

`C20B` is `mvp_required`. An authenticated Personal customer can hide or restore the selected Social, Buy, Eat, Ride, Book or Work subactions from the already selected main action, and can tap truthful Previous/Next controls to reach off-screen main actions. This repairs existing MVP navigation and adds no customer feature.

## Smallest complete implementation

- Reuse `MoolDestinationNavigationV2` for default-expanded, per-family, in-memory-only disclosure state.
- Reuse the selected `MoolGlobalNavigationV2` main action as the complete 48px Hide/Show target; add a visible up/down badge and exact semantics.
- Collapse only the 52px local rail to zero height with 160ms finite motion and immediate reduced-motion settlement. Do not navigate, reset content, add history or repurpose system Back.
- Reuse `_MoolScrollableDockActions`; reserve non-overlapping 44px Previous/Next hit regions and show arrow glyphs only while those buttons are actionable.
- Add one focused C20B widget-test owner and one static gate, then replay the affected navigation, placement, memory, brand, copy and protected-lock gates.

## Reuse and duplicate search

The production owners are `MoolDestinationNavigationV2`, `MoolGlobalNavigationV2`, `MoolOutcomeDock`, `MoolDockAction` and `_MoolScrollableDockActions`. A bounded search found no existing destination-family disclosure owner. Content-card expansion owners in Social and Work have different lifecycle, semantics and placement and are not duplicated into navigation.

No screen, route, subaction, backend owner, provider owner or persistent business-state owner is necessary. Disclosure memory remains process-local presentation state.

## Exclusions and dependencies

C20B does not perform the C20C color/glass/typography/icon redesign, change the global rail order/position/meaning, touch Screens 01–03 or the read-only screenbook, mutate copy/business/provider/backend state, or build/install an APK. It depends on C20A, the preserved r60.18 installed identity, the MVP delivery lock, permanent regression memory, approved UI locks, brand/copy gates and focused host tests.

## Test plan

Qualify six-family default state, exact expanded/collapsed semantics, zero-height collapse and restoration, route/content stability, in-session family memory, normal and reduced motion, 44px non-overlapping overflow buttons, and unchanged one-tap subactions/Back/Mool/Chat/global order.
