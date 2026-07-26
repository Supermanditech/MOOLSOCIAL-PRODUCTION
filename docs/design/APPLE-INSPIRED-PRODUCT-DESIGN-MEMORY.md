# MoolSocial product design memory

Status: **mandatory for the complete application**

Last confirmed by the product owner: 20 July 2026

## Open launch-blocking conformance issue

On 20 July 2026, the product owner reported a material regression between the
approved HTML prototype and the current physical-phone build. The reported
scope is application-wide and includes:

- visual hierarchy, styling, spacing and component treatment;
- main action and sub-action wording;
- tap, sub-tap and nested-tap structure;
- the screens or visible results that complete each user intent.

This issue is tracked as `UI-CONFORMANCE-001` in
[`QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md`](../quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md).
It blocks founder design approval and any production-launch claim until the
screenwise comparisons and acceptance replays are complete.

The existing automated tests and 81 Flutter goldens prove consistency with the
current implementation. They do **not** prove conformance to the approved
prototype and must not be used as the sole design-approval oracle.

All remediation work must be isolated from `main` until accepted. The working
branch is `remediation/prototype-conformance-2026-07-20`. Screen-specific
observations supplied by the product owner are appended to the QA-024 issue
register before code is changed.

The accepted implementation strategy is the parallel native Flutter UI V2
rebuild in
[`ADR-0002-PARALLEL-UI-V2-CONFORMANCE-REBUILD.md`](../decisions/ADR-0002-PARALLEL-UI-V2-CONFORMANCE-REBUILD.md).
Approved HTML is finalized and frozen screenwise before V2 implementation;
existing tested non-UI application layers are reused.

## Permanent product rule

Every MoolSocial user-facing surface must use one coherent, Apple-inspired
interaction and visual system. This applies to Android, iOS, the marketing
website, creator and business upload tools, workspaces, admin tools, dialogs,
empty states, permission states and future journeys.

Apple-inspired means:

- calm hierarchy with one obvious primary intent;
- content-first layouts with generous, consistent spacing;
- high-quality typography and restrained use of colour;
- translucent or elevated navigation only where it improves orientation;
- direct manipulation, immediate feedback and reversible actions;
- predictable back, close, cancel, retry and completion behaviour;
- smooth, short motion that explains state changes;
- minimum 44 x 44 logical-pixel tap targets;
- native platform conventions for keyboards, permissions, sharing and account
  approval;
- accessible contrast, text scaling and screen-reader labels.

It does **not** mean copying Apple trademarks, proprietary artwork or an exact
Apple application. MoolSocial keeps its own identity:

- navy `#000080`;
- saffron `#FF9933`;
- green `#138808`;
- the approved MoolSocial wordmark and tricolour identity line;
- Mool as the universal action launcher;
- outcome-led socio-commerce language and flows.

## Interaction architecture

Every reachable control must satisfy this contract:

1. **First tap — choose intent.** The user selects a main action or a clearly
   named object.
2. **Second tap — make the decision.** The user chooses the relevant subtype,
   item, provider, slot or method.
3. **Third tap — complete or commit.** When needed, the user confirms, pays,
   posts, books, sends, applies or saves.

A flow may complete in fewer taps when the tap itself produces the intended
result. Extra taps must not be invented merely to satisfy the three-depth model.

Every tap must do at least one of the following:

- visibly change the current state;
- reveal the next decision;
- open a complete screen or platform-controlled surface;
- complete the intent and show a durable result.

Snackbars and toasts may confirm small reversible actions such as Save. They
must not replace a required screen for buying, booking, posting, paying,
applying, authentication or support.

## Navigation rules

- The Universal screen opens in Social.
- Mool opens the seven main actions: Social, Buy, Eat, Ride, Book, Pay and
  Work.
- Chat remains reachable in one tap and always provides a direct return to the
  previously focused main action.
- The bottom navigation uses one Apple-inspired floating material treatment
  across the app.
- Main actions and focused sub-actions must not compete in one cramped row.
- Main actions appear in the Mool launcher. The focused action's sub-actions
  appear in a separate, readable control immediately above the content.
- Back returns one navigation level. Close dismisses only the current overlay.
  Cancel preserves the prior safe state.
- The current main action and current sub-action are always visually apparent.
- Product verticals use `MoolOutcomeDock`: Mool and Chat remain stable edge
  actions while no more than three readable current-task actions occupy the
  separate middle rail.
- Standard product content uses `MoolCardSurface` so elevation, border,
  pressed feedback and reduced-motion behavior remain consistent.

## Production language rules

Visible copy must describe what the user can do or what has happened.

Preferred verbs include:

`Choose`, `Watch`, `Post`, `Buy`, `Add to basket`, `Order`, `Book`, `Pay`,
`Send`, `Apply`, `Accept`, `Upload proof`, `Save`, `Try again`, `Change`,
`Cancel`, `Finish`.

The following engineering or prototype terms are prohibited in user-facing
copy unless the user is explicitly in a developer/admin diagnostic tool:

`bootstrap`, `registry`, `route`, `endpoint`, `payload`, `mode`, `world`,
`handoff`, `state machine`, `mock`, `placeholder`, `internal`, `test action`,
`intent result`, `screen 01`, `screen 02`, `screen 03`, `screen 04`.

### Customer-copy boundary — absolute

Customer-visible HTML previews and native production screens must read as a
finished product, never as a design review, implementation plan, test fixture
or developer explanation.

Inside the simulated phone viewport and every native customer UI:

- state the useful result as a confident fact, such as
  `You're in Sardarpura, Jodhpur`;
- use direct customer actions such as `Allow location`, `Open phone settings`,
  `Continue`, `Try again` and `Not now`;
- name only concepts the customer needs to make the decision;
- keep technical, operational, review and traceability language outside the
  customer viewport.

Never expose wording such as:

`draft`, `final`, `production`, `prototype`, `review`, `sample`, `example`,
`working note`, `internal plan`, `owner`, `route`, `state`, `source`,
`workflow`, `implementation`, `API`, `provider`, `fallback`, `test`,
`next screen`, `next owner`, `production search`, `review area`,
`currentArea`, `areaSource`.

Do not ask a customer to perform an implementation task. For location, avoid
copy such as `Detect my current location`, `Resolve service area` or
`Permission state`. Explain the customer benefit before requesting access,
keep native operating-system permission copy platform-owned, and present the
useful result (`You're in Jodhpur`) once it is available.

### First-open location and account boundary — locked

The clean first-open sequence is:

`Screen 01 → location consent → resolved location name → social-handle and OTP
sign-in → Universal`.

- Screen 02 asks for app-level location consent before opening the native
  operating-system permission.
- When phone Location Services are off, Screen 02 says
  `Turn on Location Services` and offers `Open phone settings`.
- Screen 02 may offer a single `Continue for now` recovery when location
  remains unavailable; it must not open another setup branch.
- Screen 02 never asks where the user lives or works.
- Home/work questions, city changes, map search and permanent-area choices are
  prohibited before Universal.
- After login, permanent serviceable area selection belongs in the user
  account inside Universal. Use customer copy such as
  `Choose your permanent serviceable area` and explain that it improves nearby
  products, services, business and earning opportunities.

### Real-user interruption and relaunch rule — absolute

First-open acceptance must never rely only on a fresh install. The app must
enforce the strict real-user state machine in
[`FIRST-OPEN-REAL-USER-STATE-MATRIX.md`](../quality/FIRST-OPEN-REAL-USER-STATE-MATRIX.md).

- An older Screen 02 completion record cannot satisfy a newer required Screen
  02 version.
- Screen 01 must not complete its handoff while the app is inactive, paused,
  hidden, locked or covered by a call. Resume restarts its uninterrupted
  foreground interval.
- Until the user explicitly taps `Continue` or `Continue for now` on the
  currently required Screen 02, every new process starts with Screen 01 and
  then returns to Screen 02.
- The Screen 02 completion version is advanced only by those two explicit
  actions. Saving another preference, route, location result, authentication
  result or deep link must preserve the previously completed version.
- App switching, calls, process death, force-stop, operating-system permission
  dialogs, Location Settings and location callbacks never mark Screen 02
  complete.
- Returning from Android permission or Location Settings returns to Screen 02;
  it never jumps directly to sign-in.
- Physical-device evidence must cover retained upgrade data, interruptions,
  kills and relaunches as well as clean install.
- Physical-device evidence must prove the installed APK checksum matches the
  reviewed candidate. Hot reload, an unidentified launcher build or an
  already-running process is not a clean first-open test.
- A founder-observed mismatch reopens the defect and overrides an earlier
  internal pass until the mismatch is reproduced and resolved.
- Before founder review, the connected phone is left with the current Screen 02
  incomplete and visible. Internal testing must not leave it at sign-in.

### Founder escalation — no regressive partial handoffs

Owner escalation recorded 20 July 2026:

- Repeated isolated Screen 01/Screen 02 handoffs over approximately five hours
  created a regressive development experience, caused mental distress and
  reduced confidence that the work would reach production grade.
- A technically correct transition into a legacy or unapproved downstream
  screen is not an acceptable founder handoff and must never be described as a
  production-grade journey.
- Internal agents own diagnosis, iteration, regression testing and exact-build
  verification. The founder must not be used as the repeated discovery loop for
  defects that comprehensive connected-journey testing could have found.
- A scoped Codex request for a production journey must produce the complete
  connected production-grade slice and its evidence in one work cycle, except
  where the approved workflow explicitly requires pausing for founder HTML
  `FINAL` approval.
- Before presenting any screen for native acceptance, every immediately
  connected downstream screen reached by its primary actions must either be in
  the same acceptance checkpoint or be explicitly identified as not yet
  production-ready. Never let a founder action unexpectedly land on a legacy
  screen.
- When two screens form one unavoidable transition, they may be bundled into
  one founder checkpoint. Screen 02 and Screen 03 are one combined acceptance
  checkpoint for the first-open journey.
- Completion persistence is expected after an explicit action: once the user
  completes Screen 02, later opens resume at Screen 03. This is acceptable only
  when Screen 03 itself is the founder-approved V2 presentation.
- No screen in a combined checkpoint is frozen, labelled accepted or committed
  as an acceptance checkpoint until the complete connected checkpoint passes
  founder review.

### Founder escalation — exact review target must be verified

Regression incident recorded 20 July 2026:

- The founder explicitly requested Screen 03, but Codex supplied and left the
  browser on a URL whose pathname opened
  `02-first-setup-language-location.html`.
- This wasted additional founder time immediately after an earlier five-hour
  regression escalation. It is a direct targeting and verification failure.
- When the founder asks for one exact screen, open that exact screen directly.
  Do not substitute an earlier screen, a journey starting point or a connected
  flow unless the founder explicitly asks to begin there.
- Before reporting that a review screen is ready, verify all three facts from
  the loaded page: the browser pathname, the visible screen heading and the
  expected primary content. A generated or intended URL is not proof that the
  correct page is open.
- If browser automation cannot verify or navigate the active tab, state that it
  was not opened. Never imply that the requested screen is visible.
- A direct review URL must contain the requested screen file as its pathname.
  For Screen 03, that is `screens/03-login-account-handoff.html`; a Screen 02
  pathname is always a failed response to a direct Screen 03 request.
- After a founder reports a wrong screen, correct the active target first.
  Do not make the founder repeat upstream taps or navigate through a previous
  screen to reach the requested review surface.

### Founder escalation — customer-copy checks must cover every visible state

Regression incident recorded 20 July 2026:

- The Screen 03 OTP viewport displayed `Email OTP uses the same verify screen
  with email instead of mobile.` This was an implementation explanation
  presented to the customer.
- Screen 01's slow-start viewport separately exposed app-version, network and
  route-selection checks. Those checks belong to implementation and
  diagnostics, not the installed product.
- The existing automated customer-copy test passed because it inspected only
  the Screen 03 login-options state. It never mounted the email/mobile OTP
  state. A test of one default state is not a customer-copy release gate.

Permanent machine rule:

- Every customer-copy gate must enumerate and mount every reachable visible
  state for the touched checkpoint: default, loading, resolved, unavailable,
  denied, slow, failure, retry, provider return, email OTP, mobile OTP, wrong
  OTP, resend and change-method states where applicable.
- The test must collect rendered `Text`, editable-field labels/hints and
  semantic labels from inside the customer screen. Static source scanning alone
  is insufficient, and a golden image alone is insufficient.
- Relationship-to-implementation wording is prohibited even when it does not
  contain an older forbidden keyword. Reject phrases such as `same screen`,
  `same verify screen`, `instead of email`, `instead of mobile`, `this screen
  is used for`, `example`, `demo`, `sample`, `for review` and `for testing`.
- Slow, recovery and accessibility states are production screens. They receive
  the same customer-copy review as the default state.
- A newly discovered prohibited phrase is added to the centralized machine
  policy and its exact missed state becomes a permanent regression test before
  the phrase is removed.
- Screen 01–03 cannot be production-locked until their complete copy-state
  inventory and compact-to-large viewport matrix pass together.

The executable policy and required state inventory are defined in
[`CUSTOMER-COPY-MACHINE-GATE.md`](../quality/CUSTOMER-COPY-MACHINE-GATE.md).

Screenbook labels and engineering contracts may use technical language only
outside the simulated customer viewport. Before any screen is frozen, the
reviewer must read only the customer viewport from top to bottom and reject
every phrase that sounds like a note to the implementation team.

Operational conditions must be written as confident, decision-ready facts.
For example:

- Use `Delivered by 7:30 pm` instead of `Retailer will confirm stock`.
- Use `Available for home delivery` instead of `Fulfilment mode enabled`.
- Use `Your order is confirmed` instead of `Order state changed`.
- Use `Upload delivery photo` instead of `Submit proof payload`.

Unavailable actions are either hidden when they are not launched or shown with
an honest reason and a useful next action. Dead controls are never allowed.

### Founder escalation — a review route failure is not customer offline proof

Regression incident recorded 20 July 2026:

- Mobile OTP displayed `You appear to be offline` while the OPPO had working
  connectivity and email OTP completed.
- The laptop Auth service was healthy. The OPPO USB transport had reconnected,
  which cleared the volatile `adb reverse` mapping used by that APK's mobile
  OTP route. This was a review-environment routing failure, not proof that the
  customer was offline.
- Email OTP used an independent device-review owner, so an email pass could not
  prove mobile OTP connectivity.

