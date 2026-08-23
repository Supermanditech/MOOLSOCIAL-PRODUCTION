# REG-20260818-2981 C34P Facebook pinned-SDK access-token API mismatch

Date: 18 August 2026 (IST)
State: registered before adapter correction or focused analyzer retry

## Incident

The first focused Facebook analyzer ran after formatting and no-diff formatting.
It rejected the new adapter because `flutter_facebook_auth` 7.2.0's base
`AccessToken` exposes neither `grantedPermissions` nor `declinedPermissions` at
the two adapter call sites. It also reported nine
`prefer_initializing_formals` infos. The analyzer exited 1; no Flutter test,
build, provider, private, network or device action followed.

## Correction contract

Use the pinned plugin's actual result surface: a successful native login after an
exact `public_profile` request may map to the adapter's success seam without
reading unavailable access-token permission lists. Keep explicit denied status
on the injected seam for denial fixtures, and convert the nine constructors to
initializing formals. Format, no-diff format and focused analyze must all pass
before the first focused Flutter test.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
