# REG-20260818-2985 C34P X-mobile wrong package import and constructor infos

Date: 18 August 2026 (IST)
State: registered before focused analyzer correction or retry

## Incident

After all four mobile owners passed independent no-diff format checks, the first
focused X analyzer exited 1 with 49 findings. The X test imported nonexistent
`package:moolsocial_v2/...`, causing URI and cascading undefined-symbol errors.
The source also had five `prefer_initializing_formals` infos. Instagram analysis
and all Flutter tests remained unstarted.

## Correction contract

After refreshed gates, read the exact package name from `pubspec.yaml` and the
five current constructor lines. Correct only the import and initializing-formal
constructors, format/no-diff both X owners, then rerun the same two-owner analyzer.
Treat the 44 downstream symbol/const findings as unproven cascades until that
single import is corrected.

## Retained evidence

- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_network_adapter_test.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
