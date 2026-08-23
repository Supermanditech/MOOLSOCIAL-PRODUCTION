# C16C Buy sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-BUY-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16C`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Shop, Wholesale, Medicine and Orders are all captured
  in the completed r60.15 OPPO audit.

## Customer outcome

Buy customers retain direct Shop, Wholesale, Medicine and Orders destinations
in one compact professional family without an edge-to-edge horizontal lane,
overflow cues or product-grid displacement.

## Reuse and duplicate decision

- Reuse `BuyV2Session.activeDockDestination`, `openDestination`, `openOrders`,
  all existing destination views, routes, catalogue/cart/order state and
  callbacks.
- Reuse the qualified C16A `MoolLocalNavigationRail`, action and token owners.
- Replace `_BuyDestinationTabs` with a mapping method that returns the shared
  owner; remove `_BuyDestinationTabsState` and `_BuyLocalRailCue`.
- Preserve the public keys `buy-local-destination-tabs` and
  `buy-local-tab-shop/wholesale/medicine/orders` for truthful test continuity.
- Duplicate search is complete. No new screen, route, action, backend, service,
  business state or commercial owner is necessary.

## Minimum complete scope

1. Map Shop, Wholesale, Medicine and Orders to the shared owner and their
   existing one-tap callbacks.
2. Remove the horizontal scroll lane, reveal controller, item-width expansion
   and overflow cues.
3. Keep every target at least 44x44 with uniform tokens and inert selected state.
4. Prove all Buy content/grid/mini-cart hit targets remain reachable above the
   transparent navigation stack.
5. Prove compact and 140% text geometry, finite selection motion and immediate
   reduced motion without any commercial-logic change.

## Explicit exclusions

- No product, catalogue, pricing, promotion, cart, order, medicine, wholesale,
  scanner, checkout, payment, copy, inventory or backend change.
- No filler action, menu, modal, palette, extra tap or horizontal strip.
- No screenbook write or HTML-to-Flutter copy.
- No build, install, credentials, provider/customer communication, payment or
  fund movement, Production, commit, push, deploy or promotion authority.

## Gate plan

- C16C static duplicate-lane/cue absence and business-owner preservation gate.
- Buy focused four-action compact/140%-text/semantics/reduced-motion tests.
- Existing Buy V2, C16A, C11 placement/motion and hit-target regressions.
- Regression memory, MVP scope and delivery-discipline gates.
