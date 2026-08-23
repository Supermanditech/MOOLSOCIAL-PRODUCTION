# UAW-C34P FIX11 Google Sign-In pre-APK evidence matrix — 2026-08-23

## Scope and acceptance boundary

This checkpoint is Google-only. YouTube, Facebook, X, Instagram, Apple,
Email Link, mobile OTP, SQL Connect, unrelated UI/backend expansion, AAB, Play
and Production remain held. No local, static, mocked, emulated or compile gate
is end-to-end Google acceptance. Acceptance requires a unique successor APK,
one in-place OPPO install, founder-completed private Google account selection,
and verified post-login auth/session/navigation persistence.

No successor version has been allocated. No FIX11 APK has been built or
installed. r60.84 remains installed, founder-rejected, consumed and
non-reusable.

## Exact r60.84 provenance established

- The installed OPPO package is `com.moolsocial.app`, version
  `1.0.0-r60.84`, version code `2026082184`.
- The installed base APK SHA-256 exactly matches the preserved r60.84 APK:
  `261B9E14E01FBA5BFB3D1021FCAD5AD2DA15538E7D814F4E22B86822D203D227`.
- The preserved APK is 104,588,128 bytes.
- The current Google/auth source, Android activity/build owners, Firebase
  configuration, pubspec/lock and focused Google test owner all matched the
  r60.84 source aggregate before FIX11 edits.
- Mapping-aware APK inspection proved the generated registrant, Firebase Core,
  Firebase Auth and MainActivity are present and integration_test is absent.
- The APK package is exact, its signature validates, and its signer matches one
  registered Android OAuth certificate for the package.
- The compiled ARM64 snapshot contains the exact configured Google Web OAuth
  client, Firebase API/app/project inputs, candidate marker and Google identity
  method/channel strings without emitting their values.

## Confirmed defects repaired

1. r60.84 failed founder Google Sign-In on the exact installed OPPO artifact.
   The failed visible outcome is confirmed; its exact live failure stage was
   not retained.
2. r60.84 forced Android through a custom deprecated GoogleSignIn
   startActivityForResult bridge and explicitly bypassed the locked official
   `google_sign_in_android` Credential Manager implementation.
3. The custom bridge treated a data-less canceled Activity result as successful
   cancellation. That erased the distinction between a user cancellation and
   a native/configuration path that returned no identity.
4. Runtime observability recorded only coarse start/final receipts. Native
   initialization, chooser request, identity return, Firebase credential
   exchange and their timeouts/failures were not durably separable.
5. The sideload preparation wrapper authorized the consumed FIX8 ticket, not
   FIX11. Its nominal GoogleOnly profile still enabled YouTube private proof,
   mobile OTP and the global full-social runtime inputs.
6. The APK regression state still described r60.84 as pending founder
   acceptance and recorded zero r60.84 provider failures.

The repair now:

- uses `google_sign_in_android` 7.2.16 as the only Android Google identity
  owner and removes the custom legacy activity bridge/direct Play Services Auth
  dependency;
- retains the protected MainActivity provider seam markers and approved UI
  projection;
- emits fixed, value-free `MOOLSOCIAL_GOOGLE_AUTH` stages for native request,
  initialization, UI request, identity return/no-identity, Firebase credential
  start/complete/failure/timeout;
- preserves `auth-google-native-no-identity` through JourneySession and shows
  the sanitized founder-visible recovery code `GSI-N01`;
- retains sanitized Firebase account-collision, invalid credential, disabled
  account, throttling, network and unclassified mappings;
- makes FIX11 preparation and build runtime explicitly Google-only, with all
  held providers and mobile OTP fail-closed;
- prevents the YouTube private Dev App Check activation from entering the
  Google-only lane while keeping live Firebase Auth/session bootstrap enabled;
- records r60.84 as founder-rejected, consumed and non-reusable, with all five
  founder failures and the FIX11 build/install machine-held.

## Confirmed non-causes / locally ruled-out candidates

| Layer | Evidence | Conclusion |
|---|---|---|
| Installed artifact identity | Installed base APK hash equals preserved r60.84 hash | No wrong-APK or stale-install explanation |
| Package/version | Package, version name and version code read back exactly | No package/version selection mismatch |
| APK signature | Signature valid; one signer; signer matches registered Android OAuth certificate | No evidenced sideload signer/OAuth certificate mismatch |
| Web OAuth selection | Exactly one Web OAuth client; compiled client matches google-services Web client | No evidenced Android-client-vs-Web-client runtime input mismatch |
| Firebase/plugin packaging | Mapping-aware registrant, Firebase Core/Auth and MainActivity present | No missing Firebase plugin packaging defect |
| Test packaging | No integration_test APK entry/class | No test-plugin production contamination |
| Source provenance | Relevant pre-FIX11 owners matched r60.84 manifest | Forensic trace applies to the exact built source |

## Evidence matrix

