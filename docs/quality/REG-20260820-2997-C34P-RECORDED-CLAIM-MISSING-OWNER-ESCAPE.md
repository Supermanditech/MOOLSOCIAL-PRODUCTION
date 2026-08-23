# REG2997 — C34P recorded claim missing-owner escape

Date: 20 August 2026 (IST)
State: registered before claim correction

## Incident

The current `/root` coordination claim records
`apps/mobile/test/uaw_c34p_fix1_public_auth_live_adapter_integration_test.dart`,
but the literal owner does not exist. The coordination gate still passed with
`-UseRecordedClaim` because it validates claim uniqueness and membership but
does not require every recorded owner to exist. No test or mutation depended
on the missing file.

## Root cause

The superseded FIX1 planning owner remained in the primary claim after the
founder-corrected FIX1A wave materialized a differently named integration
owner. The gate's recorded-claim branch lacks an existence assertion.

## Prevention

Remove the nonexistent superseded owner from the active claim, retain the exact
existing FIX1A owner, and strengthen the coordination checker so every recorded
owner must be an existing repository leaf before a recorded claim can pass.
Add a negative fixture proving a missing recorded owner fails closed.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `scripts/check-codex-subagent-coordination-policy.ps1`
- `apps/mobile/test/uaw_c34p_fix1a_apple_instagram_public_login_integration_test.dart`
- `config/codex-development-regression-registry.json`
