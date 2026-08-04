# B2B-002 wholesale pack and logistics-unit contract handoff

Date: 3 August 2026

State: **TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD**

Candidate `B2B-002-WHOLESALE-PACK-LOGISTICS-UNIT-CONTRACT-FIX2` builds on
qualified SUP-001/SUP-003 without creating a live wholesale offer. It binds one
verified canonical pack to independently reviewed, effective-dated physical
pack profiles while preserving canonical product and pack identity.

Exact qualified source is 84 files at SHA-256
`8A067CE17C21F72FC2C5A8BAD5749A8F11AC5C258FC16D5CF7042084A213C599`.
Nineteen focused tests and two unchanged-source 317-test complete backend
regressions pass with all applicable boundary, self-test, egress,
compatibility, protected-outcome and static gates.

Runtime files:

- `backend/functions/src/commerce/wholesale_pack_contract.ts`
- `backend/functions/src/commerce/wholesale_pack_contract.test.ts`

Exact evidence:
`artifacts/quality/wholesale-pack-logistics-unit-contract-b2b-2-fix2-20260803-122`.

FIX1 remains preserved and technically qualified at
`artifacts/quality/wholesale-pack-logistics-unit-contract-b2b-2-20260803-120`.
FIX2 adds exact source catalogue/product/pack lineage, contains invalid
catalogue-code input inside the B2B error boundary and caps profile history at
100 records. It changes no commercial or UI behavior.

The model covers exact count/mass/volume pack measure, each/inner/case/pallet
or weight/volume hierarchy, sale/loading levels, physical dimensions and
weight, governed codes, batch/expiry policy evidence and exact effective
windows. It does not assert actual batch/expiry observations or any live
availability.

No B2B-001, TAX-001/TAX-003 or PAY-001 decision was inferred. Physical pack
units do not establish invoice UQC or tax treatment. No MOQ, pricing, tax,
freight, deposit, payment, credit, inventory, purchase order, endpoint,
persistence adapter, provider, Flutter projection or deployment was created.
Motion/OPPO is inapplicable to this server-only candidate and remains mandatory
for the later native B2B UI ticket.
