# C09 Mool Home navigation and motion — preselection assessment

Date: 7 August 2026
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome and founder evidence

Mool is a stable first-class Home. Selecting it from a main action must not
open a return sheet, popup, Social alias or ambiguous Back page. All six main
actions remain reachable; every main action keeps its valid subactions; finite
directional motion explains forward and Back; and a selected Mool retap is a
true no-op.

The connected OPPO r60.8 audit retained frames 001–007. Social and Buy both
open a `Your Mool` surface with a header Back arrow and a prominent
`Continue Social` or `Continue Buy` card. The centre rail reveals only Social,
Buy and Eat initially, while Ride, Book and Work require an unannounced
horizontal swipe. The result is technically reachable but visually and
historically owned as a temporary return route, matching the founder's escaped
defect report.

## Reuse and duplicate search

Reuse `PersonalMoolRootV2`, `MoolOutcomeDock`, `personalMoolRootActions`, the
existing `/app/:section` route owner, `JourneySession` primary-section memory,
existing Mool motion primitives and every existing vertical session/state
owner. Update the shared owners rather than creating another Home, rail, shell,
route, service, backend, store or provider.

Implementation disposition: `reuse`, `configuration`,
`test_only_acceptance`, and bounded `new_necessary_work` inside the existing
Mool presentation/navigation owner. New screens: zero. New named routes: zero.
New backend owners: zero. A small shared route-transition helper is permitted
only if existing motion primitives cannot express the required direction and
reduced-motion behavior without duplication.

## Robustness and timeline

Acceptance covers selected-tab retap, forward/back depth, hidden-action
discovery, exact main/subaction retention, process/app-switch return, 320px and
140% text, TalkBack semantics, reduced motion, two regressions and one uniquely
machine-gated checksum-matched OPPO upgrade. Obsolete navigation code is
removed from compiled/reachable ownership, while retained evidence and dirty
workspace files are preserved.

The ticket has at most a two-day impact and remains inside the founder-locked
60–75-day delivery window. It introduces no provider, payment, credential,
Production, deployment or promotion authority.
