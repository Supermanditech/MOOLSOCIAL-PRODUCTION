# FSC06 protected Buy baseline rejection — 2026-08-10

`scripts/check-buy-protected-baseline.ps1` correctly rejected the FSC06 runtime
after the founder-authorized Products-cell removal.

- Protected predecessor baseline:
  `buy-protected-candidate-c25f-domain-navigation-20260809-01`
- Expected 43-file portable tree:
  `37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7`
- Observed FSC06 43-file portable tree:
  `6e2c18af399d8c2e0a3ab8cb63d76d5e32228f2ea69d26f0d1df662c3f3bbd8e`

The single protected runtime delta is
`apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`: it removes the local Products
cell, changes the Buy local count from three to two and leaves the shared Shop
root as the default route. No Buy catalogue, cart, checkout, coupon, payment
offer, order, session, provider, persistence or backend owner changed.

The predecessor seal remains immutable. The founder's current direction and
FSC06 preselection authorize an additive successor seal only for this bounded
navigation correction. Final OPPO acceptance remains pending, and this record
does not authorize a build, install or C28D successor.
