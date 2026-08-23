# UAW-C33K predecessor active-ticket gate replay mismatch

- Regression: `REG-20260815-2526-C33K-PREDECESSOR-ACTIVE-TICKET-GATE-REPLAY-MISMATCH`
- Date: 2026-08-15
- Failure: the C33J FIX2 checker was invoked after the MVP selection advanced
  to C33K. Its deliberate requirement that C33J FIX2 remain the active ticket
  rejected the replay.
- Impact: read-only gate failure only; no source, Firebase, Hosting, email,
  release, Play or device state changed.
- Preserved truth: C33J FIX2 remains recorded in the current MVP state with its
  exact sealed ticket hash and prior dual-PowerShell qualification evidence.
- Prevention: inspect predecessor checkers for active-ticket assertions before
  replay. Do not weaken or retry an active-only checker under successor state;
  use the current ticket's gate and a current focused source test instead.
