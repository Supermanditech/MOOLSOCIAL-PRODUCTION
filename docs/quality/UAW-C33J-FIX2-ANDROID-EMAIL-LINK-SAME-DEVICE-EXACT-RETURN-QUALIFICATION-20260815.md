# UAW C33J FIX2 Android email-link same-device exact-return qualification

## Outcome

`UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN` is
source-qualified. When a Firebase passwordless email action link is delivered
to the Android app, the existing C33J/FIX1 completion owner opens Screen03,
completes with the matching in-memory email or requests same-email confirmation
after process loss, and returns once to the exact page or protected action that
requested sign-in.

This is source qualification only. No live email, Hosting association, AAB,
Play update or OPPO acceptance was executed.

## Repair

- `AndroidManifest.xml` now preserves the existing verified
  `https://moolsocial.com/app` filter and adds exact auto-verified HTTPS filters
  for `/__/auth/links` on:
  - `moolsocial-dev-503018.firebaseapp.com`
  - `moolsocial.com`
- `email_link_runtime_configuration.dart` fails closed unless the continue URL
  is HTTPS on `moolsocial.com`, uses `/app` or `/app/...`, and contains no user
  information, non-default port or fragment.
- The runtime link domain may be blank/default or exactly one of the two
  manifest-supported hosts. Unknown or URL-shaped values remain unavailable.
- Cold-start and foreground route delivery reuse one validator and the existing
  one-shot exact-return owner. No new screen, route, backend or provider owner
  was introduced.
- The opaque email link and email address are neither logged nor persisted, and
  the email address is not placed in the return URL.

## Evidence

- FIX2 focused matrix: 3 passed, 0 failed.
- Expanded affected matrix: 78 passed, 0 failed across 14 test files.
- Whole-mobile analyzer: 0 issues.
- Parent C33J, FIX1 and FIX2 static gates passed independently in PowerShell 7
  and Windows PowerShell.
- MVP scope, approved UI, C33G FIX2 social-provider truth and C33H Firebase Phone
  Auth gates passed.
- Exact destination proof remains `/app/social?sub=create` with rendered owner
  `social-v2-create-workbench`.
- Regression memory passed after REG2516 and REG2517 were registered and gated.

## Live and release prerequisites still held

- Firebase Email/Password and Email Link enablement, authorized continue domain
  and selected Hosting link domain must be reviewed against live configuration.
- The selected Hosting domain must serve a valid Android App Links association;
  the repository `assetlinks.json` is source evidence, not proof of live
  deployment or verification.
- A future separately selected release candidate must supply the non-secret
  `MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL` and `MOOLSOCIAL_EMAIL_LINK_DOMAIN`
  defines through its release gate. The failed r60.49 candidate is not repaired
  by this source change.
- One reviewed real email send/link tap and a later Play-installed OPPO journey
  are required before runtime acceptance.

Firebase documents the `/__/auth/links` Hosting action path and Android intent
filter requirement in its passwordless email-link guide:
<https://firebase.google.com/docs/auth/android/email-link-auth>.
Android separately requires verified website association for App Links:
<https://developer.android.com/training/app-links/verify-applinks>.

## Disposition

The requested same-device exact-page return is implemented and source-qualified.
Live Firebase/Hosting, email, release and device acceptance remain separate
gates. No production-grade or external-review-ready claim is made.
