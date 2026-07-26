# ADR-0005: MoolSocial plans, launch access and Social promotion

- Status: Accepted by founder
- Date: 22 July 2026
- Applies to: MoolSocial account workspaces, feature subscriptions, launch
  access, Social promotion and advertising campaigns

## Decision

Every person keeps one MoolSocial identity. A normal customer may add Creator,
Business, Commerce or other eligible workspaces without creating another login
or losing followers, reputation, purchases, earnings or verification history.

The approved platform plans are:

| Plan | Primary owner | Product boundary |
| --- | --- | --- |
| Free | Every person | Core Social, commerce, booking, basic creation, work discovery and basic selling |
| Creator Pro | Creators | Connected-channel distribution, scheduling, advanced analytics, campaigns and creator earnings tools |
| Business Pro | Retailers, services, advertisers and employers | Catalogue, leads, promotions, team access, customer analytics and campaigns |
| Commerce Pro | Manufacturers and wholesalers | Bulk catalogue, wholesale packs, price tiers, buyer/dealer discovery, demand insights and payment terms |
| Enterprise | Larger organisations | Multi-location teams, controls, integrations and consolidated reporting |

Worker access to legitimate earning opportunities is never paywalled merely to
find or perform work. Creating a workspace may require eligibility or
verification, but a paid plan is not a substitute for verification.

## Launch access

MoolSocial may grant time-bound access to paid features during launch or a
later promotion. Every grant must have an exact start and end time, covered
features, applicable workspace and post-expiry plan. Customer UI must show the
end date before activation and while access is active.

Launch access never silently becomes a paid subscription. Paid renewal starts
only after explicit plan, price, billing interval and payment consent. Before
expiry the product should notify at useful intervals. At expiry, paid features
become read-only or return to the Free limit without deleting customer content,
analytics or financial records.

## Subscription and campaign charging are separate

A subscription purchases product capabilities and limits. Campaign funding
purchases a defined promotion with its own objective, placement, audience,
start/end time, daily or total budget and measurement. A plan price must never
be presented as ad spend, and campaign spend must never be hidden inside a
subscription.

Creator Memberships are a third, separate product in which followers pay an
eligible creator for stated benefits. They do not grant MoolSocial Pro product
features and must not share subscription naming or billing records.

## Who may promote

Eligible users may create a campaign appropriate to their active workspace:

- a person may promote an eligible MoolSocial Post or Reel;
- a creator may grow an audience or promote attributable content;
- a retailer or service provider may promote a product, service, lead or
  booking outcome;
- a manufacturer or wholesaler may promote products, packs, buyer demand or
  dealer opportunities; and
- an employer may promote a legitimate job, task or campaign opportunity.

All campaigns require a real destination, clear sponsor identity, applicable
disclosure, moderation eligibility and measurable objective. No UI promises
guaranteed views, sales, leads or earnings.

## Social placement boundary

MoolSocial may place disclosed promotions in its owned Shorts sequence, Feed,
Video discovery surrounding content, Social search and other owned discovery
surfaces. MoolSocial advertising must never be inserted into, cover or be
represented as part of the provider-owned YouTube player. Public YouTube items
do not receive fabricated commerce or sponsor relationships.

## Shared UI ownership

- Profile owns workspace activation and `Plans & access`.
- Social owns content selection, owned placements and campaign performance.
- Pay owns payment confirmation and receipts.
- Creator/Business workspaces own advanced distribution and analytics.
- The same account header and identity persist through every surface.

## Production data contract

The presentation must be backed by typed owners for plan catalogues,
entitlements, launch grants, workspace eligibility, campaign drafts, budgets,
placements, moderation, funding, delivery, attribution and invoices. Dates,
prices, limits and results cannot be hard-coded as production truth in widgets.
Local deterministic adapters may supply review data until separately
authorized real-service work begins.

## Consequences

- Three shared subscription screens are required: Plans, Plan details and
  Manage subscription.
- One dynamic Social promotion screen owns campaign goal, content,
  audience/placement, time/budget, review, funding handoff and results states.
- Existing Creator, retailer and manufacturer campaign owners must be reused;
  no parallel campaign ledger or payment implementation is permitted.
- Platform billing and store requirements must be verified against current
  official Android and Apple rules before real paid activation.
