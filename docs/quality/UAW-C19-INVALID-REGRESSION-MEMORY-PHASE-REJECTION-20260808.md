# C19 invalid regression-memory phase rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

State: **REJECTED BEFORE RETRY**

After the user-facing copy and focused C19 gates passed, the combined command
incorrectly supplied `-Phase testing` to the permanent regression-memory gate.
That gate accepts only `general`, `implementation`, `build` or `device`, so the
third command rejected even though the two preceding gates remained valid.

REG-387 now requires callers to inspect or retain the parameter contract and use
`implementation` for host test/qualification work. The memory gate must pass
before subsequent qualification continues.
