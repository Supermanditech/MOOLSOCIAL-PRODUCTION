# C33H FIX1 Firebase Phone Auth independent journey qualification

## Outcome

The source defect in `REG-20260815-2457-PHONE-OTP-PARTIAL-FIREBASE-AUTH-NOT-ROLLED-BACK` is repaired and independently gated under `UAW-C30T-R60-45-MOBILE-OTP-GATE-NONFUNCTIONAL`.

Automatic and manual Firebase Phone credential acceptance now roll back the Firebase identity if MoolSocial account bootstrap fails. The exact protected return intent remains available for retry, while private phone and OTP input are not persisted across process return.

The founder-authorized Firebase console change also completed: Phone is enabled for `moolsocial-dev-503018`, and one approved fictional test pair is registered. No real SMS was sent. The fictional phone number and verification code are intentionally absent from repository state and evidence.

## Source qualification

- Focused independent Phone OTP matrix: `6/6` passed.
- Six-file affected authentication and protected-return matrix: `54/54` passed.
- Wrong, expired, resend, manual success, automatic success, provider failure, bootstrap rollback, exact retry and process-return containment: passed.
- PowerShell 7 source gate: passed.
- Windows PowerShell source gate: passed.
- Whole-mobile Flutter analyzer: clean, no issues.
- Immutable approved Screens 01–03 gate: passed.
- MVP scope and 60–75-day delivery-discipline gates: passed for the exact ticket.

## Live readiness truth

This is source qualification, not production or OPPO acceptance. The India-only SMS-region allow-list is now qualified under C33H FIX2. The live gate remains fail closed because the following candidate-specific evidence is still required:

1. Play Integrity or reCAPTCHA return qualification for the Play-signed Android app.
2. Separately authorized real-device send/verify evidence if a real SMS journey is required.
3. A newer Play Internal Testing candidate and in-place OPPO update followed by retained exact-route acceptance evidence.

No AAB, Play upload, OPPO mutation, deployment, credential read, real SMS, email, quota submission or production claim occurred under C33H FIX1.
