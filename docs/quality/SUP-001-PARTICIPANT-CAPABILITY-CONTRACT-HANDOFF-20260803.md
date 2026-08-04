# SUP-001 participant/workspace capability contract handoff

Date: 3 August 2026

State: **TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD**

Candidate `SUP-001-PARTICIPANT-CAPABILITY-CONTRACT-FIX1` establishes the first
server-domain dependency for SUP-003 and B2B-002. It models seven participant
types and four independently governed capabilities without treating
registration, workspace type or a deterministic fixture as verification.

Exact qualified backend/build/gate source is 80 files at SHA-256
`54459BB626F366EFD9F7411BC16AF1A0622E7E5E7BE0B43BC987E230366DC16C`.
Thirteen focused tests and two complete unchanged-source 284-test backend
regressions pass with all applicable boundary, self-test, data-egress,
compatibility and static gates.

Runtime files:

- `backend/functions/src/commerce/supply_participant_contract.ts`
- `backend/functions/src/commerce/supply_participant_contract.test.ts`

Exact evidence:
`artifacts/quality/supply-participant-capability-contract-sup-1-20260803-118`.

No deployed Functions export, endpoint, database schema, persistence adapter,
credential, provider call, production record, Flutter surface or APK was
created. SUP-003 is the next dependency ticket; it may reuse only verified
capability projections and must not manufacture catalogue approval.

