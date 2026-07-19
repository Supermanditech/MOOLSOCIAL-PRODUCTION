# QA-022 — Shared account, activity, security and controls

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 157–162 and 165
- Activity, identity and consent, universal Ask, files and evidence, security,
  workspace ownership and profile-specific controls
- 39 cards, 56 protected primary/alternative actions and 56 controls
- Every filter, search, empty state, card, nested sheet, fact, step, control,
  schedule, confirmation, action, cancellation, loading, failure, exact retry,
  duplicate, offline and permission-denied outcome

## Screen-by-screen tap and nested-tap coverage

| Screen | Items | Complete user intent coverage |
|---:|---:|---|
| 157 | 5 | All, Required, Orders, Work, Offers and Updates; impossible search and reset; pharmacy renewal, Captain work, pickup order, basket offer and stock assistant; why shown, facts, steps, primary/alternative action, confirmation, failed action, exact retry, duplicate protection and accountable owner route |
| 158 | 4 | Identity, Documents, Consent and Recovery; personal verification, retailer documents, time-limited pharmacy access and alternate recovery mobile; source, recipient, purpose, expiry, update/revoke paths and duplicate-safe outcomes |
| 159 | 4 | All, Buy, Ride, Work and Workspace; invalid empty input, unmatched input, suggested intents, typed intent, camera denial, microphone denial, keyboard recovery, Scan, Voice, failed exact match, exact retry and Buy/Ride/Retailer/Earn owner routes |
| 160 | 4 | All, Identity, Orders, Content and Health; GST, order evidence, creator short and doctor report; Camera, Scan, Gallery and File sources; cancelled picker; review/share/download/delete boundaries and protected retries |
| 161 | 4 | All, Devices, Recovery, Access and Support; trusted devices, passkey/recovery, access history and emergency lock; confirmation, role denial, failure, exact retry and duplicate protection |
| 162 | 9 | All, Personal, Business, Creator, Work and Settings; personal, retailer, creator and freelancer areas plus direct Identity, Ask, Files, Security and Controls owners; every card and persistent Activity/Spaces/Controls/Chat route |
| 165 | 9 | All, Personal, Social, Communication, Workspaces, Agent and Privacy; every one of 56 switches; schedules; locked required alerts/privacy/security; 30-minute, 1-hour and until-tomorrow pauses; subscription boundary; Runs automatically, Asks before action and Never delegated authority |

## Locked operating rules

- Activity explains why an item appears and opens the accountable owner; a
  reminder never completes a regulated, money or work action by itself.
- Identity and documents expose purpose, recipient, expiry and revocation.
  Regulated access is time-limited and never represented as permanent consent.
- Ask resolves one explicit product, service, work or workspace action. Scan
  and Voice never pay, publish or submit automatically.
- Files preserve purpose and access context. Health, identity and payment
  evidence cannot be shared outside an authorized recipient and purpose.
- Security alerts, sensitive-action approval and required privacy boundaries
  cannot be disabled from ordinary preferences.
- Pausing new orders or work does not cancel accepted orders, active work,
  payout tracking or other existing obligations.
- Mool Agent is optional and inactive without a monthly entitlement. Even when
  active, money, public, legal and other sensitive final actions always need a
  fresh scoped owner approval.
- Every protected command is permission checked, failure safe and idempotent.
  A failed, offline, unauthorized or duplicate command cannot create a false
  result.

## Defects, root causes, fixes and exact replays

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| SHR-001 | The universal profile’s Workspaces action targeted the old generic workspace path, so the user could land on a placeholder owner instead of the approved shared hub | Routed Workspaces to `/app/account/workspaces` and added direct Activity and Security owners | Universal Social → profile → Workspaces → Activity → Controls → Spaces → Chat: every owner opens and return context is preserved |
| SHR-002 | Screens 157–162 and 165 had no explicit production routes before the generic `/app/:section` fallback | Added seven explicit routes and one shared state owner before the fallback | Open each approved URL directly and from every reachable card: the correct keyed screen renders, not a generic substitute |
| SHR-003 | The first Agent preview outcome used internal “sample” wording | Replaced it with the visible user outcome and explicit no-change boundary | Controls → Mool Agent → Preview daily brief: today’s preview opens and confirms nothing was sent or changed |
| SHR-004 | Initial nested visual checks captured only the page Scaffold, allowing an open bottom sheet to escape the golden evidence | Captured the full Overlay for Activity and Controls nested states and asserted each detail key before comparison | Activity → pharmacy and Controls → creator: the complete sheet, actions and underlying dimmed page are captured and replayed |
| SHR-005 | A physical replay could falsely inherit previous selections unless every run created fresh session and gateway state | The device harness mounts a new signed-in journey, Shared session and gateway and asserts empty protected outcomes before failure | Ask → fail/retry; Security → deny/fail/retry/duplicate; Controls → fail/retry/duplicate: all counters end at exactly two |
| SHR-006 | The first OPPO replay found the four-source file chooser overflowed its constrained bottom-sheet height by 27 px because the content used a non-scrollable Column | Made file-source and permission-recovery sheets scroll-controlled with a safe scroll body | Ask → Voice denial → keyboard → exact result → Files → Add → Gallery → Security: the original sequence passes with no clipped control or render overflow |

