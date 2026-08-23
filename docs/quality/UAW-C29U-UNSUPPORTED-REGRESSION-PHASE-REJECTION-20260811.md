# C29U unsupported regression phase rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1288-C29U-UNSUPPORTED-REGRESSION-PHASE-REJECTION`

The first C29U permanent-memory replay passed `-Phase external`. The script's
ValidateSet supports only `general`, `implementation`, `build` and `device`, so
PowerShell rejected the invocation before any external action.

C29U function/rules deployment is an `implementation` phase. The later fresh
APK and OPPO qualification tickets must independently replay `build` and
`device`; the C29U external-service authorization does not invent another gate
phase.
