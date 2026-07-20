# Screen 03 — Login / Account Handoff — visual v1

Production reference status: **Founder approved — FINAL**

The founder approved the exact HTML state on 2026-07-20 at:

`/screens/03-login-account-handoff.html?founderReview=1&area=Khema-Ka-Kuwa%2C%20Jodhpur%2C%20Rajasthan`

The accepted connected sequence is:

1. Screen 01 remains the single visibly branded launch screen.
2. Screen 02 resolves and durably saves the user's service area.
3. Screen 03 appears immediately and offers Google, YouTube through Google
   identity, Apple, X, Instagram, Facebook, Email OTP and Mobile OTP.
4. A provider tap opens that provider's controlled native or secure browser
   surface. MoolSocial owns the pending, cancel, failure and retry return states.
5. Email or mobile OTP uses the accepted native OTP verification presentation.
6. Verified authentication preserves Screen 02 state and opens Universal
   immediately.

Screen 02 and Screen 03 are one connected native founder-acceptance checkpoint.
Neither is production-locked by this HTML approval alone. Native acceptance
requires the complete Screen 01 → Screen 02 → Screen 03 → authentication →
Universal replay on the exact installed OPPO candidate.

The frozen HTML, shared foundation assets, two 360 × 720 reference captures,
interaction contract and checksums are immutable. Any customer-visible change
requires a new reference version and renewed founder approval.

The matching implementation must be fresh native Flutter UI V2 under
`apps/mobile/lib/ui_v2/`. It reuses the existing session, persistence,
authentication, Firebase/native configuration, account bootstrap and router.
The legacy Flutter login and OTP presentation remains read-only. Flutter must
not load this HTML or any WebView.
