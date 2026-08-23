# REG-20260818-2982 C34P Facebook constructor-redirection analyzer errors

Date: 18 August 2026 (IST)
State: registered before second constructor correction or analyzer retry

## Incident

The post-REG2981 focused analyzer proved the pinned AccessToken API correction,
but rejected the constructor-lint remediation with 18 missing or undefined named
parameter errors. Same-class generative redirects targeted private named
initializing-formal constructors, while Dart resolved redirect call sites against
the public constructor names. No test, build, provider, private or device action
followed.

## Correction contract

Preserve the public named factory API, delegate each factory to a private
positional initializing-formal constructor, and update only the internal calls.
Then require format, no-diff format and a zero-issue focused analyzer before the
first Facebook Flutter test.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
