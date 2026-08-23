# UAW C33I Screen 03 passwordless email-link reference proposal qualification

State: `SUPERSEDED_FOUNDER_REJECTED_FIRST_PROPOSAL_EVIDENCE_RETAINED`

> This document and its `84/84` matrix qualify only the founder-rejected first
> proposal at SHA-256
> `3B9F5C1CA82A379BAEF3782CBD9EA9A6A0CF39B3052FD2EF222E541A5BFD54C0`.
> They are not current proposal evidence. The approved-prototype correction is
> qualified separately in
> `docs/quality/UAW-C33I-FIX1-APPROVED-PROTOTYPE-STRUCTURE-RESTORATION-QUALIFICATION-20260815.md`.

Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

The separately versioned Screen 03 v5 founder-review proposal is present at:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\03-login-account-handoff-v5-passwordless-email-link.html`

Its SHA-256 is `3B9F5C1CA82A379BAEF3782CBD9EA9A6A0CF39B3052FD2EF222E541A5BFD54C0`.

## Product result

- Google identity remains a primary method.
- Mobile OTP remains reachable with the accepted six-digit mobile presentation.
- Unsupported numeric Email OTP is replaced only in the proposal by `Email me a sign-in link`.
- Email entry validates locally, never places the address in the review URL and masks it after the send-link transition.
- Same-device return, different-device email confirmation, invalid input, expired/already-used link, resend, cancellation and change-method states are represented.
- A completed link is contractually required to resume the exact protected destination; the prototype does not authenticate or show a false success page.
- YouTube channel access remains a later creator-tools connection and is not requested by login.

The proposal follows Firebase's current Hosting-domain and Android App Links model. It does not depend on deprecated Firebase Dynamic Links. Firebase configuration, App Links, Hosting and an email send remain separately held.

Official references reviewed:

- <https://firebase.google.com/docs/auth/android/email-link-auth>
- <https://firebase.google.com/support/dynamic-links-faq>

## Verification

The clean rendered matrix passed `84/84` combinations:

- viewports: `320x568`, `360x640`, `360x720`, `375x667`, `390x844`, `412x915`, `430x932`;
- text scales: `100%`, `140%`; and
- states: choose method, enter email, link sent, different-device confirmation, expired/already-used and Mobile OTP.

All combinations had one exact visible state, zero horizontal viewport/app/phone overflow and zero visible control below 44 pixels. Nine focused interactions passed: invalid email rejection, valid email transition, raw-address masking, different-device mismatch rejection, matching confirmation, Google local-boundary preservation and Mobile OTP reachability. Severe browser-console errors were zero.

Accepted review screenshots:

- `artifacts/quality/uaw-c33i-screen03-passwordless-email-link-reference-successor-20260815-01/screen03-v5-choose-390x844-fix1.png`, SHA-256 `8B96FDBDA04257BD7983B344C7C45BB1B9992BA87D1E42EE3C44F9834B9C9707`, `390x844`;
- `artifacts/quality/uaw-c33i-screen03-passwordless-email-link-reference-successor-20260815-01/screen03-v5-email-320x568-text140-fix1.png`, SHA-256 `D52AD783BED7C9F36DFBC2EFA44721A55960BD3F9D99988B43E188521CA92A12`, `320x568`.

The earlier non-`fix1` screenshots are preserved and rejected under `REG-20260815-2475-SCREEN03-ELEMENT-SCREENSHOT-VIEWPORT-INTERSECTION-CLIPPED`; they are not review evidence.

## Preserved boundaries

- Screenbook accepted Screen 03 source and production v2 HTML remain byte-exact at `C8B58BED63B6616F83D06C7D95FAA335DB537B3C6DF37593D601D19037ECDFEF`.
- `approved-references/manifest.json` remains unchanged at `9F104DD7B692BCFD68ED8262E187552937F145B877E5176E2A724876909384DB`.
- No immutable v5 reference exists.
- No Flutter/runtime, Firebase, Hosting, provider, backend, email, AAB, Play or OPPO action occurred.
- Explicit founder `FINAL` remains mandatory before freeze or native implementation.
