# YouTube `liveChatMessages.streamList` bridge contract

Status: **blocked before implementation; disabled everywhere**

Date: 2026-07-25  
Target environment: `moolsocial-dev-503018` only  
Production UI impact: none  
Cloud deployment performed: none

## Decision

Do not add `liveChatMessages.streamList` to the current
`youtubeProvider` JSON request/response function and do not connect Flutter
directly to YouTube gRPC.

The official YouTube streaming guide publishes a protocol definition that
currently cannot be resolved as written, and it does not publish a versioned
Node.js generated stub. The current MoolSocial provider and Flutter transports
also buffer one complete JSON response and cannot safely represent a
cancellable, long-lived stream.

Until the artifact and transport gates below are satisfied:

- the registered `liveChatMessages.streamList` capability remains unavailable;
- no API key or OAuth access token is placed in Flutter;
- no handwritten or inferred protobuf contract is accepted;
- the REST `liveChatMessages.list` path remains the only bounded fallback; and
- no Screen 01-04, HTML, route, or production UI file is changed.

## Evidence

Official source:

- <https://developers.google.com/youtube/v3/live/streaming-live-chat>
- page last updated by Google on 2026-06-25 UTC;
- service: `youtube.api.v3.V3DataLiveChatMessageService`;
- RPC: `StreamList`;
- target: `dns:///youtube.googleapis.com:443`;
- continuation cursor: `next_page_token`;
- Google recommends gRPC channel pooling for high concurrent-stream load.

The exact `stream_list.proto` text extracted from the official page on
2026-07-25 has:

- 442 lines;
- SHA-256
  `1E0588932437ECD6B4C99B3DA9A2FA1C9351DB3665BE22CB28DFE31A62672E98`;
- one `google.protobuf.Duration` reference; and
- no protobuf import declaration.

Resolving that exact text with the repository-installed
`protobufjs@7.6.5` fails with:

```text
no such Type or Enum 'google.protobuf.Duration' in Type
.youtube.api.v3.LiveChatGiftDetails
```

Adding `import "google/protobuf/duration.proto";`, deleting the field, or
handwriting a replacement type would change Google's published artifact.
That must not happen silently.

The current runtime is also incompatible with streaming:

- `backend/functions/src/index.ts` exposes `youtubeProvider` as a POST-only
  `onRequest` function with a 120-second timeout, `maxInstances: 1`, and
  `concurrency: 1`;
- it completes every operation with one JSON envelope;
- `apps/mobile/lib/core/youtube/youtube_private_dev_transport.dart` buffers
  the entire response, limits it to 2 MiB, and applies a 30-second operation
  timeout; and
- `apps/mobile/lib/core/youtube/youtube_private_dev_client.dart` decodes one
  completed JSON envelope.

Using the existing provider would block all other provider work while one
chat is open. Direct Flutter gRPC would expose provider authentication
material and is prohibited.

## Artifact gate

Implementation may begin only after one of these is recorded:

1. Google publishes a corrected, directly downloadable proto and a stable
   checksum; or
2. the founder explicitly approves a pinned local compatibility patch after
   engineering and compliance review.

If option 2 is approved, preserve:

- the original official text unchanged;
- its source URL, retrieval date, and SHA-256;
- a separate one-line compatibility patch that adds only the missing standard
  duration import;
- the exact code-generator and runtime package versions;
- generated-code provenance and license notices; and
- a CI schema test that fails on any field-number, service-name, RPC-path, or
  streaming-direction difference.

The required RPC path is:

```text
/youtube.api.v3.V3DataLiveChatMessageService/StreamList
```

No generated file may be manually edited.

## Required architecture

### Service boundary

Create a separate Dev-only service named `youtubeLiveChatStream`. It must not
be added as another case in the buffered `youtubeProvider` router.

The service has two distinct transports:

1. server-to-YouTube: native TLS gRPC using the pinned official schema;
2. Flutter-to-MoolSocial: native HTTPS streaming, using framed NDJSON or SSE.

