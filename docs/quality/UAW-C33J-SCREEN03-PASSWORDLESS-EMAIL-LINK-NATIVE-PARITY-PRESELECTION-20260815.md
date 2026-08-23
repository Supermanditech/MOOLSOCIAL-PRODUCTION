# UAW C33J Screen 03 passwordless email-link native parity preselection

Ticket: `UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY`

## Customer outcome and classification

The founder-approved Screen 03 v5 becomes a native Flutter successor: a user can choose Email link, receive truthful progress and recovery states, complete Firebase passwordless authentication, and return to the exact pending protected destination. Google and Mobile OTP remain available. This is `mvp_required` because the numeric Email OTP predecessor has no supported backend owner and blocks a complete launch authentication journey.

## Reuse and necessity

The inventory found no existing `sendSignInLinkToEmail`, `isSignInWithEmailLink`, `signInWithEmailLink`, `ActionCodeSettings` or equivalent email-link owner. The locked Screen 03 v4 bytes cannot be changed. C33J therefore adds one isolated native v5 screen and one reusable gateway/session extension while reusing the existing Screen 03 frame, `/sign-in` route, `/verify` Mobile OTP route, social-provider handoff, account bootstrap and exact pending-destination state.

No new product route or backend owner is needed. Live Firebase provider enablement, authorized HTTPS domain, Hosting/App Link configuration, email sending, build, Play and OPPO actions remain separate closed gates.

## Source and security boundary

The Firebase adapter may pass an incoming email action link opaquely to Firebase Auth, but it must never log, persist or expose the link or its action code. The raw email is never placed in a continue URL. No real email is used during source qualification.

## Test boundary

Focused tests cover founder-reference structure, six-provider order and availability truth, validation, masked sent state, resend cooldown, different-device confirmation, invalid/expired/used recovery, exact return intent, account bootstrap, Mobile OTP preservation, accessibility and required viewport fitment. The approved UI lock, MVP scope gate, regression memory and whole-mobile analyzer remain mandatory.
