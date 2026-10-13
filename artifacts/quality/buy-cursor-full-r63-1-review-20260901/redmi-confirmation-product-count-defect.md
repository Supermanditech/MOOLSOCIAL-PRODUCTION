# Redmi defect — confirmation counted units as products

- Candidate: `UAW-BUY-CURSOR-FULL-R63.1-UI-REVIEW-20260901`
- Device: Redmi `TG8HCYTGGQT885OF`
- Source commit: `fcf3e84a1b44205b08fe45b91e098dae240a1cd3`
- Evidence: `redmi-order-confirmation.png`, `redmi-split-confirmation.png`

A wholesale order containing one product with two packs rendered `2 products`. A split purchase containing two distinct products and three total units rendered `3 products`. The confirmation header used `confirmedItemCount` with product wording.

Required correction: retain item/pack quantity accounting for cart, totals and order lines, add an exact distinct confirmed-product count, and use only that count in the confirmation header.
