# REG-20260818-2973 C34P coordination-gate missing required parameters

Date: 18 August 2026 (IST)
State: registered before corrected gate invocation

## Incident

After the regression-memory gate passed at registry generation 2942, the primary
invoked the coordination checker without its mandatory `AgentRole`, `AgentTask`,
`ExpectedRegistryEntryCount`, and `ExpectedRegistrySha256` parameters. PowerShell
rejected the invocation before the checker evaluated repository state. No source,
test, provider, build, device or private action followed the failed invocation.

## Root cause

The checker was called as if it supported a parameterless repository-wide mode,
despite its declared mandatory identity and pinned-generation contract.

## Prevention

Read the checker parameter block before a resumed invocation and always pass the
exact recorded task, role, `-UseRecordedClaim`, registry entry count, and registry
SHA-256. Treat a missing-parameter rejection as non-authorizing and do not retry
until it is registered and the generation is refreshed.

## Retained evidence

- `scripts/check-codex-subagent-coordination-policy.ps1`
- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- this incident record
