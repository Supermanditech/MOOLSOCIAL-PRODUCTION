# C30U post-failure `if` expression projection parser error

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

After cycle 1 attempt 3 failed closed, the first read-only scalar projection
placed a statement-form PowerShell `if` directly inside a PSCustomObject value.
PowerShell treated `if` as a command name and rejected the diagnostic. It
produced no post-failure artifact or counter evidence.

## Root cause

The conditional value was not wrapped in the required `$()` subexpression or
calculated into a named scalar before constructing the object.

## Prevention

Calculate every conditional projection into an explicit ticket-named scalar
before object construction. Keep artifact existence, cycle-seal existence and
counter reads type-aware and bounded. A parser-rejected projection is zero
evidence and must be registered before retry.

## Release effect

This was read-only and changed no files. The failed cycle had already stopped
at the authoritative Flutter audit. No AAB, upload, Play activation,
installation or OPPO mutation occurred.

## Corrected bounded projection

- Attempt-3 Flutter log exists: `true`
- Log bytes: `155`
- Log SHA-256:
  `084C7D4339A2B576BFD77213AF0784EA3BC119A1CFE91968B49D8A558124EBBC`
- Accepted C30U source manifest exists: `false`
- Cycle-1 seal exists: `false`
- The generic release AAB path is `present` from prior preserved work; C30U
  build counters remain the authority and remain zero. Attempt 3 failed before
  its config-only step and did not invoke an AAB build.
