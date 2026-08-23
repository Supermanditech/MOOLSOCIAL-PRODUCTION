# UAW-C34P FIX1A all-eight public authentication source qualification

Date: 18 August 2026 (IST)
State: production source and local tests qualified; live provider configuration,
private founder acceptance, build, Play and OPPO remain explicitly unclaimed

## Qualified customer outcome

The existing locked Screen 03 gateway retains exactly eight public methods:

1. Google;
2. YouTube through the same Google identity;
3. Apple through Firebase's Apple provider;
4. X through OAuth 2.0 authorization code plus PKCE S256;
5. Instagram for an eligible professional account only;
6. Facebook through the native SDK with `public_profile` only;
7. Firebase passwordless Email Link; and
8. Firebase Mobile OTP.

No duplicate screen, route, JourneySession, Firebase session or authentication
backend was added. Brokered X and Instagram callbacks reuse the existing
JourneySession bootstrap, rollback, authenticated relaunch and protected-return
owners for foreground and cold/process-death paths.

## Source outcome by method

- Google and YouTube retain one native Google identity proof and one Firebase
  credential dispatch. Sanitized enumerated Google/Firebase failures remain the
  only public error surface.
- Apple uses `AppleAuthProvider`, the iOS Sign in with Apple entitlement and
  Xcode capability. Availability remains closed until the Apple/Firebase provider,
  platform and revocation facts are externally qualified.
- X uses an App Check-protected one-use server attempt, exact redirect/state,
  S256, only `tweet.read users.read`, public-client exchange, HMAC project-scoped
  Firebase identity, custom token and immediate transient provider-token
  revocation. `offline.access`, OAuth 1 and client secrets are absent.
- Instagram uses its own exact professional-login broker, only
  `instagram_business_basic`, truthful BUSINESS/MEDIA_CREATOR eligibility,
  `account_ineligible` for unsupported personal accounts, custom-token completion
  and transient token revocation. It is not Facebook Login relabeled.
- Facebook pins `flutter_facebook_auth` 7.2.0, requests exactly
  `public_profile`, passes the transient native credential directly to Firebase,
  and implements a separate tested Graph permission-revocation seam using an
  exact versioned `/me/permissions` endpoint, action-time SDK token retrieval,
  Bearer-only transport, disabled redirects, 256-byte response cap and strict
  success parsing. Logout is not substituted for revocation.
- Passwordless Email Link and Firebase Mobile OTP retain their previously
  qualified independent lifecycle, process recovery and fail-closed readiness.

## Verification

- Whole-mobile `flutter analyze --no-pub`: no issues.
- Backend `npm run typecheck`: passed with `tsc --noEmit`; no deployment or
  production build ran.
- Targeted backend tests: X `12/12`; Instagram `10/10`.
- Focused mobile suites:
  - sanitized failure/runtime availability: `26/26`;
  - shared Google/YouTube/Apple/Facebook Firebase gateway: `18/18`;
  - pure X PKCE contract: `12/12`;
  - X mobile adapter: `10/10`;
  - Instagram mobile adapter: `5/5`;
  - Facebook pure contract: `19/19`;
  - Facebook native/Graph revocation adapter: `18/18`;
  - shared cold/foreground/bootstrap/platform integration: `5/5`.
- Reused Email Link, Mobile OTP, Google selection, social truth and Screen 03
  lifecycle suites remained included in the affected manifest.
- Affected mobile cycle 1: 16 suites, `155/155`, exit 0.
- Affected mobile cycle 2: identical 16 suites, `155/155`, exit 0.
- Approved UI reference and production locks: passed.
- C34P shared-gateway and FIX1A all-eight gates:
  - PowerShell 7: passed;
  - Windows PowerShell 5.1: passed.
- MVP delivery discipline and `-RequireExecutionAuthorized`: passed for selected
  `UAW-C34P-FIX1A-ALL-EIGHT-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION`.
