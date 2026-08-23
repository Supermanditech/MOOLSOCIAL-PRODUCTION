# REG-20260821-3054 FIX6 combined test patch Instagram title context mismatch

## Observed failure

The combined FIX6 test patch assumed an exact Instagram test-title anchor that
did not exist. `apply_patch` rejected the patch before changing any test file.

## Root cause

Multiple independently owned test files were patched in one operation using a
remembered title instead of reading the exact Instagram slice first.

## Impact

- production-source changes from the preceding accepted patch remain present;
- no test file changed in this rejected patch;
- no test, build, Play, OPPO, provider or device action ran.

## Prevention and authorized retry

Read the exact local context for each test owner and patch each file
independently. Never bundle separate test owners behind one unverified anchor.
