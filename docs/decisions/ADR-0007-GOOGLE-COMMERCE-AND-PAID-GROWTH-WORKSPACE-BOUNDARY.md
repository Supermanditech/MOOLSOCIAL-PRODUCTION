# ADR-0007 — Google commerce and paid-growth Workspace boundary

- Status: **founder accepted as a future Workspace integration boundary;
  implementation deferred**
- Decision date: 23 July 2026
- Applies to: verified Creator and Business Workspaces
- Does not approve: API enablement, Merchant Center registration, Google Ads
  developer-token access, credentials, OAuth clients, advertising spend,
  customer UI, Staging, Production or promotion
- Active environment when separately authorized:
  `moolsocial-dev-503018` only

## Context

Merchant API and Google Ads Demand Gen can extend MoolSocial's creator-commerce
and business-growth value, but they are not Social viewing services. Placing
their controls in public Social, Screen 04 or Personal Create would expose
professional account operations to the wrong audience and blur the boundary
between MoolSocial commerce, YouTube data and paid Google media.

The founder therefore assigned both integrations to the future signed-in
Workspace module.

## Decision

Merchant Center, YouTube Shopping affiliate reporting and Google Ads Demand
Gen belong only inside a selected, verified Creator or Business Workspace.

They do not belong in:

- public Social or Screen 04;
- the Universal bottom rail;
- Personal Reels, Videos, Feed or Create;
- ordinary consumer search; or
- the active private YouTube provider proof.

`Work -> Workspace` or Profile may let an authorized user enter or select a
workspace. Provider configuration, account ownership, budgets, catalogues and
reports begin only inside that workspace.

## Provider-review separation

The YouTube API compliance/quota audit, Merchant API developer registration
and Google Ads API developer-token review are separate provider gates. Passing
or starting one does not approve the others.

- The active YouTube audit describes only the YouTube API Client and features
  actually present in its frozen reviewer build.
- Merchant account IDs, Merchant scopes, Ads developer tokens, Ads customer
  IDs and future Demand Gen claims stay out of that submission unless those
  integrations are genuinely part of the submitted client at that time.
- Each later Workspace integration gets its own provider registration,
  eligibility, OAuth, policy, quota, evidence and promotion record.
- No credential, account relationship, provider approval or quota allocation
  may be reused as evidence for a different provider gate.

## Merchant API boundary

When separately authorized, Merchant API may support:

- connecting an existing Merchant Center account;
- eligible platform or marketplace merchant onboarding;
- product and data-source management;
- price, availability, image and local/regional inventory sync;
- promotions, shipping, return-policy and programme settings;
- account and product diagnostics;
- conversion-source configuration; and
- per-merchant performance, price-competitiveness, best-seller and eligible
  YouTube Shopping affiliate reports.

Merchant API is not:

- a public Google Shopping search API for MoolSocial consumers;
- a checkout or payment processor;
- a normal order-import, fulfilment, cancellation or refund API;
- a guarantee of product approval or Google visibility;
- a general API to enrol every merchant in YouTube Shopping;
- a way to attach arbitrary MoolSocial products to any public video; or
- the authority for MoolSocial order attribution or creator payout.

`ordertrackingsignals` accepts already-delivered historical order signals. It
does not return or manage orders.

YouTube Shopping affiliate reports remain provider-labelled, eligibility-gated
and public alpha. Indian creators can be eligible under YouTube's current
creator rules, but the documented merchant self-service path currently carries
additional US-targeted Shopify, billing and currency conditions. MoolSocial
must not promise eligibility to Indian merchants or any other account before
Google confirms it.

Developer registration requires a production Merchant Center account with a
verified website, an authorized administrator, a dedicated Google Cloud
project registration and an API-developer contact. A third-party product
managing multiple merchant accounts uses merchant-authorized OAuth; it must not
silently substitute a MoolSocial service account for each merchant's consent.
Advanced-account or provider status is an eligibility gate, not an assumption.

Reports are requested against the authorized standalone merchant or individual
subaccount; advanced accounts are not themselves report targets. The YouTube
affiliate reporting endpoint remains `v1alpha`, programme-gated and read-only
until Google documents otherwise.

