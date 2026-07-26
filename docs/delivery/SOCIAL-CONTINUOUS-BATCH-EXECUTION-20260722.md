# Social continuous-batch execution tickets — 22 July 2026

## Founder authorization

The founder authorized one uninterrupted batch covering remaining Social HTML,
native Flutter V2 implementation, automated verification, connected-OPPO
replay, correction and final regression. Intermediate founder review stops are
waived for this batch. Candidate HTML must still be completed and verified
before its Flutter owner begins. Only explicitly approved states are indexed as
founder-approved references; other verified HTML is preserved as a candidate
implementation baseline until the final founder decision.

Current approved checkpoints remain immutable:

- Social Shorts/Videos `v1`;
- Social Feed/Create `v1`; and
- Social Feed/Create deeper `v2`.

## Production screen inventory

| Ticket | HTML owner | Outcome | Status |
| --- | --- | --- | --- |
| `SOC-BATCH-001` | Screen 05 Shorts | Continuous MoolSocial/eligible YouTube Short viewing, item actions, creator profile, comments, search, reporting, recovery and eligible commerce | HTML verified; native candidate tested |
| `SOC-BATCH-002` | Screen 06 Videos | MoolSocial discovery, selected official YouTube player, public channel profile, details, discussion, connection and unavailable/restricted recovery | HTML verified; native discovery candidate tested; live player pending |
| `SOC-BATCH-003` | Screen 07 Feed | Approved Feed carried into complete post, carousel, profile, comment, quote/repost, report and attributable-commerce journey | HTML verified; native candidate tested |
| `SOC-BATCH-004` | Screen 08 Create | Approved Post/Reel/Carousel/Drafts carried into media permission, validation, processing, retry and durable-result journeys | HTML verified; native candidate tested |
| `SOC-BATCH-005` | Screen 124 Creator Studio | Personal-to-Creator workspace conversion, eligibility and focused Studio home | HTML verified; native candidate tested |
| `SOC-BATCH-006` | Screen 125 Create & Publish | Destination-first content preparation, standard publish and per-destination requirements | HTML verified; native candidate tested |
| `SOC-BATCH-007` | Screen 126 Content Library | Draft, scheduled, published, failed and reusable content | HTML verified; native candidate tested |
| `SOC-BATCH-008` | Screen 127 Performance | Content, distribution, attributed orders and campaign outcome analytics | HTML verified; native candidate tested |
| `SOC-BATCH-009` | Screen 128 Audience | MoolSocial audience/community insights without unsupported cross-provider identity claims | HTML verified; native candidate tested |
| `SOC-BATCH-010` | Screen 129 Campaigns | Find, accept, deliver and review funded creator campaigns | HTML verified; native candidate tested |
| `SOC-BATCH-011` | Screen 130 Earnings | Delivered-order attribution, eligibility, returns/cancellations, payable balance and payout history | HTML verified; native candidate tested |
| `SOC-BATCH-012` | Screen 131 Rights & Safety | Verification, rights, disclosures, moderation, appeals and team access | HTML verified; native candidate tested |
| `SOC-BATCH-013` | Screen 132 Creator Memberships | Follower-paid creator membership plans, benefits and member controls; separate from MoolSocial Pro | HTML verified; native candidate tested |
| `SOC-BATCH-014` | Screen 167 Plans & Access | Free, Creator Pro, Business Pro, Commerce Pro and Enterprise comparison plus active launch access | HTML verified; native candidate tested |
| `SOC-BATCH-015` | Screen 168 Plan Details | Exact features, limits, price/billing interval, launch end date and explicit activation | HTML verified; native candidate tested |
| `SOC-BATCH-016` | Screen 169 Manage Subscription | Current plan, entitlement usage, renewal, invoices, upgrade/downgrade and cancellation | HTML verified; native candidate tested |
| `SOC-BATCH-017` | Screen 170 Social Promotion | Role-aware objective, content, audience, placement, duration, budget, review, Pay handoff, delivery and results | HTML verified; native candidate tested |

## Shared state and account rules

- One signed-in MoolSocial identity persists across every Social screen.
- MoolSocial-native content uses the MoolSocial public profile.
- YouTube content retains its genuine channel identity and source attribution.
- Optional YouTube viewer actions and Creator publishing connections are
  separate grants; MoolSocial login never implies either permission.
- Workspace conversion adds capabilities to the same account.
- Subscription entitlement, launch access and campaign funding are separate
  typed states.

## HTML gates before Flutter

Every reachable state must pass:

1. exact route, heading and primary-content verification;
2. every tap and nested tap;
3. seven required phone viewports at 100% and 140% text;
4. 44x44 minimum interactive target checks;
5. customer-copy checks over rendered and semantic text;
6. offline, loading, empty, denied, unavailable, failure and retry states where
   applicable;
7. source/provider disclosure and commerce-boundary checks; and
8. accepted Screen 01–04 reference-lock regression.

## Flutter tickets

| Ticket | Outcome |
| --- | --- |
| `SOC-NATIVE-001` | Isolated UI V2 Social shell and shared persistent account header |
| `SOC-NATIVE-002` | Native Shorts and item-owned engagement owners; direct official provider-player exception only |
| `SOC-NATIVE-003` | Native Videos discovery/watch/channel/details/discussion/recovery |
| `SOC-NATIVE-004` | Native Feed and personal Create with media/permission/process states |
| `SOC-NATIVE-005` | Native Creator Studio 124–132 using existing creator models, session and services |
| `SOC-NATIVE-006` | Native Plans/Access and workspace entitlement owners |
| `SOC-NATIVE-007` | Native Social Promotion using existing campaign, attribution and Pay owners |
| `SOC-NATIVE-008` | Routing, retained state, back behavior, interruption and authenticated relaunch |

All eight native tickets have an implemented and OPPO-tested candidate. This
does not mark the unapproved owners founder-accepted. Exact APK, device replay,
test and known legacy-gate evidence is recorded in
`artifacts/quality/social-continuous-batch-20260722/SOCIAL-V2-IMPLEMENTATION-AND-OPPO-EVIDENCE.md`.

## Completion gates

The batch is complete only after responsive Flutter comparisons, widget and
journey tests, exact APK checksum capture, connected-OPPO clean and retained
state replays, interruption/offline/permission matrices, affected-journey
reruns and two full regressions. No partial merge to `main` is authorized.

Implementation and physical-device verification are complete. Founder review
is pending. The exact installed review candidate is r15, SHA-256
`D60945E0E70F4D2B63B7471808E776F59AA3D929357B8A0E789B47FF6EC62475`.
Both final full regressions are `417/417` green. Historical
Creator/Universal goldens remain unchanged and run through an explicit
test-only legacy route; production defaults remain isolated native V2. The
focused V2 behavior, 69-state parity, fitment and customer-copy suite is
`42/42`; all `56/56` required first-layer viewport/text-scale combinations
pass; Screens 01–03 are `38/38`; and the approved lock gate passes. The r15
OPPO correction proves that a missing-rights publish failure returns to
editable content and then publishes exactly once. The durable parity record is
`artifacts/quality/social-continuous-batch-20260722/NATIVE-SOCIAL-69-STATE-PARITY-20260722.md`.

This remains a founder-review implementation candidate. Live provider APIs,
official YouTube playback/publishing, paid billing and server-authoritative
entitlements are not claimed by the presentation evidence.
