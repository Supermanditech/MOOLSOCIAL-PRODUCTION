# Screen 02 — First Setup / Language + Area — visual v3

Production status: **Founder approved — FINAL**

Founder approval was given on 2026-07-20 after the customer-facing wording was
corrected to state a useful result instead of presenting implementation or
permission language.

The accepted production sequence is:

1. Screen 01 remains the only branded launch screen for at least 3000 ms.
2. Native Flutter UI V2 Screen 02 appears immediately at `/setup`.
3. The screen states the resolved current area: `You're in Sardarpura` and
   `Jodhpur, Rajasthan` in the approved reference state.
4. The user can continue with that current area in one tap.
5. A traveller can separately set a usual home or work area.
6. Current area and home/work area remain separate data choices.
7. If an area cannot be confirmed, the screen offers `Choose my area` and
   `Change later` in customer language.
8. Screen 02 never requests or displays OTP. Authentication begins only on the
   later sign-in screen.

Every customer-visible state and action is recorded in
`interaction-contract.json`. The approved HTML, shared assets, reference image,
contract and checksums are immutable. Any customer-visible change requires a
new version and renewed founder approval.

Open the frozen reference at:

`html/screens/02-first-setup-language-location.html?founderReview=1`

The matching implementation is a fresh native Flutter V2 presentation under
`apps/mobile/lib/ui_v2/`. It reuses the existing JourneySession, persistence,
location owner and router. The legacy Flutter SetupScreen remains read-only,
and no HTML or WebView is used in Flutter.