- Registry generation: entries `2964`, SHA-256
  `8E3D0E23736F0A405AF08AF57A9860479D2F12AC5952D57F0046D6DC0662DFB8`.

## Exact implementation hashes

- runtime wiring `apps/mobile/lib/main.dart`:
  `B0AF5A728696509346769C85421341B4A8F2E62AF45FF3DF06D7537733625D27`
- runtime availability:
  `1EE3D620CE6D090E3A01247C6EC55C622051F1167B7781380AECE1EC9CE00E7F`
- shared session contract:
  `3575D3D6B54316A64C6DCB016E785FC5962D48790AFE660EE5E6334CE4DB1D1B`
- JourneySession callback lifecycle:
  `D0DD33F9C2F24D4D39639294DDF727D57177445F643F86C285282A1D990A97E0`
- Firebase shared gateway:
  `44D624C172CDE3CF5A409D21ED74772F88A9CA61D63D12CCBC2D8A8D761361D9`
- app foreground route owner:
  `5CD39E0AFB424F63AF13E582C80386188CA874414EDBCD9D02986B76C699E16C`
- X PKCE contract:
  `41A059BB72E00DFC693DBEEA4405F83241ED4F301CC1E99AC51AF31FD8AF8555`
- X mobile adapter:
  `05359ECD4E1C3D2D7682E4EF253748642F6384984D29C79A5EDA68AB6064E289`
- Instagram mobile adapter:
  `B43E445F6304B4F195890E4E78EDF5DB9524275FAB6F755D55CA77D8C19D580B`
- Facebook contract:
  `A5A65171789850C7B3D38C2290D3387D8D99750E9D8CED0F94DCCB887DFF58C9`
- Facebook native/revocation adapter:
  `02469367C2EB06C5E9F0269ACE7D5274FF7836A53E44136722A5FF54FF07ADFE`
- X backend broker/test:
  `9333D099978CD392AA252FF83D07FCA24FDBCCDC693CC36D2EC5601EE5323E10` /
  `DEDEE1974E1E9E62C8A9B1E3EB5B5B8FA7A93A11878922C6EBA9E5094B9E91F8`
- Instagram backend broker/test:
  `FD70D7BDF4FC429B79B5A994CC030147E00F5EEF6ECFDB02D975F62F4381D01A` /
  `F102027DF26FE5DBABFA759F692B95FA4CF96F539FD78071D71B26AD8C823202`
- backend export:
  `FB9B381E8A60B55243E7CAC55585EA15AF871E4864DC58DDDF96BCCC69B052CD`
- Android manifest:
  `D3AA99429283E668A11559F1182E0CA6BD2E79B273FF99F8729D4F54BE77A2C8`
- iOS entitlement/project:
  `B2CFF52CF90D8CC5BE5A2803C78F759D1DFFCF00F0F54615B5330C53FEA46D29` /
  `787BA753DD456B374382F8DC0DC1DB4B54A4A6EF424D7CD1A62ABAB9A3F00598`
- C34P shared gate:
  `1F7832E48F7584202E82EFD6C09AF333E179488912AE99EFCB1EDFC5D7E570BF`
- FIX1A all-eight gate:
  `5834394A754C902D9BA0AFABC41755F536458D5249E75BFBA5CC338062B2C05D`

## Git and privacy boundary

