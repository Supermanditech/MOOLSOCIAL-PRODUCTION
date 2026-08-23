# C22B preselection assessment

C22B is MVP-required shared-runtime work. It modifies the existing `MoolLocalNavigationTokens`, `MoolLocalNavigationRail` and `_MoolLocalNavigationCell` owners only. All six families already reuse those owners, so no family fork, screen, route, backend owner, business state or new subaction is necessary.

The duplicate search found `MoolSegment`, `ChoiceChip` and `SegmentedButton` owners for unrelated in-content filters; reusing them would reintroduce a strip/chip language and is rejected. The existing local navigation owner is retained and converted to one fixed 72 × 48 neutral glass capsule. The invariant 72 px width allows four capsules plus three 8 px gaps to fit a 320 px compact viewport without resizing. Estimated impact is 0.5 day inside the delivery lock. Build and install remain closed.