Permanent machine rule:

- Mobile OTP and email OTP are independent acceptance paths. Request and verify
  both; never use one as evidence for the other.
- Physical-device review must include an ADB transport reset and a mobile OTP
  replay with reverse mappings absent.
- A review APK must have a preflighted device-reachable primary Auth route and
  may retain USB reverse only as a fallback. Founder review cannot depend only
  on volatile reverse state.
- A socket or provider-route failure must use a service-specific recovery
  message. Do not claim that the customer is offline unless customer
  connectivity is actually established as the cause.
- Live production authentication remains environment-configured and must never
  contain a developer laptop address or local-review identity path.

### Accepted Screen 01–03 checkpoint — immutable during the next UI set

Founder acceptance recorded 20 July 2026:

- Screen 01 reference `v3`, Screen 02 reference `v4` and Screen 03 reference
  `v2` are production accepted on
  `remediation/prototype-conformance-2026-07-20`.
- The exact OPPO candidate and installed APK both have SHA-256
  `76c40d1a3dead71358a72afb77db940f0e9f88751b4a48d958368451d2330ed0`.
- Mobile OTP passed without any ADB reverse mapping; email OTP passed in a
  separate clean-install replay; both opened Universal.
- The accepted presentation files, HTML, reference images, contracts, goldens
  and locked tests must not be edited while the next isolated UI set is built.
- Backend/provider configuration may advance without changing the locked
  customer presentation. Combining later accepted screens with this checkpoint
  requires a new integration replay, not a rewrite of Screens 01–03.

### Screen 04 HTML founder-review candidate — founder rejected, do not freeze

Founder-authorized HTML work recorded 20 July 2026:

- Screen 04 was remade only at
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`.
- The founder-rejected candidate SHA-256 is
  `9d4bbc76104cb5208f54fdfd83603d89ee563bf0a0cdbb724249f1c27fcd9b86`.
- This is a founder-review candidate, not a `FINAL` or approved reference.
  Never add this checksum to the approved manifest and never begin Flutter
  implementation without a later explicit founder `FINAL`.
- Universal visibly exposes Social, Buy, Eat, Ride, Book, Pay, Work and Chat.
  Chat stays pinned. The Mool sheet provides the seven non-Chat focuses.
- Incoming `world` restores the requested Universal focus. Incoming
  `openMool=1` opens the Mool sheet, preserving the return contract already
  used by Social and Chat.
- Permanent serviceable-area selection belongs in signed-in
  Universal/account. The accepted Screen 01–03 presentation remains immutable.
- Every visible customer control must be named, at least 44×44 and connected
  to a real in-page outcome or a concrete HTML destination.
- Screen 04 copy review covers the default view and all reachable loading,
  empty, denied, unavailable, failure, retry, permission-recovery and result
  moments. Default-view-only review is not sufficient.
- Every founder-requested revision must rerun exact pathname, visible heading,
  primary-content, complete control, connected-destination,
  compact/large/140%-text and Screen 01–03 lock checks before presentation.

Founder rejection recorded after automated verification on 20 July 2026:

- An automated tap or fitment pass does not override the founder's visual,
  architectural, copy or brand decision.
- Do not display `Screen 04`, `Founder review`, `Awaiting founder decision`,
  `Preview other moments`, test-state buttons, commentary or similar working
  language anywhere on the visible review page. Production-bound HTML must look
  and read like the finished customer product from edge to edge. Engineering
  controls and evidence belong in separate non-customer files.
- The approved Universal core architecture is not discretionary. Learn it from
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\approved-final\screens\04-universal-focus-shell.html`
  and the pre-remake Screen 04 history, then preserve its structure while
  correcting copy and production readiness.
- Universal opens in Social. It retains the approved command/search treatment,
  focused sub-action strip, one focused product/service world at a time,
  contextual content actions and the Apple-inspired bottom outcome rail.
- The bottom rail keeps Mool and Chat stable. Mool exposes Social, Buy, Eat,
  Ride, Book, Pay and Work; the focused action's sub-actions remain in their
  approved placement. Do not replace this architecture with an unrelated
  eight-tile dashboard or a founder-preview side panel.
- Preserve the approved placement and hierarchy of Social, Buy, Eat, Ride,
  Book, Pay, Work, Chat and their product/service sub-actions. A control-count
  pass is not proof that their information architecture conforms.
- Branding must use navy `#000080`, saffron `#FF9933`, green `#138808`, the
  approved MoolSocial wordmark and tricolour identity line. Do not substitute
  an improvised initial tile, generic mark, new one-off palette or unrelated
  brand treatment.
- The HTML is a production-bound design contract, not a production WebView and
  not a visible prototype/demo. Native Flutter V2 begins only after explicit
  founder `FINAL`, and production acceptance/locking occurs only after the
  matching Flutter result passes the required device review.

The complete candidate inventory, destination boundary and verification record
is:

`artifacts/quality/screen04-html-founder-review-20260720/SCREEN-04-HTML-FOUNDER-REVIEW-WORKLOG.md`

### Founder-locked cloud environment and promotion memory

Founder decision recorded 21 July 2026:

- Local Firebase emulators remain the zero-cost first testing boundary.
- `moolsocial-dev-503018` is the separate real-service Trial environment.
- Screenwise Preview uses a Firebase App Distribution tester group inside Dev;
  it is not a fourth backend environment.
- `moolsocial-staging-503018` is clean staging and receives only promoted
  candidates.
- The Production project is created later and is never used for
  experimentation.
- Promotion is strictly:
  `emulators → Dev/Trial → Dev Preview → clean Staging → Production`.
- One client artifact cannot switch environments at runtime. Protected
  environment configuration is supplied at build time and missing live values
  fail closed.
- Do not enable every free-looking API. Each API requires an approved journey
  owner, restricted credentials, least privilege, quotas/cost controls,
  failure coverage and rollback evidence.

Both Android Studio Codex and every other Codex surface must read
`docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md` before looking at or changing
Google Cloud, Firebase, authentication, maps, APIs or distribution.

Provisioning state recorded 21 July 2026:

- The authoritative `moolsocial.com` Google Cloud organisation ID is
  `1067591230270`.
- An earlier transposed value, `1067591730370`, produced a false organisation
  permission failure. Machine rule: never retype an observed cloud identifier
  from memory; copy it from a current authoritative console/CLI observation and
  verify the resource name before any mutation.
- The MoolSocial admin principal has directly verified Organisation
  Administrator and Project Creator grants.
- `moolsocial-dev-503018` is now the active Firebase Dev/Trial project
  (`MoolSocial Dev Trial`, project number `760290687711`).
- Staging and Production remain uncreated. Dev/Trial creation does not authorize
  billing attachment, unrestricted credentials, Maps/Places/Routes enablement,
  or experimentation in Staging or Production.
- Evidence:
  `artifacts/quality/cloud-environment-bootstrap-20260721/CLOUD-ENVIRONMENT-BOOTSTRAP-EVIDENCE.md`.

### Founder-approved creator commerce — build as a core Social capability

Founder decision recorded 21 July 2026:

- `Create & Earn` is approved as a MoolSocial user-facing capability.
- The customer promise is additional income from eligible delivered
  MoolSocial sales generated by creator content, not compensation for YouTube
  views, likes, shares, comments or subscriptions.
- YouTube remains the canonical connected-video host. MoolSocial owns the
  product, campaign, retail/wholesale, serviceability, attribution, order,
  return, commission and payout experience.
- Every promoted video receives an opaque server-owned promotion identity
  binding the creator, video, campaign, product/variant and versioned
  commission rule.
- Direct product actions have priority; otherwise the last eligible
  creator-product interaction inside seven days receives credit. Attribution
  and commission are recorded per order line, and one order line can pay only
  one creator.
- Commission moves through attributed, ordered, delivered, return-window hold,
  payable and paid. Cancellation, return, chargeback or fraud can cancel,
  adjust, reverse or hold it. No commission becomes withdrawable on order
  creation alone.
- Manufacturers, brands or retailers normally reserve/fund creator commission;
  MoolSocial administers traceable settlement. Terms, caps, return conditions
  and payout timing are visible before creator acceptance.
- Buyer UI discloses that the creator may earn commission. Creator UI separates
  product visits, orders, delivered sales, returns, pending earnings, payable
  earnings and paid earnings.
- Use the owned MoolSocial HTTPS domain with Android App Links, Apple Universal
  Links and a useful web fallback. Never build new attribution on Firebase
  Dynamic Links.
- The Screen 04 bottom capability rail is founder accepted. Screen 04 action
  work now proceeds at `FND-U04-ACTION-003`, beginning with the Social
  main-action HTML. The top surface must not duplicate `Shorts`, `Videos`,
  `Feed` and `Create`; those remain owned by the accepted bottom rail.

The complete product, attribution, settlement, fraud, privacy, UI and test
contract is durable in
[`ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md`](../decisions/ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md).

This approval does not mark Screen 04 `FINAL`, authorize Flutter, enable a
YouTube API, create credentials or promote a cloud candidate.

### Universal first-layer approval gate and Social redesign

Founder decision recorded 21 July 2026:

- The Universal capability bottom rail is approved for production. Treat its
  visual design, wording, placement, motion, tap/swipe behavior, Back/Forward
  behavior and Chat/Mool boundaries as immutable during first-layer action
  design. A separate explicit founder instruction is required to reopen it.
- Do not begin native Flutter V2 or any other real production implementation of
  Universal yet. Production work remains blocked until the first-layer HTML for
  every main Universal action — Social, Buy, Eat, Ride, Book, Pay and Work — has
  been designed and explicitly approved by the founder.
- The active scope is only the first-layer Social HTML inside Screen 04. Screens
  01–03, shared runtime/CSS, downstream Social screens and Flutter remain
  outside this edit boundary.
- Social opens media-first. A personal-account customer must immediately
  encounter useful content and consumer discovery controls, without creator or
  advertiser tools being presented as universal actions.
- `Shorts`, `Videos`, `Feed` and `Create` remain owned by the accepted bottom
  rail and must not be repeated in a top action row. Watching is the visible
  content itself. The complementary public source actions are `Mool`,
  `YouTube`, `Facebook`, `Instagram` and `Promoted`. `Mool` opens MoolSocial
  reels and videos; `Promoted` opens paid MoolSocial reels. External networks mean
  public, embedded, connected or otherwise provider-permitted content shared
  with MoolSocial; the UI must not claim access to an external network's entire
  catalogue.
- `Publish`, creator campaigns, products to promote, channel connections,
  creator earnings and business promotion are not public Social launch actions.
  They live behind a Creator or Business account under the signed-in user's
  account/Work boundary. A personal user may be invited to start a Creator
  account from Create or Profile, then manage content, connected channels,
  campaigns and earnings there.
- `Promoted` is the customer-facing one-tap destination for paid MoolSocial
  reels. The content must identify its sponsor and any creator commission.
  Funder controls belong to a Business account, where a campaign may extend
  through only Facebook, Instagram or YouTube channels connected and approved
  by that account owner.
- Do not use a permanent page-level Like/Comment/Share/Remix rail. Engagement
  controls belong to the individual reel, video or post and must move with that
  content item.
- Every visible Social action must open a usable state or exact destination.
  No explanatory, decorative, duplicated, example, prototype, review,
  engineering or strategy wording may appear inside the customer viewport.
- Social must serve consumers, creators, businesses, advertisers, product and
  service owners, and broad discovery audiences without becoming a dashboard.
  MoolSocial is the central creation, management, monetisation, commerce and
  future multi-network distribution layer; it must not copy Facebook,
  Instagram, X or YouTube interfaces or claim an integration that is not live.
- Creator earning language remains governed by ADR-0003: earnings arise from
  eligible delivered MoolSocial outcomes, not from views, likes, comments,
  shares or subscriptions on any network.
- The earlier media-first Social founder-review candidate with SHA-256
  `A20E3437ACDA343C113D31B936DD38D6BEADCF9062A73FD7DA785D512F1AD87B`
  is superseded because it exposed creator actions to every personal account.
  Its historical automated evidence remains at
  `artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-FIRST-LAYER-FOUNDER-REVIEW-20260721.md`.
  The corrected candidate requires new automated evidence and founder review;
  automated verification never constitutes founder approval.

This direction authorizes an HTML founder-review candidate only. It does not
mark Social or Screen 04 `FINAL`, freeze a reference, update the approved
manifest, authorize Flutter, enable external social APIs or promote a cloud
candidate.

### Social consumer/creator account boundary correction

Founder correction recorded 21 July 2026:

- The public Social first layer is a consumer watching and discovery surface.
  It must not show creator products, campaigns, channel connections, earnings
  or advertiser controls to every personal account.
- The public one-tap sources are `Mool`, `YouTube`, `Facebook`, `Instagram` and
  `Promoted`. `Mool` means MoolSocial reels/videos. External sources are limited
  to public, embedded, connected or otherwise provider-permitted content shared
  with MoolSocial. `Promoted` means clearly disclosed paid MoolSocial reels.
- Creator tools belong to a Creator account under Profile/Work. Create may
  support ordinary personal publishing and invite an aspiring creator into
  Creator-account setup; detailed creator tools appear only after that boundary.
- Business-funded campaigns and external distribution belong to a Business
  account and can use only channels that account owner connected and approved.
- The corrected Screen 04 HTML candidate SHA-256 is
  `E67716227B93A2CE5B993A2F8E243A8582AE9FBAFCCA9B30077CB419277C30D3`.
  Evidence is durable at
  `artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-ACCOUNT-BOUNDARY-CORRECTION-20260721.md`.
- The accepted bottom rail CSS, markup and navigation JavaScript hashes remained
  byte-identical. A separate hit-test nevertheless found the accepted previous
  and next chevron tap regions overlap the centre of visible `Shorts` and
  `Create` at `390×844`. This is a pre-existing rail behavior, not a regression
  from the Social correction. Do not change it without explicit founder
  authority; do not mark complete direct-tap verification while it remains.

This correction still authorizes HTML founder review only. It does not mark
Social or Screen 04 `FINAL`, freeze a reference, authorize Flutter, enable
external social APIs or promote a cloud candidate.

### Native Social Exchange and later interoperable-network boundary

Superseding founder decision recorded 21 July 2026:

- The earlier public source actions `Mool`, `YouTube`, `Facebook`, `Instagram`
  and `Promoted` are superseded. Closed-network social sign-in does not provide
  a customer's complete external feed and must never be presented as if it
  does.
