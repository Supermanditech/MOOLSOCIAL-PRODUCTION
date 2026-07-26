# YouTube WebSub approved-channel refresh contract — 24 July 2026

## Decision

Approved-channel WebSub refresh belongs in the MVP provider proof because it
is the lowest-quota way to keep a curated YouTube catalogue current.

It remains behind
`YOUTUBE_APPROVED_CHANNEL_REFRESH_ENABLED=false` until the Dev proof passes.
It does not authorize Screen 04 HTML or Flutter changes.

## Local disabled core

The following pure backend modules define the reviewed contract without
exporting a Firebase Function or adding a cloud target:

- `backend/functions/src/youtube/websub_contract.ts`:
  fixed topic/hub construction, callback intent verification, subscription
  lifecycle, deterministic renewal timing, idempotent event keys and the
  isolated atomic refresh-quota reservation plan;
- `backend/functions/src/youtube/websub_security.ts`:
  per-subscription secret derivation, bounded raw-body handling and exact-byte
  WebSub HMAC verification; and
- `backend/functions/src/youtube/websub_atom.ts`:
  a bounded fail-closed Atom subset parser with namespace validation,
  DTD/entity/XXE rejection, approved-channel matching and defensive RFC 6721
  tombstone hints.

These modules are deliberately not imported or exported by `index.ts`. They
cannot receive network traffic, read a secret, reserve provider quota or
mutate Firestore. Their tests are local contract evidence only. Live work
still requires the ADR, manifest, IAM, budget, registry and callback gates in
this document.

## Provider truth

- YouTube push notifications cover channel uploads and video title/description
  updates.
- They do not promise deletion, privacy, statistics, comments, likes,
  subscriptions or viewer-notification events.
- Topic:
  `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`.
- Hub: `https://pubsubhubbub.appspot.com/`.
- Incoming signed Atom metadata may identify that same hub with or without its
  trailing slash. The parser accepts only those two exact hub identities.
- Incoming signed Atom `self` metadata may use provider-emitted HTTP or HTTPS,
  but only for `www.youtube.com`, the documented
  `/feeds/videos.xml` or `/xml/feeds/videos.xml` path and the one exact
  approved `channel_id`. It is identity metadata only and is never fetched or
  followed.
- WebSub delivery itself consumes no YouTube Data API unit. Hydration and
  reconciliation do.
- Parse valid Atom tombstones defensively, but always revalidate because
  YouTube does not promise deletion events.

## Required targets

| Target | Exposure | Responsibility |
|---|---|---|
| `youtubePushCallback` | public HTTPS, GET/POST only | Verification and signed Atom delivery |
| `youtubePushEventHydrator` | private Firestore trigger | Coalesced `videos.list` hydration and tombstones |
| `youtubeWebSubMaintenance` | scheduled/internal | Subscribe, renew, unsubscribe and retries |
| `youtubeThirtyDayRevalidation` | scheduled/internal | Due channel/video revalidation |
| `syncApprovedYouTubeChannels` | CI/founder-admin IAM only | Materialize approved registry and initial seed |
| existing `youtubeProvider` | Auth/App Check client surface | Read eligible approved-channel snapshots |

These targets materially expand ADR-0008 and the deployment manifest. Amend
those authorities before deployment.

## Firestore records

`youtubeApprovedChannels/{sha256(channelId)}`:

- canonical channel/owner metadata;
- founder approval state and audit fields;
- uploads playlist, curation tags and rank;
- provider verification and next revalidation no later than 30 days;
- current subscription identifier.

Only CI/founder-admin IAM may mutate the registry. Ordinary users cannot
request arbitrary hub subscriptions.

`youtubeChannelSubscriptions/{sha256(callbackCapability)}`:

- exact topic and fixed hub;
- hashed opaque callback capability;
- secret generation;
- subscribe/renew/unsubscribe state;
- request generation, authoritative lease, expiry and renewal time;
- retry/denial evidence.

Derive a unique secret per subscription from a Secret Manager root key and
channel/generation. Retain current and previous root versions during rotation.

`youtubeChannelEvents/{eventKey}`:

- sanitized channel/video identity;
- upsert-candidate or delete-hint kind;
- provider timestamps and payload digest;
- received/hydrating/applied/tombstoned/retry/dead-letter state;
- bounded processing lease and attempts.

Do not retain raw XML.

`youtubePublicVideoSnapshots/{videoId}`:

- validated provider summary and channel;
- available/unavailable/tombstoned state;
- provider/fetch/revalidation timestamps;
- snapshot version and source.

## Subscription lifecycle

Send fixed hub form data for the canonical approved channel topic, callback,
lease and derived secret. A `202` response is not activation.

Verification GET must:

- resolve an opaque capability and pending request generation;
- require exact mode/topic and bounded challenge;
- require positive bounded lease for subscribe;
- update activation/unsubscribe state in one transaction; and
- return 2xx with body exactly equal to the challenge.

Renew while the current lease remains valid, before expiry with deterministic
jitter. The pure helper targets no later than 80% of the authoritative lease,
leads expiry by 24–72 hours where the lease permits it and subtracts at most
six hours of deterministic jitter. Short leases clamp renewal between 10% and
80% of their duration. Failed renewal never deletes an active lease. Verified
unsubscribe revokes the capability and later delivery returns 410.

## Delivery security

For POST:

1. preserve `request.rawBody`;
2. bound body size, XML depth, element count and text size;
3. resolve one active opaque capability;
4. require and constant-time validate the supplied hub HMAC over exact bytes;
5. parse with DTD, entities, external resolution and networking disabled;
6. require every YouTube channel ID to match the subscription;
7. transactionally insert idempotent events; and
8. return 204 quickly; hydrate asynchronously.

