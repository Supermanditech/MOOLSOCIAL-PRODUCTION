# C29U legacy YouTube verifier unrelated approved-UI lock rejection

- Date: 2026-08-11
- Intended expected profile: `PublicDataReview`
- Result: verifier did not reach provider evaluation

The legacy deployed-state verifier's nested preflight stopped with `Approved UI lock changed for login-account-handoff accepted production file`. That owner is outside the C29U Dev backend deployment scope and belongs to the preserved accepted dirty tree. It must not be reverted, rewritten or bypassed to make a backend command green.

C29U instead has its current exact source aggregate gate and direct postdeployment evidence: three ACTIVE Node.js 22 functions with exact entry points and service accounts, exact non-secret capability flags, exact secret-name bindings on YouTube only, deny-all client rules returning 403, Cloud Run invoker-check parity, and application-level missing-App-Check/Auth responses. The stale composite verifier remains rejected pending separate owner reconciliation.