- The public first-layer Social discovery modes are `For You`, `Following`,
  `Nearby` and `Promoted`. All four are MoolSocial-owned feed decisions.
  `Promoted` must identify the sponsor and any creator commission on the
  content item.
- `Shorts`, `Videos`, `Feed` and `Create` remain in the founder-approved bottom
  capability rail. The public screen contains no second source rail and no
  duplicate top action row.
- Like, Comment, Share and Remix remain attached to the individual content
  item. Personal Create exposes `Post`, `Short`, `Video` and `Drafts`; it does
  not expose campaigns, products to promote, channel management or earnings.
- Creator and Business capabilities remain under Profile/account. Closed
  connectors must name their real eligibility boundaries: YouTube channels,
  Facebook Pages, Instagram professional accounts and any separately approved
  provider capability. A login provider is never treated as a full consumer
  social-client permission.
- Genuine interoperable networks are later adapter work. A narrow AT Protocol
  / Bluesky Dev pilot is the preferred first proof after the native Social MVP
  is stable. Public ActivityPub federation follows only after reporting,
  blocking, deletion, identity, spam, denial-of-service, moderation, privacy,
  observability and incident-response gates are ready.
- ActivityPub and AT Protocol do not impose a central per-call protocol licence
  fee. That does not make federation free: engineering, hosting, database and
  media delivery, rate-limit handling, moderation, abuse prevention, legal and
  privacy operations remain MoolSocial costs. No cloud resource, credential or
  public connector is authorized by this product decision.
- Do not show Bluesky, Mastodon, ActivityPub or any future network inside the
  customer UI until its connector is live, provider-compliant, failure-tested
  and founder-approved. Adapter seams may be designed now behind feature flags.
- When a connector is accepted, do not add another permanent network rail.
  Connected items remain inside `For You`, `Following`, `Nearby` or other
  MoolSocial discovery and carry a clear per-item source badge plus only the
  actions that connector supports. Connection management belongs under
  Profile/account, and Create shows explicit per-destination publish status,
  retry and partial-success states.
- The revised Screen 04 HTML candidate SHA-256 is
  `5CCF93809231815F69E3B46C35E33E4717E73AAF1859CE781B60E4A5F69757F2`.
  Specialized evidence is durable at
  `artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-social-native-exchange-audit-20260721-02.json`.
- The accepted bottom-rail CSS, markup and navigation-runtime hashes remained
  byte-identical. The previously recorded transparent edge-hint overlap at
  `390×844` also remains outside this edit boundary and may not be changed
  without explicit founder authority.

This decision authorizes the revised HTML founder-review candidate only. It
does not mark Social or Screen 04 `FINAL`, freeze a reference, authorize
Flutter, enable an API, create cloud resources or promote Dev, Staging or
Production.

### Founder-approved creator distribution and analytics boundary

Founder decision recorded 21 July 2026:

- MoolSocial will give eligible creators additional income by enabling them to
  publish campaign content through their separately connected accounts while
  manufacturers, brands, retailers and service providers gain attributable
  reach and delivered sales.
- Paid MoolSocial Reels are a core owned Social product. `Reel` and `Short`
  are one vertical short-video format. Posts support a single image, text or a
  swipeable image carousel; long-form Video remains separate.
- The founder-approved rail is unchanged during this revision. Its `Shorts`
  label owns the Reel/Short format and its `Feed` label owns posts and
  carousels.
- The public Social screen remains consumer-first. Campaigns, connected
  publishing channels, distribution, analytics, earnings and payouts are
  available only inside the Creator account under Profile/account. Funding and
  creator selection belong to the Business account.
- The launch connector design may include MoolSocial, YouTube channels,
  Instagram professional accounts, Facebook Pages, Threads, Pinterest business
  accounts and eligible LinkedIn accounts. Google Business Profile belongs to
  Business local promotion. WhatsApp Business is available for opt-in enquiry,
  order and support follow-up, never as a public social-feed publisher.
- TikTok is excluded from the India MVP. X awaits separate pay-per-use unit
  economics approval. Snapchat direct publishing and Indian platforms without
  a verified public API remain later partnership work and must not appear as
  live launch actions.
- Social login never grants publishing permission. Every external destination
  requires its own eligible account, consent and scopes and remains selectable
  per campaign.
- Publishing results are per destination and support partial success. A failed
  destination never removes successful posts from another destination.
- MoolSocial may combine provider reach/engagement analytics with product
  visits, attributed orders, delivered sales, returns and creator earnings.
  External engagement metrics explain performance; the MoolSocial order-line
  and commission ledger remains the payout authority.
- The founder initially accepted a six-part implementation proof inventory:
  private YouTube upload, Instagram Professional Reel, Facebook Page post/Reel,
  Threads post, Pinterest Pin and Google Business Profile offer. The later
  cost-first full-stack contract supersedes its sequencing: YouTube, Instagram
  and Facebook are the launch proof; each other connector must pass its proof
  only before that connector's feature flag can be enabled.

The complete connector, publishing, analytics and proof boundary is durable in
[`ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md`](../decisions/ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md).

The revised Screen 04 candidate adds only Social-owned Reel/Post presentation
and Creator/Business account sheets in the existing Screen 04 HTML. It does not
change the accepted bottom rail, mark Screen 04 `FINAL`, freeze a reference,
authorize Flutter or enable a provider API.

### Founder correction — YouTube Shorts and long-form Social split

Founder direction recorded 21 July 2026:

- MoolSocial owns Reels and Posts/carousels at MVP. It does not host an owned
  long-form video format. This supersedes earlier memory or handoff wording
  that described a native MoolSocial `Video` format.
- The accepted `Shorts` rail action is a mixed immersive sequence containing
  MoolSocial Reels and only positively classified YouTube Shorts. Every item
  names its source and receives source-correct actions.
- `search.list(videoDuration=short)` means a video under four minutes; it is
  not proof that a result is a YouTube Short. A YouTube Short must be verified
  from a connected MoolSocial-originated upload with known dimensions/date,
  a curated catalog record, or a future official Shorts-identification field.
- The accepted `Videos` rail action is an eligible public YouTube long-form
  library. The native MoolSocial surface exposes `Discover`, `Popular`,
  `Topics` and `Channels`, many selectable cards, provider pagination, one
  user-initiated official player and truthful unavailable/retry states.
- `Feed` remains MoolSocial Posts/carousels. Personal `Create` exposes Reel,
  Post/Carousel and Drafts. Long-form YouTube publishing remains inside the
  separately connected Creator account.
- Public YouTube items do not receive false MoolSocial Like, Comment, Follow
  or Remix mutations. MoolSocial Save, Discussion, Share and Details remain
  outside the unobscured provider player. Commerce appears only when a real
  campaign attribution and disclosure exists.
- The native library is intentionally not a copy of YouTube Home. It adds
  MoolSocial discovery, local/commerce value and attributable creator outcomes
  while the official player retains YouTube branding, controls, ads and
  playback ownership.
- Screen 04 HTML candidate SHA-256:
  `4FBAC2609FC8787AFC86E6932855E72AED73FD3879FE75C2B2418CF4DD788B40`.
- Automated evidence:
  `artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-youtube-format-contract-audit-20260721-01.json`.
  Results: `56/56` viewport/text-scale rows and `11/11` affected interactions
  passed with zero console errors. The accepted bottom-rail CSS, markup and
  runtime hashes remained byte-identical.

This records an HTML founder-review candidate only. It does not mark Social or
Screen 04 `FINAL`, freeze a reference, authorize Flutter, enable YouTube APIs,
create credentials or promote a cloud candidate.

### Founder correction — useful YouTube metadata and MoolSocial revenue layer

Founder direction recorded 21 July 2026:

- The eligible YouTube video surface should feel complete and trustworthy by
  presenting the useful public metadata supported by the current provider
  contract: title, description, thumbnail, duration, publication time, channel
  identity, public subscriber count, views, likes, comment count, topics and
  caption availability when available.
- MoolSocial does not copy the complete YouTube watch page. Unsupported or
  provider-internal features such as `Ask`, download, Premium/ad-free access,
  a verification badge, public dislike count and personalized YouTube Home/Up
  Next recommendations are absent.
- YouTube source identity and the official player remain visible and
  unobscured. Repeated provider branding is reduced outside those required
  boundaries so the native discovery, actions and commerce retain MoolSocial
  identity without disguising the true content source.
- A normal viewer sees one optional `Connect YouTube` prompt before Like,
  Comment or Subscribe. The prompt names those customer benefits, Google owns
  the approval, and each YouTube action remains separately user initiated.
  This viewing-action connection is independent from MoolSocial sign-in and
  Creator Studio's publishing-channel connection.
- MoolSocial-owned `Save`, `Discuss`, `Share` and `Details` remain outside the
  player. Campaign commerce appears only for a real attributed product/service
  record with creator-commission disclosure.
- A clearly labelled `Promoted on MoolSocial` placement may provide an owned
  advertising/revenue surface only when it is visibly separate from the
  selected YouTube item and never overlays or modifies the provider player.
- The revised founder-review HTML SHA-256 is
  `F386EE4DAE39172D89D65741A9000D678823FC5C5D7D0F082120D7438FCD89B3`.
  Automated evidence is durable at
  `artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-youtube-metadata-commerce-audit-20260721-01.json`.
  Results: `56/56` Social fitment states, `42/42` nested sheet fitment states,
  `13/13` interaction assertions, zero console errors and unchanged accepted
  bottom-rail hashes.

This correction remains an HTML founder-review candidate. It does not mark
Screen 04 `FINAL`, freeze a reference, authorize Flutter, enable YouTube APIs,
create OAuth credentials or promote a cloud environment.

### Mandatory Flutter production fitment gate for Screen 04 and later screens

Founder direction recorded 21 July 2026:

- The HTML phone matrix proves responsive founder-review intent; it is not
  sufficient evidence that native Flutter fits every device.
- When Flutter implementation is authorized, preserve the approved visual and
  interaction contract while proving at minimum `320×568`, `360×640`,
  `360×720`, `375×667`, `390×844`, `412×915` and `430×932` at 100% and 140%
  text. No primary action, player control, rail item or recovery action may be
  clipped, hidden beneath the system UI or made unreachable.
- Native verification must additionally cover landscape, current Android and
  iOS safe areas/cutouts, gesture and three-button navigation insets, display
  zoom, keyboard/IME opening, call/notification interruption and supported
  accessibility text above 140%.
- Tablet and foldable evidence is mandatory before claiming broad device
  support. Test compact and expanded tablet widths, portrait and landscape,
  split-window resizing, foldable cover/unfolded postures and hinge/display
  features. The layout must adapt or explicitly enforce a founder-approved
  support boundary; stretching a phone canvas is not acceptance.
- The official YouTube player must keep its provider-required minimum usable
  size, controls, captions, fullscreen/orientation behavior and unobscured
  branding at every supported layout. MoolSocial controls remain outside it.
- Verification must include the connected physical OPPO and Android/iOS native
  device or simulator matrices. Browser screenshots alone cannot close the
  Flutter gate.
- Evidence binds the exact Flutter build, commit, viewport/device, OS, text
  scale, orientation and player/content state. Required proof includes
  screenshots, semantics/tap results, overflow/exception logs, interruption
  replay and recovery states.
- A screen cannot be marked native production accepted, frozen or promoted
  while any supported device class has overflow, undersized targets, obscured
  content, unreachable actions, unsafe-area collision or broken player
  behavior.

## Completion evidence

### Founder-approved external reach and Creator Studio full-stack direction

Founder decision recorded 21 July 2026:

- The authoritative implementation contract is
  `docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`.
- MoolSocial uses two loops: native Social discovery that keeps people engaged,
  and Creator Studio distribution that reaches external audiences and returns
  them through attributable MoolSocial product/service links.
- Paid MoolSocial Reels, native Posts/carousels and native Video remain the
  owned core. Eligible public YouTube video may be discovered in the native
  MoolSocial feed and played through the direct official YouTube embedded
  player without opening the separate YouTube app.
- A single embedded video is not an acceptable Social feature. MoolSocial must
  show a native, paginated library of many eligible YouTube thumbnails,
  channels, playlists and deliberate search results. Users scroll or swipe,
  tap any available item and replace the one active official player without
  leaving MoolSocial.
- Connected creators may opt eligible uploads into MoolSocial discovery.
  Public discovery may also show public embeddable/syndicated video with clear
  YouTube identity. MoolSocial cannot promise YouTube's personalized Home
  recommendations, watch history or Watch Later because those are not exposed
  as a third-party Home experience.
- The product remains native Flutter. The only approved MVP WebView exception
  is the isolated provider-owned YouTube player in an OS Android `WebView` or
  Apple `WKWebView`. It contains no MoolSocial HTML, forms, navigation or
  business logic and may not be covered by MoolSocial controls.
- YouTube is the only approved external public media library for inline MVP
  playback. Facebook, Instagram and X personal feeds are not reproduced inside
  MoolSocial. External Meta audiences encounter creator posts on their own
  platforms and return through tracked MoolSocial links.
- The cost-first MVP publishing order is MoolSocial, YouTube, Instagram
  Professional accounts and Facebook Pages. WhatsApp Business is a separate
  opt-in enquiry/order/support channel, never a public feed.
- Threads, Pinterest, eligible LinkedIn and Google Business Profile are
  feature-flagged additions after individual Dev/Trial proof. X is disabled
  until its pay-per-use cost has a founder-approved budget and hard cutoff.
  TikTok remains excluded from the India MVP.
- Creator tools stay under Profile -> Creator account. Social login is identity
  only; each channel, Professional account or Page requires separate scoped
  connection and consent.
- Destination-first publishing is the default: choose YouTube, Instagram,
  Facebook or another live destination, see its requirements, then upload and
  preview.
- `Standard Publish` is an optional fast route. A creator uploads a controlled
  standard master once, selects compatible destinations and confirms once only
  after a destination-specific variant and preview passes for each one. It is
  not blind identical one-click posting.
- The MoolSocial API-project YouTube compliance audit is an accepted mandatory
  provider gate, not a product blocker. Public upload, expanded quota and live
  availability still require evidence and current provider approval.
- Creators keep external-platform income and earn additional MoolSocial
  commission only from eligible delivered MoolSocial sales. Never pay or
  reward external views, likes, comments, shares, follows or subscriptions.
