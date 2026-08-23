# C30P Windows PowerShell 5.1 negative-control evidence — 2026-08-12

The exact C30P founder launcher was invoked under built-in Windows PowerShell
5.1 before any founder prompt or build.

- Process exit code: `1` (expected rejection).
- Exact required rejection was observed: PowerShell 7 or newer is required
  before founder prompts.
- C30P machine-state SHA-256 was identical before and after the invocation.
- No transient Firebase define file existed afterward.
- No founder credential was requested, entered, read, printed or retained.

This proves the C30O native-stderr recurrence cannot consume C30P authority
through a Windows PowerShell 5.1 launch.
