# QA-005 — Ride production vertical slice

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 30–35
- Bike, Auto and Cab entry from the Universal Mool action
- Pickup, destination, scheduling, vehicle, fare and payment-method review
- Captain match, verified vehicle, arrival actions and pickup confirmation
- Live trip, add stop, fare review, safety actions and destination completion
- Explicit post-trip payment approval, receipt, rating and ride-again
- Missing item, fare, route and safety support with attached trip evidence

## Dedicated black-box coverage

- Scenarios: 9
- Passed after exact defect replays: 9/9
- Universal entry plus Ride affected suite: 24/24
- Covered outcomes: successful, empty, invalid, duplicate, cancelled, loading,
  booking failure, payment failure, support failure, retry, no duplicate
  transaction/case, compact phone, large text and cross-journey state.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Ride content collapsed beneath the bottom navigation | The dock's child `Column` expanded to the maximum height offered by the shell | Made the dock content measure to its children with `mainAxisSize: MainAxisSize.min` | Mool → Ride → Auto → Set Auto: pickup, destination, fare and booking action remain reachable above the dock: passed |
| Closing pickup or add-stop sheets could throw during their exit animation | A page-owned controller was disposed before the overlay completed unmounting | Moved each controller into an owned stateful sheet and dispose only after unmount | Edit pickup → save → sheet closes; Add stop → review fare → confirm: no exception and intended state opens: passed |
| Invalid pickup, scheduled time or added stop appeared to do nothing | The correction was rendered behind the active bottom sheet | Added validation beside the active input before any state mutation | Submit empty/short pickup, schedule and stop → visible correction → correct value → continue: passed |
| Ride section headings and support confirmation overflowed on compact or text-scaled devices | Natural-width title and action rows had no flexible text boundary | Added `Flexible`/`Expanded` boundaries and retained minimum tap targets | Replay booking, receipt and support at compact width and scaled text: no overflow: passed |
| Shared icon segments could overflow at compact width | Fixed segment padding and icon spacing consumed the available row width | Use compact horizontal padding and icon gap when a segment includes an icon | Open all Ride vehicle and fulfilment segments at compact width: all labels remain readable: passed |
| Selected missing-item and compliment labels were unreadable on the OPPO device | `FilterChip` selected foreground styling did not remain legible with the production navy fill | Replaced the two Ride choice groups with the shared deterministic `MoolSegment` control without changing the global chip theme | Receipt → select compliment; Support → Item missing → Phone: selected labels remain visible on automation and OPPO: passed |

## Affected-journey rerun

- Ride dedicated suite after fixes: 9/9 passed.
- Universal entry plus Ride suite: 24/24 passed.
- Analyzer after all fixes: no issues.
- Exact failed booking replay: one successful retry creates one booking.
- Exact failed payment replay: no money is marked paid before retry; one retry
  creates one receipt.
- Exact failed support replay: one retry creates one case without duplication.

## Full regression

- Independent full application cycle 1: 74/74 passed.
- Independent full application cycle 2: 74/74 passed.
- A proposed global chip-theme change was rejected when the existing Buy
  golden detected a 2.51% visual regression. The global change was reverted.
- Final full application regression after the local selected-label fix:
  74/74 passed.
- Android debug APK built successfully for `com.moolsocial.app` with
  `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`.
- Non-blocking build warning: several current plugins still apply the Kotlin
  Gradle Plugin directly and must be upgraded before a future Flutter version
  removes that compatibility.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Preserved authenticated setup → Universal Social: passed.
- Universal → Mool → Ride → Auto → Set Auto ride: passed.
- Book Auto → captain arriving → confirm pickup → live trip: passed.
- Reach destination → approve the final ₹112 card payment → receipt: passed.
- Receipt → Support → Item missing → Phone: selected state and report action
  are readable and reachable.
- Device-discovered selected-label defect was fixed locally, rebuilt,
  reinstalled and replayed from the required Ride entry state.
- Evidence:
  - `artifacts/device/moolsocial-production-ride-booking-device.png`
  - `artifacts/device/moolsocial-production-ride-arriving-device.png`
  - `artifacts/device/moolsocial-production-ride-live-device.png`
  - `artifacts/device/moolsocial-production-ride-payment-device.png`
  - `artifacts/device/moolsocial-production-ride-receipt-device.png`
  - `artifacts/device/moolsocial-production-ride-support-device.png`
  - `artifacts/device/moolsocial-production-ride-support-selected-fixed.png`

## Current gate

The Ride vertical slice is GO for continued production implementation against
the deterministic gateway interfaces. Real map routing, live captain supply,
telephony, emergency-provider integration and payment-provider certification
remain external launch gates; the UI does not claim those external
confirmations today.
