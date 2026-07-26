# ADR-0003: Creator commerce attribution and payout

- Status: **Founder accepted for product and UI/UX implementation**
- Decision date: 21 July 2026
- Applies to: Universal Social, Create, connected creator/brand/product journeys,
  order attribution and creator payout
- Does not approve: live YouTube OAuth/API enablement, cloud resources, Flutter
  implementation, Screen 04 `FINAL`, Staging or Production promotion

ADR-0004 supplements this decision for MoolSocial-owned Reels/Posts,
multi-network creator distribution and combined channel analytics. The
YouTube-hosting rules below continue to apply to connected YouTube video; they
do not prohibit a separately budgeted, rights-cleared MoolSocial Reel.

Founder amendment recorded 21 July 2026: the cost-first platform sequence,
official embedded YouTube playback exception, destination-first publishing and
optional Standard Publish path are governed by
`docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`.
That contract supersedes only the earlier handoff-only and blanket-WebView
wording below. Attribution, commission, fraud and payout rules in this ADR are
unchanged.

## Context

MoolSocial must give creators a commercially meaningful reason to publish or
connect original video content without making MoolSocial responsible for the
long-term delivery cost of millions of video streams. Manufacturers, brands
and retailers need traceable sales rather than vanity engagement, creators
need understandable additional income, and buyers need transparent product and
commercial-relationship information.

YouTube remains the canonical host for connected long-form video and may also
host connected Shorts. MoolSocial supplies the independent commerce value:
product discovery, retail and wholesale packs, local serviceability, campaign
terms, attribution, orders, returns, creator commissions and payouts.

## Founder-accepted product proposition

User-facing feature name: **Create & Earn**.

Primary promise:

> One video. More ways to earn.

Supporting promise:

> Keep your YouTube income and earn additional commission when your content
> generates eligible delivered MoolSocial sales.

The production UI may shorten this copy to fit a verified viewport, but it
must preserve the distinction between possible YouTube income and a separate
MoolSocial commission. It must never promise payment for views, likes, shares,
comments or subscriptions.

## Universal and Social information architecture

The founder-approved Screen 04 bottom capability rail remains:

- main actions: `Social`, `Buy`, `Eat`, `Ride`, `Book`, `Pay`, `Work`;
- Social choices: `Shorts`, `Videos`, `Feed`, `Create`;
- stable edges: `Mool` and `Chat`.

Founder correction recorded 21 July 2026: the public Social first layer is a
consumer viewing and discovery surface. It must not expose creator campaign,
product-promotion, channel-management or earnings actions to every personal
account. Those capabilities belong to a Creator account under the signed-in
user's account/Work boundary. A personal user may be invited to start a Creator
account when they choose Create or open their account, but the invitation must
not turn the public feed into a creator dashboard.

Superseding founder correction recorded 21 July 2026: the public Social
discovery selector provides `For You`, `Following`, `Nearby` and clearly
disclosed `Promoted` MoolSocial content. It must not present `YouTube`,
`Facebook`, `Instagram` or `X` as consumer-feed buttons. Signing in with one of
those providers does not grant MoolSocial the right or technical ability to
reproduce that customer's complete external feed.

External-network names may appear only inside an eligible Creator/Business
connection flow or as the source identity of a specific item that MoolSocial is
permitted to ingest, embed or link. Provider branding, consent, account type,
playback, publishing and review rules remain intact. Open-protocol connections
such as AT Protocol or ActivityPub remain later adapter work and must not be
announced in the customer UI before a live, moderated connector exists.

Inside a Creator account, the user may access `Create & Earn`, brand
collaborations, eligible products and services, connected distribution
channels, attribution, earnings and payouts. Business-funded promotion belongs
to a Business account. It may promote on MoolSocial and extend through only
eligible YouTube channels, Facebook Pages, Instagram professional accounts or
other connectors that the account owner has connected and approved and that
the provider has permitted.

