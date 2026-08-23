# C23F motion and accessibility preselection

## Customer outcome and MVP classification

The existing Mool Home hub remains fast, legible and reachable with finite
native feedback, immediate reduced motion, adaptive large text, and preserved
Back and Chat continuity. This is `mvp_required` because it closes accessibility
and navigation continuity for the founder-authorized replacement shell.

## Smallest complete implementation

- Reuse `MoolHomeHubTokens` for a maximum 220 ms Home arrival and 100 ms press.
- Reuse the existing `onOpenChat` callback in one 44 px minimum Home-header
  control; Chat does not return to the bottom rail.
- Add 100 ms pressed feedback to the single existing Mool Home launcher.
- Prove immediate reduced motion, large-text adaptive layout, target size,
  Back and Chat behavior through focused widget tests.

## Reuse and duplicate search

The existing `PersonalMoolRootV2`, `MoolGlobalNavigationV2`,
`MoolHomeHubTokens`, motion helper, route callback and Chat callback are the
only owners. No duplicate screen, route, backend, business state, family or
subaction is necessary.

## Explicit exclusions and dependencies

No screenbook mutation; no new screen, route, feature, subaction or backend;
no rail restoration; no perpetual motion; and no build, install, uninstall,
data clear, downgrade, commit, push, deploy, promotion, provider or Production
action. C23E is complete and installed r60.21 identity remains preserved.
