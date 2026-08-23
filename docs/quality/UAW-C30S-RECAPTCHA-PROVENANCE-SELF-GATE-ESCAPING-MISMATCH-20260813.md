# C30S reCAPTCHA provenance self-gate escaping mismatch

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

The newly added wrapper self-gate rejected before qualification because it searched for an unescaped `com.google.android` prefix while the runtime implementation correctly escaped that prefix inside its regular expression. A separate read-only semantic probe proved the fresh merged manifest contains `READ_GSERVICES` exactly once and the merger-blame expression matches `com.google.android.recaptcha:recaptcha:18.7.1`.

No AAB build was attempted. Build authority remained `available_once`; build and wrapper invocation counts remained `0`.

The static check must use the stable literal fragment `recaptcha:18\.7\.1` alongside independent READ_GSERVICES and merger-blame markers, while the runtime manifest/blame check remains authoritative.

Regression: `REG-20260813-1627-C30S-RECAPTCHA-PROVENANCE-SELF-GATE-ESCAPING-MISMATCH`.