- This decision changes no Screen 04 HTML or Flutter code, does not mark Screen
  04 `FINAL`, does not freeze a reference, does not enable an API and does not
  authorize cloud credentials or promotion.

A screen or journey is not production-ready until it has:

- a tap inventory;
- first-, second- and optional third-tap acceptance tests;
- success, invalid, empty, duplicate, cancelled, loading, retry, offline,
  permission-denied and failure coverage where relevant;
- clean-state exact failure replays;
- affected-journey regression;
- complete application regression;
- Android and iOS visual checks at supported sizes;
- the applicable real-user interruption, process-death, retained-data and
  relaunch rows from `FIRST-OPEN-REAL-USER-STATE-MATRIX.md`;
- no prohibited internal wording in user-facing surfaces.

This file is the durable project memory. New tickets, code reviews and release
gates must cite it.

### Screen 04 Social swipe and discovery candidate

Founder-directed revision recorded 21 July 2026:

- Reels and eligible YouTube Shorts belong to one continuous vertical flow;
  never return to a page-style `Next` button or split YouTube into a second
  Shorts destination.
- Rank MoolSocial owned and paid/promoted Reels first, but keep provider and
  sponsor identity truthful. Sponsor and commission disclosure does not hide
  with engagement chrome.
- Reel engagement controls are contextual: visible on entry, automatically
  hidden for immersion and restored by tapping the content surface.
- `For You`, `Following`, `Nearby` and `Promoted` must change actual content.
  A visual-only tab switch is a release-blocking regression.
- The video experience is MoolSocial discovery followed by one selected
  official YouTube player. It may feel familiar and efficient but must not
  clone YouTube Home, claim YouTube personalization or obscure attribution.
- Keep adjacent YouTube identity compact so content receives maximum space,
  but never remove the minimum clear source attribution or player branding.
- MoolSocial commerce, advertising and actions remain outside and distinct
  from the provider player. Unsupported copied features are prohibited.
- The accepted Universal bottom rail is unchanged and remains a protected
  production contract.

Exact HTML candidate SHA-256:
`D9444962A2E74D4F8A05E1DBF6929C5BD6D0C7A6D577E5C03B31797641DEE697`.
Evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-SWIPE-VIDEO-DISCOVERY-FOUNDER-REVIEW-20260721.md`.
Automated review passed 56/56 responsive rows and 24/24 interactions with zero
failures. This is not founder approval, `FINAL`, a frozen reference or Flutter
authorization. Native implementation still requires the full device and
interruption gates above after the entire first-layer Universal approval gate.

### Screen 04 YouTube vertical-containment regression and permanent rule

Founder-reported correction recorded 21 July 2026:

- A horizontal-overflow pass does not prove that a media item fits vertically.
  Every future HTML and Flutter audit must compare the media article, player,
  metadata surface and every reachable control with the actual content-stage
  bounds and the top edge of the persistent rail.
- A YouTube Short player and its metadata must never overlap each other or the
  accepted Universal rail. The provider player remains at least 200x200.
- Portrait media uses non-cropping `contain` behavior. Surrounding space may
  use a subdued derived backdrop; it must not misrepresent a crop as the full
  provider video.
- Shorts use the compact immersive header. On height-constrained phones, the
  top header yields its space while the accepted Mool/Social bottom rail stays
  unchanged.
- Channel and title are visible on entry. Description, public statistics,
  topics, native actions, commerce and disclosure remain reachable in the
  bounded metadata scroller. `Details` exposes the complete untruncated record.
- Scrolling metadata must not trigger a next-item swipe. Swiping the media
  surface remains the navigation gesture.
- Full API data does not mean placing every provider field on the first view.
  Show the useful public hierarchy first and put the complete available record
  in Details. Never show internal IDs or technical response fields.

Corrected founder-review SHA-256:
`A5307EB077E136B09064B40BB015C1856EE0B4A407F13CEA359B6303C75268B1`.
Evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-YOUTUBE-CONTENT-FITMENT-CORRECTION-20260721.md`.
The targeted correction passed 28/28 fitment states and 16/16 interactions;
the broader Screen 04 audit passed 56/56 responsive states and 24/24
interactions. The prior `D944...` candidate is superseded. Screen 04 remains
pending founder approval and is not `FINAL`, frozen or authorized for Flutter.

### Screen 04 Social Shorts/Videos scoped founder approval and Feed/Create review

Founder decision recorded 21 July 2026:

- The Screen 04 Social `Shorts` and `Videos` HTML states represented by source
  SHA-256
  `A5307EB077E136B09064B40BB015C1856EE0B4A407F13CEA359B6303C75268B1`
  are founder approved and parked as immutable scoped reference
  `approved-references/screens/04-universal-social-shorts-videos/v1`.
- The approval includes Shorts, Videos discovery, selected-video watch and the
  accepted Universal rail as rendered with those states. It does not approve
  Feed, Create, the remaining Universal actions, Flutter, backend/provider
  work, cloud use or promotion.
- Flutter Universal implementation remains blocked until every first-layer
  main action has completed its founder HTML approval gate. Never interpret
  this scoped reference as whole-Screen-04 `FINAL`.
- Future Feed/Create or other Screen 04 HTML work may not alter the accepted
  Shorts/Videos appearance, interactions, containment, player boundary,
  provider attribution, source-correct actions or accepted rail.

The next founder-review candidate revises only Feed and personal Create. Feed
is MoolSocial-owned Posts/carousels with genuinely different `For You`,
`Following`, `Nearby` and `Promoted` content. Commerce appears only on an
eligible linked post; paid content retains sponsor and potential creator-
commission disclosure. Personal Create exposes Reel, Post, Carousel and Drafts
only. Creator Studio, campaigns, external channel connections, analytics,
earnings and payouts remain under Profile -> Creator account; business funding
remains under Business account.

Current Screen 04 HTML SHA-256:
`1A0F35A26527C02B402C4B88B96384C74C858DCAE72FB81C253E0A022CC1DDC7`.
Evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-004-SOCIAL-APPROVAL-FEED-CREATE-FOUNDER-REVIEW-20260721.md`.
The new Feed/Create content passed 28/28 responsive rows, 14/14 interactions
and 2/2 focused copy/account-boundary checks. Feed and Create remain pending
founder approval and are not frozen or authorized for Flutter.

Known protected-rail observation: at `320×568` with simulated `140%` root text,
the byte-identical accepted rail is crowded near Create. Do not conceal this
observation or alter the founder-locked rail without separate authorization.

### Social Feed/Create first-layer founder approval and deeper same-screen rule

Founder decision recorded 22 July 2026:

- The Screen 04 Social Feed first-layer presentation and personal Create
  landing represented by SHA-256
  `1A0F35A26527C02B402C4B88B96384C74C858DCAE72FB81C253E0A022CC1DDC7`
  are approved and preserved as immutable scoped reference
  `approved-references/screens/04-universal-social-feed-create/v1`.
- The approval covers Feed discovery/content presentation, the personal Create
  landing and the accepted bottom rail as rendered with them. It excludes the
  deeper Feed/Create states, remaining Universal actions, Flutter, backend,
  external-provider work, cloud work and promotion.
- Never modify that scoped snapshot. Future Screen 04 candidates must retain
  its product hierarchy and must keep the accepted Universal rail byte-
  identical unless the founder separately authorizes a rail change.
- Native Flutter Universal work remains blocked until the first-layer HTML for
  every main Universal action is explicitly founder-approved.

The active deeper Feed/Create candidate must minimize user effort:

- Comment opens the conversation immediately in the same Social surface and
  Back returns to the originating Feed item.
- Share provides Repost, Add your thoughts, Send in Chat and Copy link. Repost
  is reversible; Add your thoughts opens a quoted-post composer in place.
- Personal Post creation begins directly in Create and supports text, one
  photo, a two-to-four-choice poll, a connected follow-up post, audience
  (`Everyone`, `Followers`, `Nearby`) and simple scheduling. Draft state is
  retained while the user writes.
- Reel creation begins directly with Camera or Choose Video. Camera consent and
  native capture are production dependencies; HTML uses an honest camera-ready
  then recording then finish sequence and never pretends recording has already
  occurred.
- Carousel creation accepts 2–10 photos, inline add/remove/reorder intent,
  caption and audience without another page.
- Drafts resume the matching Post, Reel or Carousel editor in place.
- X/Twitter and LinkedIn informed the interaction patterns—inline composer,
  connected posts, quote/repost, private save, audience, media, poll and
  scheduling—but their brands, destinations and account controls do not appear
  in personal Create. External publishing remains account-gated and feature-
  flagged under the Creator/Business contract.
- Every deeper interactive target is at least 44x44 logical pixels. All visible
  copy is customer-facing; no prototype, reviewer, example, internal planning,
  backend or state-machine language is permitted.

Current deeper founder-review candidate SHA-256:
`A38AD64A05425DD36BB0ED89679BADFD14276ED805E33B71C3C907F9260C1B7F`.
It passed 182/182 responsive state checks across the seven required viewports
at 100% and 140% text, 20/20 deeper interaction journeys, the focused copy
gate, and zero console/page errors. Accepted Shorts/Videos regressions remain
56/56 plus 24/24, and YouTube content/fitment regressions remain 28/28 plus
16/16. The founder subsequently approved this exact candidate as scoped
reference `v2`; the continuous-batch decision below controls later work.

### Founder continuous Social batch and approved MoolSocial plans

Founder decision recorded 22 July 2026: the exact `A38AD64...` Feed/Create
candidate is founder-approved and preserved as immutable scoped reference
`approved-references/screens/04-universal-social-feed-create/v2`. Versions `v1`
remain unchanged.

The founder authorized one uninterrupted batch to complete remaining Social
HTML, verify it, implement isolated native Flutter V2, test on the connected
OPPO, correct defects and run final regressions without intermediate founder
approval stops. This is a sequencing exception, not permission to label
unreviewed screens founder-approved. Unapproved HTML is preserved as a
checksummed candidate baseline until the final founder decision.

Approved MoolSocial product plans are `Free`, `Creator Pro`, `Business Pro`,
`Commerce Pro` and `Enterprise`. A normal user keeps one identity and may add
eligible Creator, Business or Commerce workspaces without a second login or
loss of history. Worker opportunity access is not paywalled merely to find or
perform legitimate work.

Time-bound launch access must state the exact end date, covered features and
post-expiry plan. It never silently converts to paid access. Subscription fees,
campaign budgets and follower-paid Creator Memberships are three separate
products and ledgers.

Eligible users may promote content or outcomes appropriate to their active
workspace. MoolSocial placements may appear only on MoolSocial-owned surfaces,
with sponsor disclosure and a real destination. They may surround YouTube
discovery but may not enter, cover or masquerade as part of the YouTube player.
No campaign UI promises guaranteed views, sales, leads or earnings.

Authoritative decision and execution files:

- `docs/decisions/ADR-0005-MOOLSOCIAL-PLANS-LAUNCH-ACCESS-AND-SOCIAL-PROMOTION.md`
- `docs/delivery/SOCIAL-CONTINUOUS-BATCH-EXECUTION-20260722.md`

### Social Flutter V2 candidate and physical-device findings

The continuous batch produced native Flutter V2 Social, Creator, plans and
promotion owners and installed exact final candidate `r15` on the connected
OPPO. Its SHA-256 is
`D60945E0E70F4D2B63B7471808E776F59AA3D929357B8A0E789B47FF6EC62475`;
the pulled installed base is byte-identical at `207304371` bytes. This is an
implementation candidate awaiting founder acceptance, not an approved
reference.

Permanent machine rules learned from the physical replay:

- Test nested navigation from the real entry path, not only by mounting the
  destination directly. Social → Creator → YouTube contained two imperative
  layers; all layers must be unwound before a global rail destination opens.
- A route query that changes the selected Social sub-action must update an
  already-mounted stateful screen. Initial constructor state alone is not
  sufficient when the router reuses the page.
- Production-theme layout must be mounted in tests. An outlined button that
  appeared valid under a minimal test theme received infinite width in the
  production theme and prevented Feed painting on the OPPO.
- Every icon-only creation control needs a finished customer-facing semantic
  label and tooltip before device handoff.
- Failure recovery must return directly to the input that needs correction.
  Retry alone is insufficient when the underlying validation condition is
  still false. r15 proves missing media-rights confirmation can return to the
  editor and then publish exactly once.
- The exact archived APK and the installed base APK must have the same hash.

Verification state:

- Social behavior, 69-state parity, fitment and customer copy: `42/42` passed;
- first-layer responsive combinations: `56/56` passed, with all named states,
  Creator owners, plans, promotion and YouTube Connect verified at compact
  `320x568` and `140%` text;
- locked Screens 01–03 suite: `38/38` passed;
- approved UI lock: passed;
- analyzer and `git diff --check`: passed; and
- two complete final regressions passed `417/417` each.

The first diagnostic regressions exposed 38 displaced legacy golden/control-
key assertions. They were not rewritten. A test-only router mode now mounts
the untouched legacy presentation for historical regression, while production
defaults remain native V2. Flutter goldens are not approved-prototype proof,
the legacy presentation remains read-only, and new V2 golden migration still
requires founder acceptance first.
The durable report is
`artifacts/quality/social-continuous-batch-20260722/SOCIAL-V2-IMPLEMENTATION-AND-OPPO-EVIDENCE.md`.
The complete parity and final-device record is
`artifacts/quality/social-continuous-batch-20260722/NATIVE-SOCIAL-69-STATE-PARITY-20260722.md`.

Do not infer live backend completion from the r15 presentation. Creator
workspace and plan activation remain owner-session states. Live YouTube data,
official playback/publishing, paid billing and server-authoritative
entitlements require their separate provider and backend gates.

### Screen 04 production-copy and implementation boundary (2026-07-22)

The founder authorized one production screen only: native Flutter V2 Screen
04, matched to the frozen `A38AD64A…` approved HTML, capability rail and
interaction contract. Screens 01–03 remain locked and later destination
screens remain outside this implementation until they are approved one by
one. The complete immutable reference is
`approved-references/screens/04-universal-focus-shell/v1`.

No visible Screen 04 production copy may contain example, demo, sample,
placeholder, reviewer, implementation, developer, working-note, internal-plan
or state-machine commentary. Visible words must be customer-facing actions,
facts, disclosures, outcomes or recovery guidance. This rule applies to the
default screen, sheets, validation, empty/loading/error states, semantics and
tooltips. A successful build or screenshot cannot override a copy-gate
failure.

The r15 Social candidate is not evidence of Screen 04 conformance. The native
Screen 04 must be compared with the frozen HTML at the same viewport, state
and text scale, then replayed through the real Screen 01 → 02 → 03 → 04 entry
path on the connected OPPO before founder review.

### Screen 04 founder-FINAL v2 and navigation machine rules (2026-07-22)

The founder marked the revised Screen 04 HTML **FINAL** after reviewing the
uniform Shorts surface, premium capability-rail response and responsive type.
Its immutable authority is
`approved-references/screens/04-universal-focus-shell/v2`; source HTML SHA-256
is `4D6B6A37E818BA860CF057879371555D2B7F811D3C16E569428C323BFEC6A8CD`.
This v2 reference supersedes Screen 04 v1 for native implementation. It does
not accept Flutter until identical-viewport comparison and connected-OPPO
replay are complete and the founder explicitly accepts that result.

Permanent implementation rules:

- MoolSocial and eligible YouTube Shorts use the same edge-to-edge content
  surface. Media is centre-cropped with `cover`, never stretched, and provider
  origin does not change the visible surface width.
- Engagement controls are content-owned, appear when a Short opens, dismiss
  after 2800 ms, and return on content tap. Sponsor identity and required
  disclosure remain available independently of transient controls.
- A vertical swipe advances through one continuous Shorts sequence across
  MoolSocial and eligible providers. There is no web-page-style Next control.
- The approved capability rail retains Mool and Chat at the edges, a
  horizontally available main-action or focused sub-action ribbon, the
  45/14/41 tricolour identity and restrained 220–460 ms motion. A confirmed
  rail selection gives native haptic feedback; motion must not create overflow
  or interfere with assistive technology.
- Tapping a main action opens its focused sub-action ribbon. Mool reveals the
  main-action root without discarding the current world or remembered focused
  sub-action. Tapping Mool again returns to that focused ribbon.
- Android Back from a focused Screen 04 ribbon returns to the Mool root.
  Android Back from an inline nested Create state returns one logical level
  first. A destination opened from Screen 04 must be pushed, not replace
  Screen 04, so Back restores the exact originating world and sub-action.
- Chat, commerce and other deeper destinations must preserve a reliable return
  to Universal. Sign-out is the only intentional authentication-boundary
  replacement.
- Navigation acceptance covers every main action and last remembered
  sub-action, rapid taps, horizontal ribbon discovery, deeper destination
  return, Android Back, Mool recovery, interruption/resume and authenticated
  relaunch. A direct widget mount is not sufficient evidence.
- Validate 320×568, 360×640, 360×720, 375×667, 390×844, 412×915 and 430×932 at
  both 100% and 140% text before device handoff. Production copy remains bound
  to `docs/quality/SCREEN-04-PRODUCTION-COPY-GATE.md`.

### Screen 04 founder-directed v3 play and rail amendments (2026-07-22)

After Screen 04 v2 was marked `FINAL`, the founder directed two production
corrections during native review. They are frozen as immutable HTML reference
`approved-references/screens/04-universal-focus-shell/v3`, source SHA-256
`55EB65F2A01D709502CB69D6BBED62EAEDB069D8C32E38B816D13B7BB5A23F48`.
Versions v1 and v2 remain unchanged.

Permanent machine rules:

- Shorts never display `Watch` or `Pause` as text over the media. Use one
  compact premium frosted circular control with a solid play/pause glyph and
  complete accessibility labels.
- After every main-action or sub-action tap, the capability ribbon
  automatically reveals the selected action and its next available action.
  When the selected action is last, keep that last action visible.
- Horizontal drag/swipe remains enabled. The small previous/next chevrons are
  only non-blocking discovery cues and must never intercept an action tap.
- The selected action must never be pushed out merely to reveal the next
  action. Treat active plus next as one geometry pair at every supported
  viewport and text scale.
- Direct action visibility, not only scrollability, is a release gate. The v3
  HTML evidence passes 490/490 active-plus-next cases, 363/363 full assertions,
  218/218 taps, 44/44 customer-copy views and all 14 responsive cases with
  zero console errors.

Native Flutter remains awaiting connected-OPPO review and explicit founder
acceptance. A passing HTML or widget audit does not mark Screen 04 production
accepted.

### Screen 04 Social correction cycle and MoolSocial Chat direction (2026-07-22)

Founder review of the native candidate reopened the editable Screen 04 Social
HTML. Immutable Screen 04 references v1, v2 and v3 remain unchanged. No new
Flutter work may use this correction until the revised HTML is explicitly
marked `FINAL`, frozen as a later immutable version and added to the approved
manifest.

The correction gate requires:

- one consistent responsive type scale across Shorts, Videos, Feed, Create and
  nested states;
- centred icon-only premium play controls with complete semantic labels;
- Shorts details remain visible until the user dismisses them. Never hide the
  creator, caption or commerce context on a timer while the user may be
  reading or interacting;
- captions that do not fit the compact view expose a minimum-44x44 `More`
  action and expand in place with `Less`. Reading and scrolling the expanded
  details must not dismiss the overlay or advance to another Short;
- a slightly more compact capability ribbon that preserves at least 44x44 tap
  targets, visible separation and automatic active-plus-next visibility;
- YouTube cards limited to fields and behavior actually available from the
  YouTube Data API and official embedded player. MoolSocial controls stay
  outside an active YouTube player, which must never be covered or restyled;
- only known eligible and embeddable YouTube Shorts in the mixed vertical
  sequence. Do not infer that an arbitrary YouTube video is a Short;
- a media-first Feed with an always-ready inline composer. Text, photo and poll
  posting must complete in Feed without opening another screen;
- Feed and Create have different jobs. Feed provides quick participation:
  short updates, one photo and polls. Create provides richer publishing:
  Reels, multi-photo carousels, detailed posts, drafts, audience and scheduling.
  Do not duplicate the Feed quick composer on the Create landing;
- every authenticated MoolSocial account may publish posts, Reels and
  carousels. A public profile is an authenticated account whose audience is
  public; it is not an unauthenticated writer. Creator or Business work-account
  activation is required only for monetisation, paid promotion, product
  attribution, campaigns and external distribution;
- public browsing may show eligible content, but any write action must request
  sign-in and preserve the intended format and return state. The current
  install-to-Universal journey already authenticates the user before Screen 04;
- immediate Create actions for richer Reel, carousel and detailed-post work,
  using only the approved navy `#000080`, saffron `#FF9933`, green `#138808`
  and neutral surfaces; and
