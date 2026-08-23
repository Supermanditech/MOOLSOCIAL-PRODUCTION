# REG-20260818-2992 C34P FIX1A gate X revocation token-spelling mismatch

Date: 18 August 2026 (IST)
State: registered before source signature projection or gate retry

## Incident

After the REG2991 selector correction, the FIX1A gate advanced through ticket,
MVP, runtime, session and mobile assertions, then rejected the X backend because
it required the literal `revokeAccessToken(accessToken`. The X broker's revocation
source and 12/12 tests are present, but its parameter/call spelling differs. No
correction or retry followed.

## Prevention

After registration, project the exact X revocation interface and call-site lines.
Assert a stable semantic method signature plus its awaited call rather than a
local variable name, then rerun the same PowerShell 7 gate.

## Retained evidence

- `backend/functions/src/auth/x_pkce_broker.ts`
- `backend/functions/src/auth/x_pkce_broker.test.ts`
- `scripts/check-uaw-c34p-fix1-public-auth-live-adapter-blocker-resolution.ps1`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
