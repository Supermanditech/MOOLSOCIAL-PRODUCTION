# REG3001 — C34P affected-manifest expected-total inference

Date: 20 August 2026 (IST)
State: registered before official affected-cycle retry

## Incident

The primary inferred that the prior 16-suite `155` total plus one new App Check
assertion would produce `156`. The exact reconstructed 16-file manifest passed
with a bounded native summary of `158/158`. No test failed, but the stated
expected total was false and the first run cannot qualify after registration.

## Root cause

The old qualification report described reused suite families without listing
every file/count, and the primary derived a total from narrative labels instead
of accepting only the current executable manifest's counted result.

## Prevention

Freeze the exact 16 literal test paths returned by current-tree inventory,
accept `158` only from the bounded native `All tests passed` summary, and run
two fresh identical cycles after the registry refresh. Durable evidence must
list every suite path and never arithmetically infer a successor total from an
older narrative.

## Retained evidence

- `docs/quality/UAW-C34P-FIX1-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION-QUALIFICATION-20260818.md`
- `config/codex-development-regression-registry.json`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
