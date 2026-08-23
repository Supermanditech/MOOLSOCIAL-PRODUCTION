# REG3103 — audit edits changed an immutable platform configuration test

- Date: 2026-08-21
- Status: registered before correction

The approved UI lock rejected `apps/mobile/test/platform_configuration_test.dart`
after the Android audit added new assertions and changed its startup source-order
oracle. This test is checksum-bound to the accepted Screen 03 production lock
and is not an authorized successor owner. No build or device action followed.

Prevention: restore the locked owner byte-for-byte, preserve its original
literal source-order contract by locating the failure helper above Firebase,
and add new Android audit checks only in a separately claimed successor test.
