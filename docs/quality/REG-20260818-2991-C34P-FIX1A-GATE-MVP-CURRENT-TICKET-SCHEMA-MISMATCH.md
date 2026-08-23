# REG-20260818-2991 C34P FIX1A gate MVP current-ticket schema mismatch

Date: 18 August 2026 (IST)
State: registered before bounded MVP projection or gate retry

## Incident

The first PowerShell 7 execution of the new FIX1A all-eight source gate stopped
before source assertions because it read `$mvp.currentTicket.ticketId`. The MVP
state does not expose a `currentTicket` property at that location. No correction,
retry, test or external action followed.

## Root cause

The gate copied a semantic planning label from the reconstruction summary instead
of using the persisted MVP JSON's exact top-level schema.

## Prevention

After registration, project only the top-level MVP property names and the bounded
ticket identity nodes. Patch the gate to the one proven selector, reread the line,
then retry the same PowerShell 7 gate before Windows PowerShell compatibility.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `scripts/check-uaw-c34p-fix1-public-auth-live-adapter-blocker-resolution.ps1`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
