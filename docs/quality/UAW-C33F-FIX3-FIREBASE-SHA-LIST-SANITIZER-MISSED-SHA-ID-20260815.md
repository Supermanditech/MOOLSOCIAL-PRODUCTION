# UAW-C33F FIX3 Firebase SHA-list sanitizer missed SHA Id

- Recorded at: `2026-08-15T10:46:18.4672065Z`
- Regression: `REG-20260815-2398-C33F-FIX3-FIREBASE-SHA-LIST-SANITIZER-MISSED-SHA-ID`

The first schema-only rendering redacted all certificate hashes and credential-sensitive shapes but did not redact the Firebase CLI table's 16-hex `SHA Id` resource identifiers. These are not certificate or credential values, but they were unnecessary provider metadata and should not have been emitted.

The captured output must not be rendered again. All future schema sanitizers redact standalone 16-hex resource identifiers before output. The existing in-memory raw capture may be parsed only to produce counts and boolean relationships.
