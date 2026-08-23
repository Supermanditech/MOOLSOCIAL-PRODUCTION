# MoolSocial autonomous Buy and whole-app backend readiness audit

Date: 2026-08-14 IST
State: `READ_ONLY_AND_LOCAL_TEST_AUDIT_COMPLETE_RUNTIME_BACKEND_AND_EXTERNAL_WRITES_HELD`
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Authority and boundary

The founder directed Codex to look into other Buy backend work or other autonomous work across the existing pages while release approval is pending. This authorizes safe local inspection and tests. It does not replace the exact C30W machine-state owner, select a successor ticket, authorize a runtime/backend write, create a store or endpoint, access credentials, call a provider, deploy, build, upload, install, mutate the OPPO, send a message, submit quota, move funds or change a Play track.

`config/mvp-scope-gate-state.json` still owns C30W and records `backendWriteAuthorized=false`. The pre-ticket robustness/reuse checkpoint remains fail-closed before every successor selection. No successor was registered or selected by this audit.

## Release bootstrap wiring truth

The current normal release bootstrap in `apps/mobile/lib/main.dart` explicitly wires:

- Firebase phone authentication;
- HTTP email authentication;
- native Google/Firebase social identity;
- Data Connect account bootstrap;
- device location/current-area owners; and
- `ChatSession.production()`.

`SharedSession` separately builds an authenticated Social content gateway when the exact content endpoint define is present and otherwise fails closed with `UnavailableSocialContentGateway`.

The release bootstrap does not inject production sessions for the remaining customer/business domains. `MoolSocialApp` therefore constructs their default sessions, and those sessions currently select review gateways:

| Domain surface | Current release-default owner | Backend truth |
| --- | --- | --- |
| Buy / Medicine / order placement | `BuySession` -> `ReviewBuyOrderGateway` and `ReviewBuyMedicineGateway` | deterministic review receipts and review prescription/pharmacist acknowledgements; no production transport |
| Eat | `EatSession` -> `ReviewEatOrderGateway` | review completion only |
| Ride | `RideSession` -> `ReviewRideGateway` | review completion only |
| Book | `BookSession` -> `ReviewBookGateway` | review completion only |
| Work | `WorkSession` -> `ReviewWorkGateway` | review completion only |
| Pay | `PaySession` -> `ReviewPayGateway` | no live payment truth |
| Retailer | `RetailerSession` -> seven review gateway families | no live catalogue/order/POS/books/campaign/control service |
| Manufacturer | `ManufacturerSession` -> `ReviewManufacturerGateway` | no live manufacturer service |
| Captain | `CaptainSession` -> `ReviewCaptainGateway` | no live captain service |
| Operations | `OperationsSession` -> `ReviewOperationsGateway` | no live operations service |
| Creator domain session | `CreatorSession` -> `ReviewCreatorGateway` | separate Social/YouTube production owners do not make this generic session live |
| Shared non-Social actions | `SharedSession` -> `ReviewSharedGateway` | Social content may be live/fail-closed independently; generic shared business actions remain review-owned |

Passing UI and local journey tests does not turn these gateways into production services. The existing QA-023 decision remains correct: whole-app real-user production launch is no-go while authoritative business APIs, payments and provider owners are absent.

## Backend endpoint and persistence inventory

The backend contains `114` TypeScript source/test owners and exports four HTTP functions from `backend/functions/src/index.ts`:

1. `youtubeProvider`;
2. `moolSocialContent`;
3. `moolSocialChat`; and
4. `youtubeOAuthCallback`.

There are zero imports of `./commerce/` anywhere in those 114 TypeScript owners. No Buy catalogue, serviceability, inventory, reservation, basket, order, payment, prescription or fulfilment endpoint is exported. The repository also has no commerce Firestore rules or Data Connect schema owner.

The current Buy mobile gateway is therefore correctly described as review-only. It must not be connected directly to Firestore, Firebase Functions, an invented URL or a payment SDK merely to make the page appear live.

## Existing commerce foundation that must be reused

Eight local commerce contract families already exist:

- participant/workspace capabilities (`SUP-001`);
- canonical product, pack and offer (`SUP-003`);
- wholesale pack/logistics units (`B2B-002`);
- provider ready/busy/paused state;
- acceptance SLA policy;
- market/schedule SLA overrides;
- immutable order-timer policy snapshots; and
- maker-checker acceptance-policy governance/audit/rollback.

The five selected Buy machine-state owners checked in this audit all retain exact contract and test SHA-256 matches. Every one records `newStoresOrEndpoints=0` and `liveCommands=0`. Their held slices truthfully include production stores, adapters, assignment/orchestration, Admin presentation and live provider notifications.

Ten acceptance-policy/readiness/order-timer source/test owners are preserved untracked user files. They were inspected and tested but not edited.

## Current qualification

- Backend TypeScript `tsc --noEmit`: passed.
- Commerce compiled-owner freshness: every source owner has a current compiled owner.
- Commerce unit corpus: `137 passed`, `0 failed`, `0 skipped`.
- Whole local backend unit corpus: `516 passed`, `0 failed`, `0 cancelled`, `0 skipped`, `0 todo`.
- Current regression-memory gate: `2087` entries, `1183` applicable implementation entries, passed.
- Five current Buy state-owner contract/test hash pairs: all exact.

