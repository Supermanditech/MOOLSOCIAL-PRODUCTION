# REG2996 — C34P registry-tail projection truncation

Date: 20 August 2026 (IST)
State: registered before bounded tail retry

## Incident

The primary projected all 46 C34P tail entries with every narrative field into
one JSON result. The tool truncated the 15,911-token output, so the projection
is not complete registry-tail evidence. The registry remained unchanged.

## Root cause

The selected entry count was bounded but the aggregate narrative size was not
measured before emission, repeating the semantic-incompleteness class for a
large JSON owner.

## Prevention

Resolve the exact last ID and line first, then read only the small literal tail
needed for an append. For qualification, project IDs/count/hash separately and
read relevant entries in independent bounded groups whose rendered size is
measured before output. Reject every truncated group.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
- `docs/quality/CODEX-SUBAGENT-MANDATORY-COORDINATION-POLICY-20260818.md`