## Google Ads Demand Gen boundary

Demand Gen may later let an authorized advertiser create and manage campaigns
from a MoolSocial-native Workspace flow while the Google Ads API delivers the
campaign on eligible Google surfaces such as YouTube in-stream, in-feed,
Shorts, Discover, Gmail, Maps or Display.

The MVP commercial model is:

1. each advertiser connects its own separate Google Ads account;
2. Google bills that advertiser's payment profile directly;
3. MoolSocial may charge a separately disclosed, founder-approved management
   or workflow fee; and
4. every campaign begins paused and can spend only after explicit budget,
   destination, asset and policy review.

MoolSocial must not pool unrelated advertisers into one Ads account. It must
not prepay advertiser media in the initial release. It must not present Demand
Gen as a way to place Google ads inside MoolSocial.

MoolSocial also requires a Google Ads manager account developer token with an
access level and permissible use that covers the implemented operation.
Test-account access is not production approval. Each advertiser authorizes the
multi-user OAuth flow for its own customer account; server-side tenant
authority binds the OAuth principal, manager/login customer ID and target
customer ID. Password collection is prohibited.

Demand Gen channel controls express eligible requested surfaces; they do not
guarantee inventory, delivery, position or result. Campaigns are created
paused, and enablement requires advertiser confirmation of account, budget,
assets, destination, channel choice, policy state and the separately disclosed
MoolSocial fee.

Ads displayed inside the MoolSocial consumer product would require a separate
publisher-monetisation decision such as AdMob or Google Ad Manager. That is
outside this ADR.

## Attribution and payout boundary

Google and YouTube provider metrics remain external, source-labelled evidence.
They cannot overwrite:

- MoolSocial campaign identity;
- MoolSocial product-link attribution;
- order-line creator assignment;
- delivered/returned order state;
- creator commission state; or
- the MoolSocial payout ledger.

Provider affiliate commissions, when available, are a separate provider
programme and ledger.

## Cost, quota and safety gate

No related API is enabled merely because Google does not publish a metered
per-call price.

Before either integration begins, its Workspace journey must have:

- provider eligibility and account ownership proof;
- least-privilege OAuth and, for Ads, developer-token approval;
- tenant-isolated credentials and reports;
- current quota and API-policy inventory;
- a named owner for backend, support, policy and reconciliation cost;
- advertiser-funded media spend with a hard budget and automatic stop;
- failure, denial, revocation, duplicate and rollback behavior;
- local deterministic tests before any Dev call; and
- founder-reviewed HTML before native Flutter implementation.

Merchant and Ads absence must never block the Social MVP or YouTube playback,
private upload and analytics proof.

## Environment and promotion

The permanent order remains:

`local contracts -> moolsocial-dev-503018 -> Dev Preview -> clean Staging ->
later Production`

Merchant API, Google Ads API, credentials and spend remain disabled until a
separate founder authorization names the exact Workspace slice and cost owner.

## Delivery authority

Execution is tracked in:

`docs/delivery/GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`

## Official authorities

- Merchant API overview:
  <https://developers.google.com/merchant/api/overview>
- Merchant account structures:
  <https://developers.google.com/merchant/api/guides/accounts/overview>
- Merchant developer registration:
  <https://developers.google.com/merchant/api/guides/quickstart/registration>
- Merchant quotas:
  <https://developers.google.com/merchant/api/guides/quotas-limits>
- Merchant YouTube affiliate reports:
  <https://developers.google.com/merchant/api/guides/reports/analyze-youtube-affiliate-performance>
- Demand Gen campaign creation:
  <https://developers.google.com/google-ads/api/docs/demand-gen/create-campaign>
- Demand Gen channel controls:
  <https://developers.google.com/google-ads/api/docs/demand-gen/channel-controls>
- Google Ads OAuth:
  <https://developers.google.com/google-ads/api/docs/oauth/overview>
- Google Ads access levels:
  <https://developers.google.com/google-ads/api/docs/api-policy/access-levels>
- Google Ads multi-user OAuth:
  <https://developers.google.com/google-ads/api/docs/oauth/multi-user-authentication>
- Google third-party policy:
  <https://support.google.com/adspolicy/answer/6086450>
