# UAW C31C unrelated platform-configuration UI-lock drift

## Observed gate failure

After the C31C whole-mobile analyzer passed, the global approved UI-lock gate
rejected `apps/mobile/test/platform_configuration_test.dart` for the accepted
login/account-handoff checkpoint. The expected checksum was
`deffe5cfd7cd7c1432d6057e5c045a1569dc3f71fbd5f9d8ef26251e984a68ca`; the
current preserved dirty-tree checksum was
`725e88030d0687de86e8770705b55a5a447e09c4ca986439b0b94adad80c64b1`.

## C31C boundary

C31C did not select, read for mutation or edit that protected test owner. Its
exact runtime, backend, test and gate owners are limited to the registered Chat
ticket and successor evidence. The protected mismatch is therefore retained,
not restored, resealed or bypassed.

## Required disposition

The global UI-lock gate remains failed until a separate founder-authorized
protected-lock reconciliation establishes the correct owner. C31C may only
claim scoped source qualification; it cannot support a release or production-
grade claim while this unrelated global gate is red.

## Later C30X FIX1 resolution

The founder later directed every AAB-audit finding to be ticketed and
implemented. C30X FIX1 created immutable Screen03 v4 test-only acceptance,
preserved all customer-visible and historical owners, and locked the current
platform configuration regression. The focused v4 gates and global approved
UI lock now pass; C31C itself did not mutate the protected owner.
