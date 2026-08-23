# C30M qualification one-second timeout rejection

- ID: `REG-20260812-1449-C30M-QUALIFICATION-ONE-SECOND-TIMEOUT-REJECTION`
- Date: 2026-08-12
- Scope: local C30M provider-only qualification
- Result: host terminated the local command after one second; no cloud action occurred

The first full local qualifier was incorrectly given a one-second command
timeout in an attempt to obtain an early yield. The shell runner terminated it
instead. None of that run is accepted. C30M retries with the bounded long
timeout required by the backend suite and uses progress commentary, never an
artificially short process timeout.
