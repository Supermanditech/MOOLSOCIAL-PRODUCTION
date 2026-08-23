# REG-20260818-2987 C34P shared-auth integration first analyzer six issues

Date: 18 August 2026 (IST)
State: registered before correction or focused analyzer retry

## Incident

The first focused analyzer for the primary-owned shared authentication integration
exited 1 with six findings: three callback calls remained typed as
`SocialAuthGateway` because the local variable was not explicitly promoted to
`SocialAuthCallbackGateway`; the broker-result switch omitted the intentional
`accountIneligible` outcome; and the temporary Facebook Graph revocation seam had
two `prefer_initializing_formals` infos. No retry or test followed.

## Correction contract

Bind a promoted callback-interface local after the type check, add
`accountIneligible` to the sanitized terminal broker outcomes, and use a private
positional initializing-formal constructor behind the existing named revocation
factory. Format/no-diff the affected primary owners, then rerun the identical
nine-owner analyzer before any shared integration test.

## Retained evidence

- `apps/mobile/lib/features/journey01/journey_session.dart`
- `apps/mobile/lib/features/journey01/review_journey_services.dart`
- `apps/mobile/lib/main.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
