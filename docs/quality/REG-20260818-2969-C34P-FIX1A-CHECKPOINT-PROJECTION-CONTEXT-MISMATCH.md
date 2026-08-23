# REG-20260818-2969 C34P FIX1A checkpoint projection context mismatch

Date: 18 August 2026 (IST)
State: registered before raw-line checkpoint correction

## Incident

After REG2968, founder disclosure and authorization were updated and parsed
successfully in independent operations. The next independent checkpoint patch
used the displayed parsed `approvalState` projection as removal context.
`apply_patch` could not match the literal JSON line and rejected the operation
atomically. The checkpoint and provider gate remained unchanged.

The three implementation subagents were again stopped before further action
when registry movement became pending.

## Root cause

A semantic JSON projection was used as if it preserved the literal source bytes
of the compact state line, repeating the durable rule that projections confirm
values but never provide patch context.

## Prevention

Locate only the top-level checkpoint `approvalState` physical line using the
already verified checkpoint boundary, read that one raw line, copy it verbatim
into a one-line patch and parse the result immediately. Apply the same raw-line
rule independently to `providerGate.nextTicket` and `providerGate.state`.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
