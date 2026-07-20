# Screen 02 — First Setup / Language + Current Location — visual v4

Production status: **Founder Accepted — immutable**

Founder approval was confirmed on 2026-07-20 after exact-APK OPPO replay of the
connected Screen 01–03 checkpoint.

The accepted first-open behavior is:

1. Screen 02 appears immediately after Screen 01 when its current completion
   version has not been explicitly completed.
2. MoolSocial first explains the location benefit and asks for consent.
3. Android owns the permission prompt. If Location Services are off, the app
   offers the phone setting and rechecks on return.
4. A resolved current area is shown by customer-readable place name.
5. `Continue` preserves that current area; `Continue for now` completes without
   inventing a location.
6. No home/work or permanent serviceable-area form appears before login.
   Permanent serviceable area selection belongs inside Universal account
   settings.
7. Screen 02 never requests or displays OTP.

Open the frozen HTML at:

`html/screens/02-first-setup-language-location.html?founderReview=1`

The HTML, reference images, interaction contract, production lock and hashes
in this directory are immutable. A founder-directed replacement requires a new
version; this directory must never be overwritten.
