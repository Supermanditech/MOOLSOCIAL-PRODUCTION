# REG-20260818-2990 C34P Facebook default HTTPS port normalization fixture

Date: 18 August 2026 (IST)
State: registered before fixture correction or serialized retry

## Incident

The serialized Facebook adapter suite passed 17 tests and failed 1. Its endpoint
negative matrix expected `https://graph.facebook.com:443/v25.0/me/permissions`
to be distinguishable from the valid endpoint. Dart `Uri.parse` normalizes the
explicit default HTTPS port away, producing the identical canonical URI; source
readiness correctly remained true. No retry, transport, network or provider
action followed.

## Correction contract

Remove only the semantically indistinguishable explicit-`:443` fixture. Retain
all wrong-scheme, wrong-host, wrong-version/path, query, fragment and user-info
negative cases. Format/no-diff, rerun focused analysis, then rerun exactly the
adapter test file in a new serialized window.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart`
- `apps/mobile/test/uaw_c34p_facebook_native_sdk_adapter_test.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
