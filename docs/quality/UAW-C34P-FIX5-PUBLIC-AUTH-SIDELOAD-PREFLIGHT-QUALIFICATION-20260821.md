# UAW-C34P FIX5 public-auth sideload preflight qualification

## Outcome

One checksum-bound release APK may be built with the founder-held upload key
and installed once on the connected OPPO for method-by-method public-auth
preflight. This does not authorize Play upload, Production promotion, private
login, real email or real SMS.

## Source qualification

- branch `remediation/prototype-conformance-2026-07-20`;
- HEAD `f6dfe7587aa02d782e94282d14af8bafff48ded0`;
- Flutter analysis: no issues;
- focused runtime: 28/28;
- two identical affected cycles: 20 suites, 190/190 each;
- approved UI locks: passed;
- FIX6 and shared C34P gates: passed in PowerShell 7 and Windows PowerShell 5.1;
- source manifest: 287 files, SHA-256
  `461D39D27CB264A49017FDD854C266CB77FEA35860ED252660A4545C7A792E30`.

The first gated release attempt produced no APK because current AGP required
explicit custom resource-value enablement. REG3074 records the failure; the
Android application module and self-test now enforce `resValues = true` before
the single registered retry.

The second gated release attempt produced no APK because an ignored stale
`GeneratedPluginRegistrant.java` referenced the test-only integration plugin.
REG3075 preserves that file byte-for-byte outside the compiler source set; the
Android source-set exclusion keeps it out of release compilation. REG3076
retains the original historical evidence path and verifies that it matches the
preserved copy.

The first attempted exclusion used an unsupported AGP 9 Kotlin DSL API and was
stopped by the targeted compile precheck under REG3077. The final source-set
contract removes the empty Java root while retaining Kotlin and generated
variant sources.

The third gated attempt reached final package signing and produced no artifact
because the supplied key password could not recover the upload alias. REG3078
adds a founder-local hidden re-prompt and Java keystore validation that passes
no password on a command line.

## Runtime truth

- Google and YouTube may open through the explicit locally registered signing
  branch; Play signing qualification stays false.
- X, Instagram and Facebook point at the Dev public-auth broker and their
  configured exact callbacks.
- Email Link remains enabled with the exact authorized domain.
- Mobile OTP remains unavailable because sideload cannot qualify production
  attestation.
- Apple remains unavailable due to the founder-reported account-recovery
  blocker.

## Acceptance boundary

Sideload can preflight launch, Screen 03, Google/YouTube shared identity,
Facebook native configuration, provider handoffs and fail-closed recovery. It
cannot prove Play Integrity/App Check acceptance, Play signing, production SMS,
or public Meta review. Those remain later gates.

## Built artifact

- release APK: qualified;
- bytes: 82,534,780;
- SHA-256: `9864620717B2B9EBACF651D21C8D6EC2FC6FD7A75BBC7480ADDB7CFD91372426`;
- APK signature: valid;
- signer matches preserved upload certificate: yes;
- package/version: `com.moolsocial.app`, `1.0.0-r60.77+2026082177`;
- debuggable: false.

The OPPO currently holds a Play-signed predecessor. Android cannot install the
upload-key-signed sideload as an in-place update, so uninstalling the existing
app and clearing its local data requires a separate destructive-action
confirmation before installation.
