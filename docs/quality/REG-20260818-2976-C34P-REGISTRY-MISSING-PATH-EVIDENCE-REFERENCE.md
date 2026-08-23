# REG-20260818-2976 C34P registry missing-path evidence reference

Date: 18 August 2026 (IST)
State: registered before correcting REG2975 evidence

## Incident

REG2975 accurately registered that the claimed FIX1 delivery checker was absent,
but its registry `evidence` array also listed that nonexistent checker path. The
regression-memory gate requires every evidence path to exist and rejected the
entry before coordination or MVP evaluation. No implementation or external action
followed the rejection.

## Root cause

The missing subject of the incident was incorrectly treated as a durable evidence
artifact. The incident document and coordination policy already contain the path
and are sufficient retained evidence.

## Prevention

Evidence arrays may reference only verified existing repository artifacts. Record
an absent path in the incident narrative or structured mistake field, never as an
evidence-file entry. After registration, remove only the nonexistent reference,
recompute the registry hash, repin coordination, and rerun memory first.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- `docs/quality/REG-20260818-2975-C34P-FIX1-DELIVERY-GATE-CLAIMED-PATH-MISSING.md`
- this incident record
