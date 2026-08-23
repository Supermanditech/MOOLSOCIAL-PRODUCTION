# C30Z regression-memory path and inline-ID assumption

Date: 2026-08-15
Regression: `REG-20260815-2215-C30Z-REGRESSION-MEMORY-PATH-AND-INLINE-ID-ASSUMPTION`
Status: resolved; exact owners/schema read and implementation memory gate passed

## Finding

The first read guessed `docs/quality/CODEX-REGRESSION-MEMORY.md`, which does
not exist. A follow-up then assumed the prevention-prose memory repeated the
exact `REG-20260815-2214` identifier inline; it does not. Neither failed read
is accepted as registry evidence.

## Prevention

Resolve the exact prevention-memory filename with a bounded inventory. Read
incident identifiers and statuses from
`config/codex-development-regression-registry.json`, and use
`docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md` only for its prevention
lessons. No source, build, Play, OPPO, provider, credential or external-service
state changed.