Inside the gated Creator account, the primary creator-commerce entry uses:

- heading: `Create. Recommend. Earn.`;
- body: `Choose products you trust, publish through YouTube and earn commission
  on eligible delivered orders.`;
- primary action: `Find Products to Promote`;
- secondary action: `Connect YouTube`;
- proof points: `Commission shown upfront`, `Sales tracked`, `Secure payouts`.

Each visible action must have a concrete state or connected destination. Until
its downstream screen is accepted, Screen 04 may show a production-quality
in-page contract state and must not route into unapproved legacy UI while
claiming production readiness.

## Content-hosting decision

1. MoolSocial does not retain a permanent duplicate of a connected YouTube
   video merely to serve playback.
2. An explicit YouTube handoff or connection of an already published video is
   a valid fallback. Direct API upload is permitted only after the provider
   proof, audit, authorization and release gates in ADR-0004 and the full-stack
   Social contract pass.
3. Native Flutter must not render MoolSocial UI through HTML/WebView. The sole
   MVP exception is the direct official YouTube embed in an isolated OS
   WebView/WKWebView defined by the full-stack Social contract.
4. YouTube playback, branding and controls remain clearly YouTube-owned and
   are not covered, overlaid or modified by MoolSocial commerce controls.
5. MoolSocial product cards, attribution actions and earnings information are
   native MoolSocial content outside the YouTube player.
6. MoolSocial never downloads, caches or stores YouTube audiovisual content
   without the required rights and approvals.

## Attribution identity

Before a creator publishes or connects content, the server creates an opaque
`promotion_id` that binds:

`creator → connected video → campaign → eligible product/variant → versioned commission rule`.

The customer receives a short first-party MoolSocial URL such as
`https://mool.social/c/<opaque-token>`. The public token must not expose raw
creator, customer, campaign or order identifiers.

The creator workflow supplies:

- the unique MoolSocial campaign link;
- a short creator/product recovery code;
- a native `Products in this video` treatment when the content is discovered
  through MoolSocial;
- an optional QR representation when appropriate for the content format.

The token is resolved and validated on the server. Client-provided creator,
rate or campaign fields are never trusted as attribution authority.

## Founder-accepted attribution rule

1. A deliberate `View Product` or `Buy Now` action from a creator-video product
   card creates the strongest eligible attribution.
2. Otherwise, the last eligible creator-product interaction within a seven-day
   conversion window receives credit.
3. Attribution is stored per order line, not only per order. One basket may
   therefore credit different creators for different items.
4. A valid customer-entered creator code may recover attribution when the
   tracked link was unavailable.
5. A single order line can produce at most one creator commission.
6. Direct or organic items with no eligible creator interaction produce no
   creator commission.
7. The qualifying campaign and commission terms are versioned. The order-line
   attribution snapshot records the applicable version and cannot be silently
   rewritten after checkout.
8. Same-device anonymous attribution may be attached to the customer account
   after sign-in. Cross-device attribution is reliable only when the same
   signed-in account or a valid recovery code connects the journey.

View-through attribution without a deliberate product action is outside the
first production version because it is less transparent and creates avoidable
creator disputes.

## Commission lifecycle

The immutable commission lifecycle is:

`attributed → ordered → delivered → return-window hold → payable → paid`.

Alternative terminal or recovery states include:

- `cancelled` for cancelled or unpaid orders;
- `reversed` for full returns, chargebacks or confirmed fraud;
- `adjusted` for partial returns or eligible quantity changes;
- `held-for-review` for fraud, fulfilment or attribution disputes.

Commission is never withdrawable merely because an order was created or paid.
The default commission base is eligible net merchandise value after ineligible
discounts, cancellations and returns, excluding shipping, taxes and unrelated
charges unless a founder-approved seller contract explicitly defines another
lawful basis.

Every commission entry retains the order line, promotion, creator, video,
campaign, rule version, calculation basis, state transitions and payout
reference. Settlement handlers must be idempotent so retries cannot pay the
same commission twice.