- logical Back/forward restoration for video watch, Feed comments, Create
  composers, Reel source/camera/ready states, Mool root, focused ribbon and
  deeper destinations.

MoolSocial Chat is a first-party real-time communications product, not a link
to another messaging app. Its planned capability set includes personal and
group conversations, voice and video calls, images, videos, documents, voice
notes, replies, reactions, forwarding, delivery/read status, presence and
privacy controls, contact discovery, invitations, blocking/reporting, secure
multi-device continuity, and business conversations with catalog, order and
support context.

The Chat home should use familiar low-effort messaging principles: compact
search, conversation rows with avatar/name/latest activity/time, unread counts,
clear delivery state, one-tap compose, and immediate Chats, Calls, Updates and
business-tool access. Chat remains one tap from Universal and must not display
misleading forward/back arrows. Back from Chat restores the exact Universal
world and focused action; nested Chat Back moves one logical level at a time.

Contact discovery is explicit opt-in. Explain why address-book access is
needed, support invitation without silent uploads, minimise retained contact
data and provide revoke/delete controls. Safety, spam prevention, encryption,
backup and regulatory requirements are release gates, not decorative copy.

Use the supplied messaging screenshots only as behavioral references. Do not
copy the WhatsApp name, logo, green trade dress, proprietary icons or exact
screen composition. MoolSocial must keep its own branding, component geometry,
copy and interaction contract. This section records product direction only;
Chat HTML and Flutter still require their own founder-review and acceptance
sequence.

## Screen 04 Social correction v4 and deployment order — 22 July 2026

The reopened HTML candidate now has SHA-256
`5C18839F19DCB21982453A908BA96B75986B7ABCD963346F85BF765A44429A8D`.
The expanded audit passes `1,441/1,441` with zero failures and zero console/page
errors. This does not mark the checksum `FINAL` or approved.

Durable correction rules:

- MoolSocial Reels and eligible YouTube Shorts share one centred, icon-only
  play control. No visible `Watch` label appears on Shorts.
- Social filter, metadata, body, card-title and page-title roles are shared
  across Shorts, Videos, Feed, Create and nested states.
- Shorts details never disappear on a timer. `More` remains expanded until an
  explicit `Less` or chrome-dismiss action.
- Feed posts immediately inside Feed; Create remains the richer Reel,
  Carousel, detailed Post and Draft workspace.
- The active rail item and its next item are automatically visible, targets
  remain finger-safe and horizontal swipe remains available.
- A literal YouTube Home clone is not a provider capability or product goal.
  Native MoolSocial discovery may be familiar and media-first while keeping
  accurate YouTube attribution and an unobscured official player.
- Back and Forward restore the selected content and nested sheet; Feed Share
  history retains its post identifier.

Chat remains deferred until the Chat module. The Universal Chat edge is a
one-tap root destination and must not expose previous/next Social navigation.
Later Chat may provide familiar private messaging, groups, calls, video calls,
media/files, contact discovery/invites and business conversations, but must
use independent MoolSocial branding, icons and interaction details rather than
copying WhatsApp trademarks or exact trade dress.

The cascade is mandatory:
`docs/delivery/SOCIAL-MODULE-GO-LIVE-CASCADE-20260722.md`. Flutter remains
paused until founder `FINAL`; live YouTube integration begins in Dev/Trial only
after native UI acceptance and must pass before Staging or Social go-live.

## Screen 04 Social Gate 0 v5 founder approval — 22 July 2026

The founder approved the exact Screen 04 HTML at SHA-256
`B4A7F6B91A1F488EC5BA78D2A84379316EE9FD918264715C0BE1ED11F78A459A`
and authorized isolated native Flutter V2 implementation. The immutable
authority is `approved-references/screens/04-universal-focus-shell/v5`.
Screens 01–03 and every earlier Screen 04 reference remain read-only.

Permanent Create and public-content rules:

- Create is an immediate same-surface workbench. Selecting a format changes
  the workbench inside Screen 04; it does not open a decorative format page.
- MoolSocial-owned Create formats are `Reel`, `Carousel` and `Post`. Do not add
  owned long-form Video at MVP; eligible long-form video remains YouTube-hosted
  under Social Videos and the official player boundary.
- Reel exposes Camera and Gallery on the first tap. Carousel opens the image
  chooser on the first tap and accepts 2–10 images. Post focuses the writing
  field on the first tap.
- Post contains direct Image, Image Poll, Quick Poll and Quiz actions. These
  actions expand inline and keep the user inside the current Create surface.
- After publication, Reel, Carousel, Post, Image Poll, Quick Poll and Quiz each
  appear as a complete public content item. They must be built from the
  authenticated account and the content owned by the Social session. Blank
  preview cards, hard-coded success cards and developer-facing copy are
  prohibited.
- Image Poll shows image choices; Quick Poll shows text choices; Quiz shows
  answer choices and identifies the correct result after a deliberate answer.
  Poll and quiz public states include truthful vote totals, percentages and
  closing status where applicable.
- Ordinary public creation is available to every authenticated MoolSocial
  account. Creator and Business workspaces gate campaigns, earnings,
  attribution, analytics and external distribution—not ordinary posting.
- Native acceptance requires identical-viewport parity, 100% and 140% text
  fitment, complete Back/forward and rail replay, exact installed-APK evidence
  on the connected OPPO and explicit founder acceptance.

### Screen 04 native Create interaction correction — 22 July 2026

During connected-OPPO review, the founder approved continuing native work and
directed a lower-effort Create interaction based on the progressive behavior
of established publishing tools. This correction is additive to Gate 0 v5;
it does not reopen Screens 01–03, the Universal shell, the approved bottom
rail, or any previously accepted Social public-content behavior.

Permanent native rules:

- Create opens as one ready public composer. The writing field is immediately
  available; do not require a preliminary format-selection screen.
- The same composer exposes Image, Carousel, Image Poll, Quick Poll, Reel and
  Quiz. Selecting an action changes only the inline working area and never
  opens a replacement MoolSocial page.
- Image opens the native image chooser directly. Carousel opens native
  multi-image selection directly. Image Poll, Quick Poll and Quiz expose their
  real choice fields inline on the first tap.
- Reel reveals Camera and Gallery inline on the first tap. The source choice
  respects camera-versus-existing-file intent and must not become a decorative
  intermediate page.
- Owned long-form Video remains excluded. `Reel` is the MoolSocial-owned
  vertical-video action; eligible long-form viewing remains under YouTube.
- All action labels must remain fully visible at compact widths and 140% text.
  Do not horizontally park a partly cut word. Social's four bottom-rail choices
  remain simultaneously visible and finger-safe.
- Do not show an empty `Your content` preview or explanatory placeholder. Show
  the content library only after real session-owned content exists.
- Publication still produces the six approved public states from actual
  entered or selected session data: Reel, Carousel, Post, Image Poll, Quick
  Poll and Quiz. No fixed preview or hard-coded publication result is allowed.

## Screen 04 Social Videos progressive journey — pending founder review, 22 July 2026

The founder reopened only the Social Videos experience after supplying a
current mobile YouTube behavioral reference. Preserve every accepted Screen
01–03 lock, the Screen 04 bottom rail, the direct Create composer and all
session-owned public publication work. The Videos change is additive.

The production interaction contract is:

- Videos opens as a media-first discovery feed with the MoolSocial header,
  search, service area and approved bottom rail still present.
- A video-card tap opens one focused watch surface. The official YouTube player
  boundary is never covered, re-skinned or falsely presented as MoolSocial
  playback.
- The first information layer shows title, public metrics, channel identity,
  engagement entry points, comments preview and the next videos.
- Tapping title/metadata opens a persistent Description sheet containing only
  supported fields: description, publication time/date, duration, caption
  availability and public statistics when available.
- Tapping channel identity opens channel title, description, thumbnail,
  subscriber count when public, video count and channel views when available.
