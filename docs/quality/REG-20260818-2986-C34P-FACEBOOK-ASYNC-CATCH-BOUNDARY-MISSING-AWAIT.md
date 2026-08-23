# REG-20260818-2986 C34P Facebook async catch boundary missing await

Date: 18 August 2026 (IST)
State: registered before one-line correction or focused adapter retry

## Incident

In the serialized Facebook window, the existing contract suite passed 19/19.
The new adapter suite passed 9 tests and failed 2: Firebase and generic credential
failures escaped the intended sanitized outcome mapping because `signIn()`
returned `_completeSignIn(response)` without awaiting it inside the surrounding
`try`. No retry, provider, private, build or device action followed.

## Correction contract

Change only the success branch to `return await _completeSignIn(response);`, then
format, prove no-diff format, rerun focused analysis, and rerun only the adapter
test file in a new serialized Flutter window. The already-green 19-test contract
suite does not need repetition for this one-line control-flow correction.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart`
- `apps/mobile/test/uaw_c34p_facebook_native_sdk_adapter_test.dart`
- `apps/mobile/test/uaw_c34p_facebook_login_contract_test.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
