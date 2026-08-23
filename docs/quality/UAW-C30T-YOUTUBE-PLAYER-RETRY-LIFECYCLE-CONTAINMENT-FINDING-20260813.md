# C30T YouTube player retry/lifecycle containment finding — 2026-08-13

## Finding

The official-player recovery surface displayed `Try again` for every failed state, but its callback called ordinary `select`. The controller deliberately refuses ordinary reselection after a same-video provider or native terminal failure; only retryable provider code 5 may recreate once through `retryPlayerFailureFromUser`. The visible retry therefore did not execute its advertised recovery contract. Separately, a platform-channel failure while enforcing lifecycle pause could escape the unawaited app-lifecycle callback.

## Bounded correction

Derive retry visibility from the controller snapshot, call the exact one-shot retry API, and leave terminal failures with only the existing official `Open YouTube` recovery. If lifecycle pause delivery fails, detach, release the process-wide lease, emit a sanitized terminal snapshot and do not rethrow.

## Verification

The controller, public-runtime and Android-boundary suites passed `45` serial tests. They prove the one permitted provider-code-5 retry budget, exact `retryPlayerFailureFromUser` UI wiring, retry visibility derived from `snapshot.failure.retryable`, terminal native recovery, lifecycle pause-channel failure detachment, and process-wide lease release. Evidence SHA-256: `49CDF5E4FE5A0FDD319D09975C74D323445CF91AC6026C138904620D6B305F37`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. The preserved C30S r60.44 AAB remains byte-identical. No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
