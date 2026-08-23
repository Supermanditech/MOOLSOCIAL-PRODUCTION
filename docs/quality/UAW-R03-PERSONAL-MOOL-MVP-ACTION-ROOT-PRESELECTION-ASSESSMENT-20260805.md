# UAW-R03 preselection robustness/reuse assessment and disclosure

Date: 5 August 2026
Ticket: `UAW-R03-PERSONAL-MOOL-MVP-ACTION-ROOT`
State: `ASSESSED_AND_SELECTED_FOR_DIRECT_NATIVE_FLUTTER_IMPLEMENTATION`

## Customer outcome and classification

A normal Personal user opens one compact native Mool root and sees exactly
Social, Buy, Eat, Ride, Book and Work, plus global Chat. Standalone Pay is not
shown. Every main action and Chat is reachable in one deliberate tap.

Classification: `mvp_required`. This is the stable launch hub for every MVP
journey and the first visible consumer of the R01 projection. Leaving the old
seven-action palette in place would advertise postponed Pay scope and break the
founder-locked MVP boundary.

## Reuse and duplicate inventory

Existing owners inspected:

- the R01 canonical projection and validator;
- the existing `/app/mool` path and `JourneySession.previousPrimarySection`
  return-context owner;
- `MoolCardSurface`, `MoolGlassSurface`, brand, spacing, motion, tap-target and
  reduced-motion tokens;
- accepted Social `SocialUniversalV2` and its protected internal rail;
- accepted Buy V2 routes; and
- legacy `UniversalShell`/`screen04Worlds`, which expose seven root actions and
  therefore remain containment inventory only.

Duplicate-search result: no existing unprotected native screen truthfully
renders the six-action MVP root. Editing the accepted Social presentation would
cross its protected boundary, while reusing legacy `UniversalShell` would show
Pay. One isolated shared Personal Mool root is therefore necessary. The
existing `/app/mool` route is reused; no additional route, controller, service,
session, backend owner or per-user-type screen is added.

Implementation disposition:

- `new_necessary_work`: one shared native root presentation;
- `thin_policy_adapter`: the existing `/app/mool` route selects that owner;
- `reuse`: existing navigation/session/design-system owners; and
- `acceptance_tests`: projection parity, navigation, semantics, reduced motion
  and responsive fitment.

## Smallest complete scope

1. Add a versioned R03 interaction/navigation contract tied to the protected
   R01 projection identity.
2. Add one compact native Flutter V2 Mool root with six action cards, stable
   Mool orientation, global Chat and visible/system Back recovery.
3. Route each card in one tap through its existing exact route; use a pushed
   destination so Back returns to the Mool root.
4. Use finite 240 ms directional/staggered arrival, existing press
   acknowledgement and a static reduced-motion state.
5. Reuse `/app/mool`; do not create another screen per actor or vertical.

## Explicit exclusions

- No sub-action or vertical end-journey implementation in R03.
- No edit to locked Screens 01-03, accepted Social files, accepted Buy
  presentation/vertical files, screenbook HTML or immutable references. The
  shared router may receive only the assessed `/app/mool` thin adapter; this
  does not rebaseline or replace protected FIX7.
- No standalone Pay, local capability grant, workspace activation or route
  bypass.
- No backend/provider/payment/environment write, build, install, OPPO action,
  commit, push, deployment or promotion.

## Dependencies and evidence

- R01 completion and projection SHA-256
  `5F963AD44DC7B8ABD4527B99A609150CA7003998AE9BD7A7FFE57EAEFF9FE6B2`.
- R02 completion and existing authenticated Universal entry.
- Parent manifest SHA-256
  `45D765390EA6B2D94F334CB4F5B2AB67162657A447B220A10650EB7621DB34A8`.
- Founder native Flutter directive and non-stop one-child authorization.

Test/evidence plan: format/analyze; contract-to-widget projection parity; exact
six-action/no-Pay/global-Chat widget tests; one-tap destination and Back
continuity; reduced-motion and 320/390/430 responsive tests; existing Screen 04
conformance and Buy route regressions; protected-boundary checks with exact
known predecessor rejections preserved. Android/iOS captures, OPPO and build
evidence remain for their separately machine-gated qualification child.

Timeline impact: two engineering days or less. This replaces a non-conforming
legacy root without creating duplicated vertical screens and remains inside
the 60-75-day lock.
