# C30W r60.47 cold-start source repair qualification — 2026-08-14

## Outcome

The blocking r60.47 cold-start regression is repaired in source and guarded by
fail-closed release controls. The failed Play-installed r60.47 candidate is not
reclassified: it remains failed and Internal Testing only.

The Flutter bootstrap now uses one testable five-key release configuration
contract. Missing release setup renders a customer-safe first frame instead of
throwing before `runApp`. No internal key name or credential value is rendered.

The single-AAB wrapper now invokes the C30W release-runtime build gate before
the app-bundle invocation. Future candidate state must prove exactly the
Firebase Android API-key and Google server-client-ID define names, exactly
three hidden founder prompts, transient cleanup, and founder qualification of
the server client ID. The post-install phase rejects blank UI, timeouts, fatal
Flutter/AndroidRuntime errors, ANR, wrong installer/package/version, missing
in-place-update proof or missing artifact relationship.

## Qualification

- branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- source files: 1,091
- source fingerprint:
  `2CBABF3E5C7400E3193A3083624B09C975DD279BFE1CF34A2F1A628D0BBC9DDA`
- focused manifest: 59 files
- focused manifest SHA-256:
  `6F6C9C7AE281510F156CA4869854A37D0424338F88839D23F64C8A1114F47147`
- cycle 1: 409 passed, 3 declared skips, 0 failed, 0 errors
- cycle 2: 409 passed, 3 declared skips, 0 failed, 0 errors
- whole-mobile analyzer: clean
- PowerShell 7 source gate: passed
- Windows PowerShell source gate: passed
- corrected C30V wrapper static gate: passed with three hidden inputs
- failed r60.47 state replay through the new build phase: rejected as required

## Remaining release boundary

No successor AAB, upload, activation, installation or OPPO mutation was
performed or authorized by C30W. A future candidate requires a new exact
founder build/upload/install authorization, fresh sealed-source qualification,
founder-only secure inputs, and the mandatory C30W `build` and `postinstall`
gate phases. The current app on OPPO remains the known failed r60.47 candidate.
