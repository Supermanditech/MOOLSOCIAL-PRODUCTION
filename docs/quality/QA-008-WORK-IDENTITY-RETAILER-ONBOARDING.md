# QA-008 — Work identity and retailer onboarding vertical slice

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 67–74
- Work opportunity feed, search, filters and recoverable refresh
- Opportunity details, terms, save and application
- New-user handoff from a saved opportunity into My Work
- Existing and alternate mobile-number identity paths
- Business activity and exact work-profile selection
- Unsupported-workspace request without creating a false workspace
- Business details, workplace proof, owner proof and declaration
- Optional GST reminder, proof attachment and later completion
- Review status, failed status check, exact retry and approval
- One or multiple verified workspaces inside My Work
- Grocery and kirana retailer setup through one live product
- Household price, quantity and explicit delivery/collection controls
- Exact return from Chat and Mool to the originating Work screen

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 67 | Find verified work | For You, Nearby, Delivery, Retail and Creator filters; search; empty search; clear; refresh; failed refresh; retry; expand/collapse; proof; save; terms; review and apply |
| 68 | Understand one opportunity | Details; eligibility; payout rule; proof rule; location; expiry; terms; save; apply; failure; retry; duplicate protection; start My Work |
| 69 | Manage work identities | Start My Work; resume review; finish setup; open live workspace; saved opportunity; add another work; switch among multiple workspaces |
| 70 | Choose work type | Products & Trade and every reachable work family; supported profiles; change selection; unsupported request; invalid request; failed request; exact retry |
| 71 | Confirm contact and work details | Account mobile; alternate mobile; invalid number; OTP send failure; resend/retry; exact OTP; remove alternate number; required business fields |
| 72 | Add proof and declaration | Upload and camera choices; permission denial; failed upload; retry; remove; workplace proof; owner proof; review; missing proof; missing declaration; duplicate-submit protection |
| 73 | Complete review | Optional GST now/later; invalid GST reference; GST failure and retry; submitted review; failed status check; exact retry; Chat and exact return; workspace approval |
| 74 | Make retailer workspace usable | Start retailer setup; required product; quantity; purchase price; selling price; incomplete validation; fulfilment choice; setup failure; exact retry; live shop confirmation |

## Dedicated black-box coverage

- Scenarios: 11
- Passed after exact defect replays: 11/11
- Work plus Universal affected suite: 29/29
- Full application regression cycle 1: 110/110
- Full application regression cycle 2: 110/110
- Analyzer after all source fixes: no issues
- Covered outcomes: successful, empty, invalid, duplicate, cancelled,
  loading, retry, permission denied, gateway failure, review failure,
  optional GST, unsupported activity, incomplete retailer setup, compact
  width, larger text, exact route return and multiple workspaces.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Checking the review update crashed the installed debug app after navigation | The local emulator build used a placeholder Firebase API key while the native Firebase Performance SDK still collected automatically on a background thread | Disabled Analytics, Crashlytics, Messaging auto-init and Performance collection in the debug manifest until real Firebase production credentials are supplied | Work → opportunity → application → My Work → proof → review → Check review update → Workspace ready; held for 12 seconds beyond the original crash window, process remained alive, MoolSocial retained focus and logcat contained no fatal exception |
| A protected Work deep link could be consumed before the destination was mounted | Route confirmation was recorded during the navigation transition instead of after the destination frame | Confirm protected route consumption in a post-frame callback only after the destination is mounted | Clean protected Work entry → authenticated mount → intended Work screen appears once without redirect or duplicate navigation |
| Mool opened from Work could close into the previous Social state | The global palette did not retain the Work origin | Record `work` as the Mool origin and restore the exact Work entry when the palette closes | Work → Mool → Work: the Work home returns without browser-back dependence |
| Proof validation could be present without a visually distinct error state | The proof step reused neutral supporting text for required-state feedback | Added customer-facing error styling beside the missing proof and declaration | Review with missing proof/declaration → correction is visible → add proof → accept declaration → submit succeeds |
| Bottom actions and cards could overlap or lose Material behavior in compact layouts | Work cards and action dock did not share one dock-safe scaffold contract | Added a Work scaffold with safe-area spacing, persistent primary action placement and Material-backed cards | Compact width plus larger text → scroll → nested action → completion: no covered control, overflow or lost tap |
| Physical ADB input briefly concatenated three numeric fields | The phone keyboard resized the window while fixed test coordinates continued to target stale locations | Restarted each field replay from the current clean keyboard state and verified values independently | Quantity 24 → purchase ₹48 → selling ₹55, Home delivery on and Store collection off; final Shop ready state verified. This was a test-driver failure, not an application defect |

## Exact failed-operation replays

- Feed refresh failure keeps the current opportunities and exposes one retry.
- An empty search produces a recoverable empty state and Clear restores the
  feed.
- Opportunity application failure retains the same opportunity. Exact retry
  sends one application and does not duplicate it.
- A new user saves an opportunity, completes My Work and can return to that
  exact opportunity to apply.
- Invalid alternate mobile numbers cannot request an OTP. Gateway failure
  keeps the number and exact retry sends one OTP.
- An unsupported work request creates no workspace. Failed submission retains
  the request and exact retry sends it once.
- Proof upload and profile submission failures retain every entered business
  field and existing proof. Exact retry creates one review case.
- GST and review-status failures preserve the same review reference. Retry
  cannot create a second work profile.
- Incomplete or failed retailer setup keeps the product, quantity, prices and
  fulfilment choice. Exact retry makes one retailer shop live.
- Chat opened from review returns to the same review screen. Mool opened from
  Work returns to Work.
- One and multiple verified workspaces remain inside My Work and do not replace
  the personal MoolSocial account.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Preserved authenticated setup → Universal → Mool → Work: passed.
- Work opportunity → details → Review & Apply → saved for new user: passed.
- My Work → Products & Trade → Grocery/Kirana Shop → business details → two
  proofs → declaration → review: passed.
- Review → Check review update → Workspace ready: exact original crash replay
  passed and remained stable.
- Retailer setup → Aashirvaad Whole Wheat Atta 1kg → quantity 24 → purchase
  ₹48 → sell ₹55 → Home delivery on → Store collection off → Finish setup:
  `Shop ready` passed.
- Evidence:
  - `artifacts/device/moolsocial-production-work-earn-device.png`
  - `artifacts/device/moolsocial-production-work-opportunity-device.png`
  - `artifacts/device/moolsocial-production-work-choose-device.png`
  - `artifacts/device/moolsocial-production-work-proof-device.png`
  - `artifacts/device/moolsocial-production-work-status-device.png`
  - `artifacts/device/moolsocial-production-workspace-ready-device.png`
  - `artifacts/device/moolsocial-production-retailer-setup-device.png`
  - `artifacts/device/moolsocial-production-retailer-live-device.png`

## Current gate

The deterministic Work identity and retailer-onboarding slice is **GO** for
continued full-scale implementation. It is **NO-GO** for a public live launch
until production Firebase credentials, employer funding and eligibility,
identity/KYC and document review, GST verification, payouts, catalogue and
inventory sync, delivery availability, payment settlement and moderation are
connected to certified live services. The debug application intentionally
does not claim that those external services are active.
