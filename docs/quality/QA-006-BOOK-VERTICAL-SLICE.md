# QA-006 — Book production vertical slice

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 36–56
- Book master entry with Doctor, Salon and Get It Done decisions
- Doctor clinic, hospital OPD, video and follow-up choices
- Patient/family selection, child age, symptoms, reports and medical consent
- Verified clinic invite, patient approval, private follow-up workspace,
  reports, reminders and sharing control
- Salon service and visit mode, price, slot, add-ons and payment choice
- Confirmed salon slot, route, reschedule/cancel, check-in, queue, final bill,
  rating, repeat booking and saved-record support
- Get It Done city, task, exact instruction, helper fee, spend cap and
  protected hold
- Verified helper, live status, proof/bill review, explicit release, unused
  return, receipt, rating and helper preference
- Wrong proof, incomplete task, overcharge and safety support through case,
  decision and saved resolution

## Dedicated black-box coverage

- Scenarios: 11
- Passed after exact defect replays: 11/11
- Universal entry plus Book affected suite: 27/27
- Covered outcomes: successful, empty, invalid child age, missing consent,
  duplicate submit, cancelled, loading, provider/slot failure, payment
  failure, helper-match failure, release failure, support failure, resolution
  failure, retry, no duplicate transaction/case, compact phone and large text.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Voice search and Universal regression expected the former generic Book sheet | Book intents now correctly open dedicated production routes | Updated recovery and return assertions to the real Doctor route and its preserved Social return | Social → Voice → “book a doctor” → Doctor → remount required clean Social state → Profile/Chat → back: passed |
| Re-entering a test section reused the previous router | The test harness mounted the same stateful app key | Force a new app/router key whenever a clean section state is required | Doctor voice route → clean Social start → account controls and Chat return: passed |
| Main Mool → Book still opened the old generic intent card | The command palette used the generic `/app/book` route for every action | Route the Book main action directly to `/app/book/home` | Universal Social → Mool → Book: production Book master appears in one tap with Get It Done, Doctor and Salon: passed on automation and OPPO |
| Book section titles wrapped awkwardly beside helper copy on the physical compact-width device | Title and detail competed in one horizontal row | Stack the customer title and its short decision hint vertically | Mool → Book and every titled Doctor/Salon/Task section at 360 logical pixels: readable with no clipped intent: passed |
| Book master and Get It Done subtitles truncated on the OPPO | Copy exceeded the available one-line app-bar width | Tightened customer-facing copy without removing meaning | Book header/search and Get It Done header on rebuilt OPPO APK: fully readable: passed |

## Exact failed-operation replays

- Doctor confirmation failure retains patient, symptoms, reports and consent;
  one retry creates one appointment.
- Salon slot failure takes no payment; one retry creates one booking.
- Salon payment failure marks no bill paid and states no money was deducted;
  one retry creates one saved bill.
- Get It Done helper failure creates no protected hold; one retry creates one
  active task.
- Payment-release failure moves no money; one retry releases once and returns
  the unused amount once.
- Support attachment failure keeps the payment protected; one retry creates
  one case.
- Resolution failure moves no money and keeps the case open; one retry saves
  one resolution.

## Full regression

- Final full application cycle 1: 86/86 passed.
- Final full application cycle 2: 86/86 passed.
- Analyzer after all fixes: no issues.
- Android debug APK built successfully for `com.moolsocial.app` with
  `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`.
- Non-blocking build warning: several current plugins still apply the Kotlin
  Gradle Plugin directly and must be upgraded before a future Flutter version
  removes that compatibility.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Preserved authenticated setup → Universal Social: passed.
- Universal → Mool → Book: production Book master opened directly: passed.
- Book → Doctor: verified appointment, care choices, need choices and sticky
  next action are readable and reachable.
- Book → Salon: service, place, price, slot, verification and review action
  are readable and reachable.
- Book → Get It Done: city, task, exact instruction, proof rule and review
  action are readable and reachable.
- Evidence:
  - `artifacts/device/moolsocial-production-book-home-device.png`
  - `artifacts/device/moolsocial-production-doctor-device.png`
  - `artifacts/device/moolsocial-production-salon-device.png`
  - `artifacts/device/moolsocial-production-task-device.png`

## Current gate

The Book vertical slice is GO for continued production implementation against
deterministic gateway interfaces. Live doctor/hospital licensing feeds,
medical-record storage certification, provider availability, maps, telephony,
real payment/hold/refund rails, helper identity checks and safety operations
remain external launch gates; the UI does not claim those integrations are
certified today.
