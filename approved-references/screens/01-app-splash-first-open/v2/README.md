# Screen 01 — App Splash / First Open Handoff — visual v2

Production status: **Founder Accepted — immutable**

Founder approval was given on 2026-07-20 for the Screen 01 visual composition,
motion, visible states, the current two-line temporary copy, and the final
production launch-continuity decision.

The long-term product tagline remains research-pending. The approved temporary
copy for this immutable version is:

1. `Create. Connect. Work. Grow.`
2. `One app for life and business.`

Final production launch-continuity decision:

1. Android's mandatory system launch window remains plain MoolSocial navy with
   no visible logo, text, or duplicate Screen 01 composition.
2. Native Flutter V2 Screen 01 is the only visibly branded launch screen.
3. Flutter Screen 01 remains visible for a minimum of 3000 ms so the promise can
   be read before the existing journey owner selects the next route.

Changing that copy, layout, motion, or any visible state requires a new HTML
version and renewed founder approval before the matching Flutter change.

Open the frozen reference at:

`html/screens/01-app-splash-first-open.html?founderReview=1`

The `founderReview=1` parameter prevents automatic navigation and forces the
motion preview for review. The normal URL respects the operating system's
reduced-motion preference and silently hands off after 3000 ms.

The matching native Flutter V2 production implementation and physical OPPO
replay are accepted in `production-acceptance.json`. CI verifies every locked
hash before other product checks run.
