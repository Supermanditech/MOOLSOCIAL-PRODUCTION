# Google commerce and Demand Gen Workspace backlog — 23 July 2026

Status: **deferred future Workspace backlog; no API, credential, spend or UI
authorization**

Authority:

- `ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md`
- `ENVIRONMENT-PROMOTION-BOUNDARY.md`
- `ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md`
- `ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md`

Permanent order:

`local contracts -> moolsocial-dev-503018 -> Dev Preview -> clean Staging ->
later Production`

These tickets do not belong to Screen 04 or the active private YouTube provider
proof.

| Order | Ticket | Outcome | Current status |
| --- | --- | --- | --- |
| 1 | `WS-GOOGLE-GOV-001` | Lock all Merchant Center, YouTube Shopping affiliate and Google Ads controls to a selected verified Creator/Business Workspace | Decision recorded; implementation deferred |
| 2 | `WS-GOOGLE-GOV-002` | Keep the YouTube API audit, Merchant developer registration and Ads developer-token review as separate provider dossiers; record exact client/project/account boundaries | Pending before any provider application |
| 3 | `WS-GMC-001` | Establish a production Merchant Center account, verified website, authorized admin, API-developer contact and dedicated GCP developer registration required for Dev API work | Pending separate founder authorization |
| 4 | `WS-GMC-002` | Prove advanced-account or marketplace/provider eligibility and any Google-support configuration; never infer eligibility from registration | Pending provider eligibility |
| 5 | `WS-GMC-003` | Prove merchant-authorized OAuth for existing multi-merchant access and, only when eligible, new-merchant account creation/configuration | Pending |
| 6 | `WS-GMC-004` | Prove tenant-isolated product, inventory, promotion, shipping and return-policy sync | Pending |
| 7 | `WS-GMC-005` | Prove conversion sources and reports against each authorized standalone merchant or individual subaccount | Pending |
| 8 | `WS-GMC-ORDER-006` | Accept delivered order-tracking signals only and enforce the explicit no-order-import boundary | Pending |
| 9 | `WS-YTAFF-001` | Prove merchant and creator programme eligibility plus read-only `v1alpha` affiliate reports | Pending; alpha/eligibility gated |
| 10 | `WS-ADS-001` | Prove advertiser-owned account connection, manager developer token, sufficient access/permissible use, multi-user OAuth and tenant binding of login/target customer IDs | Pending |
| 11 | `WS-ADS-002` | Create a paused Demand Gen draft with explicit budget, channel controls, assets, policy state and advertiser confirmation | Pending |
| 12 | `WS-ADS-003` | Prove advertiser-billed media spend, separate disclosed MoolSocial service fee, advertiser reporting/customer-ID access, rejection, refund and automatic-stop behavior | Pending |
| 13 | `WS-COST-001` | Model request quota, infrastructure, support, affiliate commission, media spend, service fees and kill switches | Pending |
| 14 | `WS-QA-001` | Run deterministic local mocks, then an explicitly authorized Dev proof with tenant, revoke, quota and rollback tests | Pending |
| 15 | `WS-UI-001` | Design provider-observed Workspace HTML and obtain explicit founder `FINAL` | Blocked by provider proof |
| 16 | `WS-FLUTTER-001` | Implement isolated native Flutter Workspace parity and physical-device acceptance | Blocked by HTML freeze |

## Non-negotiable acceptance rules

- Public Social and Personal Create never expose professional provider setup.
- YouTube audit material never claims deferred Merchant or Ads capability,
  accounts, identifiers, access or approval.
- Merchant reports are queried only for the authorized merchant/subaccount.
- Merchant developer registration uses the approved primary Merchant Center
  identity and dedicated GCP project; registration is not advanced-account,
  marketplace, programme or production eligibility.
- Merchant API never appears as consumer Google-product search, checkout or
  order management.
- YouTube affiliate reports never promise programme entry, product tagging or
  MoolSocial payout authority.
- Every advertiser has a separate Google Ads account and pays Google directly.
- Each Ads connection binds the consenting OAuth principal, manager/login
  customer ID and target customer ID to one authorized Workspace tenant.
- Test Account or Explorer access is not represented as Basic/Standard access,
  and no operation exceeds the developer token's approved permissible use.
- Demand Gen does not place Google ads inside MoolSocial.
- Channel controls express requested eligible surfaces; no placement, delivery
  or result is guaranteed.
- No campaign can spend before explicit review, a hard budget and an automatic
  stop.
- Any MoolSocial management/workflow fee is disclosed separately from Google
  media spend, and the advertiser can obtain its Google Ads customer ID,
  spend and performance records.
- No API or credential is created until the exact Dev ticket receives separate
  action-time founder authorization.
- Social MVP delivery continues independently.
