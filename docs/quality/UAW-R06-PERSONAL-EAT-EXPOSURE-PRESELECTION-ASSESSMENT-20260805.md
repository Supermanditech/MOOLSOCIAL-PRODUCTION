# UAW-R06 Personal Eat exposure preselection assessment

Date: 5 August 2026
Ticket: `UAW-R06-PERSONAL-EAT-EXPOSURE`
Classification: `mvp_required`
State: disclosed and selected under the founder-authorized sequential MVP batch

## Customer outcome

A Personal user taps Eat from Mool and reaches one compact native Flutter
surface that exposes exactly **Order Food** and **Book Table**. Either choice
opens its existing restaurant journey in one tap. Back, Mool and global Chat
remain continuously available and restore a safe Eat/Mool context.

## Why this is MVP required

Food ordering is a high-frequency consumer action and table booking is the
only other founder-retained Eat action for MVP. The launch projection expressly
postpones Tiffin. A truthful Eat root is therefore necessary before production
launch; leaving the current old presentation in place would expose a postponed
action and conflict with the direct-native UX directive.

## Reuse and duplicate-owner assessment

- Existing production owners are reused for Order Food (`/app/eat/home`), Book
  Table (`/app/eat/table`), `EatSession`, restaurant data and their downstream
  journeys.
- The current old Eat landing/dock is not reusable as the MVP root because it
  exposes Tiffin and its presentation was explicitly rejected by the founder.
- No existing compact native action-choice owner exists under `ui_v2`.
- One shared, configuration-driven native action-choice surface is the smallest
  non-duplicating owner. R07 Ride, R08 Book and R10 Work can configure the same
  owner rather than creating three more landing-screen implementations.
- The existing catch-all `/app/:section` route remains the route owner. R06
  adds only an Eat policy branch; it does not register a new route.

## Smallest complete implementation

1. Add one shared `MvpActionChoiceRootV2` presentation owner with finite
   directional arrival motion, static reduced-motion behavior, visible Back,
   one-tap Mool and one-tap global Chat.
2. Add the Eat configuration with exactly Order Food and Book Table.
3. Route production `/app/eat` through that shared owner while retaining the
   tests-only legacy presentation switch.
4. Push Order Food to `/app/eat/home` and Book Table to `/app/eat/table` so the
   existing restaurant journey remains the sole downstream owner.
5. Prove compact/responsive fit, semantics, reduced motion and route callbacks
   with focused widget/router tests.

## Explicit exclusions

- No Tiffin exposure and no deletion of its legacy route in this ticket;
  legacy/deep-link containment belongs to UAW-R12.
- No restaurant catalogue, basket, checkout, booking confirmation, fulfilment,
  payment, provider acceptance or delivery behavior change.
- No backend, API, controller, session, route-registration or data-model owner.
- No final-acceptance claim for the existing downstream Eat screens.
- No build, install, OPPO mutation, external-service action, credential access,
  commit, push, deploy, promotion or protected FIX7 change.

## Dependencies and approvals

- Founder-preauthorized `MVP-UNIVERSAL-ACTION-EXPOSURE-AND-WORKSPACE-ROUTING-REFERENCE-BATCH`.
- Completed UAW-R01 action projection and UAW-R03 Personal Mool root.
- Existing restaurant journey routes and `EatSession` remain authoritative for
  downstream behavior.
- Native Flutter whirlpool-navigation directive and the 60–75 day reuse lock.

## Test and evidence plan

- Machine MVP scope gate with `-RequireExecutionAuthorized` before runtime
  writes.
- Focused screen tests at compact and regular viewports for exact action count,
  absence of Tiffin, one-tap callbacks, Back/Mool/Chat and reduced motion.
- Production-router tests for `/app/eat`, Order Food and Book Table transitions.
- Focused analyze plus R03 Mool-root and existing Eat journey regressions.
- No golden regeneration, protected-baseline replacement, APK build or device
  action.

Estimated batch impact: **1–2 days**, inside the locked 60–75 day launch plan.