Never fetch a payload URL. Hub/topic origins and paths are constants. Do not
trust source IP as authentication. Redact capabilities, HMACs and XML.

## Hydration and tombstones

Atom is only a hint. Display truth comes from the existing restricted
server-key `videos.list` contract.

- Coalesce changes for the same video for 30–60 seconds.
- Fetch and validate channel attribution and existing eligibility policy.
- Update the durable snapshot and version.
- Missing/private/deleted/unembeddable/restricted content becomes unavailable
  or tombstoned and disappears from live discovery.
- Duplicates and out-of-order events never write snapshots directly.
- A tombstone hint still requires provider reconciliation where possible.

## Seed, revalidation and quota

On approval:

1. `channels.list` verifies the channel and uploads playlist;
2. `playlistItems.list` obtains a bounded initial inventory; and
3. `videos.list` hydrates batches of up to 50.

A cursor-based scheduled job revalidates due channels/videos no later than 30
days, without scanning all collections.

Add an atomic `refresh` quota sub-budget under the project `general` bucket,
proposed Dev ceiling 500 units/day. If exhausted, retain retryable events,
make no provider call and serve the last valid snapshot with stale semantics.
The local plan requires both ledgers to be reserved in one transaction before
the outbound request; the current quota store does not yet implement that
multi-ledger transaction.

## App Check and IAM

- The hub callback cannot require Firebase Auth/App Check because Google is
  the caller.
- The callback runtime gets only subscription/event Firestore access and the
  WebSub root-secret version—no OAuth/upload/provider-key access.
- Hydrator/revalidation gets the restricted server key and required Firestore
  access.
- Schedules use their own invoker identity.
- Founder registry sync is CI/admin IAM only.
- Client reads remain feature-gated and App Check protected.

## Required proof

Unit/emulator:

- topic/form construction, verification, renewal, denial, unsubscribe;
- exact challenge echo and mismatch handling;
- raw-byte HMAC success/failure;
- Atom/tombstone parsing and XXE/oversize rejection;
- idempotent duplicates, concurrency and out-of-order delivery;
- wrong-channel and unavailable provider results;
- quota exhaustion with zero provider calls;
- batch/cursor revalidation;
- IAM negatives and redacted logs.

Live Dev, one founder-controlled channel:

- verified lease;
- upload and title/description update events;
- duplicate delivery;
- hydration and tombstone recovery;
- renewal before expiry; and
- flag-disable rollback plus verified unsubscribe.

## Current blockers

- founder-approved Dev channel IDs and registry owner;
- amendment to ADR-0008 and the deployment target manifest;
- public callback and narrow invoker approval;
- Firestore ordered queries/indexes and atomic project+refresh quota ledger;
- live proof of the hub lease/signature behavior.

The exact `INR 1,000` monthly Dev alert is already live; it is not a WebSub
blocker and is not a hard spending cap.

## Official authorities

- <https://developers.google.com/youtube/v3/guides/push_notifications>
- <https://www.w3.org/TR/websub/>
- <https://www.rfc-editor.org/info/rfc6721/>
- <https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.https.request>
- <https://firebase.google.com/docs/functions/schedule-functions>
- <https://cloud.google.com/scheduler/pricing>

## Disabled local foundation checkpoint — 24 July 2026

The contract, security and bounded Atom-parser libraries and their tests now
exist under `backend/functions/src/youtube/websub_*`. The approved-channel
refresh feature remains disabled by default.

Independent backend verification passed `153/153`, including `37` WebSub
tests. The private-Dev package gate and Screens 01–03 locks passed. A repository
scan found no WebSub export, Firebase target or deployment-manifest activation.
Durable evidence and exact source hashes are at
`artifacts/quality/youtube-websub-local-20260724-01/LOCAL-WEBSUB-FOUNDATION-EVIDENCE.md`.

No public callback, secret, subscription, scheduled job, provider hydration or
cloud resource exists from this checkpoint. All blockers listed above remain.

## Local provider-compatibility hardening checkpoint — 25 July 2026

The disabled local foundation now additionally:

- parses the exact notification shape currently published in Google's YouTube
  push-notification guide, including its slashless hub link and nine-digit
  fractional timestamps;
- accepts only the documented/live YouTube `self` identity variants described
  above and still performs no XML-originated network request;
- validates calendar days, leap years, clock fields and numeric offsets before
  canonicalizing equivalent provider instants to one UTC representation for
  stable event keys;
- preserves provider precision up to nine fractional digits while removing
  insignificant trailing zeroes;
- raises the hard element ceiling from `256` to `1,024`, which is sufficient
  for the retained realistic 50-entry fixture while keeping the 50-event,
  256-KiB body, depth, text and attribute ceilings intact; and
- accepts a denial only for the matching pending subscribe or renewal intent.
  C0/DEL control characters are never retained in denial evidence.

Focused WebSub verification passed `43/43`. Complete backend verification
passed `159/159`. A direct read-only parse of the current public Google
Developers channel feed passed with `15` events from `20,896` bytes.

After the concurrently edited Android adapter stopped changing the locked
Screen 02 dependency graph, the private-Dev package gate was rerun and passed:
preflight, approved Screens 01–03 locks, the `159/159` backend suite, the
82-file private-Dev content scan and local package verification. The gate wrote
no deployment package because it ran with `-SkipFlutter` and without
`-Materialize`.

This passing local gate is not deployment readiness, activation or promotion.
The feature remains disabled and repository scans still find no WebSub
Firebase export, target or deployment-manifest activation. Exact current
hashes and command outcomes are retained in
`artifacts/quality/youtube-websub-local-20260724-01/LOCAL-WEBSUB-FOUNDATION-EVIDENCE.md`.
