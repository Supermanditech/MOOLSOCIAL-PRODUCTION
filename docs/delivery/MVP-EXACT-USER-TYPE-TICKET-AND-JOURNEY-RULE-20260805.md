# MVP exact user-type ticket and journey rule

Date: 5 August 2026
State: founder-directed and active for all new ticket planning

Latest bounded action/profile refinement:
`docs/delivery/MVP-FOUNDER-ACTION-PROVIDER-SURFACE-DIRECTIVE-20260805.md`.
Where this file's original disposition changed, the later explicit founder
directive controls and the table below records the reconciled result.

## Production-language correction

`Business`, `provider`, `partner`, `merchant`, `professional`, `creator` or
`Admin` is not a sufficient production actor when the actual user type and
permission are known. Those words may describe a parent grouping only. Every
executable child ticket must name the exact user/workspace type, exact
capability and exact authoritative outcome.

Examples:

- prohibited: `business onboarding`;
- required: `Grocery / Kirana Shop identity, service-area, Shop-offer and
  order-acceptance capability activation`;
- prohibited: `provider fulfilment`;
- required: `Delivery Partner PIN-code, capacity, handling-type, pickup and
  delivery-proof capability activation`;
- prohibited: `Admin review`;
- required: `Medical Store / Pharmacy licence and medicine-fulfilment reviewer
  decision with reason, evidence, expiry and appeal owner`.

## Mandatory ticket fields

Every new parent and child ticket records:

1. exact user type ID and customer-facing label;
2. exact acting role and workspace boundary;
3. one practical customer or operator outcome;
4. exact entry, decisions, confirmation and completion taps;
5. authoritative server owner for identity, permission and resulting state;
6. allowed capability, geography, category and validity period;
7. draft, submitted, pending, approved, rejected, suspended, expired and
   revoked behavior where applicable;
8. offline, duplicate, cancellation, interruption, retry and support recovery;
9. `mvp_required`, `mvp_supporting` or `beyond_mvp` classification with reason;
10. smallest complete launch scope and explicit exclusions;
11. dependencies and separate regulatory, finance, provider, reference,
    environment and founder approvals; and
12. exact automated, responsive, accessibility, browser/device, audit and
    checksum evidence.

A generic parent portfolio is permitted only when every executable child uses
this exact actor/capability format. A label never grants a capability. Admin
may activate only registered capabilities whose independent evidence and gates
have passed.

## Exact known profile registry and current MVP disposition

All 29 approved profile targets remain explicit. `Registered disabled` means
the type remains known to the product and Admin registry but receives no live
feature, promise, user exposure or implementation authority in the current MVP.

| Exact profile target | Current classification | Practical current boundary |
| --- | --- | --- |
| Personal user | `mvp_required` | Authenticate, buy, receive an order, use funded Work where eligible and use the approved Social slice; no workspace capability is implied. |
| FMCG Manufacturer | `mvp_supporting` | Launch-pilot product-master, verified pack, eligible wholesale offer and dispatch only; manufacturing ERP and broad B2B remain excluded. |
| FMCG Supplier / Distributor | `mvp_required` | Complete Wholesale launch pack/MOQ offer, service area, exact commercial terms, accepted order and dispatch only. |
| Raw Material Supplier | `beyond_mvp` | Registered disabled; future raw-material sourcing requires its own exact procurement journey. |
| Packaging Supplier | `beyond_mvp` | Registered disabled; future packaging sourcing requires its own exact procurement journey. |
| Grocery / Kirana Shop | `mvp_required` | Identity, Shop catalogue/offer/stock, acceptance timer, pick/pack, handover and customer-order completion. |
| General Retail Shop / Dukaan | `mvp_required` | Only founder-approved launch categories and service areas; same truthful offer/order/fulfilment contract as its enabled category. |
| Individual Product Seller | `beyond_mvp` | Registered disabled; marketplace-seller activation requires separate identity, tax, returns and fulfilment authority. |
| Restaurant / Dhaba / Cafe | `mvp_required` | Bounded Order Food and Book Table journeys only; Cloud Kitchen, Tiffin and broader restaurant depth remain excluded. |
| Cloud Kitchen | `beyond_mvp` | Registered disabled; future menu, kitchen capacity, food order and delivery journey is separate. |
| Tiffin Provider | `beyond_mvp` | Registered disabled; future plan, pause, delivery calendar and food-safety journey is separate. |
| Individual Doctor | `mvp_required` | Bounded Doctor discovery, decision-ready fee/time/mode, booking, service completion and recovery only; Clinic, Hospital, diagnosis, clinical records and unapproved telemedicine remain excluded. |
| Clinic | `beyond_mvp` | Registered disabled; future clinic schedule, patient, visit and regulated-data journey is separate. |
| Hospital | `beyond_mvp` | Registered disabled; future hospital OPD/admission journey requires separate exact authorization. |
| Medical Store / Pharmacy | `mvp_required` | Licence, service area, medicine offer, prescription/pharmacist review, accepted quantity, fulfilment and handover only. |
| Salon / Parlour | `mvp_required` | Bounded exact service, price, visit mode, professional/slot, payment, service completion and recovery journey only. |
| Home Beauty Provider | `beyond_mvp` | Registered disabled; future home-service identity, safety, slot, travel and proof journey is separate. |
| Individual Service Provider | `beyond_mvp` | Registered disabled; each service category requires an exact scoped journey rather than a generic provider ticket. |
| Bike Captain | `mvp_required` | Bounded Bike Ride capability with independent vehicle, document, geography, safety, availability, assignment, trip, payment and recovery authority. |
| Auto Captain | `mvp_required` | Bounded Auto Ride capability with independent vehicle, document, geography, safety, availability, assignment, trip, payment and recovery authority. |
| Cab / Car Captain | `mvp_required` | Bounded Cab/Taxi Ride capability with independent vehicle, document, geography, safety, availability, assignment, trip, payment and recovery authority. |
| Delivery Partner | `mvp_required` | Buy-order service area, capacity, handling type, assignment, pickup, proof, handover and failure recovery; no seller or Ride rights. |
| Local Porter / Goods Transporter | `mvp_supporting` | Dependency-held for the bounded Wholesale pilot only; general transport marketplace remains excluded. |
| Transport / Fleet Operator | `beyond_mvp` | Registered disabled; multi-vehicle dispatch and enterprise fleet operations are not launch MVP. |
| Shorts Creator | `mvp_required` | Native/eligible YouTube content, rights, one declared action and bounded campaign; founder-deferred with the current YouTube compliance step. |
| Long-Form Video Creator | `beyond_mvp` | Registered disabled for owned long-form hosting/publishing; no broad video-platform expansion in MVP. |
| Multi-Format Creator | `mvp_required` | Native text/image and eligible public YouTube-link scope only; founder-deferred with the Social/YouTube sequence. |
| Freelancer / Field Partner | `mvp_required` | Funded Work eligibility, terms, acceptance, proof, review/rework/appeal and auditable payout result. |
| Get It Done Provider | `beyond_mvp` | Registered disabled; generic service booking is blocked until category-specific complete journeys are approved. |

