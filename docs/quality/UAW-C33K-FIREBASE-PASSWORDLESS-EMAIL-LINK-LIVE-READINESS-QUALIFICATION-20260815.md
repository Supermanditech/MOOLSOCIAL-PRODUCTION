# UAW C33K Firebase passwordless email-link live-readiness qualification

## Outcome

`UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS` is live-readiness
qualified for Firebase project `moolsocial-dev-503018`.

Exactly two authorized Firebase Authentication writes were accepted and
counted after the founder refreshed the console session:

1. Email/Password was enabled with passwordless Email Link enabled.
2. Exact authorized domain `moolsocial.com` was added.

The pre-refresh rejected submissions remain preserved as uncounted regression
evidence. No failed submission was treated as a successful write.

## Authoritative sanitized readback

- Provider table: Email/Password, Phone and Google are present.
- Provider editor: Email/Password is checked and Email Link is checked.
- Authorized domains:
  - `moolsocial-dev-503018.firebaseapp.com`
  - `moolsocial-dev-503018.web.app`
  - `moolsocial.com`
- `https://moolsocial-dev-503018.firebaseapp.com/.well-known/assetlinks.json`:
  HTTP 200, one exact `com.moolsocial.app` association, SHA-256 fingerprint
  present.
- `https://moolsocial.com/.well-known/assetlinks.json`: HTTP 200, one exact
  `com.moolsocial.app` association, SHA-256 fingerprint present.

No Hosting deployment was necessary because both public association files were
already current.

## Source and failure-handling truth

- `firebase.json` declares `auth.providers.emailPassword: true` and preserves
  the existing Google provider declaration.
- The locally installed Firebase CLI does not support `--only auth`; its dry
  run failed before deployment and that path is closed without tool update,
  access-token workaround or retry.
- Initial console provider and domain rejections are registered as REG2520 and
  REG2522 and were resolved only after explicit founder refresh plus
  authoritative postwrite readback.
- Firebase editor interaction failures are registered as REG2519 and REG2524;
  exact fresh-DOM actions and closed-dialog readback resolved them.
- The PowerShell assetlinks verifier parser mistake is registered as REG2525
  and the corrected read-only command passed on both public origins.
- The C33J FIX2 checker is intentionally active-ticket-only and rejected a
  replay after C33K selection. REG2526 records the mismatch; the predecessor's
  sealed dual-host qualification remains preserved and is not falsely retried.
- Current C33J FIX2 focused source matrix: 3 passed, 0 failed.
- Current whole-mobile Flutter analyzer: no issues.

## Held boundaries

Action counts under C33K are provider enablement `1`, authorized-domain addition
`1`, Hosting deployment `0`, live email send `0`, AAB build `0`, Play upload or
activation `0`, and OPPO mutation `0`.

No secret value, credential, token, private identity payload or customer email
address was accessed or recorded. Identity Platform Marketplace activation,
funds, live email acceptance, release construction, Play and OPPO testing remain
separate gates.

## Final gates

- Regression memory: 2,497 entries; 1,558 applicable implementation entries.
- MVP delivery-discipline and exact C33K execution-authority gate: passed.
- Approved UI/reference locks: passed.
- C33K postwrite gate: passed in PowerShell 7 and Windows PowerShell.
