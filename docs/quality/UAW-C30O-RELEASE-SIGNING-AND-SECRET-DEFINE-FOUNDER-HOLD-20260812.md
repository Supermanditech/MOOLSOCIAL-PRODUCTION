# C30O release-signing and secret-define founder hold

- Date: 2026-08-12
- Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30O`
- Version: `1.0.0-r60.41 (2026081241)`
- Build authorization: available and unconsumed

## Read-only readiness findings

The production Gradle release configuration fails closed unless all four founder-controlled upload-key environment variables are present:

- `MOOLSOCIAL_UPLOAD_STORE_FILE`
- `MOOLSOCIAL_UPLOAD_STORE_PASSWORD`
- `MOOLSOCIAL_UPLOAD_KEY_ALIAS`
- `MOOLSOCIAL_UPLOAD_KEY_PASSWORD`

All four are currently absent in the agent build environment. A bounded production-repository search, excluding artifacts, build output, and temporary evidence, found no `*.jks` or `*.keystore` file.

The required `MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE` environment variable is also absent. Its founder-qualified file must contain the required `MOOLSOCIAL_FIREBASE_API_KEY`, must never be read by the agent, and must not be recorded in repository evidence or command output.

## Completed prerequisites

- Play app and Internal tester list exist.
- Play Integrity is linked to Dev project `760290687711`.
- Temporary Cloud IAM access was removed and Domain Restricted Sharing inheritance restored.
- Firebase App Check Play Integrity configuration exists.
- The Play App Signing SHA-256 is registered on the Firebase Android app.
- Two identical complete C30O source-qualification cycles remain sealed with manifest SHA-256 `44608E9837EE6ED93029AEA6E623135E5D499DABF8A715B519CA7A66870B7D23`.

## Hold

Do not invoke `scripts/invoke-play-internal-aab-build-c30o.ps1` until the founder has supplied a founder-controlled upload keystore through a visible password-safe workflow, disclosed only its public SHA-256 certificate fingerprint, and qualified the secret define-file path without exposing its contents.
