# C16A preselection robustness and reuse assessment

State: `selected_for_execution_after_founder_authorized_C16_registration`

## Customer outcome and MVP classification

Ticket:
`UAW-PERSONAL-MVP-SUBACTION-DESIGN-TOKEN-AND-ADAPTIVE-LAYOUT-FIX1-C16A`.

Customer outcome: every supported main-action family uses one professional,
compact and adaptive subaction language that keeps destination content
dominant, keeps every action one tap away and preserves one anchored native
shell.

Classification: `mvp_required`. The checksum-matched r60.15 OPPO candidate was
founder-rejected for a confirmed visual/navigation regression across Social,
Buy, Eat, Ride, Book and Work. Correcting that supported launch boundary is
required for safe founder qualification; this is not optional redesign depth.

## Reuse and duplicate inventory

The live production owner inventory found:

- one shared shell and motion owner: `MoolDestinationNavigationV2`;
- one stable global rail owner: `MoolGlobalNavigationV2`;
- one existing shared local action model and four-family rail owner:
  `MoolLocalNavigationAction` and `MoolLocalNavigationRail`;
- two bespoke local renderers to consolidate into that shared owner:
  Social `_TrackingRailRibbon` / `_RailAction` and Buy
  `_BuyDestinationTabs`;
- existing production route/state/callback owners for every supported family:
  `SocialUniversalV2`, `BuyV2Session`, `EatSession`, `RideSession`,
  `BookSession` and `WorkSession`; and
- existing C13 direct-default routing plus C10E destination-page motion,
  Back, Mool and Chat continuity owners.

Repository source search found no need for another screen, route, backend,
provider, service or persistent state owner. The only necessary new work is a
shared tokenized adaptive presentation contract inside the existing design and
destination-navigation owners, plus focused acceptance gates. Social and Buy
must stop owning visually divergent local rail implementations; all existing
labels, icons, callbacks, routes and sessions are reused.

Implementation dispositions: `reuse`, `configuration`,
`new_necessary_work`, and `test_only_acceptance`.

## Smallest complete implementation

- define one shared typography, icon, spacing, selected-state and adaptive
  count layout contract;
- compose 2-action families as a compact centred group, 3-action Ride as a
  compact balanced group and 4-action Social/Buy without an edge-to-edge
  left-to-right strip or hidden overflow interaction;
- retain at least 44-by-44 keyed targets, one-tap semantics and immediate
  reduced-motion behavior;
- keep the approved global rail geometry, order, position and meaning fixed;
- transition destination and local content behind the stable shell with
  finite production motion; and
- preserve safe content insets so grids, controls and final scroll targets are
  never obscured or displaced by navigation.

No new screen, route or backend owner is proposed. The shared presentation
contract is necessary because the current three local renderers encode
different typography, icon scale, spacing, distribution and selection rules;
configuration alone cannot prove global uniformity until they converge on one
runtime owner.

## Explicit exclusions

- no filler subaction, new feature, menu, modal, palette or extra tap;
- no top-promotion-zone placement or left-to-right subaction panel;
- no change to global rail geometry, order, position or meaning;
- no Screens 01–03, approved HTML, Social provider or Buy commercial logic;
- no backend, credentials, live messages/calls, payment/funds or Production;
- no build, install, uninstall, data clear, downgrade, commit, push, deploy or
  promotion during C16A.

## Robustness, dependencies and evidence

The predecessor r60.15 APK/evidence and installed checksum remain preserved.
Before design selection, the real OPPO audit captures all six families and
every selected subaction. C16A then requires focused shared-owner tests for
2/3/4 counts, compact and 140-percent text, target geometry, global tokens,
selection semantics, finite directional motion, immediate reduced motion,
stable-shell ownership and content hit safety. C16B through C16G remain
separate family acceptance units. C16H alone may open one successor build and
in-place install after two complete host cycles.

The work reuses existing owners and adds no route-level screen, so the expected
timeline impact is one day and remains within the founder-locked 60–75-day
window.
