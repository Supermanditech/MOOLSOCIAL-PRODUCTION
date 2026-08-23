# C30T qualifier provider-revision hardcode finding

Date: 2026-08-13

## Finding

The local C30T qualifier correctly requires the future Dev reviewer profile to expose public discovery plus read-only owner connection while every mutation, upload, Analytics and Live capability remains false. It also hardcoded `youtubeprovider-00036-qer`, the currently deployed revision whose `ownerConnect` flag is false. Any authorized environment correction must create a new Cloud Run revision, so the unchanged qualifier could never pass after that correction.

## Bounded correction

The qualifier now loads the C30T machine state and compares the live `youtubeprovider` and `youtubeoauthcallback` revisions with the exact non-empty identities sealed there. Static readiness rejects restoration of the stale revision hardcodes. A future separately authorized deployment workflow must update the machine revision only after exact read-only deployment evidence.

No provider, Hosting, machine revision, build, upload, install or external communication is changed.
