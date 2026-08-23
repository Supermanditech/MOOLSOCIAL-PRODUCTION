# C30T second protected test lock mismatch

Date: 2026-08-13

After the Social customer-copy coverage was isolated and the first protected file returned to its accepted checksum, `check-approved-ui-locks.ps1` exposed a second mismatch: `apps/mobile/test/platform_configuration_test.dart` expected SHA-256 `DEFFE5CFD7CD7C1432D6057E5C045A1569DC3F71FBD5F9D8EF26251E984A68CA` but the current file is `4FF706B8E5DB506D5B91D83A1DDF4B0705CD0EABE918CA61E1771FF2C1638191`.

No manifest will be changed. The successor assertions must be isolated into a C30T-owned test and the protected owner restored exactly before deployment preflight can pass.
