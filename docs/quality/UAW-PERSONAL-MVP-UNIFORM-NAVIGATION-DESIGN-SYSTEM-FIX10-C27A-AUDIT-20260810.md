# C27A uniform navigation design-system audit

## Founder outcome

Audit and correct the accepted Mool switcher and every Social, Shop, Food,
Travel, Care and Work bottom action rail so text, icon, target, spacing,
background, shape, selected state and positioning form one production-grade
native Flutter standard.

## Predecessor and device evidence

- Installed predecessor: C26H r60.25, device-qualified and founder review
  pending.
- OPPO: CPH2375, serial `2b3e0f71`, 720 by 1612 physical pixels at density 320.
- Source evidence: the C26H cumulative screenshots and current shared Flutter
  owners.
- Live accessibility evidence: the Social root UI hierarchy exported the Mool
  control at `[0,1404][108,1442]`, the Social family root at
  `[112,1404][220,1442]`, and local controls at only 32 physical pixels high.

## Reuse and duplicate-search result

The six founder-facing families already converge on exactly two shared native
Flutter presentation owners:

1. `MoolDestinationNavigationV2` and its embedded Mool switcher in
   `apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart`.
2. `MoolLocalNavigationRail` and `MoolLocalNavigationTokens` in
   `apps/mobile/lib/core/design/mool_design_system.dart`.

All Social, Shop, Food, Travel, Care and Work call sites project their truthful
existing actions through those owners. The duplicate search found no need for
a new screen, route, backend, state owner or feature-local rail. Older
`MoolOutcomeDock` and capsule primitives serve other role surfaces and are not
copied into the personal navigation path.

## Findings

### C27A-F1 — token fragmentation

The visible dock is shared structurally but not stylistically. Mool, family
root, local actions and switcher rows hardcode different widths, icon boxes,
label sizes, weights, radii and indicators. Legacy capsule values remain the
geometry source for the current unboxed local rail.

### C27A-F2 — inherited family backgrounds

The transparent dock exposes unrelated feature canvases. C26H therefore shows
a pale Social rail, peach Shop rail, white Food/Travel/Work rails and a dark
Care/Medicine rail while the switcher is open. The same foreground can become
weak or illegible even though the component code is nominally shared.

### C27A-F3 — nonuniform label scale

Bottom labels start at 9.5 logical pixels and use `FittedBox.scaleDown`, so long
truthful labels may render smaller than short labels. Mool, family, local and
switcher labels also use different weights. This defeats a fixed typography
standard and weakens legibility.

### C27A-F4 — competing selected states

Mool, family root and local action can all appear active simultaneously. The
implementation also uses three accent systems: home-hub emission colours,
navigation-family colours and a fixed navy local selection. The hierarchy does
not communicate one current destination clearly.

### C27A-F5 — sparse cluster drift

Two- and three-action families are centered inside the remaining rail while
four-action families fill it. The relation between family root and first local
action moves by family count, leaving unnatural empty space in Food and Work.

### C27A-F6 — Android semantic-bound collapse

Host tests assert nominal Flutter cell sizes but do not inspect exported Android
accessibility bounds. On the connected OPPO the bottom controls export only
16–19 logical pixels of vertical bounds, below the 44px minimum, while the
visual dock extends toward the system-navigation region. Device qualification
must fail unless the exported controls are at least 44 logical pixels high.

### C27A-F7 — rejected predecessor runtime remains active

`MoolDestinationNavigationV2` still initializes an unused disclosure animation,
overlay controller, anchor keys and up to 20 post-frame anchor measurements
from the removed predecessor rail design. These owners do not contribute to
the approved C26 render tree and add avoidable frame/state work.

### C27A-F8 — Social predecessor height constraint

`Screen04ContextTabs` wraps the shared 58px local rail in the older 52px
`railHeight` token. Other family projections do not add that constraint, so the
same shared component does not receive the same vertical geometry in Social.

### C27A-F9 — Mool launcher visual absence on Travel and Work roots

The C26H Travel and Work root screenshots show an empty first dock cell where
Mool must render, while their later switcher screenshots show the same Mool
control and the UI hierarchy retains its semantics. A persistent global
launcher cannot depend on a later overlay or repaint state to become visible.

## Approved successor standard

- One 58px dock height; no increase in content loss.
- The predecessor `railHeight` token aliases the same 58px destination height
  so Social cannot constrain the shared rail differently.
- One neutral, clear, non-themed dock canvas with a single top hairline; no
  family gradient, capsule, card, shadow, blur or horizontal scroll.
- Fixed 54px Mool and family-context cells.
- Local actions use a fixed 72px preferred cell, 8px gap, leading compact
  alignment for sparse families, and adaptive equal cells only when four
  actions must fit at 320px.
- One 22px icon optical box.
- One fixed 10.5px Inter label size, height 1.05, weight 700 unselected and 800
  selected; no scale-down box.
- One family accent map for the quiet family-context cue and the switcher.
- Only the current local action owns the 14 by 2 selected indicator. Mool owns
  it only while the switcher is open. The family root is context, not a second
  selected destination.
- Switcher remains embedded vertical glass with six 56px rows, outside-tap,
  tap/swipe and Back dismissal, finite 180ms motion and immediate reduced
  motion; its width, radius, icon, text and selected state become shared tokens.
- Android/device evidence must prove at least 44 logical pixels for every Mool,
  family-root and local-action semantic target.
- Root-state tests and device screenshots must prove the Mool icon and label
  render before the switcher is ever opened in all six families.

## Scope classification

- Classification: `mvp_required`.
- Minimum complete scope: shared tokens, shared dock, embedded switcher,
  six-family projection tests, Android semantic-bounds evidence and successor
  qualification.
- Exclusions: no screen, route, action, backend, content, customer copy,
  authentication, session or feature-state expansion; no HTML copied into
  Flutter; no second navigation owner.
