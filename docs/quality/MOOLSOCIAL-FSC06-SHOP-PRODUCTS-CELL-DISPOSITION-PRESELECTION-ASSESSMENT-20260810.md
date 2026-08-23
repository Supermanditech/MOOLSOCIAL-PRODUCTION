# FSC06 Shop Products-cell disposition — preselection assessment

## Exact outcome

A Shop customer sees Shop as the family root and retains direct Wholesale and
Orders actions, without a second Products cell that resolves to the same Shop
owner. Existing contextual coupons and payment offers remain where they are;
no Offers destination is invented.

## Reuse and duplicate search

The shared family catalogue and the native Buy bottom rail both declare
Products with route `/app/buy?sub=shop`, while the shared Shop root uses the
same route. The exact production owners already support Shop catalogue,
Wholesale and Orders. Offer records are owned inside catalogue/cart/checkout
and have no independent route contract.

Implementation disposition: reuse plus configuration. Remove the duplicate
Products action from the existing shared catalogue and Buy rail, retain the
Shop root, and adjust only the affected navigation tests and counts.

## Robustness coverage

- Shop remains the default one-tap family route.
- Wholesale and Orders remain direct and preserve Back/state behavior.
- Contextual coupons and payment offers are unchanged.
- No Social, YouTube, Feed or Create owner changes.
- No screen, route, backend or provider owner is added.
- C28D remains unresolved and no APK candidate or host qualification is
  implied by this nonbuild ticket.

## Exclusions and dependencies

No Offers screen, route, filler, backend or fake state is authorized. No build,
install, device mutation, credential access, external write, commit, push,
deploy, promotion or Production write is authorized. FSC01 is complete and its
evidence is preserved.

Estimated timeline impact: one day or less, inside the locked 60–75-day plan.
