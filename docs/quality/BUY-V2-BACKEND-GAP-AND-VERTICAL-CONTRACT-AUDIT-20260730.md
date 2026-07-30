# Buy V2 backend gap and vertical-contract audit

Recorded: 2026-07-30 IST
Mode: read-only backend inspection plus mobile contract documentation
Ticket: `BUY-FV2-054`

## Inspected production owners

- `backend/functions/src`
- `backend/functions/package.json`
- `contracts`
- `apps/mobile/lib/features/buy`
- `apps/mobile/test/ui_v2/buy`

The backend contains 79 files. Its production implementation and tests are
YouTube-specific. Search across the backend found no Buy catalogue, Shop
search, Wholesale search, Medicine search, inventory, cart, checkout, order or
Buy-admin endpoint. The only repository contract document is the account-setup
journey contract. No Buy transport schema, API error envelope, database model
or authorization contract is established.

## Existing durable mobile boundaries

These are in-process Flutter facts, not network API contracts:

- destinations are `shop`, `wholesale`, `medicine` and the order owner;
- Shop and Wholesale use distinct offer IDs with one shared canonical product
  identity;
- Shop and Wholesale retain independent category IDs, pricing, seller,
  fulfilment, return and minimum-order facts;
- Medicine uses independent product IDs, licensed-pharmacy ownership and
  prescription/regulatory facts;
- destination switching clears transient query/filter state while retaining
  the independently selected category for each vertical;
- cart scope and checkout scope preserve vertical ownership;
- fulfilment groups are separated by destination and seller;
- saved address and selected payment are independent session selections;
- orders retain destination, partner, progress, status and exact product IDs
  when those IDs were created by the current session.

`buy_v2_vertical_contract_test.dart` now protects these established facts at
the adapter seam without defining a server protocol.

## Explicitly absent and therefore deferred

The following cannot be implemented safely without founder and API decisions:

- endpoint paths, HTTP methods, request/response envelopes and error codes;
- database tables/collections, identifiers, retention and migration policy;
- pagination cursor shape, page-size limits and result ranking;
- filter/sort wire values and vertical-specific availability rules;
- authoritative inventory reservation, price validity and concurrency rules;
- cart ownership, merge, expiry and guest-to-account behaviour;
- checkout idempotency, payment orchestration and retry semantics;
- prescription storage, review, consent, expiry and access-control policy;
- authentication claims, Buy roles, RBAC matrix and tenant boundaries;
- MoolSocial admin resources, mutation permissions and audit-history schema;
- observability event names, PII classification, redaction and retention;
- service-level objectives, cache policy and provider fallback rules.

Adding any of those now would invent backend behaviour or contracts. No
backend source, schema, deployment file or protected Social code was changed.

## Safe next backend gate

Before backend implementation, an approved contract package must define at
least identity, authorization, request/response and failure semantics for each
vertical. Shop, Wholesale and Medicine should expose replaceable adapters over
shared infrastructure while keeping their validation and fulfilment rules
separate. Until that authority exists, regression protection at the current
mobile seam is the safe durable work.
