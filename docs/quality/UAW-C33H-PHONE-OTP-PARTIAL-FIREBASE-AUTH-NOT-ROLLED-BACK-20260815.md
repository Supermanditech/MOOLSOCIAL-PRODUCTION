# Phone OTP partial Firebase authentication rollback defect

- Regression: `REG-20260815-2457-PHONE-OTP-PARTIAL-FIREBASE-AUTH-NOT-ROLLED-BACK`
- Source finding: both automatic verification in `_sendOtp` and manual verification in `verifyOtp` could authenticate Firebase before `_completeAuthentication` failed during account bootstrap.
- Unsafe result: the UI reported failure but the underlying Firebase user could remain signed in.
- Required correction: sign out through the existing `OtpGateway`, keep MoolSocial unauthenticated, retain the protected return intent, and permit an exact retry. The repair must be tested independently for automatic and manual verification.
