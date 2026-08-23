# C30T YouTube read-only connection state-continuity finding — 2026-08-13

## Findings

The active production route correctly uses `uploadCapabilityAuthorized=false`,
requests `YouTubeConnectPurpose.readonly`, and does not render upload controls.
Two local state defects remained:

1. Init, lifecycle-resume, disconnect and callback refreshes had no ordering
   owner. An older completion could replace a newer connected channel status.
2. A `failed` callback query was reapplied on every refresh. After the user
   retried, the old failure could return on the next lifecycle refresh.

## Correction

Each connection refresh now owns a monotonically increasing generation; stale
success and error completions are ignored. The callback failure is held as one
pending notice, consumed after its first authoritative refresh, and re-armed
only when an updated route widget supplies a newly changed failed result.

## Verification

The focused creator/connection suite passed `11` tests, including deterministic
out-of-order lifecycle completion and failure-consumption journeys. It also
reproves read-only purpose, exact connected channel identity, disconnect/privacy
controls and upload-surface exclusion. Evidence SHA-256:
`D2C61AAB6AE76CC3BEB1AD70664B73DFB87B83873FFEE90F83DFE48865839340`.

No provider deployment, OAuth scope change, AAB, Play action, OPPO mutation,
Hosting action or external communication occurred.
