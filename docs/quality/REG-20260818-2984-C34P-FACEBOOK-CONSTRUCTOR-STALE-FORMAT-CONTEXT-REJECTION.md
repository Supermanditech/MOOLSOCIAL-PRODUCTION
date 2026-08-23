# REG-20260818-2984 C34P Facebook constructor stale-format context rejection

Date: 18 August 2026 (IST)
State: registered before constructor reread or patch retry

## Incident

The first REG2982 positional response-constructor correction landed and passed
bounded readback. The next bounded `FlutterFacebookNativeLoginClient` constructor
patch was atomically rejected because the exact formatted indentation/layout no
longer matched the remembered context. No partial change, formatter, analyzer,
test, build or external action followed the rejection.

## Prevention

After refreshed gates, read only the current constructor region, patch that one
constructor with its exact present context, and immediately read it back. Do not
reuse pre-format or remembered context across constructor corrections.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