| Layer / claim | Static or local proof now | Emulator/mock proof now | Requires signed OPPO/provider interaction |
|---|---|---|---|
| Screen 03 Google tap reaches JourneySession | Widget test passes | Fake gateway dispatch count/result | Founder tap confirms physical hit target only |
| Google-only provider availability | FIX11 gate proves only Google is enabled by runtime projection | Widget unavailable-state tests | Installed successor readback must show held providers non-actionable |
| Official native bridge availability | Source gate, locked plugin, mapping-aware APK precedent, release Kotlin compile | Injected gateway seams | Successor must open the real OPPO Google chooser |
| Credential Manager initialization/retry | Unit tests prove initialize-once and failed-init retry | Injected exception fixtures | Device/Play Services behavior cannot be simulated as acceptance |
| Cancellation/no-identity propagation | Unit/widget tests preserve stage and `GSI-N01` | Synthetic cancellation | Only OPPO can distinguish founder cancellation from repeated provider/config no-identity behavior |
| Firebase credential exchange | Contract tests prove ID-token credential call, timeout and safe error mapping | Fake Firebase client | A real Google ID token exchange is private and founder-only |
| Account collision | Sanitized mapping and negative fixture pass | Synthetic Firebase exception | A real collision depends on the founder-selected account; no private account probing is authorized |
| Authenticated bootstrap | Interactive UID binding, mismatch, timeout, rollback and retry tests pass | Fake verified UID/token | Real Firebase currentUser/token reload must succeed after founder sign-in |
| Navigation/session persistence | Success, rollback, relaunch and ready-route tests pass | Memory/store fixtures | OPPO relaunch/back/navigation must be verified after real sign-in |
| App Check interaction | Google-only source gate proves YouTube Dev App Check activation is excluded | Activation tests remain independent | Any live Firebase enforcement effect is observable only in signed device flow/config readback |
| Package/signing/OAuth | r60.84 signer/package/config match proved; successor rules encoded | N/A | Successor APK must be independently reverified after its one build |
| Google provider enabled in Dev Identity Platform | Founder console evidence confirms Google Enabled and the Web SDK configuration section present | No identifier or secret value was retained | Console presence is established; signed OPPO exchange remains live-only |

## Focused verification completed

- FIX11 Google forensic readiness gate: passed.
- Google Android identity/Credential Manager readiness: passed.
- Approved UI locks: passed.
- Scoped Flutter analyzer over modified source/tests: no issues.
- Firebase/Google identity gateway tests: 25 passed.
- Runtime composition/widget/bootstrap owner: passed.
- Public auth failure/availability, Screen 03 session and Screen 03 widget group:
  passed.
- Release Android resource integrity with forced processReleaseResources: passed.
- Release Kotlin compilation: passed.
- Reviewed Kotlin plugin and manifest namespace baselines: passed.
- PowerShell preparation/build/readiness scripts: parse with zero errors.
- Wrong candidate and missing GoogleOnly negative preparation checks reject before
  any secret prompt.
- Mandatory APK/AAB build-control self-test: passed after aligning the wrapper,
  exact APK runtime allowlist and negative fixtures to FIX11 Google-only truth.
- Official Google Credential Manager readiness: live positive and corrupted
  authenticate-call negative fixture both pass.
- Android release lint: zero errors and one reviewed historical unused-resource
  warning.
- Whole-mobile analyzer: no issues.
- Focused Google, bootstrap, navigation, retry, recovery and Screen 03 owners:
  102/102 tests passed.
- Unique successor version `1.0.0-r60.85` (`2026082385`) is allocated.
- The 650-row final build-input manifest independently replays with zero
  malformed, duplicate, missing, changed, escaped or private-machine-input rows;
  SHA-256 `58936FBF15BFDE0FFAB58DA4FC79972B8DD44F87922A27689CDC1ACB9AE75A3B`.
- The source seal includes the parser-checked local signer-preflight and
  successor-build launchers. The build launcher requires the same-process
  preflight marker and remains withheld until the secure no-artifact preflight
  succeeds.

These results prove local wiring and contracts only. They do not authorize an
APK build by themselves.

## Remaining blockers and hypotheses

### Resolved external readback blocker

The earlier Admin configuration and public auth URI probes returned HTTP 403
(REG3491 and REG3493). On 2026-08-23, founder-provided Dev console evidence
confirmed Google is Enabled and the Web SDK configuration section is present.
No identifier or secret value is retained in this evidence record, and no
console mutation was required. The readback blocker is resolved.

### Live-only hypotheses

- The official Credential Manager chooser may still return a cancellation-class
  result for a configuration problem; official plugin documentation states
  that some configuration failures cannot be distinguished from user
  cancellation. FIX11 makes this observable as `GSI-N01`, not as acceptance.
- Google Play Services/account chooser behavior on the connected OPPO is not
  locally provable.
- Firebase Auth provider exchange, account collision/linking and token reload
  are not proven until the founder selects a private account.
- Post-login persisted navigation is not proven until a real authenticated
  session is created on the OPPO.

## Build decision

The Dev provider readback, local historical APK/AAB control replay, FIX11 gates,
unique version allocation and cycle-03 final source seal are green. Build remains
machine-held only for the actual upload-keystore signer/OAuth preflight, which
requires the founder to enter both passwords in the existing secure local
PowerShell prompt without exposing them to Codex output. The same local process
must run the sealed no-artifact preflight launcher before the one build. All artifacts and
evidence remain on the local laptop; no upload, Play, AAB or remote project
mutation is authorized.
