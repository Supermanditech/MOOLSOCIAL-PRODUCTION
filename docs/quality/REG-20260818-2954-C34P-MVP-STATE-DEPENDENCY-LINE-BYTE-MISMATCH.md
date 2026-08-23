# REG-20260818-2954 C34P MVP-state dependency line byte mismatch

Date: 18 August 2026 (IST)
State: registered before byte-faithful inspection

## Incident

After REG2953, the primary re-read the exact current dependency line and copied
its visible text into a one-line patch. Patch verification still rejected the
line, so the rendered line is not accepted as byte-faithful patch context. The
hunk was atomic and changed no state; no later runtime, test, provider, build,
device, private or external action occurred.

## Root cause

The visible PowerShell rendering did not expose whatever byte or character
difference prevented exact patch matching. Repeating visually identical context
would be an unbounded retry, not evidence-based state editing.

## Prevention

Inspect only the one physical line's UTF-8 byte length and non-ASCII character
positions, then use unique adjacent short fields to replace the complete current
assessment block or use a byte-faithful literal copied from a bounded raw slice.
Do not issue the same one-line patch again. Parse and project the dependency
array immediately after the corrected bounded operation.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
