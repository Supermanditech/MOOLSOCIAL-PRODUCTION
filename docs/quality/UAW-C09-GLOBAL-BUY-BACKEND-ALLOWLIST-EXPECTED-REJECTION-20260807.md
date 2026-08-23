# C09 global Buy backend allowlist expected rejection

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## Result

`scripts/check-buy-backend-contract-boundary.ps1` rejected the unrelated dirty
file
`backend/functions/src/commerce/acceptance_policy_governance_contract.test.ts`
as an unapproved Buy backend file owner.

The file belongs to the separately registered acceptance-policy audit/rollback
contract (`config/buy-mvp-acceptance-policy-audit-rollback-state.json`). C09 did
not create, modify, authorize or include it in the Android runtime source
aggregate. The gate failure therefore remains visible as a global dirty-tree
hold and is not repaired by expanding a protected backend allowlist inside this
mobile-navigation ticket.

## Prevention and build disposition

Before invoking repository-global gates in a shared dirty workspace, reconcile
new owners against their ticket state. A global rejection outside the candidate
input set is recorded separately from applicable mobile gates and cannot be
misreported as a pass. The APK candidate may proceed only if the machine-state
protected-boundary disposition names this rejection, proves backend files are
excluded from the candidate source aggregate, and every applicable mobile gate
passes.