- Public comments use `commentThreads.list` only when enabled. Disabled,
  restricted, missing and unavailable data must be honest states.
- YouTube attribution remains visible on YouTube-derived results and playback.
  MoolSocial Save, Discuss, Share and commerce remain separate from
  provider-owned Like, Comment and Subscribe.
- Familiar progressive behavior is permitted; YouTube trademarks, exact trade
  dress, proprietary icons and a copied interface are not.

The editable HTML passed 337/337 automated assertions across all seven required
viewports at 100% and 140% text. Evidence is retained under
`artifacts/quality/screen04-video-progressive-html-20260722`. This HTML is not
FINAL and must not be frozen or implemented in Flutter until explicit founder
approval.

### Founder correction — Social Videos mobile interaction parity, 23 July 2026

The progressive Social Videos HTML remains pending and requires another
founder-review revision before `FINAL`:

- Remove the visible `← Videos` page pill. It creates an unnecessary navigation
  step and is not an accepted customer-facing control.
- Use platform-native Back/gesture behavior and contextual close behavior.
  Returning from channel or Description must restore the exact watch item,
  playback context and scroll position; returning from watch must restore the
  exact discovery position.
- The discovery surface must follow the low-effort mobile behavior demonstrated
  in the founder-provided YouTube references: immediate search and topic
  discovery, media-first choices and one-tap transition into the selected
  video.
- The selected video must open as the primary content. Its first information
  layer, persistent Description layer and channel-details layer must be
  progressively reachable without decorative intermediary pages or repeated
  controls.
- Match the useful interaction architecture and information availability, not
  YouTube trademarks, proprietary icons or protected trade dress. Required
  YouTube source identity, official-player controls and policy boundaries
  remain visible and unobscured.
- Preserve all previously accepted Screen 04 work: bottom-rail behavior,
  Shorts corrections, Feed behavior, the direct Create composer, all six
  session-owned public content results, customer-copy safeguards and compact
  text-fitment rules.
- Re-audit the top Create/posting region and every Social text role for broken
  words, inconsistent sizing, clipping and unnecessary blank space before any
  new Flutter candidate is built.

This is a pending design/interaction correction only. It does not approve a
new HTML checksum, authorize Flutter Videos changes or change the locked
Screens 01–03 checkpoint.

## Screen 04 Social v7 production-candidate checkpoint — 23 July 2026

This checkpoint supersedes the pending Social Videos correction above while
preserving every earlier immutable reference as history.

- Final HTML authority:
  `approved-references/screens/04-universal-focus-shell/v7`.
- Final HTML SHA-256:
  `DBD9C3D20F230533E8513536E6BA2B4BDDBBB4AECF509C77265187FFDFF5E72F`.
- HTML verification: 897/897 across the seven required phone viewports at
  100% and 140% text, with no recorded finding or console error.
- Screen 04 Flutter UI V2 now implements the approved capability rail, Shorts,
  Videos, Feed and Create without importing the legacy presentation.
- Videos uses native Back only: channel -> Description -> watch -> exact prior
  discovery position. Do not restore the rejected page-level `Videos` pill.
- Every video record must own internally consistent title, channel, summary,
  statistics, dates, hashtags and channel details. Never reuse one content
  item's metadata for another. The physical OPPO mismatch that exposed this
  rule is now covered by an automated regression assertion.
- Feed remains immediately writable and publishes session-owned content.
- Create remains a single direct surface: Reel, Carousel and Post are primary;
  Post owns Image, Image Poll, Quick Poll and Quiz. Camera and Gallery open
  directly, and content-library states are truthful rather than fabricated.
- The Mool root automatically exposes the active main action and its next
  action. A focused world automatically exposes the active sub-action and its
  next sub-action. Swipe remains available; it is never the only discovery
  mechanism.
- Chat is one tap away and must return to the exact Screen 04 state. The later
  Chat-module product direction remains separate and must use independent
  MoolSocial branding rather than copied WhatsApp trade dress.
- App switch, resume and authenticated force-stop/restart must preserve the
  Universal context and must not regress to OTP.

Exact native review APK:
`artifacts/quality/screen04-social-final-mission-20260723/moolsocial-screen04-social-v7-device-review-r2.apk`
at SHA-256
`70A596D24D9DA659CAC51A5452A96C6A739C5B0BBBEA5BAE84E4D8F91A7CFF4C`.
The base APK pulled from the OPPO has the identical hash. The affected suite
passed 73/73; both full regressions passed 448 tests with only the two preserved
historical capture jobs skipped; approved Screens 01–03 locks passed.

This is a verified native candidate, not founder native acceptance. Await an
explicit `Accepted` or `Rejected` decision on the installed OPPO candidate.
Do not merge to `main`. Live YouTube Data API, OAuth/player/upload/analytics and
quota verification remain Gate 3 Dev/Trial work after native acceptance.

## Screen 04 Social v8 final candidate checkpoint — 23 July 2026

This checkpoint supersedes the rejected v7 native candidate while preserving
v7 and every earlier reference as immutable history.

- Final HTML authority:
  `approved-references/screens/04-universal-focus-shell/v8`.
- Final HTML SHA-256:
  `0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`.
- HTML verification: 1023/1023 across the seven required phone viewports at
  100% and 140% text; zero finding and zero console error.
- Videos alone uses the compact search-first header. It must not restore the
  Universal location chip or large command bar. A non-empty discovery query
  may remain applied after Watch, but Watch itself opens with compact search
  and no keyboard.
- Video Back order is channel -> Description -> Watch -> exact filtered
  discovery. No page-level Videos back pill and no keyboard-only Back step is
  permitted.
- Channel statistics render a value and its label separately. Never duplicate
  suffixes such as `channel views` or allow a metric to truncate because the
  value already contains its label.
- Feed keeps the public composer at the bottom thumb zone. Successful posting
  dismisses focus and the keyboard, clears the composer and renders the
  session-owned public item in the visible feed.
- Shorts controls remain user-controlled. `More` is shown only when it reveals
  meaningful additional content or supported provider metadata; expanded copy
  persists until explicit `Less`. It must never be a label-only toggle.
- Create keeps the truthful content library above the direct thumb-zone
  workbench. Reel, Carousel, Post, Image, Image Poll, Quick Poll and Quiz remain
  one-surface actions with native system pickers where required.
- The main-action and sub-action rails automatically keep the active choice and
  next choice visible. Swipe remains available but is never required to
  discover the next action. Chat returns to the exact prior Screen 04 state.
- App switch/resume preserves the current Screen 04 state. Authenticated
  force-stop/restart returns to Screen 04 after the locked launch interval and
  must not regress to OTP.

Exact native review APK:
`artifacts/quality/screen04-social-v8-mission-20260723/moolsocial-screen04-social-v8-final-device-review.apk`
at SHA-256
`37F8E3718E4E7A53D1DB8949B4D1A14D3C6D77039DB5841442F020CBB07C09A1`.
The OPPO-installed base is byte-identical at 208,494,800 bytes. The affected
suite passed 91/91; both full regressions passed 448 tests with the same three
superseded capture jobs skipped; analyzer and all Screen 04/approved-lock gates
passed.

This remains a verified candidate pending founder `Accepted` or `Rejected`.
Do not merge or promote it to `main`. Live YouTube Data API, OAuth, official
player, upload, analytics and quota validation remain Gate 3 Dev/Trial work
after native acceptance.

## Founder override — Screen 04 Social v9 ownership and direct action — 23 July 2026

The founder has reopened Screen 04 Social after reviewing additional
Instagram and X interaction references. This supersedes earlier memory that
assigned rich personal publishing to a visible Create sub-action, but only for
the editable v9 founder-review candidate. Immutable v8 remains preserved at
HTML SHA-256
`0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`;
its verified native APK remains evidence, not current founder acceptance.

Permanent v9 candidate direction:

- Reels owns Reel discovery and creation. A compact top-left search expands for
  Reels and creators. A separate contextual `+` begins Camera/gallery
  selection directly, followed by the same one-surface editor.
- Feed owns public Post, Photo/GIF, Carousel, Existing Reel, Image Poll, Quick
  Poll and Quiz. A contextual `+` sits in the thumb zone and opens a
  keyboard-ready composer without a format landing page.
- MoolSocial does not add general owned long-form Feed video. An existing
  MoolSocial Reel may be attached to a Feed post.
- Visible Create is a removal candidate only after every responsibility,
  saved/deep-link entry, Back/forward path and internal route/session contract
  has a compatible owner and passing proof.
- Provider screenshots express low-effort interaction principles only.
  MoolSocial must not copy Instagram/X trade dress, trademarks, wordmarks,
  proprietary icons or exact screen composition.

The governing ticket pack is
[`SCREEN-04-SOCIAL-FOUNDER-CORRECTION-TICKETS-20260723.md`](../delivery/SCREEN-04-SOCIAL-FOUNDER-CORRECTION-TICKETS-20260723.md).
This record does not mark HTML complete or `FINAL`, does not freeze v9 and does
not authorize Flutter changes. Correct the editable HTML, verify it and present
the exact candidate for explicit founder review first.

## YouTube API-first Social gate — 23 July 2026

The founder paused the Screen 04 v9 UI correction and directed a real-provider
capability gate before further Shorts/Videos design. This changes sequencing,
not the native product architecture.

- Screen 04 v9 remains `DRAFT / HOLD`. Do not freeze it, update the approved
  manifest or change Flutter UI during the provider spike.
- Preserve immutable v8 and its native evidence as history; it is not the
  current founder-accepted candidate.
- YouTube can supply public metadata, official in-app playback, connected
  creator upload and creator-owned analytics. It does not expose personalized
  YouTube Home, the native Shorts recommendation feed, Watch History, Watch
  Later or the complete YouTube app UI.
- Build MoolSocial discovery, ranking, navigation, Feed, Reels, commerce and
  creator tools natively. The sole WebView/WKWebView exception remains the
  unmodified official YouTube player.
- YouTube source identity, controls, links and ads remain visible. Some
  YouTube-owned links may require an external handoff; do not promise that
  every provider journey remains inside MoolSocial.
- No MoolSocial commercial element may cover or alter the player. Adjacent
  commerce requires independent MoolSocial value and a genuine campaign
  relationship.
- Creator uploads use separate YouTube OAuth, explicit channel/title/
  description/privacy/audience confirmation and resumable direct-to-YouTube
  transfer. The unaudited Dev project keeps API uploads private.
- The July 2026 `brandPartner` video part is a candidate for eligible
  creator/brand deals. It does not replace rights, disclosure, attribution,
  delivered-order commission or payout records.
- The current Dev project/day buckets are separated: 100 `search.list` calls,
  100 `videos.insert` uploads, 10,000 `videos.batchGetStats` calls and 10,000
  general Data API units for other methods. MoolSocial's private-Dev caps stay
  lower at 20 searches, 10 uploads, 500 `videos.batchGetStats` calls and 2,000
  general units. These defaults are enough for controlled Dev proof, not
  public scale.
- YouTube-hosted playback removes MoolSocial video hosting/streaming cost for
  that provider copy, but backend, OAuth, security, metadata, moderation,
  analytics, compliance and support still have cost. Never promise an
  unconditional zero-cost integration.

Authority:

- `docs/decisions/ADR-0006-YOUTUBE-API-FIRST-SOCIAL-INTEGRATION.md`
- `docs/delivery/YOUTUBE-API-CAPABILITY-AND-ENDPOINT-MATRIX-20260723.md`
- `docs/delivery/YOUTUBE-INTEGRATION-PREPARATORY-TICKETS-20260723.md`

The founder authenticated Google Cloud Console and enabled the minimum Dev
service set on 23 July 2026:

- project: `moolsocial-dev-503018`;
- project number: `760290687711`;
- enabled: `youtube.googleapis.com`;
- enabled: `youtubeanalytics.googleapis.com`;
- successful operation:
  `operations/acat.p2-760290687711-a9ca0f31-b826-4955-8486-7e66dc423ca2`;
- deferred: `youtubereporting.googleapis.com`; and
- credentials created: none.

The later private-Dev inventory on the same date additionally confirmed:

- project lifecycle: `ACTIVE`;
- project billing attachment: disabled;
- one Firebase-created Browser key restricted to Firebase APIs, not YouTube;
- one Firebase Android app registered as `com.moolsocial.app`, App ID
  `1:760290687711:android:4202409fd3ab38f6ce076a`;
- `firebaseappcheck.googleapis.com` and `playintegrity.googleapis.com` enabled
  successfully;
- the founder accepted the applicable Google terms and Play Integrity is
  registered for the verified Dev signing fingerprint; and
- the founder has explicitly authorized Dev billing attachment under the
  recorded cost controls; the intended organisation account exists but
  currently reports `open: false` while Google's prepayment credit is pending,
  so no link may be attempted until it becomes open; and
- Secret Manager, Cloud Functions, Cloud Run, Cloud Build, Artifact Registry
  and Firebase Data Connect were not enabled because the project is not
  attached to billing.

This is only service activation. It does not approve a UI, create a usable
integration, authorize Staging/Production or permit unrestricted credentials.
Never request or accept a password, OTP, recovery code, API key or OAuth secret
in chat. The founder enters credentials only into Google's own surface.

### Permanent YouTube cost and pricing memory

The founder requires the integration to avoid additional MoolSocial cost
wherever technically possible and to disclose every unavoidable cost before it
is incurred.

- Official embedded playback and direct phone-to-YouTube resumable upload are
  the default because MoolSocial does not store, transcode or deliver that
  YouTube copy.
- “No published YouTube API per-call price” never means the integration is
  cost-free. Broker/cache execution, OAuth verification and support, encrypted
  token custody, metadata refresh, analytics, monitoring, moderation and
  compliance remain MoolSocial costs.
- YouTube does not publish an API fee per official embedded playback. Never
  charge for API access, YouTube data or access to YouTube functionality.
- Paid plans may cover only independent MoolSocial value: campaigns, brand–
  creator matching, product attribution, orders, returns, commission, payouts,
  creator workflow, teams, MoolSocial sales analytics and explicitly selected
  managed-media services.
- Google Ads or any other external spend is off by default. It requires a named
  payer, price, budget and automatic cutoff.
- A free tier is a limited allowance, not a permanent price promise. Every
  feature needs a cost class, quota cap, measured usage and kill switch before
  public release.
