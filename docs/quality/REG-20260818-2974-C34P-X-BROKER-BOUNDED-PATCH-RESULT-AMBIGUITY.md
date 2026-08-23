# REG-20260818-2974 C34P X-broker bounded-patch result ambiguity

Date: 18 August 2026 (IST)
State: registered before owner readback or continuation

## Incident

While operating under the last passing generation-2942 gates, the X-broker
subagent created its claimed TypeScript scaffold and verified 123 lines. It then
issued one bounded same-owner append. The patch tool returned an empty structured
result and the primary stop notice arrived before the mandatory owner readback,
leaving the second mutation outcome unverified. The agent stopped without an
index/test write, parser, typecheck, test, build or external action.

## Prevention

After the registry refresh, the same owner must be read back in a bounded scalar
projection before any retry. If the intended section is present exactly once,
accept it without reapplying; if absent, apply only that bounded section once and
read it back immediately. Never infer success or failure solely from an empty
structured patch result.

## Retained evidence

- `backend/functions/src/auth/x_pkce_broker.ts`
- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- this incident record
