# C09 Windows wildcard evidence-search failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## What failed

A read-only `rg` evidence lookup mixed valid literal roots with the operand
`docs\quality\UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C08*`.
Native ripgrep does not receive PowerShell wildcard expansion for that Windows
path, so it reported an invalid filename and the diagnostic command exited 1.

No source, application, build, OPPO state or retained evidence was changed.

## Root cause and prevention

The existing regression-memory rule prohibiting wildcard path operands was not
applied to a secondary evidence root. Every ripgrep operand must be an existing
literal file or directory; filename selection uses `-g` filters. One invalid
secondary root invalidates the complete command and its result is never used as
absence evidence.
