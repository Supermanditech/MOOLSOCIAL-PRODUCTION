# Buy V2 R29 founder iteration approval and R30 direction

Recorded: 30 July 2026

## Founder decision

The founder reviewed the checksum-matched R29 Buy candidate on the connected
OPPO and approved it as the current Buy UI/UX **iteration baseline**, subject
to further changes.

This decision:

- accepts R29 as the structural starting point for the next Buy session;
- does not declare the current Buy experience immutable or release-final;
- does not authorize commit, push, deploy, publication, production signing or
  backend implementation; and
- preserves the founder-FINAL Buy HTML `v1` unchanged. Any future reference
  revision follows a new-version founder-review cycle.

## Proven open defect

The founder observed that adding from Shop makes Cart behave separately from
Wholesale and Medicine. The implementation currently stores one line
collection but allows entry points to open vertical-specific scopes. Ticket
`BUY-FV2-074` requires one aggregate Cart entry while retaining visibly
separated fulfilment, prescription and checkout requirements inside it.

No fix was implemented during this ticket-registration turn.

## Partner-language direction

The founder directed that customer-visible `Verified` language be removed
because repeated `Verified retailer/shop/wholesaler/manufacturer` wording
feels cheap and less trustworthy.

The initial Buy inventory found:

- 103 matching lines across six production files;
- 85 `Verified retailer` occurrences;
- one `Verified shop` occurrence;
- eight `Verified wholesaler` occurrences;
- 55 `Verified distributor` occurrences;
- 21 `Verified manufacturer` occurrences; and
- 11 `Licensed pharmacy` occurrences.

These counts overlap because catalogue rows contain more than one role.
`Licensed pharmacy` and other genuine regulatory facts are not synonyms for a
marketing badge and must not be removed blindly.

Ticket `BUY-FV2-075` requires a founder-approved glossary that distinguishes:

- the commercial party's actual role;
- its fulfilment role;
- its relationship with MoolSocial; and
- any true regulatory or safety status.

Candidate terms such as `Mool retail partner`, `Mool trade partner`, `Mool
pharmacy partner`, `Mool manufacturer partner`, `Mool service partner` and
`fulfilment partner` are proposals only. No application copy changes begin
until the founder selects the final taxonomy.

The application-wide direction also covers shop, salon, clinic/hospital,
service provider and other business surfaces, but implementation must proceed
module by module under each module's protection and acceptance boundary.
Protected Social remains unchanged until separately authorized.

## R30 UI/UX programme

The next Buy UI/UX session is recorded in Tickets `BUY-FV2-076` through
`BUY-FV2-085`:

- shared motion and honest state acknowledgement;
- responsive screen-type and vertical themes;
- an unmistakable animated MoolSocial identity with an accurate tricolour
  relationship;
- restrained 3D commerce interactions;
- stable product tiles with real, changing product information;
- first-party MoolSocial promotion modules;
- transparently disclosed sponsored/other advertisement placements;
- safe and performant inline video advertisements;
- accessibility, reduced-motion and performance gates; and
- one complete cross-surface founder review before the Buy backend begins.

## Production and data boundary

Motion may use existing state and existing product facts. Dynamic product
information, paid advertising and video advertising may not invent a
production API, database field, campaign, advertiser, measurement event,
consent rule or business policy.

Presentation owners must remain replaceable and independently configurable for
Shop, Wholesale, Medicine and future verticals. Empty, unavailable, reduced-
motion and stale states are part of the design contract, not afterthoughts.

## Current durable identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- R29 source fingerprint:
  `B7911CDD3D770F3E7260C18B7B2388E92C59819A266147CBF4D70E248E54CCCB`
- R29 candidate/installed APK SHA-256:
  `3136A7CFA4EB1C3A001422F18C8C49CF1CE775F673EA68EFF71BC1D4956918CD`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

State:
`FOUNDER_APPROVED_ITERATION_BASELINE_WITH_OPEN_R30_UIUX_BACKLOG`.
