# REG3008 — Post-outage evidence write before coordination replay

Date: 20 August 2026 (IST)
State: registered before further repository or browser action

## Incident

After the forced laptop shutdown, the primary independently verified branch,
HEAD and both instruction owners, but created the REG3006 and REG3007 evidence
documents before replaying the mandatory regression-memory and coordination
gates. No product, provider, browser, build, Play, OPPO or external state was
changed by those evidence-only writes.

## Root cause

The outage recovery sequence was resumed after partial reconstruction instead
of waiting for both current-generation machine gates to pass before any write.

## Prevention

After every power loss or forced restart, complete branch, HEAD, bounded
handoff, policy generation, current memory and both mandatory machine gates
before any evidence, registry, state, source, browser or external action. The
primary explicitly confirms that no exact session was in flight.

## Retained evidence

- `docs/quality/REG-20260820-3006-C34P-FIX5-PENDING-GATE-INCREMENTAL-PROVIDER-WRITE-COUNT.md`
- `docs/quality/REG-20260820-3007-REG3006-EVIDENCE-READBACK-EMPTY-OUTPUT.md`
- `config/codex-development-regression-registry.json`
