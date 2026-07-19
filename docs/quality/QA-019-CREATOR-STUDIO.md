# QA-019 — Creator Studio, business-funded Reels and YouTube Connect

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 124–132 and 166
- Creator Studio, native publishing, content library and performance
- Audience, campaigns, earnings, rights, safety and memberships
- YouTube Connect for persistent Shorts and long-form video
- Native promotional Reels funded by verified businesses for 1–7 days
- Every visible control, nested sheet, invalid input, cancellation, loading,
  offline, permission-denied, gateway failure, exact retry and duplicate action

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 124 | Understand creator value and continue the next creator task | Create, Library, Campaigns and Audience; priority campaign; draft review; earnings; performance; channel controls; Studio, Create, Earnings, Mool and Chat dock routes |
| 125 | Publish the correct creator format with truthful funding and rights | Funded Reel, YouTube, Text Post and Image Post; camera/gallery/remove; title and caption; sponsor disclosure; 1–7 day funded duration; automatic expiry; rights; cancelled review; invalid review; failed draft and exact retry; duplicate draft; failed publish and exact retry; duplicate publish; open library |
| 126 | Find and continue content in every state | Published, Drafts, Scheduled and Unavailable; search; no result; clear; filters; every item; rights and availability; open performance; continue editing; replace YouTube connection |
| 127 | Understand attention, demand, verified outcomes and earnings | 7, 28 and 90 days; Content and Campaign views; reach, watch time and engagement; verified-value trend; outcome metrics; top-content detail; privacy explanation; CSV and PDF exports |
| 128 | Understand and engage the audience without exposing private people | Aggregated audience, geography and interests; invite explanation; cancelled share; consented share; no-contact outcome; memberships; audience question; comments; privacy boundaries |
| 129 | Review and accept one funded business campaign | Best Fit, Invited, Active and Complete; filters; every campaign; sponsor, fit, fixed pay, outcome pay, format, geography, disclosure, attribution and deadline; blocked accept without terms; failed accept; exact retry; duplicate accept; create deliverable |
| 130 | Trace creator earnings to the source and prepare a statement | Overview, Ledger and Payouts; every earning record; amount, status, campaign/sale reason and return treatment; failed statement; exact retry; duplicate statement; PDF/CSV availability |
| 131 | Control creator identity, rights, team and account safety | Identity, Profile, Rights, Disclosures, Team, Safety and Security; every control sheet; rights alert; blocked appeal without evidence; failed appeal; exact retry; duplicate appeal |
| 132 | Offer memberships with clear benefits, billing and creator take-home | Eligibility; every membership plan; price, billing, benefits, members and take-home; blocked save without confirmations; failed save; exact retry; duplicate save |
| 166 | Connect persistent YouTube content to one Mool action | Help; channel cancel/connect; invalid URL; failed validation; exact retry; source preview; Buy, Book, Order, Apply, Visit and Chat actions; category, location and reference; optional business-funded discovery for 1–7 days; rights and action-truth confirmations; review; failed publish; exact retry; duplicate publish; open connected content |

## Locked operating rules

- A native promotional Reel is paid for by a verified business, not by the
  creator.
- The creator selects a funded campaign and a precise run of 1, 2, 3, 4, 5, 6
  or 7 days. The creator sees the reserved earning before publishing.
- The native Reel automatically leaves the live campaign when the selected
  duration ends. Its paid disclosure and campaign evidence remain in records.
- Native Reels are limited to 60 seconds in this launch model.
- Persistent Shorts and long-form video remain on YouTube. YouTube Connect
  links one video to one explicit Mool action without rehosting the video.
- A paid YouTube discovery placement may end after 1–7 days; the underlying
  YouTube video remains on YouTube.
- Native text and image posts are separate from paid Reel duration.
- Only verified campaign or commerce outcomes can become payable. Views alone
  are not represented as sales or guaranteed creator earnings.
- Rights, material connection and paid disclosure must be confirmed before a
  funded publication.
- Draft, publish, campaign acceptance, statement, appeal and membership saves
  are idempotent and safe to retry.
- Offline or unauthorized protected actions call no gateway and preserve the
  user’s work.

## Defects discovered, root cause, fix and exact replay

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| CRE-001 | YouTube channel and audience-invite sheets used fixed-height modal bodies and overflowed vertically on a phone | Made the sheets scroll-controlled with safe bounded scroll bodies | Open each sheet at 412 × 915, traverse all content and close: no clipping or blocked action |
| CRE-002 | YouTube location and campaign dropdowns used unconstrained rows and overflowed horizontally | Expanded the fields inside bounded rows and retained readable values | Source → Action → open location and campaign → select each value: no overflow and selection is visible |
| CRE-003 | The library audit retained the Unavailable filter before trying to open a Published item, allowing prior state to create an invalid replay | Reset the required tab before every item replay and mounted each scenario from a clean state | Unavailable → clean Published state → open published item → Performance: correct owner route every time |
| CRE-004 | Four Creator Studio owner actions were compressed into one row, reducing hierarchy and readable action detail | Rebuilt the group as calm two-column action cards with icon, title and outcome text | Screen 124 at 412 × 915 → read and tap all four cards: every label is legible and every owner opens |
| CRE-005 | Several evidence fields exposed internal wording such as “record attached”, “rule included” and “funding rule” | Replaced them with “Confirmed for this content”, “Earning conditions included” and “Why this amount” | Library, export and earning detail → read evidence → close or continue: the user can understand the outcome without implementation terms |
| CRE-006 | Campaign and membership fact labels plus performance-chart labels were below the production supporting-text target | Increased compact supporting labels and values while retaining bounded wrapping | Screens 127, 129 and 132 at 412 × 915: labels remain readable with no overflow |

