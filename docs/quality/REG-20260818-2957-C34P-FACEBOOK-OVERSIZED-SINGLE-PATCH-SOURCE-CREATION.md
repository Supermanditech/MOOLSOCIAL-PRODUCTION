# REG-20260818-2957 C34P Facebook oversized single-patch source

Date: 18 August 2026 (IST)
Task: `/root/auth_facebook`
State: registered before source reconciliation

## Incident

After its refreshed gates passed, the Facebook subagent created
`apps/mobile/lib/core/auth/facebook_login_contract.dart` in one `apply_patch`
operation. Immediate mandatory readback reported 353 lines, 11,365 bytes and
SHA-256 `580E5CCC7FF79B453318C5C6C525B7055B0393877424A990D549E1F3E78F4441`.
This violated the durable rule that a new source expected to exceed roughly 300
lines must be assembled as a scaffold plus bounded section patches.

The subagent stopped before creating its test owner, formatting, analysis or
tests. No provider, browser, device, private, account or external action
occurred.

## Root cause

The complete planned source was treated as one new-file operation instead of
estimating its size and applying the bounded-source construction rule before
the first write.

## Prevention and reconciliation

The primary reviews the existing source in exact non-overlapping windows of at
most 100 lines through EOF before it can be accepted. Any correction uses a
fresh local hunk and immediate readback. The subagent creates the missing test
owner as a scaffold plus bounded sections, formats only its two owners, and
waits for a serialized test window. The existing source is preserved; it is not
deleted or recreated to erase the incident history.

## Retained evidence

- `apps/mobile/lib/core/auth/facebook_login_contract.dart`
- `config/codex-development-regression-registry.json`
- this incident record