- Firebase Blaze attachment has no fixed subscription charge by itself, but
  it enables metered services. Functions 2nd gen can scale to zero with
  `minInstances=0`; Cloud Build, Artifact Registry and Secret Manager have
  limited included allowances.
- Firebase SQL Connect's underlying Cloud SQL database is the eventual
  always-on cost floor. An eligible unchanged default database may receive a
  three-month trial; afterward Firebase publishes Cloud SQL pricing as
  starting at USD 9.37/month. Before creating it, verify trial eligibility and
  the displayed Mumbai estimate. Use USD 25/month only as an internal
  conservative safety reserve, never as a Google price quote.

The durable authority is
`docs/delivery/YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md`.

### Private Dev provider foundation checkpoint — 23 July 2026

The YouTube provider foundation now exists only in the privileged backend and
provider-only Data Connect connector. Screen 04 HTML remains `DRAFT / HOLD`;
no Screen 04 or Flutter presentation change is authorized by this checkpoint.

- The provider starts fail-closed. Public metadata, owner connection, private
  upload and owner Analytics are independent runtime flags and all default to
  off. The current single deployed Functions boundary binds the complete
  server secret set, so every required Dev secret must exist before even the
  public-data proof is deployed.
- The local verification passed TypeScript checks and 50/50 deterministic
  backend tests.
- The compile-time-gated, non-UI Flutter private-Dev client passed targeted
  analysis and 23/23 platform/provider tests. It supports public metadata,
  owner connection, private direct-to-Google resumable transfer,
  reconciliation, owner Analytics and disconnect without changing any
  Screen 01–04 presentation.
- The current Data Connect schema and both connectors compiled in an isolated
  generation workspace without changing generated production Flutter files.
- The local Functions, Authentication and Data Connect emulators started
  together.
- A capability query returned every YouTube capability disabled.
- A public-video request returned HTTP 503 `capability_disabled` before secret
  access or YouTube quota use.
- Refresh tokens and resumable session URLs have separate AES-256-GCM
  purposes; access tokens remain process-memory only.
- Upload initialization is private-only and the media transfer path is
  client-to-YouTube, not through MoolSocial Functions.
- Upload jobs persist a complete canonical request fingerprint. Reuse of an
  idempotency key with changed content type, size or metadata is rejected.
- Stale session creation and expired resumable-session states become terminal
  failures instead of retrying forever.
- Publication reserve/update operations are conditional on the ACTIVE YouTube
  connection and use atomic row locking, so an older in-flight request cannot
  recreate or mutate provider data after disconnect.
- The server OAuth callback consumes one-time state, resolves the selected
  owner channel and exposes only sanitized connection status.
- If credential persistence succeeds but connection persistence fails, the
  server restores the earlier credential or deletes the newly written one.
- App Check protects deployed calls; Firebase Auth is additionally required
  for owner operations.
- Separate search, upload and general quota buckets use atomic reservations
  and conservative Dev caps.
- No YouTube server API key, OAuth client, refresh token, live upload or
  Analytics result has been created or claimed.

Evidence:

`artifacts/quality/youtube-provider-private-dev-20260723-02/LOCAL-PROVIDER-FOUNDATION-EVIDENCE-02.md`

Google/Firebase reauthentication and the read-only inventory are complete.
The founder accepted the Play Integrity terms and explicitly authorised
billing attachment for **only** `moolsocial-dev-503018` under the recorded
cost controls. The remaining external blocker is Google's billing-account
activation: the intended organisation account currently reports `open: false`
while its required prepayment credit is pending. Do not try to link it until
Google reports `open: true`. Codex must never receive, type, copy or store a
password, OTP, recovery code, API-key value or OAuth secret. Once the account
opens, establish project-scoped cost guardrails, link only the Dev project,
create only restricted credentials, deploy with all flags off, and enable one
supervised capability at a time.

Cloud evidence:

`artifacts/quality/youtube-private-dev-cloud-bootstrap-20260723-01/CLOUD-BOOTSTRAP-EVIDENCE.md`

Execution and audit authority:

- `docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md`

## YouTube-centred Social authorization — 24 July 2026

The founder authorized a new Screen 04 direction after the API-first pause:
YouTube may become a primary engagement centre inside MoolSocial, and the
editable Screen 04 HTML may be materially restructured to support the strongest
permitted discovery, playback, channel, comment, creator-connect, private
upload and creator-analytics journeys.

This authorization changes the design objective, not the acceptance gates:

- prove the provider surface in private Dev before claiming a feature;
- revise HTML first from the observed provider contract;
- show the exact HTML state to the founder;
- require explicit founder `FINAL` before freezing or changing Flutter;
- then implement native parity and repeat physical OPPO testing;
- preserve Screens 01–03 and every immutable Screen 04 reference; and
- never place example, commentary, implementation or planning wording in the
  user-facing product.

YouTube remains a clearly attributed provider. The official player retains
YouTube controls, branding, advertising and supported outbound links.
MoolSocial must not imitate YouTube so closely that provider identity is
ambiguous, suppress player behavior, invent unsupported Home/Shorts/watch
history features or charge for functionality YouTube provides free. Its
independent value is the MoolSocial-native Feed, commerce, campaigns,
attribution, earning, collaboration and business workspace around provider
content.

The founder supplied evidence of a successful INR 3,000 Google Cloud payment.
Cloud Shell separately verifies billing account `01F9D3-44031C-B5E225` open
and linked only to `moolsocial-dev-503018`. That payment does not set the
monthly Dev budget alert. Workload provisioning remains held until the founder
records the exact monthly INR alert amount and all security prerequisites
pass.

The authorized Windows workspace now also contains a verified portable Google
Cloud CLI under `C:\GUARANTEED OUTCOME\.tools\google-cloud-sdk` with isolated
configuration at `C:\GUARANTEED OUTCOME\.gcloud-moolsocial`. It is not
authenticated and must never import or copy credentials from another CLI,
Cloud Shell or unrelated configuration. The already authenticated Cloud Shell
remains the current administrative surface unless the founder completes a new
provider-owned login for that isolated configuration.
- `docs/delivery/YOUTUBE-API-COMPLIANCE-QUOTA-VALUE-PROPOSAL-20260723.md`

The proposal is a gated form package, not a sent email and not a claim of
partnership, approval, user scale or production readiness. YouTube's published
submission path is the API Services Audit and Quota Extension Form. Numerical
quota requests and benefit claims are filled only after measured private
Preview evidence and founder/legal review.

## Deferred Google commerce and paid-growth Workspace boundary — 23 July 2026

The founder assigned Merchant API and Google Ads Demand Gen to the future
signed-in Workspace module.

- Merchant Center, eligible YouTube Shopping affiliate reporting and Demand
  Gen configuration live only inside a selected verified Creator/Business
  Workspace.
- They never appear in public Social, Screen 04, the Universal rail, Personal
  Reels, Videos, Feed or Create.
- Merchant API is catalogue, inventory, promotion, diagnostics and reporting
  infrastructure. It is not consumer Google-product search, checkout, payment
  or ordinary order management.
- YouTube affiliate reports are eligibility-gated provider analytics. Do not
  promise Indian merchant eligibility, arbitrary product tagging or programme
  entry.
- Demand Gen delivers advertiser-funded campaigns on eligible Google surfaces;
  it does not place Google ads inside MoolSocial.
- Each advertiser connects and pays through its own Google Ads account.
  MoolSocial may later charge only a separately approved and disclosed
  management/workflow fee.
- Provider reports never replace the MoolSocial order-line attribution,
  delivered-order commission or payout ledger.
- Merchant API, Google Ads API, credentials and spend remain disabled. This
  boundary does not change the Screen 04 `DRAFT / HOLD` or block the active
  private YouTube provider proof.

Durable authority:

- `docs/decisions/ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md`
- `docs/delivery/GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`

### Private Dev activation safety checkpoint — 24 July 2026

The founder's Dev-only billing authorization is durable, but it is not
permission to use a closed account, Staging, Production, unrestricted
credentials or uncontrolled spend. Google still reports the intended billing
account `open: false`, so the Dev project remains unlinked.

Before any live provider deployment:

- run `scripts/check-youtube-private-dev-preflight.ps1`;
- preserve all Screen 01–04 UI and accepted-reference locks;
- require exact project `moolsocial-dev-503018`;
- keep all four YouTube capability flags off;
- keep both provider Functions at `minInstances: 0`, `maxInstances: 1` and
  `concurrency: 1`;
- keep Dev daily ceilings at or below search 20, upload 10 and general 2,000;
- never proxy media through MoolSocial storage or Functions;
- link only after the authorized account reports open, then create
  project-scoped budget controls before workloads;
- configure credentials only through Google-controlled surfaces without
  putting values in chat, source or evidence; and
- enable and prove one supervised capability at a time.

The 24 July local foundation passed 56/56 backend tests, 22/22 targeted
Flutter client tests, fresh isolated Data Connect generation, approved UI
locks and production-source credential scanning. It is readiness evidence,
not a live deployment or YouTube approval.

Durable evidence:

`artifacts/quality/youtube-private-dev-readiness-20260724-01/PRIVATE-DEV-READINESS-AUDIT.md`

## Cost-first YouTube private Dev control plane — 24 July 2026

This section supersedes earlier private-Dev wording that treated Data
Connect/Cloud SQL as the active YouTube provider deployment. It does not
reverse ADR-0001 for relational commerce, stock, checkout, settlement or
workspace records.

- The active private-Dev YouTube persistence adapter is Cloud Firestore.
- Provision exactly one Standard edition, Native mode `(default)` database in
  `asia-south1`. Keep delete protection on and point-in-time recovery, TTL,
  backups and backup schedules off.
- Firestore owns only encrypted provider connections, one-use OAuth attempts,
  upload orchestration/idempotency, atomic quota reservations and append-only
  redacted audit. Mobile/web clients have no direct access to these provider
  collections.
- Existing Data Connect/Cloud SQL adapters are preserved and deferred. The
  private YouTube deployment may not enable Data Connect or Cloud SQL Admin and
  may not provision a Cloud SQL instance.
- YouTube hosts and streams YouTube media. For the private upload proof, the
  phone sends bytes directly to Google's resumable-upload URL. MoolSocial does
  not store, proxy, transcode or serve those media bytes.
- No MoolSocial-owned long-form video storage is part of MVP. Native Reel video
  storage is also outside this proof and remains disabled until a separate
  media design, payer, budget, retention policy and founder decision exist.
- YouTube quota is not an ordinary per-watch or per-upload media price.
  MoolSocial still pays for its own Functions, Firestore, secrets, build
  artifacts, logging, App Check and operations after applicable allowances.
- Firestore's free quota is a measured capacity boundary, never a zero-cost
  guarantee. TTL deletes, PITR, backups, restore and clone are outside that
  boundary and remain disabled.
- Only `youtubeProvider`, `youtubeOAuthCallback` and `firestore:rules` may
  deploy. Both Functions run as
  `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`.
  The runtime remains keyless and receives Datastore User, App Check token
  verifier and per-secret accessor only. Owner, Editor, Datastore Owner, broad
  secret roles and user-managed service-account keys are prohibited.
- All provider flags remain false at initial deployment. Search, upload,
  batch-stats and general caps remain at or below `20/10/500/2000`, Functions
  scale from zero with at most one instance, and Functions artifacts retain
  for one day.
- Those provider caps are not a global Cloud Billing cap. The exact
  project-scoped monthly budget is mandatory, but budget alerts also do not
  stop spend.
- Enable governance APIs and verify the exact budget first; enable workload
  APIs afterward. A first Functions deployment may create its expected source
  bucket, Cloud Build execution, `gcf-artifacts` repository and
  Eventarc/Pub/Sub identities in the exact Dev project/region.
- Firestore location is effectively committed when created. If an existing
  `(default)` database has the wrong location, mode, edition or protection,
  stop rather than deleting, recreating or adding another database.
- The deployer needs `iam.serviceAccounts.actAs` on the dedicated runtime
  identity. Do not grant project Owner as a shortcut.
- Screen 04 remains `DRAFT / HOLD`. This backend decision changes no UI,
  route, accepted reference or Screens 01–03 artifact.

Physical OPPO provider proof is not yet ready. The Flutter client uses
`AndroidPlayIntegrityProvider`, and a USB-installed or sideloaded APK may not
be Play-licensed or `PLAY_RECOGNIZED`. Before OPPO proof, configure and verify
the sole current off-Play Dev policy:

- `appIntegrity.allowUnrecognizedVersion = true`;
- `accountDetails.requireLicensed = false`; and
- `deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY`.

The expected Dev SHA-256 must be registered and no App Check debug token may
remain. A debug-provider build/token is deferred and not implemented by this
package.

A registered fingerprint alone is not App Check proof. Missing, invalid,
expired and replayed-token tests remain mandatory.

Durable decision and exact execution order:

- `docs/decisions/ADR-0008-YOUTUBE-PRIVATE-DEV-FIRESTORE-COST-FIRST-CONTROL-PLANE.md`
- `docs/delivery/YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md`
- `docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md`

## YouTube private-Dev deployment and product truth — 24 July 2026

This is the current durable memory and supersedes earlier statements that the
billing account is closed/unlinked or that only two deployment targets exist.

- Billing account `01F9D3-44031C-B5E225` is open and linked only to
  `moolsocial-dev-503018`.
- The founder approved, and Cloud Shell verified, the exact `INR 1,000`
  monthly project-scoped alert with 50%, 80% and 100% thresholds. It is an
  alert target, not a hard spending cap; application-side hard stops remain
  mandatory.
- The local Windows environment has no `gcloud`; use the
  founder-authenticated Google Cloud Shell for required cloud
  inventory/mutation without copying credentials or session material.
- Before any cloud mutation, run the read-only
  `scripts/check-youtube-private-dev-security-prerequisites.ps1` gate. It must
  prove the YouTube-only key restriction, exact Android package/fingerprint,
  required Play Integrity settings, zero App Check debug tokens, keyless
  runtime identity and exact IAM boundary. There is no debug-token exception.
- Firestore must be the qualifying `(default)` database and must report
  `freeTier: true`; stop otherwise.
- `firebaserules.googleapis.com` is required. Deploy exactly
  `functions:provider:youtubeProvider`,
  `functions:provider:youtubeOAuthCallback` and `firestore:rules`.
