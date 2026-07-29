# MoolSocial commerce and advertising around YouTube content

## Decision

The founder's concept is viable only with a strict separation:

- the video or Short remains YouTube-hosted and plays in the unobstructed
  official player;
- MoolSocial commerce, retailer promotion, household baskets and product
  actions remain native MoolSocial content outside the player; and
- the MoolSocial commercial content must provide enough independent value to
  justify its placement even if all YouTube API data were removed.

This is not a general right to sell an advertisement against any YouTube
video. The implementation uses one of the two patterns below.

## Pattern A — campaign-linked product context

Use when a real MoolSocial campaign explicitly binds:

`creator + YouTube video + eligible product/variant + commission rule`.

Below the selected-video metadata, display:

- heading: `Products featured in this video`;
- seller/fulfilment partner;
- final delivered price;
- pack/variant;
- serviceability and delivery promise;
- `View product` or `Add` action;
- disclosure: `Creator collaboration — the creator may earn commission from
  eligible purchases`; and
- MoolSocial identity distinct from YouTube source identity.

Do not attach this module to an unrelated public result.

## Pattern B — independent MoolSocial placement

Use when the commerce module is independently useful to the customer without
the selected YouTube item, for example:

- a local household basket;
- a serviceable retailer offer;
- a time-bound MoolSocial sale;
- a medicine reminder governed by the Medicine journey; or
- a local service relevant to the user's deliberate MoolSocial context.

Label it `Promoted on MoolSocial`. Keep it visually separated from the video
record. Do not use language such as `YouTube offer`, `recommended by YouTube`
or `sponsored by YouTube`.

## Forbidden presentation

- any overlay, frame, gesture interceptor, badge, commerce button or
  advertisement over the official player;
- blocking playback until a user views, shares, purchases, subscribes,
  comments or signs in;
- inserting a MoolSocial pre-roll, mid-roll or post-roll inside the player;
- obstructing YouTube advertising, controls, branding or links;
- paying or rewarding a user for YouTube watching or engagement;
- charging for ordinary access to public YouTube playback;
- implying a creator earns MoolSocial commission from YouTube views, likes,
  comments, shares or subscriptions;
- fabricating a product relationship for an unrelated public video; or
- using YouTube API data as the sole reason an unrelated advertisement can be
  sold on the screen.

## Revenue and attribution statement

YouTube engagement remains provider-owned. MoolSocial earns only from its own
independent services and commerce. Creator commission is calculated only from
eligible delivered MoolSocial order lines under the versioned campaign rule,
return hold and fraud controls. It is never based on YouTube engagement.

## Reviewer explanation

> MoolSocial does not sell placements on or within YouTube audiovisual
> content or the YouTube player. The official player remains unmodified and
> unobstructed. Any MoolSocial product or promotion is native application
> content outside the player and is displayed only where the MoolSocial
> commerce record supplies independent customer value. Campaign-linked
> product cards require a real creator/video/product relationship and include
> a commercial-relationship disclosure.
