# UAW C33J Screen03 passwordless email-link native parity qualification

## Outcome

The founder-approved Screen 03 v5 reference is implemented and source-qualified
without modifying the locked v4 production/reference owners. The native chooser
preserves Google, YouTube, Apple, X, Instagram and Facebook; Email link is
passwordless; Mobile OTP remains available.

## Qualified source behavior

- Production `/sign-in` selects native `LoginScreenV5`; historical presentation
  tests may still select the untouched v4 owner explicitly.
- Email-link UI covers entry, sent, different-device confirmation,
  expired/used/invalid recovery and choose-another-method states.
- Firebase gateway code uses the injected runtime configuration and fails closed
  when a qualified HTTPS continue/link domain is absent.
- Cold-start and foreground returns reuse one `JourneySession` validator.
- Unsupported social providers remain visible reference controls but do not
  falsely dispatch or claim live availability.

## Evidence

- Parent focused matrix: 10 passed, 0 failed.
- Foreground FIX1 matrix: 3 passed, 0 failed.
- Affected regression batch: 68 passed, 0 failed.
- Whole-mobile analyzer: 0 issues.
- Parent and FIX1 static gates passed on both PowerShell hosts.
- Approved UI and MVP scope locks passed.
- Machine state:
  `config/screen03-passwordless-email-link-native-parity-state-c33j.json`.

## Remaining live requirements

The source is not live-ready until the separately authorized Firebase Email
Link provider, authorized HTTPS domain, Hosting link domain, Android App Links,
real email delivery/completion, AAB, Internal Testing and OPPO evidence all pass.
No such external action occurred under C33J.
