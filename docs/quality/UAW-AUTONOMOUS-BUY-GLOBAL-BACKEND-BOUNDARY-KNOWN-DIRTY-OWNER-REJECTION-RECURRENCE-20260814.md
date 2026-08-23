# Autonomous Buy global backend-boundary known dirty-owner rejection recurrence

Date: 2026-08-14
Registry ID: `REG-20260814-2115-AUTONOMOUS-BUY-GLOBAL-BACKEND-BOUNDARY-KNOWN-DIRTY-OWNER-REJECTION-RECURRENCE`

The historical repository-global Buy backend absence-boundary gate was invoked during the read-only audit. It correctly rejected the preserved `backend/functions/src/commerce/acceptance_policy_governance_contract.test.ts` owner, which durable FSC06 and regression evidence already identifies as a separately ticketed file outside that gate's old allowlist.

The failed gate is not retried, weakened or used to modify the user-owned file. Current evidence instead uses exact ticket-state hashes, backend TypeScript typecheck and the compiled commerce test corpus. Any additive replacement of the historical absence boundary needs a separately selected and authorized ticket.
