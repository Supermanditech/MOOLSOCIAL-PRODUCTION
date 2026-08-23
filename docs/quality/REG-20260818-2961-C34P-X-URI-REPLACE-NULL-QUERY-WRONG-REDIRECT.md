# REG-20260818-2961 C34P X URI null-query redirect rejection

Date: 18 August 2026 (IST)
Task: `/root/auth_x_pkce`
State: registered before source correction and focused retest

## Incident

The serialized X PKCE Flutter test completed with exit code 1 and `+4 -8`.
The first failure proved that `Uri.replace(query: null)` retained the source
query instead of producing the configured query-free authorization endpoint.
The same assumption in exact callback-base comparison made seven later valid or
intentionally invalid callback cases return `wrongRedirect` before their
specific state, expiry, denial or cardinality validations could run.

No source was changed after the failure and no retry, network, browser,
provider, device, private, account, build or Git publication action occurred.

## Root cause

The contract assumed a nullable `Uri.replace` argument clears an existing query
and fragment. In Dart, `null` means retain the current component for this API.

## Prevention and retry authority

The X owner introduces one explicit query-and-fragment-free base helper using a
fresh `Uri` projection, applies it to both configured authorization endpoint and
callback exact-base comparison, and adds/retains the direct base assertion that
failed first. After fresh local readback, format and clean two-owner analysis,
the primary may open one serialized rerun of the exact focused Flutter test.

## Retained evidence

- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart`
- `config/codex-development-regression-registry.json`
- this incident record
