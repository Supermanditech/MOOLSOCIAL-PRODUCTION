# C34L r60.76 presealed Internal Testing upload runbook

Upload remains held until a C34L postbuild-qualified AAB is bound to both state
owners and the retained evidence verifier proves exact SHA-256, bytes, signer,
package/version, Google app ID, Crashlytics ID, merged manifest, split/arm64
payload, attempt number, source manifest and provenance. The terminal state
must be crash-reconciled and counts must be `1/0/0/0`.

Before one upload authority is exposed, the browser qualification must
durably prove all three flags for the current session: live known route,
signed-in MoolSocial application route and Google Play **Internal Testing**
route. Their retained proof file and hash are transition prerequisites; prose
or a nonempty string is insufficient.

Only the exact C34L AAB may be uploaded and activated, once, on Internal
Testing. Play must parse `1.0.0-r60.76` / `2026081376`; the release must contain
one bundle, no previous rejected artifact and no other track action. Any
mismatch, unexpected page, second-upload prompt or ambiguous control stops
before the Play write and rejects C34L.
