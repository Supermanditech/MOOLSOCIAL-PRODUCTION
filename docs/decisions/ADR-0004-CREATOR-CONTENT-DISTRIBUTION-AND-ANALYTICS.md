# ADR-0004: Creator content distribution and analytics

- Status: **Founder accepted for product and HTML UI/UX design**
- Decision date: 21 July 2026
- Applies to: Creator Studio, Business Promotions, paid MoolSocial content,
  connected publishing destinations, channel analytics and commerce attribution
- Does not approve: credentials, OAuth clients, API enablement, provider review,
  Flutter implementation, Screen 04 `FINAL`, Dev/Trial use or promotion

The authoritative cost-first platform sequence, embedded YouTube viewing
boundary, destination-first workflow, Standard Publish workflow and full-stack
service/test contract are in
`docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`.
This ADR remains authoritative for owned-content, account, analytics and
provider-proof principles where it does not conflict with that later founder
decision.

## Outcome

MoolSocial will give eligible creators one place to choose a funded campaign,
create content, select connected publishing destinations, review each
destination, publish and compare channel performance. Manufacturers, brands,
retailers and service providers gain attributable reach and sales. Creators
retain any provider-owned income and may earn additional MoolSocial commission
from eligible delivered MoolSocial orders.

The customer journey is:

`campaign → creator content → selected connected channels → tracked MoolSocial
product action → order-line attribution → delivery/return clearance → creator
commission`.

MoolSocial does not pay for external views, likes, comments, shares or
subscriptions. External analytics explain reach and engagement. The
MoolSocial order and commission ledger remains the payout authority.

## Owned content model

- Paid MoolSocial Reels are a core owned Social product and appear in the
  clearly disclosed `Promoted` discovery mode.
- `Reel` and `Short` are one vertical short-video format, not two separate
  creator formats.
- Posts support text, one image or a swipeable image carousel.
- MoolSocial does not host an owned long-form video format at MVP. Long-form
  viewing and creator publishing use eligible YouTube-hosted video under the
  provider/player and connected-channel boundaries in the full-stack contract.
- The founder-approved Screen 04 rail is not redesigned in this cycle. Its
  existing `Shorts` label owns the Reel/Short format and its existing `Feed`
  label owns posts and carousels.
- Sponsor identity and potential creator commission are disclosed on every
  promoted content item.

## Account boundary

- Personal Social remains a media-first watching and discovery surface.
- Personal Create offers Reel, Post/Carousel and Drafts. Long-form YouTube
  publishing belongs to the separately connected Creator account, not the
  public personal Create surface.
- Merchant Center, YouTube Shopping affiliate reporting and Google Ads
  connections belong inside a selected verified Creator/Business Workspace;
  they never alter Personal Social or Personal Create.
- Campaign selection, product promotion, connected channels, publishing
  destinations, channel analytics, commission and payouts belong to the
  Creator account under Profile/account.
- Campaign funding, creator selection, local-business distribution and
  customer follow-up belong to the Business account.
- Social login is never treated as publishing permission. Every destination
  is connected separately and remains optional for every campaign.

## Connector capability boundary

Only provider capabilities with a documented direct API and passed proof may
be exposed. Release priority is cost-first:

| Destination | Release lane | Use | Required customer boundary |
| --- | --- | --- | --- |
| MoolSocial | Owned core | Paid/organic Reels, posts and carousels | Native owned destination |
| YouTube | MVP priority 1 | Eligible public embedded playback, authorized channel video uploads and analytics | Channel OAuth; per-video review |
| Instagram | MVP priority 2 | Professional-account Reels/posts and insights | Business/Creator account only |
| Facebook | MVP priority 3 | Page posts, videos and Reels | Managed Page only; not personal timeline |
| WhatsApp Business | Separate messaging slice | Opt-in enquiry, order and support follow-up | Messaging/Flows; never a public social feed |
| Threads | Feature-flagged expansion | Text, image, video and link posts | Separate authorized Threads account |
| Pinterest | Feature-flagged expansion | Business Pins and destination analytics | Board, Pin and MoolSocial URL review |
| LinkedIn | Feature-flagged expansion | Member or eligible organization posts | Applicable member/organization permission |
| Google Business Profile | Feature-flagged expansion | Local offers and Shop/Order/Book actions | Business account only |

TikTok is outside the India MVP. X remains outside the launch connector set
until its pay-per-use unit economics are founder-approved. Snapchat direct
Public Profile publishing and Indian networks without a verified public API
remain later partnership work. Partnership-only destinations must not appear
as live customer actions before written access, implementation and verification.

## Publishing contract

1. The default flow asks the creator to choose a destination first and shows
   its account eligibility and media requirements before upload.
2. The creator chooses only a supported Reel, provider-hosted Video or
   Post/Carousel format. `Video` is never represented as MoolSocial-owned
   long-form hosting.
3. An optional `Standard Publish` flow lets the creator explicitly select or
   deselect every compatible connected destination before one upload.
4. Each destination receives its own caption, media, disclosure and eligibility
   validation.
5. The creator reviews destination-specific content before publishing.
6. One final confirmation is allowed only after every selected destination
   passes preflight; it never means blindly sending one identical payload.
7. Publishing is asynchronous and records a separate external post identity
   and permalink per destination.
8. The UI supports `ready`, `uploading`, `processing`, `published`, `needs
   action`, `failed`, `retrying` and `cancelled` per destination.
9. Partial success is normal. A failed destination never removes successful
   posts from other destinations.
10. Users may disconnect a destination without deleting content already
   published there.

## Analytics contract

Creator and Business views may combine:

- provider-owned reach, views and engagement;
- product-link visits;
- attributed orders;
- delivered sales;
- cancellations and returns;
- pending, payable and paid creator commission;
- campaign budget and business spend.

Every number names its source and refresh time. Provider engagement is never
used as the commission authority. ADR-0003 continues to own order-line
attribution, return-window holds, fraud controls and payout state.

Google affiliate analytics remain provider-labelled external metrics. Neither
those reports nor Google Ads reporting can overwrite the MoolSocial order and
commission ledger.

## Founder-accepted implementation proof gate

Before a connector can be claimed live, its authorized Dev/Trial work must
prove the applicable row below. This proof does not authorize native UI before
the HTML/founder gates:

1. eligible public YouTube discovery and official inline playback on the OPPO;
2. one private YouTube upload and processing result;
3. one Instagram Professional Reel and insight read;
4. one Facebook Page post/Reel with a tracked link;
5. every later feature-flagged connector, including Threads, Pinterest or
   Google Business Profile, before its flag can be enabled.

For every connector, the proof also records account eligibility, scopes,
provider review status, quotas/cost, token revocation, partial failure,
analytics freshness and deletion/disconnection behaviour. Provider work follows
the environment order in `ENVIRONMENT-PROMOTION-BOUNDARY.md` and requires
separate action-time authorization.

## Current HTML authorization

This decision authorizes only the founder-review Screen 04 HTML states for:

- MoolSocial Reel and promoted-reel presentation;
- Post/Carousel presentation;
- Creator Studio entry under Profile;
- format and destination selection;
- per-channel publishing results;
- creator performance, earnings and Business Promotions boundaries.

It does not change the accepted bottom rail, freeze Screen 04, update the
approved-reference manifest or authorize Flutter work.
