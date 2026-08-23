# UAW-C34P all-public-authentication source qualification

Date: 18 August 2026 (IST)
Ticket: `UAW-C34P-ALL-PUBLIC-AUTHENTICATION-SHARED-GATEWAY-EXECUTION`
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
Disposition: local source/contracts qualified; live provider and device
acceptance separately pending

## Outcome

The existing founder-approved Screen 03 v5, `/sign-in` route,
`JourneySession`, account bootstrap/rollback and protected-return path remain
the only public authentication owners. No login presentation, accepted
reference, route, session or backend owner was created or changed.

The C34P source wave now provides:

- one sanitized public-authentication failure taxonomy; GoogleSignIn and
  Firebase provider messages are mapped by enumerated code and provider-authored
  exception text cannot reach customer copy;
- one runtime readiness contract that keeps each method unavailable until its
  exact dependencies are qualified;
- one Google ID-token/Firebase dispatch shared by Google and YouTube, with no
  YouTube credential or channel scope at login;
- the existing Firebase passwordless Email Link cold/foreground/process-loss/
  exact-return owner and independent Firebase Phone Auth send/verify/rollback
  owner, with mobile availability additionally requiring candidate-specific
  attestation readiness;
- one pure X OAuth 2.0 authorization-code/PKCE contract using secure randomness,
  RFC 7636 S256 through the pinned `crypto` package, exact redirect/state,
  single-use bounded attempts, `tweet.read` plus `users.read`, conditional
  `offline.access`, token-exchange description and public-client revocation
  requiring `token` plus `client_id`; and
- one pure Facebook Login contract requiring the exact Android package and
  launch activity, separately qualified key-hash fact, exact HTTPS redirect,
  `public_profile` only, no email permission by default, native-adapter
  readiness, cancellation/denial/collision/network outcomes, logout,
  revocation and data-deletion readiness.

The former direct Firebase `TwitterAuthProvider` and native
`FacebookAuthProvider` dispatches were removed. They were not compliant live
paths: the founder requires X OAuth 2.0 PKCE, and native Facebook requires its
separately configured SDK adapter. `main.dart` therefore keeps X and Facebook
unavailable with `xPkceAdapterInstalled: false` and
`facebookNativeAdapterInstalled: false`. X additionally requires a separately
authorized server exchange that validates the provider result and returns a
Firebase custom token. No backend write was authorized under C34P.

## Verification

- Changed-owner format gate: 10 files, 0 changes.
- Whole-mobile Flutter analyzer: no issues.
- C34P static shared-gateway gate:
  - PowerShell 7: passed;
  - Windows PowerShell 5.1: passed.
- Focused new suites:
  - sanitized failure/runtime availability: `24/24`;
  - Google/YouTube/Firebase shared gateway: `13/13`;
  - X OAuth 2.0 PKCE final strengthened suite: `12/12`;
  - Facebook Login contract: `19/19`.
- Reused lifecycle suites:
  - Firebase Phone Auth independent journey: `6/6`;
  - Screen 03 passwordless Email Link parity: `10/10`;
  - foreground Email Link return: `3/3`;
  - Android same-device exact Email Link return: `3/3`;
  - public-review Firebase Email Link selection: `5/5`;
  - Google account-selection configuration parity: `2/2`;
  - social-provider truth: `2/2`;
  - Screen 03 session/bootstrap/protected-return: `11/11`.
- Affected manifest cycle 1: 12 suites, `110/110`, exit 0.
- Affected manifest cycle 2: 12 suites, `110/110`, exit 0.
- Approved UI reference and production locks: passed before and after.
- MVP delivery-discipline and `-RequireExecutionAuthorized` gates: passed for
  the selected beyond-MVP C34P parent.
- Registry generation after all discovered incidents:
  entries `2935`, SHA-256
  `B8CF8311D3803FCD4D50FE483B86041D98C94448256872FFA5E15FCE8C5D761C`.

## Exact implementation hashes

- sanitized failure taxonomy:
  `42B55B7222923428B93E7973AF161B35AB0B7D68C5C99495BD125AEE178948A9`
- runtime availability contract:
  `AB93A8D4FF9869230BAC5D309B983C4585E2D03C89F5B42ABDAC35B0E9382556`
- X PKCE contract:
  `41A059BB72E00DFC693DBEEA4405F83241ED4F301CC1E99AC51AF31FD8AF8555`
- Facebook Login contract:
  `03A0229D89A8E5988A63BFECC37FCD71D895AD519662965FC03ADD1E34330E97`
- Firebase/public gateway owner:
  `26CF1E395C663A229B277FFBD76C39204F0117508D8E43CC99C2E51A71073761`
- runtime bootstrap/availability wiring:
  `0E22B4074FC0C02637A15C6A37E87244769E810E932964242C53292D4E2C86AB`
- shared Google/Firebase test:
  `D43533AECD134093D20DDB7F2B9B8AB4404CE52EE8A5F4967B2BC1B961184919`
- failure/availability test:
  `BF50A307AD26AB8FC1F31054F44F4F5593891CAC4E2BDC57973F4D013C7E028F`
- X PKCE test:
  `5A3306808ABED19EE35ECE2876894FBA8E587FE6133C55E1997479548F53D97E`
- Facebook Login test:
  `1F31431310A599F0502253DE829CF8E1694A4C32288721864D9B1723CC9772EC`
- C34P static gate:
  `8C96238EC58E06E2BEFE2C420F41EA3EE204FAD8921C53270975ABFF15C7AF11`
- robustness/reuse assessment:
  `A2E675F7DDC1716847AEE824FE7CF64DA14228F3CA8E2E4B3A095C3345E8F4F8`
- MVP scope state:
  `796E1AB136B5E898870C10EE28B5D63EC97018333CC10E22153F1E0A1C9BCEC3`

## Held boundaries and remaining work

No provider console, Firebase/Meta/X write, provider-app or credential
creation, secret/token/private-identifier access, real email/SMS, funds, build,
Play action, OPPO action, account chooser or private login occurred. The
connected OPPO and rejected r60.72 install were not mutated or reused. C34L
remains preserved and paused.

Production/runtime acceptance remains open for:

1. a separately authorized X provider app/exact callback and Firebase custom-
   token broker, followed by native browser/return integration;
2. a separately configured native Facebook SDK adapter and exact Meta/Firebase
   app/package/activity/key-hash/redirect/privacy/data-deletion facts;
3. candidate-specific Google/Play-signing, Phone attestation and live provider
   configuration gates;
4. founder-only private email, mobile OTP and provider/account journeys; and
5. one separately authorized AAB, Internal Testing activation and in-place OPPO
   acceptance candidate.

Accordingly, Google/YouTube, Email Link and Mobile OTP have production-oriented
source and regression evidence behind held live gates. X and Facebook have
qualified protocol/configuration/fail-closed source contracts, but are not live
customer sign-in implementations until the explicitly held adapter/backend and
provider dependencies are authorized and completed.
