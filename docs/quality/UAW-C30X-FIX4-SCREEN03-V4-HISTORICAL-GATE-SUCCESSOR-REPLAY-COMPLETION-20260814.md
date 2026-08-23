# C30X FIX4 completion

Date: 2026-08-14
Ticket: `UAW-C30X-FIX4-SCREEN03-V4-HISTORICAL-GATE-SUCCESSOR-REPLAY`
State: gate replay repair complete; successor source reseal pending

The Screen03 v4 gate now separates immutable acceptance checks from its scope
context. It accepts only:

- the exact completed FIX1 creation ticket with reference-write authority; or
- exact FIX4/C30X read-only replay tickets with reference-write authority
  false.

All contexts require test/gate authority and reject runtime, backend, build,
device, external-service and secret authority. No approved reference, manifest,
runtime, test, asset or golden byte changed under FIX4.

Qualification:

- FIX4 active-scope v4 gate: passed on PowerShell 7 and Windows PowerShell.
- C30X read-only replay v4 gate: passed on PowerShell 7 and Windows PowerShell.
- Global approved UI lock: passed.
- No build, upload, activation, install, device mutation, deployment, external
  write or secret access occurred.

The first provisional C30X manifest is preserved as superseded. A fresh
attempt must include the FIX4 ticket and corrected gate before cycle 1.
