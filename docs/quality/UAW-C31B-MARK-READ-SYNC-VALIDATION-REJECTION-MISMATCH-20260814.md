# C31B mark-read synchronous validation rejection mismatch

Date: 2026-08-14
Registry ID: `REG-20260814-2132-C31B-MARK-READ-SYNC-VALIDATION-REJECTION-MISMATCH`

The first C31B service test used `assert.rejects` for invalid mark-read input, but the new method was not declared `async`; identifier validation threw synchronously before the assertion could own the promise.

The correction makes this mutation match the async contract of sibling Chat mutations. Both validation and repository errors then reject consistently. The failed test run is not qualification evidence.
