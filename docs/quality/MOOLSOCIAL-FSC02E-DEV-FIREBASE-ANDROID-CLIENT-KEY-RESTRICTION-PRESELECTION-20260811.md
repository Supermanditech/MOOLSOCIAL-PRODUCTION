# FSC02E Dev Firebase Android client-key restriction preselection — 11 August 2026

## Bounded founder finding

The live Firebase Android app and qualified r60.28 signing identity match `com.moolsocial.app`, but the Firebase-managed Android client key has no allowed Android applications. Its API targets are already restricted to Firebase services. C29B therefore remains closed: embedding that client configuration before the exact package/signing restriction exists would not meet the production-grade security boundary.

No key string, credential value, OAuth material, App Check debug token or secret value was read, copied, hashed or output. The protected OPPO remains on r60.28 and no build or install is authorized by this ticket.

## Reuse, duplicate and MVP assessment

The existing Firebase Android app, existing auto-associated client key, existing Firebase-only API targets, qualified signing identity and existing in-memory SDK-config build owner are reused. No new key, API, app, screen, route, backend or client owner is needed. The one minimal outcome is an exact metadata-only restriction patch followed by no-value verification.

This is an MVP-supporting security dependency for the already-selected C29B review candidate. It is sequential and temporarily owns the single active scope slot; it does not inherit C29B build, install or device authority.

## Exact authorized write boundary

- Project: `moolsocial-dev-503018` (`760290687711`).
- Firebase Android app: `1:760290687711:android:4202409fd3ab38f6ce076a`.
- Existing API-key UID: `14fee65f-18c4-48b7-a7dd-aa5ce35d4353`.
- Add exactly one allowed Android application: package `com.moolsocial.app`, SHA-1 `1E4345AA0707C8A4C74F5485B47B14E911923B46`.
- Preserve the complete existing `apiTargets` collection byte-for-byte in semantic content.
- Patch only `restrictions`, using the current resource etag, then poll and verify.

The authority comes from the founder's 11 August direction to complete everything required in the Dev provider/Firebase runtime before OPPO testing and to request assistance only if Google needs visible authentication. It excludes key-value access, key rotation/deletion, target changes, deployments, billing/IAM/Auth/App Check changes and every Production or protected-device mutation.

## Required completion evidence

Completion must record only non-secret metadata: exact resource identity, before/after API-target semantic digests and counts, exact application restriction, operation completion and post-write etag change. The key string must never be requested or persisted. After completion, active scope returns to C29B with external-service write authority false.
