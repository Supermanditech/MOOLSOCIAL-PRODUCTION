# REG-20260818-2971 C34P FIX1A provider-state raw-line mismatch

Date: 18 August 2026 (IST)
State: registered before character comparison and anchored correction

## Incident

The FIX1A provider `nextTicket` one-line patch succeeded and parsed correctly.
The following one-line provider `state` patch used the visibly printed raw line
as removal context, but `apply_patch` still could not match it and rejected the
hunk atomically. The provider state remained the FIX1 value; every external,
build, device and secret authority remained false.

All implementation subagents remained stopped during registry movement.

## Root cause

The visible line contained a character or spacing difference that was not
proven byte-for-byte before patching. Repeating the same apparent line would not
be evidence-based.

## Prevention

Compare the physical provider-state line to the intended removal literal by
length, ordinal equality and first mismatch without emitting the state body.
Then patch the two-line unique block anchored by the already corrected FIX1A
`nextTicket`, parse immediately and rerun the MVP execution gate. Do not retry
the rejected one-line form.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
