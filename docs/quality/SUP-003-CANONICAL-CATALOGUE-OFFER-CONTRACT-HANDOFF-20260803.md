# SUP-003 canonical catalogue and participant-offer contract handoff

Date: 3 August 2026

State: **TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD**

Candidate `SUP-003-CANONICAL-CATALOGUE-OFFER-CONTRACT-FIX1` establishes the
canonical product -> verified pack -> participant offer dependency required by
B2B-002. It reuses SUP-001 capability truth and keeps catalogue governance,
participant proposal and customer eligibility separate.

Exact qualified source is 82 files at SHA-256
`6F4574FBA21C7E31813FE8F05F170FE6E3FE7066998DF063026C79E454A30E50`.
Fourteen focused tests and two unchanged-source 298-test complete backend
regressions pass with all applicable boundary, self-test, egress,
compatibility and static gates.

Runtime files:

- `backend/functions/src/commerce/catalogue_contract.ts`
- `backend/functions/src/commerce/catalogue_contract.test.ts`

Exact evidence:
`artifacts/quality/canonical-catalogue-offer-contract-sup-3-20260803-119`.

No endpoint, persistence adapter, production catalogue, provider, payment,
Flutter projection or deployment was created. B2B-002 is next and must add
pack/loading facts as governed effective-dated snapshots rather than changing
canonical identity or inventing prices/terms.

