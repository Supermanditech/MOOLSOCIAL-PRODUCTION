# C24E Book Doctor and Salon Home preselection assessment — 2026-08-09

## Customer outcome and MVP classification

Customers can find the right Doctor or Salon service using search, direct
categories, provider trust, price and availability before the existing booking
journey. This is `mvp_required`: Doctor and Salon are already approved Book
actions and currently expose dense form-first entry screens instead of clear
service discovery homes.

## Smallest complete implementation

- Reuse `DoctorBookingScreen`, `SalonBookingScreen`, `BookSession`,
  `BookGateway`, all existing Doctor/Salon routes and the C24B service-home
  primitives.
- Recompose only the two existing entry owners around search, categories,
  trusted-provider cards, truthful availability/price and direct booking.
- Preserve Clinic, Hospital OPD, Video and Follow-up meanings; preserve Salon,
  Home visit, Makeup and Package modes, add-ons, payment, cancellation,
  confirmation, visit, completion and support behavior.
- Keep Doctor under Book and Medicine only under protected Buy.

## Reuse and duplicate search

The native inventory has one Doctor entry screen, one Salon entry screen, one
shared Book session/gateway and complete downstream routes/tests. No new
screen, route, backend, gateway, persistent state or subaction is necessary.
The disposition is existing-owner `reuse` plus presentation `configuration`.

## Explicit exclusions

- no doctor/medicine merge, Medicine move or pharmacy duplication;
- no Get It Done reactivation, filler category or fabricated provider state;
- no copied reference assets, logos, trade dress or promotional clutter;
- no Social/Buy business-content change;
- no APK build/install, backend/provider/external write, commit, push, deploy,
  promotion or Production action.

## Dependencies, robustness and tests

C24A–C24D are complete and the exact Social/Buy successor protection seals are
active. Focused tests must prove 320/390/430 widths, 1.4 text scale, minimum
44px targets, direct search/category/provider selection, truthful price and
availability, Doctor/Medicine placement, existing downstream booking/error
recovery, connected MoolSocial/Chat/Back continuity and immediate reduced
motion. The estimated impact is one day within the 60–75-day lock.
