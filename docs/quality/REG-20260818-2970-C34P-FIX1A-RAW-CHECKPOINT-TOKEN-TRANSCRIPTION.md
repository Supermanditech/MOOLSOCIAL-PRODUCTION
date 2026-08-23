# REG-20260818-2970 C34P FIX1A raw checkpoint token transcription

Date: 18 August 2026 (IST)
State: registered before exact checkpoint line replacement

## Incident

The primary correctly located and printed the single physical top-level
checkpoint `approvalState` line after REG2969. While transferring it into the
one-line patch, the removal context was manually changed from
`external_provider` to `external provider`. Exact verification rejected the
patch atomically. The checkpoint and provider gate remained unchanged.

All implementation subagents remained stopped during this registry movement.

## Root cause

The raw line was visually retyped instead of transferred byte-for-byte,
repeating the state-token transcription class already captured in REG2953.

## Prevention

Use the exact raw line as returned, preserving every underscore and space. The
next patch contains only that one removal line and one replacement line. Parse
the resulting checkpoint before locating or editing provider-gate lines.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
