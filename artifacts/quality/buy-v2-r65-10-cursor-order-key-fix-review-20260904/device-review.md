# r65.10 Redmi device review

Device: Redmi `TG8HCYTGGQT885OF`  
Package: `com.moolsocial.app.cursorreview`  
Version: `1.0.0-r65.10-cursorreview` (`2026090326`)  
APK SHA-256: `E2A84F2CA0F547FDB7B34AC93EFC7DD0B233A5E4830011FFA1B1C7D9B36D90EA`

## Passed journeys

- Installed APK pull matches the built APK byte-for-byte.
- Retained Orders history with repeated `MS-NEW-01` delivery IDs renders normally: 8 active, 2 delivered, zero duplicate-key/internal error screen.
- `Track order` opens the exact selected order, shows 40% progress, seller, address, products, payment method and five-step delivery timeline; Android Back returns to Orders.
- Fresh Shop order: product Add → compact 64dp Cart → scoped Cart → Address → Payment → PhonePe → confirmation.
- Payment handoff title is exactly `PhonePe · ₹37`.
- Payment return shows `Payment confirmation pending` and `Do not pay again`; `Check payment` reconciles to `Order placed` with the exact ₹37 total and address.
- Scanner shows automatic-scanning status, animated scan line, `Scan now`, manual-code fallback, torch, camera switch and Back.
- Scanner manual-code `Cancel` and `Find product` settle above the keyboard with enabled clickable non-zero Android bounds.
- Quick-delivery expanded controls stay in one row; Hide removes the full rail and exposes the side restore action without reserving a blank row.
- Wholesale and Bulk toggles remain selected/readable; supplier type, delivery promise, product Add and retained compact Cart remain present.
- No customer screen in the replay exposed implementation, review, route, state, prototype or Flutter diagnostic language.

## Evidence map

- `redmi-review-02`: retained Orders after duplicate-key repair.
- `redmi-review-03`: tracking detail.
- `redmi-review-04`: Back returns to Orders.
- `redmi-review-06`: Shop Add and compact Cart acknowledgement.
- `redmi-review-07`: selected PhonePe and enabled Review order.
- `redmi-review-08`: brand-correct PhonePe handoff.
- `redmi-review-09`: pending payment / no-double-payment recovery.
- `redmi-review-10`: reconciled order confirmation.
- `redmi-review-11`: active scanner.
- `redmi-review-12`: keyboard-safe manual-code semantics.
- `redmi-review-13` and `14`: Quick controls and hide/restore.
- `redmi-review-15` and `16`: Wholesale/Bulk.

This remains an isolated UI-review build and does not qualify production backend adapters, settlement, courier GPS or Care/Medicine ownership.
