# REG-20260818-2958 C34P primary analyzer unused fake parameter

Date: 18 August 2026 (IST)
State: registered before source-test correction and analyzer retry

## Incident

The primary formatted six owned Dart files, then ran one focused Flutter
analyzer process against those exact owners. The process completed after 68.4
seconds with exit code 1 and one warning:
`providerFailure` was an optional fake-client parameter that no test supplied.
No Flutter test was started and the nonzero analyzer run is not qualification
evidence.

## Root cause

The fake client was expanded for both Google-credential and generic-provider
failure injection, but X and Facebook were simultaneously changed to fail
closed before generic Firebase dispatch. Only the Google failure seam remained
reachable, leaving the generic optional parameter unused.

## Prevention

Remove the unused `providerFailure` constructor parameter, field and branch
from the exact fake owner; keep the reachable `googleFailure` seam and its
sanitized Firebase tests. Reformat the single test owner, run a no-diff format
check, then rerun the same focused analyzer with full session/exit metadata
before any focused test.

## Retained evidence

- `apps/mobile/test/firebase_social_auth_gateway_test.dart`
- `config/codex-development-regression-registry.json`
- this incident record
