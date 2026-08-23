# UAW C30T r60.45 Email OTP gate nonfunctional — 13 August 2026

The founder reports that Email OTP does not complete authentication on the Play-installed `1.0.0-r60.45 (2026081345)`. Email OTP is an independent path and cannot inherit a pass from Mobile OTP or a social-provider flow. A successor must diagnose its exact owner and prove request, invalid/expired input, resend, success, cancellation and return to the requested Social route. No founder email address or OTP value may be captured. No second AAB/upload/install is authorized.

## Source-selection blocker

The production client wires `HttpEmailOtpGateway` to `MOOLSOCIAL_AUTH_API_BASE_URL`, but the current release boundary supplies no value for that define. The gateway therefore fails closed before a request. Repository-wide exact-symbol and route searches also prove that no `/v1/auth/otp/request` or `/v1/auth/otp/verify` backend owner exists; only the unbacked client assumption exists.

Firebase Authentication's supported Flutter passwordless email flow sends an email sign-in link and completes through an authenticated App Link return. It does not provide the numeric six-digit Email OTP contract currently presented by locked Screen 03. See [Firebase email-link authentication](https://firebase.google.com/docs/auth/flutter/email-link-auth).

No safe source correction can invent email delivery, code storage, rate limiting, replay protection, expiry, account binding and custom-token minting, and no locked-screen change can silently turn the accepted numeric flow into a link flow. Selection therefore remains blocked until the founder chooses and authorizes either:

1. a versioned Firebase email-link presentation/return contract; or
2. a custom numeric Email OTP backend and delivery provider with explicit security, privacy, abuse, cost and environment authority.

The control remains visible in current production and is a release blocker. This finding does not defer or waive it, and no email address, OTP, credential, service, build or external system was accessed or changed.

## Founder pre-launch decision — 13 August 2026

The founder selected existing Google identity sign-in plus a Firebase-owned
email authentication path for completion before full public launch. The
independent Firebase path is recorded as passwordless email-link authentication
because Firebase does not natively own the current custom six-digit Email OTP
contract. A custom numeric Email OTP backend was not selected.

This ticket is pending, not waived and not selected for source implementation
in the current repair round. It requires a separately versioned presentation,
App Link return, invalid/expired/retry/cancel coverage and exact requested-route
return before launch. This decision creates no AAB, email, provider, cloud or
external-service authority.
