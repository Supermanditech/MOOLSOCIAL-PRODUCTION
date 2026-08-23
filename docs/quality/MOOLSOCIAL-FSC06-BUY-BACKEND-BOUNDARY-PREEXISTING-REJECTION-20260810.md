# FSC06 Buy backend-boundary pre-existing rejection

`scripts/check-buy-backend-contract-boundary.ps1` rejected the current preserved
dirty tree because this unrelated path is not in its approved Buy backend owner
inventory:

`backend/functions/src/commerce/acceptance_policy_governance_contract.test.ts`

FSC06 did not create, read, modify or delete that owner. The selected ticket
changes navigation only and explicitly forbids backend work. The file remains
preserved for its owning user/ticket, and the global backend-boundary rejection
is disclosed rather than bypassed.
