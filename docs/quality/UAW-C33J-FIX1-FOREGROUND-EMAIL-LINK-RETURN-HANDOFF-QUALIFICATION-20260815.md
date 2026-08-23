# UAW C33J FIX1 foreground email-link return handoff qualification

## Outcome

`UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF` is source-qualified.
An email sign-in link delivered while MoolSocial is already running is handled
once by the existing `JourneySession` validator. A matching in-memory email
completes authentication and reaches the exact pending destination; a process
return without that email shows the same-email confirmation state. Unrecognized
routes remain unhandled.

This is not live email-link, AAB, Play or OPPO acceptance.

## Repair

- `MoolSocialApp.didPushRouteInformation` owns the foreground lifecycle handoff.
- `JourneySession` retains only a canonical, non-persisted one-shot completion
  destination so router refresh cannot consume and replace the exact return.
- No email link, action code, token or email address is logged or persisted by
  the repair.
- No route, screen, backend or provider owner was added.

## Evidence

- FIX1 focused matrix: 3 passed, 0 failed.
- Parent C33J focused matrix: 10 passed, 0 failed.
- Affected regression batch: 68 passed, 0 failed.
- Whole-mobile analyzer: 0 issues.
- FIX1 and parent static gates passed in PowerShell 7 and Windows PowerShell.
- MVP scope, approved UI, C33G FIX2 provider truth and C33H source gates passed.
- Exact foreground destination proof binds both GoRouter provider/delegate URI
  `/app/social?sub=create` and the rendered `social-v2-create-workbench` owner.

## Held boundaries

- No Firebase Authentication, authorized-domain or provider write.
- No Hosting, Android App Links or `assetlinks.json` write/deployment.
- No live email send or real email-link access.
- No secret value access.
- No AAB, Play upload/activation or OPPO mutation.

Firebase requires Email/Password plus passwordless Email Link to be enabled,
an authorized HTTPS continue domain, `handleCodeInApp: true`, and mobile link
handling before a live flow can be accepted:
<https://firebase.google.com/docs/auth/flutter/email-link-auth>.

Android App Links separately require a verified web association and application
intent-filter configuration:
<https://developer.android.com/training/app-links/verify-applinks>.

## Disposition

Source qualification is complete. Live Firebase/Hosting/App Link configuration,
one reviewed live email send, release build, Internal Testing and OPPO acceptance
remain separately gated. No production-grade or reviewer-ready claim is made.