- `backend/firestore/youtube-private-dev.rules` is the sole source and denies
  every client read/write. After deployment, fetch the active
  `cloud.firestore` release and referenced ruleset through the Firebase Rules
  REST API and prove its sole source exactly matches the repository file.
- Firestore Security Rules do not restrict Admin SDK/privileged server access.
  The keyless runtime service account, narrow IAM and server-side
  authorization/tenant checks are therefore permanent security controls.

Permanent YouTube product/API truth:

- Current project/day buckets are 100 `search.list`, 100 `videos.insert`,
  10,000 `videos.batchGetStats` and 10,000 general Data API units. Private-Dev
  caps stay at 20 searches, 10 uploads, 500 `videos.batchGetStats` calls and
  2,000 general units.
- Later connected comment/rate/subscribe/playlist writes generally consume 50
  general units and require `youtube.force-ssl` with explicit in-context
  consent. They are outside the current readonly/upload/analytics proof.
- The YouTube APIs do not provide personalized Home/native recommendations,
  watch history, Watch Later or an authoritative public Shorts resource/
  `isShort` field. MoolSocial must not clone, claim or infer them.
- Official YouTube playback is only through the IFrame Player inside the
  isolated OS WebView/WKWebView. Changing Flutter/framework does not create
  another compliant player. MoolSocial UI stays outside it.
- Public/unlisted publication remains forbidden. The current direct upload
  proof is private-only until the applicable YouTube compliance audit/approval.
- MoolSocial must not charge for API access, YouTube data or access to YouTube
  functionality. Chargeable value must remain independently owned MoolSocial
  commerce, workflow, attribution, analytics, team or managed-media service.

Official authorities:

- <https://developers.google.com/youtube/v3/determine_quota_cost>
- <https://developers.google.com/youtube/v3/revision_history>
- <https://developers.google.com/youtube/v3/docs/playlistItems/list>
- <https://developers.google.com/youtube/iframe_api_reference>
- <https://developers.google.com/youtube/terms/required-minimum-functionality>
- <https://developers.google.com/youtube/terms/developer-policies>
- <https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps>
- <https://firebase.google.com/docs/firestore/security/get-started>
- <https://firebase.google.com/docs/firestore/security/rules-conditions#authentication>
- <https://firebase.google.com/docs/reference/rules/rest>
- <https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys>

## Dev App Check and YouTube-centred Screen 04 checkpoint — 24 July 2026

The live Firebase App Check REST configuration for the Dev Android app has
been corrected for physical off-Play OPPO testing:

- one-hour token TTL;
- unrecognized off-Play app versions allowed;
- Play licensing not required; and
- minimum device recognition set to `MEETS_DEVICE_INTEGRITY`.

The prior live `NO_INTEGRITY` result is a closed configuration regression. A
paginated App Check REST inventory reports zero registered debug tokens. App
Check enforcement and real-token/rejection/replay proofs are not complete, and
no debug-provider exception is permitted.

The service-level App Check inventory contains only Firebase Authentication,
with baseline protection `UNENFORCED` and replay protection off. No Firestore
service configuration is present. Do not enable either service until the exact
physical-OPPO token acceptance and negative-token matrix passes.

Screen 04 may now be materially restructured after provider proof so YouTube
is the primary Social engagement centre. “No layout boundary” does not remove
provider, accessibility, branding, truthful-data or approved-reference gates.
It does remove the earlier editable-candidate constraint that the current rail
and sub-action placement must remain byte-identical: the next HTML candidate
may revise that hierarchy when real provider behavior warrants it, while
preserving discoverable Mool, Chat, Videos, Shorts and proprietary Feed/Create
journeys and leaving every immutable reference untouched.
The experience is MoolSocial-designed around real YouTube metadata and the
unmodified official player; it must not be an indistinguishable YouTube clone.

The durable next-candidate contract is
`docs/delivery/SCREEN-04-YOUTUBE-CENTRED-INTERACTION-CONTRACT-20260724.md`.
The complete supported/deferred/unsupported capability classification is
durable at
`docs/delivery/YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md`.
Its next provider priorities are the official embedded-player runtime and
WebSub refresh for approved channels; neither permits a personalized YouTube
Home/Shorts clone.
The binding contracts are
`docs/delivery/YOUTUBE-EMBEDDED-PLAYER-RUNTIME-CONTRACT-20260724.md` and
`docs/delivery/YOUTUBE-WEBSUB-APPROVED-CHANNEL-REFRESH-CONTRACT-20260724.md`.
The active Screen 04 HTML remains `DRAFT / HOLD`. Founder `FINAL` is still
required before a new immutable freeze or Flutter presentation change.

The corrected public-catalogue and owner P1 server contracts independently
pass `116/116` backend tests and the full private-Dev package gate. Evidence is
at
`artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.
This is local contract proof only; live cloud/provider, player, WebSub, revised
HTML, Flutter and OPPO gates remain open.

The read-only Dev cloud inventory is at
`artifacts/quality/youtube-private-dev-readiness-20260724-03/READ-ONLY-CLOUD-INVENTORY.md`.
It confirms billing is linked and the live YouTube quotas are present, but
Firestore, workload APIs, provider secrets and the dedicated runtime identity
remain absent. No cloud service was enabled.

## Disabled YouTube player and WebSub local checkpoint — 24 July 2026

The official-player and approved-channel WebSub foundations are now locally
implemented and verified, but remain disabled and unexported.

- The player uses one provider-only bootstrap, stable MoolSocial origin, typed
  commands/events over one exact-origin transferred `MessagePort`, a one-player
  lease and lifecycle pause/dispose rules. There is no `JavaScriptChannel`,
  `addJavascriptInterface`, injected window bridge, WebKit handler, WebView
  plugin or Screen 04 wiring.
- Standard 320 CSS-pixel presentation must allocate at least `320×200`; a
  `320×180` 16:9 iframe is below YouTube's minimum. Verified vertical Shorts
  may use 9:16. Provider controls, attribution, links and advertising remain
  unobscured.
- WebSub accepts only founder-approved channel topics, verifies capabilities
  and exact raw-body HMAC, rejects unsafe/bounded XML failures, derives
  idempotent events and plans lease renewal and atomic refresh quota.
- Player/private-client tests pass `47/47`; backend tests pass `153/153`
  including `37` WebSub cases; package/lock/diff/forbidden-bridge/export scans
  pass.

Evidence:

- `artifacts/quality/youtube-embedded-player-local-20260724-01/LOCAL-PLAYER-FOUNDATION-EVIDENCE.md`
- `artifacts/quality/youtube-websub-local-20260724-01/LOCAL-WEBSUB-FOUNDATION-EVIDENCE.md`

This does not authorize Screen 04 or Flutter presentation changes and does not
prove provider playback, live WebSub delivery or OPPO acceptance. Screen 04
remains `DRAFT / HOLD` until live provider proof informs the revised HTML and
the founder marks that exact state `FINAL`.

### Founder-approved private-Dev monthly budget alert

On 24 July 2026 the founder approved `INR 1,000` as the exact monthly Google
Cloud private-Dev budget alert for `moolsocial-dev-503018`, with 50%, 80% and
100% current-spend notifications. The earlier INR 3,000 payment remains an
account payment and is not this monthly decision. A Google Cloud budget is an
alerting control, not a spending cap; application quota hard stops, disabled-
by-default capabilities, max instances and supervised provider gates remain
mandatory.

The matching live project-scoped budget was created and re-read as the only
budget on billing account `01F9D3-44031C-B5E225`. Its durable evidence is
`artifacts/quality/youtube-private-dev-budget-20260724-04/LIVE-BUDGET-EVIDENCE.md`.

After that budget passed, the exact reviewed prerequisite/provider APIs were
enabled or idempotently confirmed. Data Connect, Cloud SQL Admin and YouTube
Reporting remain disabled. Evidence:
`artifacts/quality/youtube-private-dev-api-prerequisites-20260724-05/LIVE-API-PREREQUISITE-EVIDENCE.md`.

### Keyless private-Dev provider identity

The YouTube provider runtime identity is now live in the exact Dev project.
It is keyless, has only Datastore User and App Check Token Verifier at project
scope, and permits the reviewed founder-domain deployer to act as it through
one service-account-scoped Service Account User binding. Never broaden these
roles, create a service-account key or attach this identity to an unrelated
workload.

Evidence:
`artifacts/quality/youtube-private-dev-runtime-identity-20260724-06/LIVE-RUNTIME-IDENTITY-EVIDENCE.md`.

### Cost-first Firestore boundary is live

The exact Dev project has one Firestore Standard Native `(default)` database
in `asia-south1`. It reports free-tier eligibility, delete protection on, PITR
off, and zero TTL policies, backup schedules or retained backups. It stores
only encrypted YouTube provider control state; no MoolSocial or YouTube media
bytes may be stored there.

The database initially had no active `cloud.firestore` Rules release. Before
any endpoint or capability activation, deploy the repository's exact deny-all
Rules source and independently verify the active release/ruleset. Never infer
client denial from database creation alone.

Evidence:
`artifacts/quality/youtube-private-dev-firestore-20260724-07/LIVE-FIRESTORE-EVIDENCE.md`.

### Restricted private-Dev secrets checkpoint

The private-Dev server API key inventory contains exactly one reviewed key,
UID `08aabcbf-8716-4974-adf9-62de98c9e125`, restricted only to
`youtube.googleapis.com`. The secret value is held only in Secret Manager as
`YOUTUBE_SERVER_API_KEY`; it must never appear in source, chat, logs,
screenshots or evidence.

The two token-encryption secrets
`YOUTUBE_TOKEN_ENCRYPTION_KEY_V1` and
`YOUTUBE_TOKEN_ENCRYPTION_KEY_V2` contain distinct 32-byte random values
generated and transferred inside Cloud Shell without display. Each of the
three live secrets has exactly one enabled version and one accessor binding
for the dedicated runtime identity. V2 is the current write key; V1 is
rotation compatibility only.

The founder's monthly private-Dev budget alert remains exactly `INR 1,000`,
with 50%, 80% and 100% alerts. It does not hard-stop spend.

OAuth remains an explicit founder-owned gate. Never invent or placeholder the
consent support email, Privacy Policy URL, Terms URL,
support/revocation/deletion URL, test users, dedicated Dev channel, OAuth
client ID or client secret. Do not deploy the provider Functions until those
inputs and both OAuth secret versions pass the exact security preflight.

Evidence:
`artifacts/quality/youtube-private-dev-restricted-secrets-20260724-08/LIVE-RESTRICTED-SECRETS-EVIDENCE.md`.

## YouTube official-method and private-Dev Auth checkpoint — 25 July 2026

This is the current durable YouTube checkpoint. It supersedes earlier memory
statements that Reporting remained disabled, no Google Auth brand/client
existed, or only four proof profiles controlled the private-Dev surface. Those
earlier statements remain historical evidence of the implementation sequence.

- The official inventory contains `99` methods with no silent gap:
  `87` are implemented locally through the privileged backend, typed native
  Flutter contracts and focused tests; `8` remain provider/representative/
  content-owner/channel/programme eligibility gated; and `3` are unsupported,
  deprecated or have no approved MoolSocial customer value.
- `liveChatMessages.streamList` is the one intentionally disabled transport
  gap. The present generated-stub and long-lived streaming architecture cannot
  bridge it safely. Bounded read-only live chat uses
  `liveChatMessages.list` behind the `Live` proof profile.
- “Implemented locally” is not a customer or provider claim. It proves
  disabled plumbing, typed contracts and tests only.
- The exact Dev project now has `youtube.googleapis.com`,
  `youtubeanalytics.googleapis.com` and
  `youtubereporting.googleapis.com` enabled.
- The external Google Auth Platform brand and dedicated confidential backend
  OAuth client now exist for private Dev. Identifiers, secrets, tokens and
  review credentials remain outside source, evidence and chat. Secure secret
  custody, test-user consent and live reconciliation remain open.
- The seven proof profiles are `PublicData`, `OwnerConnect`, `OwnerActions`,
  `CreatorAssets`, `Live`, `PrivateUpload` and `OwnerAnalytics`. Every profile
  defaults to `false`, may be enabled only for one supervised proof, expires
  within at most 30 minutes and returns to `false` after proof or rollback.
- There is still no verified live public-data response, provider playback,
  owner connection/action, creator asset mutation, live operation, private
  upload, Analytics/Reporting result, physical OPPO provider acceptance or
  customer availability. Do not describe the Social YouTube surface as live.
- Screen 04 remains governed by the full observed-provider -> editable HTML ->
  founder `FINAL` -> immutable freeze -> native Flutter -> connected-OPPO
  acceptance sequence. Cloud configuration cannot bypass this design gate.
- Merchant API and Google Ads Demand Gen remain deferred to the signed-in
  Workspaces module. They are not part of Social, the YouTube OAuth client or
  the current private-Dev proof.

## Founder gate — public YouTube viewing on physical OPPO first, 25 July 2026

The founder narrowed the immediate private-Dev milestone to one supervised,
reversible proof before any creator-channel workflow advances:

1. preserve the accepted Screen 04 native Flutter presentation and its
   approved navigation contract;
2. install the exact Dev APK on the connected OPPO;
3. prove that the installed package obtains genuine Firebase App Check
   attestation through Play Integrity, with no App Check debug token;
4. activate only the `PublicData` proof profile for a short, explicit expiry
   window;
5. show real eligible public YouTube catalogue data and official embedded
   playback inside Screen 04 on that OPPO;
6. preserve screenshots, logs, APK checksum, installed-package checksum and
   the post-proof rollback result; and
7. return every YouTube proof profile to disabled immediately after the proof.

`OwnerConnect`, `OwnerActions`, `CreatorAssets`, `Live`, `PrivateUpload` and
`OwnerAnalytics` remain disabled and deferred until the founder accepts the
physical-OPPO public-viewing result. Creator connect, publishing, upload,
Analytics, Reporting and channel-management UI must not be presented as
available during this gate. `PrivateUpload` additionally remains blocked
pending a server-revocable upload gateway; a raw resumable YouTube upload URL
must not be issued to a device.

This gate authorizes backend/runtime integration and physical proof only. It
does not authorize a new Screen 04 HTML revision, a new immutable reference,
or presentation changes beyond the already accepted Flutter contract. Any
provider-observed presentation change still follows the editable HTML,
founder `FINAL`, immutable freeze, native Flutter parity and OPPO acceptance
sequence.
