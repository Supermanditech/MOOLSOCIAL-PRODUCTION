# Screen 02 — First Setup / Language + Location — visual v2

Production status: **Founder Accepted — immutable**

Founder approval was given on 2026-07-20 for the complete Screen 02 visual
composition and interaction journey.

The accepted production sequence is:

1. Screen 01 remains the only branded launch screen for at least 3000 ms.
2. The existing `JourneySession` route owner selects `/setup`.
3. Native Flutter UI V2 Screen 02 appears immediately.
4. Screen 02 resolves the app language from the phone without showing a
   first-open language picker.
5. The user chooses current location, manual area, or confirms continuation
   without an area.
6. Only a completed Screen 02 outcome can route to Screen 03 sign in.
7. OTP verification is not shown or requested by Screen 02. It remains a later
   authentication step only after Screen 03 explicitly requests a code.

The accepted visible and nested states are recorded in
`interaction-contract.json`. Changing their copy, layout, order, interactions,
or route boundary requires a new HTML version and renewed founder approval.

Open the frozen reference at:

`html/screens/02-first-setup-language-location.html?founderReview=1`

The matching Flutter implementation must remain a native presentation in
`apps/mobile/lib/ui_v2/`. It reuses `JourneySession`, `JourneyStore`,
`LocationPermissionGateway`, and the existing `/setup` route. The legacy
Flutter `SetupScreen` remains read-only and is not mixed into UI V2.

