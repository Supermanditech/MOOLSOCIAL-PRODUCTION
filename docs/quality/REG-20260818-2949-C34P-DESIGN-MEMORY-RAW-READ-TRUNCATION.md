# REG-20260818-2949 C34P design-memory raw-read truncation

Date: 18 August 2026 (IST)
State: registered before bounded reread

## Incident

During C34P mandatory reconstruction, the primary requested the complete
`APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md` owner in one raw result. The tool
reported output truncation, so none of that result is accepted as complete
design-memory evidence. No later source, test, build, provider, browser, device,
private or external action followed the truncated read.

## Root cause

The document was treated as a manageable required owner without first measuring
its current line count. Its cumulative design history exceeds the safe output
boundary.

## Prevention

Measure every substantive required owner before a complete read. Read this
design memory in independent, non-overlapping pages of at most 250 lines through
the exact current EOF, and reject any page that truncates. Apply the same
measure-first rule to every remaining dense policy or source owner.

## Retained evidence

- `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
- `config/codex-development-regression-registry.json`
- this incident record
