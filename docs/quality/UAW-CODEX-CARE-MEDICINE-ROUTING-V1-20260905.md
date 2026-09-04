# Care-owned Medicine routing

Ticket: `UAW-CODEX-CARE-MEDICINE-ROUTING-V1-20260905`

Defect: `UAT-BUY-078`

Baseline: `f94cfd4752dd73b58a69568475803d6cf25cb8d0`

## Outcome

Medicine is entered and displayed through the Care route family. Historical Buy Medicine links recover to the matching Care destination without losing product, cart, checkout, order, tracking or recovery parameters.

## Scope

- Make `/app/book/medicine` the canonical Medicine route.
- Redirect historical `/app/buy/medicine` and Medicine-scoped `/app/buy` links to Care.
- Update shared Care navigation, search and intent entry points.
- Preserve the accepted Medicine commerce implementation, catalogue, session, cart and order models unchanged.
- Verify Care navigation, legacy-link recovery, exact parameter continuity and responsive routing.

## Exclusions

- No Buy catalogue, cart, checkout, order, scanner or payment implementation edit.
- No medical advice, pharmacy backend, APK, device or deployment work.
