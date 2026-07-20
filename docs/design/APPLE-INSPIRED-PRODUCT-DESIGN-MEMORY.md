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

## Completion evidence

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
