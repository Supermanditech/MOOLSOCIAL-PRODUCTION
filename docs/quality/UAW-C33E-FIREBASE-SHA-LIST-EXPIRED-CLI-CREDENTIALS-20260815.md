# C33E Firebase SHA-list expired CLI credentials

Date: 15 August 2026
Regression: `REG-20260815-2341-C33E-FIREBASE-SHA-LIST-EXPIRED-CLI-CREDENTIALS`

The bounded read-only `firebase apps:android:sha:list` request returned no SHA
inventory because the existing Firebase CLI session is expired and requested
reauthentication. No reauthentication, credential inspection, credential
copy, token output or retry is authorized or performed.

The CLI emitted `firebase-debug.log`. That file is preserved unmodified and is
not opened or inspected because it may contain private diagnostic material.
Recovery is limited to a founder-visible Firebase Console yes/no check for the
known Play app-signing SHA-1, or a later separately authorized non-secret read
session. No Firebase, Google, Play, OPPO, build, provider or external-service
state changed.

Later on 15 August 2026, after separate founder authorization, interactive
Firebase reauthentication was mistakenly launched from the production
repository. Firebase CLI removed the earlier transient untracked debug file on
successful exit. Its contents were never inspected. The durable sanitized
record in this document remains the evidence authority, and the invalid
transient pointer was removed under
`REG-20260815-2396-C33F-FIX3-INTERACTIVE-REAUTH-REMOVED-TRANSIENT-DEBUG-EVIDENCE`.
