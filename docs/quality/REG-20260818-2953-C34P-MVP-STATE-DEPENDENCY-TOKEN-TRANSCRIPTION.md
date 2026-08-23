# REG-20260818-2953 C34P MVP-state dependency token transcription

Date: 18 August 2026 (IST)
State: registered before verbatim-context retry

## Incident

While applying the next small selected-assessment hunk, the primary retyped the
stored C34L dependency token with `Internal Testing` instead of its exact
`Internal_Testing` form. Patch verification rejected the hunk atomically. The
dependency array and every other state field remained unchanged; no later
runtime, test, provider, build, device, private or external action occurred.

## Root cause

An exact current JSON line that had already been read was manually transcribed
instead of copied byte-for-byte into the removal side of the patch.

## Prevention

Re-read the single current `selectedTicketAssessment.dependenciesAndApprovals`
line and copy it verbatim as patch context. Never reconstruct machine-state
tokens from prose or visual memory. Apply only that one line and immediately
parse/project the resulting current dependency array before another state hunk.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