- branch: `remediation/prototype-conformance-2026-07-20`;
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`;
- dirty-tree non-emitting digest at the qualification pre-report checkpoint:
  bytes `591533`, records `7214`, SHA-256
  `2333FF68A8B51C64503BF5F4BA32B061F048342669A299C06425A5F819430053`;
- the large pre-existing dirty worktree was preserved;
- no commit, push, merge or main-branch action occurred;
- no account identifier, private email/phone/link, OTP, password, provider
  chooser content, real token, secret or key-hash value was entered or retained.

## Explicitly unclaimed live completion

This qualification is source/test readiness, not live provider acceptance.
Production enablement still requires founder-owned, externally verified provider
and release facts: Google/Firebase/Play signing; Apple Developer/Firebase return
and revocation configuration; X public client/redirect, Functions runtime values,
App Check and Firestore abandoned-attempt TTL; Instagram professional-login app,
exact redirect, app review/live mode and server runtime values; Facebook app ID,
client token, package/activity, debug and release key hashes, redirect, privacy,
data-deletion and exact versioned Graph endpoint. Real Email Link, real SMS OTP,
private provider journeys, build, Play/Internal Testing and OPPO acceptance were
not performed and must not be inferred from the green local evidence.

## 20 August 2026 production-auth continuation addendum

The dedicated `20-08-2026` continuation preserved the locked Screen 03 and
reused the prior qualified implementation. It corrected two newly detected
source/test defects before official cycles:

- the mobile public-auth supplier now uses one Firebase App Check limited-use
  token per request, matching backend `verifyToken(..., { consume: true })`
  replay protection; the ordinary cached `getToken()` path is absent;
- the unused pure X contract and its test no longer permit `offline.access` or
  a refresh lifecycle. Every X owner now enforces exactly `tweet.read` and
  `users.read`.

Method-by-method focused evidence is green:

- Google native identity to Firebase `1/1` and YouTube through the same Google
  identity `1/1`;
- Apple Firebase dispatch/failure `3/3` plus platform capability `1/1`;
- X pure PKCE `12/12`, mobile adapter `10/10`, backend broker `12/12`;
- Instagram professional mobile adapter `5/5`, backend broker `10/10`;
- Facebook minimum-permission contract `19/19`, native/Firebase/Graph
  revocation adapter `18/18`;
- passwordless Email Link native lifecycle `10/10`, foreground return `3/3`
  and Android exact-return configuration `3/3`;
- independent Firebase Mobile OTP `6/6`; and
- shared failure/readiness including the limited-use App Check composition
  `27/27`.

Two fresh identical affected cycles passed the exact same 16 literal suites at
`158/158` each. Whole-mobile analysis reports no issues. Backend
`tsc --noEmit` passes. Targeted compiled backend X and Instagram suites remain
`12/12` and `10/10`. Approved UI locks pass. The shared C34P gate and FIX1A
all-eight gate pass in PowerShell 7 and Windows PowerShell 5.1.

The current registry generation is `2972` entries at SHA-256
`2CD3B0C0862E75CF53D744D46801B57FB86AC39521A27F6E290711B046683466`.
The post-qualification non-emitting dirty-tree digest is bytes `592315`,
records `7223`, SHA-256
`057D2736CAFBD0CFA641B33BA99B024D6641AB597A466359B7C23CBFFCBB6AD8`,
stderr bytes `0`, exit code `0`.

Changed production/test gate hashes:

- `apps/mobile/lib/main.dart`:
  `D4695ED10077CF8C3C2F9A6E1DE5A01081DEC0611A1E398468723F1739A4AC05`;
- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`:
  `422398E55002838C997ED909E53C09CF0AE6F319F5EA2E48FF7109FCAE3F9D6F`;
- limited-use readiness test:
  `2E065222DD758092D9158DCD1EBF76DC2B7C723DE22D79A69B1F6485A828A0BE`;
- X pure-contract test:
  `0F7C4E55F8A85CA26A65960053D7CCBEC30252C0AF9CA1E8E07F5D197A7BFE02`;
- shared gateway gate:
  `5BD7EB9A37EC12D4F7E02E73B02EE64D2F6A0052090E3DE64393A2F9CAFAA1B8`;
- FIX1A gate:
  `84DEB03869EADB08E87137B5CCABAEDF5526EA7607174F59FF3C6F1C7D5F69F1`.

No provider-console write, deployment, provider request, real authentication,
real email/SMS, private input, build, Play, OPPO, funds, commit, push, merge or
main-branch action occurred. Live provider readback, build/Internal Testing and
OPPO method-by-method acceptance remain later gates and are not implied by this
source qualification.
