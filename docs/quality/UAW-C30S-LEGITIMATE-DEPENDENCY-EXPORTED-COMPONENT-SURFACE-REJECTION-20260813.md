# C30S legitimate dependency exported-component surface rejection

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

The fresh merged release manifest rejected before build authority consumption because its exported surface contained six components rather than only the two app-owned activities. Merger blame proved the additional four are contributed by retained dependencies:

- `GenericIdpActivity` and `RecaptchaActivity` from `firebase-auth:24.1.0` for federated and reCAPTCHA authentication callbacks.
- `RevocationBoundService` from `play-services-auth:20.7.0`, protected by `com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION`. Google documents that it handles access revocation from Google Settings and is added automatically by that dependency.
- `ProfileInstallReceiver` from `androidx.profileinstaller:profileinstaller:1.4.0`, protected by `android.permission.DUMP`. Android documents that this receiver is tool-only and its action filter uses the dump permission.

MoolSocial retains Firebase federated authentication, including Google/YouTube identity provider flow. Removing these components blindly would regress authentication callbacks, disconnect/revocation handling or runtime profile tooling.

The correction must require exactly the six known names with exact node types, protecting permissions, callback actions and merger-blame versions. Any surface or origin drift rejects. No r60.44 AAB was built; authority and all build counters remained untouched.

Official references:

- <https://firebase.google.com/docs/auth/android/phone-auth>
- <https://developers.google.com/android/reference/com/google/android/gms/auth/api/signin/RevocationBoundService>
- <https://developer.android.com/reference/androidx/profileinstaller/ProfileInstallReceiver>

Regression: `REG-20260813-1630-C30S-LEGITIMATE-DEPENDENCY-EXPORTED-COMPONENT-SURFACE-REJECTION`.
