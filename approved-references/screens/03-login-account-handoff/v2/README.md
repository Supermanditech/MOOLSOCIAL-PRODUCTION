# Screen 03 — Login / Account Handoff — visual v2

Production status: **Founder Accepted — immutable**

Founder approval was confirmed on 2026-07-20 after the exact installed OPPO APK
completed both mobile OTP and email OTP to Universal.

The accepted connected behavior is:

1. Screen 03 follows explicit completion of Screen 02.
2. It offers Google, YouTube through Google basic identity, Apple, X,
   Instagram, Facebook, Email OTP and Mobile OTP.
3. Each social action reaches a provider-controlled handoff or a truthful,
   recoverable return state; MoolSocial never asks for provider credentials.
4. Email and mobile each use the same accepted native OTP presentation.
5. Verification preserves Screen 02 state and opens Universal without an
   intermediate success screen.
6. A device-review routing failure must not be mislabeled as proof that the
   customer is offline.

Open the frozen HTML at:

`html/screens/03-login-account-handoff.html?founderReview=1&area=Khema-Ka-Kuwa%2C%20Jodhpur%2C%20Rajasthan`

The HTML, reference images, interaction contract, production lock and hashes
in this directory are immutable. A founder-directed replacement requires a new
version; this directory must never be overwritten.