The Flutter app never uses a WebView for this function and never receives a
YouTube API key, refresh token, or access token.

### Fail-closed activation

Every condition below must be true:

- runtime project is exactly `moolsocial-dev-503018`;
- `MOOLSOCIAL_PROVIDER_ENV=dev`;
- `YOUTUBE_PROOF_PROFILE=live`;
- `YOUTUBE_LIVE_ENABLED=true`;
- `YOUTUBE_LIVE_CHAT_STREAM_ENABLED=true`;
- the proof expiry is valid and no more than 30 minutes away; and
- all other mutually exclusive proof profiles are false.

Missing, malformed, expired, local-default, staging, or production
configuration returns `capability_disabled`. The new flag defaults to false
and is never a Flutter compile-time override.

### Request security

Every connection must:

- use HTTPS;
- verify a Firebase ID token;
- verify a limited-use Firebase App Check token with `consume: true`;
- reject `alreadyConsumed` App Check tokens;
- accept only POST;
- cap the raw request body at 4 KiB;
- reject unknown JSON keys;
- validate `liveChatId` and any continuation token before upstream use; and
- generate a server request ID rather than trusting an invalid client value.

There is no emulator authentication bypass for this endpoint. Tests use
injected verifiers.

The server fixes the YouTube request parts to:

```text
snippet,authorDetails
```

The client cannot supply arbitrary `part`, metadata, target, RPC name,
provider header, or upstream credential values. Locale is selected from a
server-maintained allowlist of founder-approved app locales.

### Upstream authentication

Use the server-held `YOUTUBE_SERVER_API_KEY` for publicly readable live chats.
An owner OAuth token may be used only for a separately registered owner-only
operation with its exact approved scope. Never mix the two credential modes
implicitly.

Only these upstream metadata names are allowed:

```text
x-goog-api-key
authorization
```

Exactly one is present for a request.

### Bounded private-Dev limits

Initial proof limits:

| Limit | Value |
|---|---:|
| Service instances | 1 |
| Concurrent downstream clients | 32 |
| Concurrent upstream chats | 4 |
| Subscribers per upstream chat | 8 |
| gRPC channels | 2 |
| Upstream streams per channel | 2 |
| Downstream session duration | 105 seconds |
| Subscriber queue | 64 frames and 256 KiB |
| Maximum frame | 64 KiB |
| Heartbeat interval | 15 seconds |
| Reconnect attempts per session | 4 |
| Reconnect delay | jittered 1, 2, 4, then 8 seconds |

Limits are server constants during the proof. They may be reduced through a
validated server configuration, never increased by a client request.

When a subscriber queue reaches either cap, close that slow subscriber with a
retryable terminal frame. Do not drop arbitrary chat messages and do not let
one slow subscriber block the shared upstream stream.

### Fanout and lifecycle

Share one upstream stream for subscribers with the same canonical key:

```text
liveChatId + locale + fixed parts
```

Each upstream entry owns:

- one gRPC call;
- its latest `next_page_token`;
- a bounded set of subscribers;
- a bounded reconnect counter;
- a channel-pool lease; and
- an abort controller/lifecycle signal.

Required behavior:

- cancel the upstream call immediately when its final subscriber disconnects;
- remove downstream listeners on request abort, response close, and timeout;
- release the channel lease in one `finally` path;
- resume with the last delivered `next_page_token`;
- send the latest cursor with each batch;
- end normally on `offline_at` or a chat-ended event;
- treat authentication and invalid-argument failures as terminal;
- retry only documented transient gRPC statuses;
- honor backpressure from `response.write`;
- never buffer an unbounded history; and
- never cache chat message bodies after the session ends.

Message IDs cannot be used as a simple permanent deduplication key:
YouTube documents that gift events may reuse an ID when the combo count
changes. Deduplication must therefore use an event-version/content digest or
allow a later update for the same gift-event ID.

### Downstream frame contract

