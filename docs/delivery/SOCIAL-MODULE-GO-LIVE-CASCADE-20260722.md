# Social module go-live cascade — 22 July 2026

Status: **active ordered backlog; no production promotion authorized**

This cascade supersedes any earlier wording that could be read as permission
to continue native Screen 04 work before the reopened HTML is founder-final.
Every gate is sequential. A later gate cannot bypass an earlier failure.

## Gate 0 — founder-final HTML

- Immutable Screen 04 v8 is preserved at HTML SHA-256
  `0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`.
  Its verified native candidate is not founder-accepted and has been reopened
  by the latest Screen 04 Social correction.
- The active v9 correction is controlled by
  `SCREEN-04-SOCIAL-FOUNDER-CORRECTION-TICKETS-20260723.md`.
- Correct the editable HTML so Reels owns contextual creation/search and Feed
  owns direct public publishing. Visible Create may be removed only after all
  responsibilities and compatibility entries have passing proof.
- Founder reviews the complete v9 Screen 04 Social surface and nested states.
- Founder states `FINAL` for one exact v9 HTML checksum.
- Freeze that HTML, shared CSS, assets, reference images, interaction contract
  and checksum as a new immutable approved-reference version. Never rewrite
  v8 or any earlier Screen 04 version.
- Keep Screens 01–03 locked. v8's rail remains immutable history; any v9 rail
  change requires explicit founder `FINAL`.

Current active v9 candidate checksum: **pending HTML correction and
verification**.

## Gate 1 — isolated native Flutter V2 parity

- Reconcile the existing unaccepted Screen 04 native candidate against only
  the newly frozen HTML. Do not patch the legacy UI or put HTML in a WebView.
- Preserve existing models, sessions, services, API adapters, authentication,
  Firebase/native configuration, identity and business logic.
- Implement Social type roles, Shorts control parity, direct Feed composer,
  legacy Create-entry compatibility and the new Reels/Feed ownership
  boundaries, exact rail behavior and nested history.
- Use the narrow WebView/WKWebView exception only for the provider-owned
  YouTube player. Surrounding discovery and commerce remains native.
- Run phone, text-scale, safe-area, orientation, keyboard, accessibility,
  tablet/foldable and interruption matrices.

## Gate 2 — native verification and founder acceptance

- Compare HTML and Flutter at identical viewport, content, state and text
  scale.
- Replay every visible tap, nested tap, Back, Forward, root return and retained
  state on the connected OPPO.
- Run affected journeys and two full regressions from the exact installed APK.
- Founder reviews the installed candidate and states `Accepted` or `Rejected`.
- Preserve an accepted native checkpoint only on the remediation branch. Do
  not partially merge it into `main`.

## Gate 3 — real YouTube integration in Dev/Trial

Start this gate **after Gate 2 native acceptance and before any Social Staging
promotion**. The player host and discovery contract are then stable, while
provider behavior can still be corrected safely in Dev.

- Enable YouTube Data API only in `moolsocial-dev-503018` under an approved,
  restricted credential plan. Keep secrets and refresh tokens server-side.
- Use API key-backed public discovery/metadata where permitted and separate
  OAuth consent for user-specific YouTube actions or creator publishing.
- Populate the native paginated library from real eligible source types and
  multiple distinct videos. Do not claim YouTube's personalized Home feed.
- Play the selected item in the official embedded player inside the approved
  native host, with YouTube identity, controls, ads and errors intact.
- Prove unavailable, removed, private, non-embeddable, age/region restriction,
  player errors, retry, orientation, fullscreen, audio focus, background/
  resume and rapid-selection cases on OPPO.
- Add quota caching, request coalescing, freshness labels, budget alerts and an
  automatic feature stop. Recheck current quota rules before traffic.
- Complete provider compliance/audit work needed for public upload or expanded
  quota. Do not create extra projects to evade quota.

## Gate 4 — operational Social owners

Before Social can be called fully operational, real owners must exist for:

- Reel/Post/Carousel ingest, processing, storage, delivery and lifecycle cost;
- profiles, follow graph, Feed ranking, comments, likes, saves, shares,
  reporting, blocking and notifications;
- content rights, sponsor/affiliate disclosure, moderation, appeals, abuse and
  rate limiting;
- creator/business eligibility, campaign linking, attributable order lines,
  return-window holds, commission ledger and payout state;
- subscription/launch-access entitlements without silent paid renewal;
- privacy, consent, export/deletion, audit logs, observability, incident
  response and customer support; and
- analytics separating YouTube engagement, MoolSocial engagement, commerce
  and creator earnings.

Creator distribution to YouTube, Instagram Professional and Facebook Pages is
feature-flagged until each adapter independently passes OAuth, eligibility,
publishing, partial-failure, analytics, revocation and compliance proof.

## Gate 5 — Staging candidate

- Promote only the exact Dev-proven build and configuration to
  `moolsocial-staging-503018`.
- Repeat provider policy/pricing, security/privacy, load/cost, accessibility,
  Android/iOS, device, interruption and recovery tests.
- Run affected journeys and two full regressions with immutable evidence.
- No production data, production credentials or production project is used.

## Gate 6 — Social go-live decision

Social is `GO` only when Gates 0–5 are green, the founder accepts the exact
Staging candidate, release gates are green and rollback/monitoring/on-call
owners are ready. Until then:

- HTML founder review: available;
- native implementation: blocked pending `FINAL`;
- YouTube real-service integration: queued for Dev after native acceptance;
- Staging: blocked; and
- Production go-live: **NO-GO**.

## Founder sequencing override — API-first YouTube proof, 23 July 2026

The founder has paused Gate 0 v9 correction and directed a bounded YouTube
provider proof before further Shorts/Videos UI work.

New immediate order:

1. preserve Screen 04 v9 as `DRAFT / HOLD`;
2. complete the capability/policy/quota inventory;
3. reauthenticate and run a non-UI provider spike only in
   `moolsocial-dev-503018`;
4. prove public discovery, official playback, private creator upload,
   analytics, revocation, quota and failure contracts;
5. use observed evidence to revise the Screen 04 HTML;
6. resume founder `FINAL`, immutable freeze, native parity and OPPO acceptance;
7. continue operational, Staging and go-live gates.

This sequencing override does not authorize MoolSocial presentation in a
WebView, Flutter changes before frozen HTML, partial promotion, Staging access
or Production. Governing details are in ADR-0006 and
`YOUTUBE-INTEGRATION-PREPARATORY-TICKETS-20260723.md`.
