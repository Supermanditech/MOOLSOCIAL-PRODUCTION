# REG-20260818-2975 C34P FIX1 delivery-gate claimed path missing

Date: 18 August 2026 (IST)
State: registered before alternate-path search or gate creation

## Incident

While preparing to refresh the FIX1A execution gates, the primary attempted a
read-only parameter inspection of
`scripts/check-uaw-c34p-fix1-public-auth-live-adapter-blocker-resolution.ps1`.
The coordination policy claims that path, but the filesystem reported that the
file does not exist. The preceding MVP checker read succeeded. No retry, alternate
filename search, source/test mutation, build or external action followed.

## Prevention

After registration and generation refresh, enumerate only the bounded C34P script
filenames, reconcile whether the checker was never created or was named
differently, and either invoke the proven existing owner or create the claimed
gate in one small scaffold plus bounded patches. Never assume a claimed owner is
already materialized.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- `scripts/check-uaw-c34p-fix1-public-auth-live-adapter-blocker-resolution.ps1`
- this incident record
