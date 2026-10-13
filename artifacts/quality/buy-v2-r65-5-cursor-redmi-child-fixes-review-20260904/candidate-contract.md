# r65.5 candidate contract

Candidate: `UAW-BUY-V2-R65.5-CURSOR-REDMI-CHILD-FIXES-20260904`

This isolated Cursor UI-review candidate verifies only the founder-approved Buy child corrections after r65.4:

- compact Quick-delivery controls, hide/restore behavior and no reserved blank row;
- compact floating Cart action that does not obscure adjacent product actions;
- visible, keyboard-safe scanner manual-code actions and truthful active-scanning feedback;
- accurate product-versus-item quantity wording through Cart, Checkout, confirmation and tracking;
- retained Store, Wholesale and Bulk navigation, cart, payment, order and tracking journeys;
- final `BuyV2ChatRouteAdapter.productLink` contract for later shared Chat integration.

The APK uses the isolated `com.moolsocial.app.cursorreview` package, emulator-backed review runtime and no production backend or payment settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration branches are excluded.
