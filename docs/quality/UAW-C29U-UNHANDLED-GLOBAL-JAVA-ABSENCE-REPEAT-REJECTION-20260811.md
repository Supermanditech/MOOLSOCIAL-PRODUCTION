# C29U unhandled global Java absence repeat rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1290-C29U-UNHANDLED-GLOBAL-JAVA-ABSENCE-REPEAT-REJECTION`

After the 495 backend tests passed, the first C29U emulator preflight invoked
`Get-Command java` without explicit absence handling. Global Java is not on
this host PATH, so the probe exited nonzero before any emulator or cloud action.

The existing Firebase emulator workflow owns a bundled JDK. The retry resolves
that literal owner, temporarily exposes its `bin` to the emulator child, uses a
synthetic local project ID, and restores the host environment afterward.
