# C29U diagnostic owner-path and composite-read rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1287-C29U-DIAGNOSTIC-OWNER-PATH-AND-COMPOSITE-READ-REJECTION`

A diagnostic command combined a regression-memory read with the MVP gate-owner
read and guessed `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.json`, which
does not exist. Although the gate owner printed, the command exited nonzero and
its output was rejected as composite evidence.

The repository instructions identify the durable registry as
`config/codex-development-regression-registry.json` and the human memory as
`docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`. Future reads use one
literal owner per invocation and require that invocation to complete cleanly.