## Exact failed-operation replays

- Draft failure creates no draft; exact retry creates
  `CR-DRAFT-125-0719` once.
- Funded Reel publish failure creates no Reel; exact retry creates
  `REEL-125-0719` once with a 7-day expiry in the replay.
- YouTube validation failure creates no validation; exact retry creates
  `YT-VALID-166-0719` once.
- Connected YouTube publish failure creates no connected post; exact retry
  creates `YT-POST-166-0719` once.
- Missing campaign terms call no gateway. Acceptance failure creates no
  acceptance; exact retry creates `CR-ACCEPT-129-2048` once.
- Statement failure creates no file; exact retry creates
  `CR-STATEMENT-130-0726` once.
- Missing appeal evidence calls no gateway. Appeal failure creates no appeal;
  exact retry creates `CR-APPEAL-131-2041` once.
- Missing membership-benefit or billing confirmation calls no gateway.
  Membership failure creates no plan update; exact retry creates
  `CR-MEMBER-132-local-insider` once.
- Offline and permission-denied commands preserve all creator work and call no
  protected gateway.

## Independent UI/UX enhancement cycle

The second UI/UX cycle began only after the first dedicated, affected and full
regressions were green.

- Captured and inspected stable 412 × 915 baselines for 13 important states.
- Rebuilt Creator Studio’s main actions as spacious two-column cards.
- Increased compact label readability without adding decorative controls.
- Replaced internal evidence wording with direct creator outcomes.
- Kept business-funded Reels visually and behaviorally separate from YouTube,
  text and image publishing.
- Preserved Apple-inspired calm surfaces, restrained color, clear hierarchy,
  44 px controls, persistent Mool/Chat access and deterministic back paths.
- Preserved every validation, authorization, failure, retry and idempotency
  boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated screens 124–132 and 166 black-box scenarios: 11/11 passed.
- Affected Creator and universal journeys: 70/70 passed.
- Full application regression pass 1: 238/238 passed.
- Initial visual capture: 13/13 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated screens 124–132 and 166 black-box scenarios: 11/11 passed.
- Creator visual baselines: 13/13 passed twice.
- Affected functional and visual regression: 81/81 passed.
- Full application regression pass 2: 251/251 passed.
- Flutter analyzer: no issues.
- Physical OPPO CPH2375 exact replay: 1/1 passed three times.
- The second OPPO cycle used `flutter clean`, fresh dependency resolution, a
  new debug APK build and reinstall.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`, Android 13.
- Package: `com.moolsocial.app`.
- Exact replay: Creator Studio → Funded Reel → 7 days → failed Draft → exact
  retry → failed Publish → exact retry → YouTube Connect → failed Validate →
  exact retry → Buy action and funded campaign → failed Publish → exact retry
  → Campaign → failed Accept → exact retry → Earnings → failed Statement →
  exact retry → Rights → failed Appeal → exact retry → Membership → failed
  Save → exact retry.
- Assertions: every protected ID listed above exists once and all eight
  failed/retried gateway counters equal exactly two.
- Screenshot checkpoints are captured by
  `integration_test/creator_device_replay_test.dart`.
- OPPO/ColorOS denied shell-level uninstall and app-data-clear commands. This
  did not affect isolation: every physical replay mounted a new in-memory
  signed-in journey, injected a new gateway and asserted every outcome ID was
  empty before its first failed action.

## Remaining external blockers

- Creator identity, channel verification, business verification and team roles
  still use deterministic review data.
- YouTube OAuth, channel ownership, Data API quotas, player policy, rights and
  availability need Google/YouTube production integration and certification.
- Native Reel and image upload, scanning, transcoding, CDN delivery and
  scheduled 1–7 day expiry need production media services and lifecycle jobs.
- Campaign budgets, fund reservation, disclosure, attribution, returns,
  earnings ledger, tax treatment and payouts need live business, commerce and
  payment systems.
- Membership enrolment, recurring billing, cancellation, refunds and
  entitlement access need store/payment-provider integration.
- Copyright evidence, moderation, fraud, appeals and safety escalation need
  production policy services and staffed operating procedures.
- Analytics and exports need privacy thresholds validated against live data
  and legal approval.
- The Android build emits a future Flutter migration warning for plugins that
  still apply the Kotlin Gradle Plugin; it is not a current build or runtime
  failure.

## Evidence-based gate

The deterministic Flutter Creator slice for screens 124–132 and 166 is **GO**
for continued full-scale implementation. It is **NO-GO** for public media
upload, YouTube connection, business-funded campaigns, creator earnings,
memberships, rights decisions or payouts until the external systems above are
connected to production services and certified in their sandboxes.
