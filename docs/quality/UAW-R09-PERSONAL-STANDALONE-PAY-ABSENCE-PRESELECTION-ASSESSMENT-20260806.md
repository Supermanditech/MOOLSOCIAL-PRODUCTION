# UAW-R09 Personal standalone Pay absence preselection assessment

Date: 6 August 2026
Ticket: `UAW-R09-PERSONAL-STANDALONE-PAY-ABSENCE`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user sees no standalone Pay promise in Mool or the bounded action
roots. Payment and receipt actions remain inside their exact authorized order,
booking, trip or Work record. Removing the false broad launcher promise is a
founder-retained launch-truth requirement.

## Reuse and smallest complete scope

- Accept by test only: `personalMoolRootActions` already contains exactly the
  six MVP actions and no Pay route.
- Reuse the versioned Personal action projection, whose `removedActions`
  already records Pay, Recharge, Bills, Scan & Pay and generic Receipts.
- Preserve transaction-owned payment/session/screen owners and all historical
  routes for the later UAW-R12 central-containment ticket.
- Add one bounded contract test; change no production Dart file.

Necessity proof: implementation is already complete through R01/R03. New
runtime work would duplicate policy or risk deleting payment owners needed by
valid journeys. A separate acceptance contract is still necessary because R09
is an exact preauthorized customer-outcome unit.

## Explicit exclusions

- No price, payment, receipt, refund, recharge, bill, scan, payout or money
  behavior change.
- No route deletion or deep-link containment; UAW-R12 owns old-route handling.
- No backend/provider/payment-service call, credential or funds movement.
- No build, install, OPPO mutation, commit, push, deploy, promotion or
  protected-baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01/R03, existing
transaction-owned payment owners and later R12 containment.

Verification: ticket/route contract test; Personal action-projection gate and
self-test; R03 Mool regression; existing Pay vertical preservation regression;
full analyze; no build/device action.

Estimated batch impact: **test-only, under 1 day**, within the locked window.