## Exact failed-tap replays

- All 39 card details open from their required clean screen and expose every
  fact, step, reason and reachable action.
- All 56 protected primary/alternative commands reject missing confirmation
  where required, fail once without completion, succeed on exact retry and
  report duplicate completion without a third gateway call.
- Empty Ask input and an unmatched request call no gateway. A failed exact
  product match preserves the words; retry resolves `/app/buy/grocery`.
- Camera and microphone denial expose settings or keyboard recovery. Successful
  Scan states that nothing is paid automatically; Voice requires review before
  search.
- Emergency lock calls no gateway while unauthorized. Authorization followed
  by a failed command preserves the unlocked state; exact retry creates one
  completed lock command.
- Every locked or subscription-required control preserves its previous value
  and explains the boundary. Every ordinary control changes and can be saved.
- Offline and unauthorized actions preserve prior state and selections and
  call no protected gateway.

## Independent UI/UX and wording audit

- Captured and inspected stable 412 × 915 baselines for all seven owner pages,
  the exact Ask result and two nested sheets.
- Replayed all 10 baselines without updating them.
- Preserved calm Apple-inspired surfaces, safe areas, clear hierarchy,
  persistent Mool/Chat access and deterministic back navigation.
- Kept Activity, Spaces and Controls in one consistent dock without adding
  decorative actions.
- Searched the new user-facing source for prototype, demo, mock, review mode,
  adapter, API, placeholder, internal and sample wording. The only result was
  SHR-003 and was corrected.
- Kept legitimate statuses such as GST Pending user-facing because they
  describe actual required work, not implementation state.

## Regression and build evidence

- Dedicated shared black-box scenarios: 20/20 passed.
- Visual baselines: 10/10 passed after generation and 10/10 passed again
  without baseline updates.
- Affected shared and Universal functional/visual regression: 52/52 passed.
- Full Flutter regression pass 1: 309/309 passed.
- Full Flutter regression pass 2: 309/309 passed.
- Post-SHR-006 affected regression: 52/52 passed.
- Post-SHR-006 final full application regression: 309/309 passed.
- Flutter analyzer: no issues.
- Android debug APK: built successfully.
- APK SHA-256:
  `9C43BC90E83221DA396B46B3C0954FEC3EDC69ACE969724700634CF98DBA5171`.
- The first physical OPPO run discovered SHR-006 and failed as required.
- The corrected exact physical replay passed three times; two independent
  clean cycles were screenshot-backed through the integration driver.
- Cycle 1 and cycle 2 checkpoints are byte-identical for each matching state.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`, Android 13.
- Exact replay: empty Ask → microphone denied → keyboard recovery → Voice →
  injected exact-match failure → exact retry → Files → Gallery → emergency
  lock role denial → injected failure → exact retry → duplicate tap → creator
  control → injected save failure → exact retry → duplicate tap → Agent
  subscription boundary → locked sensitive-action boundary.
- Assertions: Ask, emergency lock and creator control each call their protected
  gateway exactly twice and create one completed result; denied and duplicate
  attempts create no extra call.
- Evidence:
  - `artifacts/quality/shared/oppo-cycle-1-shared-159-exact-ask-result.png`
  - `artifacts/quality/shared/oppo-cycle-1-shared-161-emergency-lock-complete.png`
  - `artifacts/quality/shared/oppo-cycle-1-shared-165-agent-boundaries.png`
  - `artifacts/quality/shared/oppo-cycle-2-shared-159-exact-ask-result.png`
  - `artifacts/quality/shared/oppo-cycle-2-shared-161-emergency-lock-complete.png`
  - `artifacts/quality/shared/oppo-cycle-2-shared-165-agent-boundaries.png`

## Remaining external blockers

- Live Firebase identity, device registry, passkeys, recovery, role claims,
  notification delivery and immutable access history require the production
  Google project.
- DigiLocker, GST and regulated-document verification require approved
  provider integration, consent records and policy review.
- Camera, media, document storage, virus scanning, retention, sharing and
  health-data access require production services and legal controls.
- Universal Ask needs production search/index, authorization, inventory,
  maps, work and workspace services.
- Mool Agent needs entitlement billing, scoped authorization, auditable jobs,
  stop controls and fresh-approval enforcement for sensitive actions.
- The Android build emits a future Flutter migration warning for plugins that
  still apply the Kotlin Gradle Plugin; it is not a current build failure.

## Evidence-based gate

The deterministic Flutter shared-controls slice is **GO** for founder review
and continued production-service integration. It is **NO-GO** for public
identity, regulated-document access, security enforcement, cross-workspace
automation or Mool Agent execution until the external systems are connected
and certified.
