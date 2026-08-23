# C30S legitimate reCAPTCHA READ_GSERVICES manifest rejection

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`
Affected candidate version: `1.0.0-r60.44 (2026081244)`

## Rejection and identity proof

The fresh release-manifest preflight completed successfully and then the C30S denylist rejected `com.google.android.providers.gsf.permission.READ_GSERVICES`. This happened before build-authority mutation. State remained `available_once` with build count, wrapper invocation count and config-only count all `0`. The only release AAB remained the sealed r60.43 predecessor (`E7E7DF249C71195FF9EDF8FD0247AEB64C91FEC3DD541F4A5A8FD11690AD8A69`). No r60.44 AAB was built.

Fresh manifest-merger blame attributes the permission exactly to `com.google.android.recaptcha:recaptcha:18.7.1`, pulled by retained `firebase-auth:24.1.0`. Firebase's official Android phone-auth documentation confirms that Firebase Authentication uses reCAPTCHA when Play Integrity cannot be used, so this dependency is part of the retained authentication fallback rather than an unused messaging or advertising SDK.

## Correction gate

The permission must not be broadly allowlisted. The build wrapper must require it exactly once and require fresh merger-blame provenance from the exact reCAPTCHA artifact. Notification, Cloud Messaging and advertising permissions remain forbidden. The merger-blame report must be sealed with the artifact evidence. Any origin or version change rejects for reclassification.

Official reference: <https://firebase.google.com/docs/auth/android/phone-auth>

Regression: `REG-20260813-1626-C30S-LEGITIMATE-RECAPTCHA-READ-GSERVICES-MANIFEST-REJECTION`.
