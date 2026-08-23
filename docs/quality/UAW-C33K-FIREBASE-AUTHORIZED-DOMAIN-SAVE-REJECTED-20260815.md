# UAW C33K Firebase authorized-domain save rejected

Date: 2026-08-15

Regression: `REG-20260815-2522-C33K-FIREBASE-AUTHORIZED-DOMAIN-SAVE-REJECTED`

## Finding

The one authorized submission to add exactly `moolsocial.com` returned the
visible Firebase console message `Error updating authorised domain list`. The
dialog remained open and the authoritative domain table still contained only
the two default domains, so the action count remains zero.

This is the second distinct Firebase Authentication configuration rejection in
the same signed-in console session. Read-only provider, domain and Hosting
access works. No secret, private identity payload or email address was read.

## Resolution rule

- Do not retry another Firebase console write in the same unchanged session.
- Treat repeated provider and authorized-domain rejection as a shared
  authorization/session prerequisite blocker rather than invalid customer
  input.
- Preserve all action counts at zero until authoritative postwrite tables
  change.
- A source-only Firebase Auth configuration preflight may continue, but no CLI
  deploy occurs until the console session or IAM condition is corrected.

No Hosting, email, build, Play or device action was performed.

## Resolution

The founder explicitly refreshed the Firebase console page. After the provider
write succeeded and the unchanged provider dialog was closed, one fresh exact
`moolsocial.com` submission succeeded. Authoritative readback showed
`moolsocial-dev-503018.firebaseapp.com`, `moolsocial-dev-503018.web.app` and
`moolsocial.com`. The rejected pre-refresh submission remains uncounted; the
successful post-refresh domain write is counted exactly once.