The historical global Buy backend-absence boundary is not green in the current dirty tree. It correctly rejects the separately ticketed untracked `acceptance_policy_governance_contract.test.ts` file because that old gate predates the approved local contract work. Durable FSC06 evidence already records the incompatibility. The gate was not weakened, its allowlist was not changed and the preserved file was not touched. A future additive replacement requires its own selected ticket.

## Exact dependency finding

The next lawful Buy backend step is not checkout, order placement, PhonePe, an HTTP adapter or a direct Flutter connection.

The registered sequence requires `SUP-004` inventory/reservation/serviceability truth before seller-specific `SUP-005` orders and `PAY-003` payment attempts. `SUP-004` is currently blocked because no exact inventory owner, fulfilment owner or qualified freshness/serviceability contract has been named. Existing state `BUY-MVP-NO-RESERVATION-OFFER-READINESS` correctly holds execution for those missing dependencies.

This makes the current critical path:

`SUP-001 participant capability + SUP-003 catalogue/offer + B2B-002 pack`
`-> founder-named inventory and fulfilment owners`
`-> SUP-004 inventory/reservation/serviceability quote`
`-> SUP-005 seller-specific order commitment`
`-> PAY-003 provider-neutral payment attempt`
`-> separately authorized PhonePe sandbox adapter`
`-> Flutter production adapters and accepted live journeys`.

No later step may be pulled forward to simulate the missing earlier truth.

## Prepared existing-ticket disclosure for a future SUP-004 selection

This is planning only. It is not registered, selected or executing.

- **Ticket:** existing registered `SUP-004`.
- **Customer outcome:** a Personal or verified Business Buy customer receives an explicit serviceable, stale, partial or unavailable quote for the exact destination, pack and quantity; the app never invents stock, delivery or landed price.
- **Classification:** `mvp_required`, because truthful availability and serviceability must precede Cart commitment, order placement and payment.
- **Smallest complete implementation:** one local deterministic domain contract reusing SUP-001/SUP-003/B2B-002 and the existing readiness policy; exact named inventory and fulfilment owners; no store/endpoint until its separate adapter slice is selected.
- **Explicit exclusions:** no customer UI, no review-gateway replacement, no live inventory, no reservation mutation, no payment, no provider call, no credentials, no deployment, no build, no device action and no Production data.
- **Dependencies requiring founder/business direction:** exact launch participant/workspace type, exact pilot category/geography, authoritative inventory owner, authoritative fulfilment owner, reservation authority, quote freshness threshold and the accountable unavailable/stale recovery owner.
- **Test plan:** tenant/workspace authorization, participant capability, category and service-area eligibility, exact pack/quantity, stock/freshness, no-reservation behavior, reservation conflict/idempotency where later authorized, cut-off/lead time, delivery/collection, retail/wholesale isolation, stale/partial/unavailable results, nonmutation, restart serialization and payload-free audit evidence.
- **Reuse disposition:** reuse and one provably necessary domain contract only; zero new screens or routes; persistence/endpoint remains a later separately selected adapter slice.

## Planning-only whole-app follow-on

After the YouTube compliance result is recorded and C30W no longer owns the machine state, the previously proposed post-YouTube whole-app audit should add an exact release-gateway realism row for every page family. It must prove one of three truthful states per action:

1. authenticated production owner;
2. explicit unavailable/coming-later state with no false completion; or
3. separately authorized provider sandbox/Dev trial.

Review gateways, local delayed success, fixture receipts and customer-visible completion copy must fail the future release-realism gate. This should reuse the current domain sessions and QA-023/production-cascade owners rather than create duplicate pages or services.

## Founder decisions on return

Release approvals for proposed r60.48 remain exactly separate and unchanged.

For Buy/backend work, the next distinct decisions are:

1. decide whether `SUP-004` becomes the next backend ticket only after the C30W/YouTube ordering gates permit successor selection;
2. name the exact inventory and fulfilment owners plus pilot actor/category/geography/freshness boundary;
3. approve the completed pre-ticket robustness/reuse assessment and local backend-write authority only;
4. later and separately approve a persistence/HTTP adapter slice after the local contract passes; and
5. keep provider credentials, deployment, PhonePe sandbox, funds, Flutter runtime wiring, Play, build and device actions separately gated.

## Remaining risks

- The current OPPO remains failed r60.47; this audit does not change release readiness.
- Most non-Social business pages can currently produce review-owned outcomes in a release process.
- Commerce contracts are strong but disconnected from stores, endpoints and Flutter.
- SUP-004 and every downstream order/payment slice remain dependency blocked.
- The old global Buy absence-boundary gate and newer separately ticketed untracked contract owners need an additive, authorized reconciliation before that gate can become release evidence again.
- No whole-app production-grade claim is permitted until every reachable action has authoritative backend/provider truth or an explicit unavailable state and passes live journey acceptance.
