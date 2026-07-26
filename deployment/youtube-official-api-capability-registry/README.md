# YouTube official API capability registry

Status: read-only contract and drift gate. It is not a service-enablement,
deployment, OAuth-publication, quota, compliance, UI, or live-provider proof.

This directory classifies every method exposed by the pinned official Google
Discovery documents for:

- YouTube Data API / YouTube Live Streaming API v3;
- YouTube Analytics API v2;
- YouTube Reporting API v1.

The product and phase interpretation cross-references
`docs/delivery/YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md`.
That audit remains unchanged. The registry makes its capability boundary
machine-enforceable and explicitly includes lesser-known surfaces such as
`tests.insert`, `thirdPartyLinks.*`, `videoTrainability.get`, and the official
server-streaming `liveChatMessages.streamList` method whose Discovery ID is
`youtube.youtube.v3.liveChat.messages.stream`.

## Pinned official inventory

| Source | Discovery revision | Classified methods |
|---|---:|---:|
| YouTube Data / Live v3 | `20260723` | 83 |
| YouTube Analytics v2 | `20260721` | 8 |
| YouTube Reporting v1 | `20260721` | 8 |
| Total | — | 99 |

Availability classification:

| Class | Count |
|---|---:|
| `implemented-local` | 14 |
| `disabled-gated` | 75 |
| `eligibility/partner-only` | 8 |
| `unsupported-customer-value` | 1 |
| `deprecated/excluded` | 1 |

Product phase classification:

| Phase | Count |
|---|---:|
| `A-private-dev-proof` | 14 |
| `B-public-read-plane` | 5 |
| `C-connected-viewer-actions` | 23 |
| `D-creator-channel-management` | 15 |
| `E-creator-live-workspace` | 18 |
| `F-creator-intelligence-reporting` | 15 |
| `G-provider-granted-only` | 7 |
| `permanent-exclusion` | 2 |

`implemented-local` means only that a local adapter/client or test path exists.
It does not mean the method is enabled, live-proven, production-approved, or
customer-visible. Likewise, an official method does not mean Google grants it
to every channel or application.

## Read-only verification

Run from the repository root:

```powershell
node scripts/verify-youtube-official-api-capability-registry.mjs
```

The verifier uses Node built-ins and the public Discovery documents only. It:

- sends no API key, OAuth token, cookie, or other credential;
- performs only allowlisted HTTPS `GET` requests;
- never calls `gcloud`, Firebase, a YouTube customer-data endpoint, or a
  service-enablement endpoint;
- fails on a Discovery revision change;
- fails on an added, removed, duplicate, or unclassified method;
- fails when a method lacks a phase, availability class, scope class, or
  precise reason.

Verified result on 25 July 2026:

```text
youtube-data-live-v3: revision 20260723; 83/83 methods classified.
youtube-analytics-v2: revision 20260721; 8/8 methods classified.
youtube-reporting-v1: revision 20260721; 8/8 methods classified.
PASS: 99/99 official methods are classified; all pinned revisions match; no credentials or mutations were used.
```

Any future drift must be reviewed and deliberately classified before the gate
can pass. The registry must never be loosened to infer that unsupported YouTube
home recommendations, arbitrary native YouTube UI, ad inventory, monetization,
or partner-only features are available to MoolSocial.