## Funding and unit economics

The manufacturer, brand or retailer normally funds or reserves the creator
commission budget when launching the campaign. MoolSocial administers the
attribution, hold, reconciliation and payout. A separately authorized
MoolSocial-funded campaign may use a MoolSocial promotional budget.

Every campaign must define before creator acceptance:

- eligible products and variants;
- retail/wholesale applicability;
- fixed collaboration fee, if any;
- commission amount or percentage;
- maximum commission/order/campaign budget;
- attribution window;
- delivery and return conditions;
- campaign dates and territories;
- inventory/serviceability requirements;
- payout schedule;
- content usage rights and approval requirements.

The creator must see the commission in decision-ready language, for example
`Earn ₹80 per eligible delivered order`, with the attribution window and
return rule adjacent to it.

## Customer and partner UI contracts

### Creator

Each connected video or campaign shows:

- product visits;
- orders placed;
- delivered orders;
- returned orders;
- pending earnings;
- available payout;
- total paid;
- next payout date where known.

Views may be displayed only as provider-owned or clearly identified metrics;
they do not determine the MoolSocial creator commission.

Any future Google or YouTube affiliate commission is a separate provider
programme and ledger. It cannot overwrite MoolSocial campaign attribution,
delivered-order commission, return holds or payout state. The Workspace
boundary is recorded in
`ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md`.

### Buyer

The product/video surface identifies `Products featured in this video` and
shows product, price, retail/wholesale pack, serviceability, delivery and seller
before purchase. It includes the disclosure:

> Creator collaboration — the creator may earn commission from eligible
> purchases.

### Manufacturer, brand or retailer

The campaign entry is `Grow Sales with Creators`, with actions to launch a
campaign, find creators, send products where applicable and track attributed
sales. Reporting distinguishes orders, delivered sales, returns, creator
commission, campaign spend and MoolSocial fees.

## Fraud, privacy and trust boundary

At minimum, risk controls cover:

- creator self-purchases and linked household/payment/address patterns;
- bot or scripted clicks;
- duplicate event delivery;
- cancel-and-reorder manipulation;
- leaked recovery codes;
- false fulfilment or delivery events;
- chargebacks and repeated high-return activity;
- expired campaigns, products or commission budgets.

Attribution collection must be disclosed, purpose-limited and retained only as
required for orders, payouts, disputes, accounting and legal duties. Creator
and buyer authentication credentials are never placed in tracking URLs.

Paid or barter commercial relationships require clear customer disclosure.
Creators are responsible for truthful original content and required YouTube and
Indian advertising/endorsement disclosures. MoolSocial must not incentivize or
pay for YouTube views, likes, shares, comments or subscriptions.

## Deep-link decision

Use the owned MoolSocial HTTPS domain with verified Android App Links and Apple
Universal Links, plus a useful web fallback when the app is not installed.
Do not use Firebase Dynamic Links; that service shut down on 25 August 2025.

## Delivery and test boundary

This decision authorizes product memory and HTML UI/UX design only. It does not
authorize credentials, APIs or cloud mutations.

Before native or backend acceptance, tests must prove:

- direct video-to-product attribution;
- delayed conversion inside and outside the seven-day window;
- multiple creators across different order lines;
- deterministic same-product creator precedence;
- anonymous-to-signed-in binding;
- recovery-code attribution;
- cancelled, partial-return, full-return, chargeback and fraud holds;
- duplicate webhook/event idempotency;
- campaign expiry, budget exhaustion and inventory loss;
- same-device, app-not-installed and authenticated cross-device paths;
- transparent creator, buyer and seller ledger views;
- no payment for YouTube engagement metrics.

Screen 04 remains a founder-review HTML candidate until the founder explicitly
marks the complete HTML state `FINAL`. Flutter V2, cloud/API setup and trial
promotion remain behind their existing separate gates.