The machine-readable mirror is
`config/mvp-exact-user-type-scope-matrix.json`. A later policy decision may
change a type's disposition only through an explicit versioned founder record;
it never silently rewrites this decision.

## Correct next MVP planning parent

The vague planning candidate
`BUSINESS-ADMIN-MVP-SUBMISSION-TO-GOVERNED-LAUNCH-END-TO-END-JOURNEY` is
withdrawn and must not be used.

The corrected parent candidate is:

`SUPERADMIN-MVP-EXACT-LAUNCH-PARTICIPANT-PROVISIONING-AND-CONTROL-END-TO-END-JOURNEY`

It is a parent acceptance journey only. Its eventual 30–50 child tickets must
be separated at minimum into these exact practical lanes:

1. Personal user account/eligibility read-only control;
2. Grocery / Kirana Shop activation and order-capability control;
3. General Retail Shop / Dukaan launch-category activation;
4. FMCG Supplier / Distributor wholesale-offer and dispatch activation;
5. FMCG Manufacturer bounded product-master, pack and dispatch pilot
   activation;
6. Medical Store / Pharmacy licence and Medicine-fulfilment activation;
7. Restaurant / Dhaba / Cafe Order Food and Book Table activation;
8. Individual Doctor bounded booking activation;
9. Salon / Parlour bounded service/slot activation;
10. Bike Captain Ride activation;
11. Auto Captain Ride activation;
12. Cab / Car Captain Ride activation;
13. Delivery Partner area, capacity, assignment and proof activation;
14. Local Porter / Goods Transporter bounded Wholesale-pilot activation;
15. Freelancer / Field Partner Work eligibility/proof/payout activation;
16. funded-Work opportunity funder budget/terms/capacity control;
17. independent Work evidence reviewer/rework/appeal control;
18. Shorts Creator rights/action/campaign activation, dependency-held by the
    current YouTube sequence;
19. Multi-Format Creator native-post/eligible-link activation, likewise held;
20. exact identity and licence reviewer role;
21. exact catalogue/product-master reviewer role;
22. exact pharmacy/regulated-product reviewer role;
23. exact food-business reviewer role;
24. exact Doctor/Salon regulated-capability reviewer role;
25. exact Ride vehicle/document/safety reviewer role;
26. exact finance/funding/reconciliation reviewer role;
27. exact Trust and Safety/rights reviewer role;
28. exact support/case-recovery operator role; and
29. exact launch/canary/health/pause/rollback operator role.

Each lane must split again where one ticket would otherwise own multiple
unrelated capabilities. The exact Restaurant, Individual Doctor, Salon,
Bike-Captain, Auto-Captain and Cab-Captain boundaries above are now bounded MVP
planning scope. Cloud Kitchen, Tiffin Provider, Clinic, Hospital, Home Beauty,
fleet, generic service-provider and all depth outside the exact founder action
directive stay explicit in the registry but cannot enter an MVP execution
portfolio without separate exact founder authorization.

## Authority boundary

This rule and matrix are planning/project memory. They do not preauthorize the
corrected parent, any child implementation, build, browser/OPPO execution,
external-service action, production data, credentials, commit, push, deploy or
promotion.
