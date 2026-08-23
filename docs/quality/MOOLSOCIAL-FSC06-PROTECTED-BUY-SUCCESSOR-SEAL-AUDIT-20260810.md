# FSC06 protected Buy successor seal audit

## Decision

The C25F predecessor baseline remains preserved byte-for-byte. FSC06 creates an
additive pending-OPPO successor seal because the founder explicitly directed a
truthful disposition for the duplicate Products destination and the bounded
audit found no genuine independent Offers outcome.

## Exact protected delta

The 43-file protected Buy inventory is unchanged. One protected runtime owner
changed:

- `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart` removes the Products local
  action, changes the Shop local action count to two, maps Wholesale and Orders
  to their new local indices, and keeps the existing Shop family root as the
  one-tap default route.

No Buy catalogue, product data, cart, checkout, coupon, payment offer, order,
recovery, provider, gateway, persistence, session or backend owner changed.
Existing Offers data remains transaction-contextual. No Offers screen, route or
filler content was added.

The shared catalogue change in
`apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart` is outside the
Buy protected tree and removes only the matching Products action entry. The
shared Shop family route remains `/app/buy?sub=shop`.

## Identity

- Predecessor portable tree:
  `37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7`
- FSC06 portable tree:
  `6e2c18af399d8c2e0a3ab8cb63d76d5e32228f2ea69d26f0d1df662c3f3bbd8e`
- File count: 43 in both trees.

## Host verification before seal activation

- Focused Shop catalogue, real-router and route-continuity group: 19 passed.
- Shared six-family fitment/accessibility group: 33 passed.
- Cross-family route/navigation group: 17 passed, 1 pre-existing skip.
- Flutter analysis: clean.

This successor seal protects the authorized source state only. It is not an APK
candidate, does not qualify Android exported semantics and does not resolve
C28D. Build, install and OPPO acceptance remain closed.
