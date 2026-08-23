# REG2905 — C34L final-audit exact-ID inventory semantic truncation

## Incident

On 2026-08-17, the independent final auditor ran a bounded repository inventory intended to report three exact identifier-pattern sections. The command produced the first pattern header and 100 rows with a reported total count of 976, then printed only the second section header. The expected second results/count and entire third section were absent. No explicit truncation warning was emitted, but the three-section result was semantically incomplete and is not accepted as audit evidence.

## Impact

- The cross-repository authoritative-producer identifier inventory is incomplete.
- The auditor stopped before retry, behavior testing, or any later command.
- No repository mutation, recovery, candidate, seal, cycle, launcher, build, Play, OPPO, browser, private/account, device, secret, or external action occurred.
- A possible caller-fabrication blocker remains a candidate only until the warning-free audit completes.

## Root cause

The inventory combined multiple high-cardinality repository searches and row projections in one output. The first section alone consumed the bounded result budget, silently preventing complete evidence for later sections.

## Prevention

- Run each exact identifier search as a separate command.
- First return only a scalar match count; then page only the relevant owner paths/lines in small bounded slices.
- Require every expected section header, scalar count, and terminal marker before accepting a compound projection.
- Treat semantically missing sections as truncation even without a tool warning, stop, register, and replay memory before retry.

## Disposition

Registered truthfully. No missing identifier inventory is treated as proof that authoritative producer authentication exists or is absent.
