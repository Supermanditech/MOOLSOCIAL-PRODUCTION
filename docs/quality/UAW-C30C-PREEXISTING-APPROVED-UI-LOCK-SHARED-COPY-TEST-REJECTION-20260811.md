# C30C pre-existing approved-UI lock shared-copy-test rejection

- Regression: `REG-20260811-1365-C30C-PREEXISTING-APPROVED-UI-LOCK-SHARED-COPY-TEST-REJECTION`
- Date: 2026-08-11
- Gate: `scripts/check-approved-ui-locks.ps1`.
- Existing mismatch: `apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart` expected `B07468F487A5C04286F0D228CDCCF7EAD373154C756600C58DC216A4EDD2BD11`, found `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9` before C30C implementation.
- C30C boundary: do not edit that shared test, the immutable manifest, or any Screen 01-03 presentation/reference/lock owner; add a new focused Search test instead.