All frames contain `version: 1` and a server request ID. Allowed frame types:

- `ready`: session limits and current cursor;
- `batch`: sanitized messages, active poll, `offlineAt`, and next cursor;
- `heartbeat`: liveness only;
- `retrying`: attempt number and bounded delay;
- `terminal`: normal completion or retryable session limit;
- `error`: stable public error code with no provider secret or raw stack.

Unknown frame types, oversized frames, invalid UTF-8, invalid JSON, and
provider-shaped values outside the allowlist fail closed in Flutter.

Provider text is rendered only as plain native text. Provider image URLs use
the existing YouTube image-host allowlist. No HTML is interpreted.

### Logs and retention

Logs may contain:

- request ID;
- stable public result/error code;
- duration;
- frame and byte counts;
- reconnect count; and
- a one-way digest of the canonical fanout key.

Logs must not contain:

- Firebase or App Check tokens;
- API keys;
- OAuth tokens;
- continuation tokens;
- raw live-chat IDs;
- message text;
- channel display names; or
- image URLs.

## Flutter contract

Add a separate streaming transport rather than extending `_invoke` to pretend
that a stream is one JSON response.

It must:

- pin the exact private-Dev streaming host and path;
- obtain a fresh Firebase ID token and limited-use App Check token for every
  connection and reconnect;
- expose a Dart `Stream` whose cancellation closes the HTTP request;
- parse arbitrary network chunk boundaries;
- enforce frame and total-session limits before decoding models;
- expose the latest continuation cursor only to the internal reconnect loop;
- reconnect only within the server-provided session/retry bounds; and
- remain unavailable unless the server capability response and the local Dev
  proof gate both allow it.

No UI or HTML change is part of this bridge task.

## Required focused tests

### Schema and target

- official source hash is recorded;
- schema resolves with the explicitly approved compatibility patch;
- exact service, method, request/response type, field numbers, and
  server-streaming direction are asserted;
- target is exactly `dns:///youtube.googleapis.com:443`.

### Server

- every flag defaults false and every invalid flag combination fails closed;
- non-Dev projects fail closed;
- expired proof fails closed;
- missing/invalid Firebase Auth fails;
- missing/replayed App Check fails;
- unknown fields, parts, metadata, locale, IDs, and oversized bodies fail;
- two subscribers share one upstream call;
- the ninth subscriber and fifth upstream chat are rejected;
- slow-subscriber queues never exceed both caps;
- last-subscriber cancellation cancels upstream and releases its channel;
- transient reconnect uses the last cursor and bounded jittered backoff;
- terminal gRPC statuses do not reconnect;
- gift-event ID updates are not incorrectly discarded;
- logs contain no credential, cursor, ID, message, or URL;
- malformed provider content fails closed.

### Flutter

- endpoint pinning rejects lookalike hosts, ports, query strings, and paths;
- split and combined chunks produce identical frames;
- malformed UTF-8/JSON, unknown type, and oversized frame fail closed;
- stream cancellation closes the socket;
- reconnect obtains new Auth and limited-use App Check tokens;
- retry and total-session budgets are enforced;
- default-disabled mode performs no network request.

### Integration

- local fake gRPC server proves fanout, backpressure, cancellation, and cursor
  resume;
- Firebase emulator proof uses real Auth and consumed App Check semantics or
  remains blocked with explicit evidence;
- Flutter connects only to the MoolSocial stream service;
- repository secret scan finds no provider credential in Flutter or fixtures;
- existing REST live-chat tests remain green.

## Promotion gates

The bridge remains disabled until all are true:

1. artifact gate is closed;
2. focused tests above pass;
3. cost/quota telemetry and kill switch are proven;
4. a founder-authorized local physical-device proof passes;
5. compliance review confirms allowed display, retention, and attribution;
6. the capability registry and exact implementation evidence are updated;
7. no existing accepted screen or route changes; and
8. no cloud deployment occurs without a separate explicit authorization.

Staging and production remain out of scope.

