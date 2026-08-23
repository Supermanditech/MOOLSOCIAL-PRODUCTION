# C31A backend test summary anchor mismatch

Date: 2026-08-14
Registry ID: `REG-20260814-2126-C31A-BACKEND-TEST-SUMMARY-ANCHOR-MISMATCH`

The first compiled C31A Chat test process exited zero, but the success parser expected test-count lines to begin exactly with `#` and emitted no counts from this captured environment. That run is not accepted as qualification evidence.

The corrected focused test capture emits a bounded final tail on success and failure so the exact `tests`, `pass` and `fail` lines remain visible. No live backend, deployment or external write occurred.
