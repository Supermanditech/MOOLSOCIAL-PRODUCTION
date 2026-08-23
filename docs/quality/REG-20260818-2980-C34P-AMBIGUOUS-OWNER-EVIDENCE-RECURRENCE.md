# REG-20260818-2980 C34P ambiguous-owner evidence recurrence

Date: 18 August 2026 (IST)
State: registered before correcting REG2979 evidence or running a gate

## Incident

While registering REG2979, the primary placed the X-mobile source owner in its
registry evidence array even though the incident exists precisely because that
owner's existence is not yet proven. This repeats the REG2976 prevention class.
The error was detected before the memory gate ran; all agents remained stopped.

## Prevention

For mutation-ambiguity incidents, evidence arrays must contain only the registry,
coordination policy and verified incident document until owner existence is
proven. The potentially absent or ambiguous owner belongs only in narrative and
structured mistake fields. Remove the unverified path before running memory.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- `docs/quality/REG-20260818-2979-C34P-X-MOBILE-SCAFFOLD-RESULT-AMBIGUITY.md`
- this incident record
