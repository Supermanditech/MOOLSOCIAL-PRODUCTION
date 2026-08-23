# UAW C33K Firebase passwordless email-link live-readiness preselection

## Founder disclosure

- Ticket: `UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS`
- Customer outcome: a customer can request the approved passwordless email
  sign-in link and Firebase accepts the MoolSocial HTTPS return domain while
  Google and Mobile OTP remain available.
- Classification: `mvp_required`, because the founder-approved Screen03 email
  method is a core authentication path and the live Dev configuration currently
  blocks it.

## Bounded live inventory

- Project: `moolsocial-dev-503018`.
- Phone: enabled.
- Google: enabled.
- Email/Password and Email Link: absent from the enabled-provider table.
- Default authorized domains preserved:
  `moolsocial-dev-503018.firebaseapp.com` and
  `moolsocial-dev-503018.web.app`.
- `moolsocial.com`: not yet present in the authorized-domain table.
- Both `moolsocial-dev-503018.firebaseapp.com` and `moolsocial.com` currently
  return HTTP 200 for `/.well-known/assetlinks.json` with the exact
  `com.moolsocial.app` identity. No Hosting deployment is necessary.

No secret value, private identity payload or authentication material was read
or recorded.

## Smallest complete execution

1. Enable the existing Email/Password provider and its passwordless Email Link
   option.
2. Preserve Phone and Google.
3. Add only `moolsocial.com` to authorized domains, preserving the two defaults.
4. Re-read sanitized provider/domain state and the two public App Links files.
5. Run regression, MVP, C33J FIX2 and C33K gates on both PowerShell hosts.

Live email sending, Hosting deployment, AAB, Play and OPPO remain separate.

## Authority

The founder authorized the required actions on 15 August 2026 immediately
after C33J FIX2 listed the live-readiness prerequisites. This ticket consumes
only the two exact Firebase Authentication configuration writes above.
