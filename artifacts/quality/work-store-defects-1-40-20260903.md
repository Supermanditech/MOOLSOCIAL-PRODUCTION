# Work Store — Atomic Defect Context 1–40

Status: founder-authorized implementation batch. This file is the retained product context for implementation, local visual review, one combined OPPO APK, and final OPPO regression.

## Defects 1–20 — primary OPPO audit

1. In-Store Wholesale shows both Shop and Store navigation rails; keyboard mode retains the wrong Shop rail.
2. Store Search opens a separate boxed page instead of using the approved inline Wholesale/Bulk search interaction across Store destinations.
3. `+ Add` opens a prefilled Aashirvaad Atta record instead of a blank retailer-defined product flow.
4. The product editor does not expose the complete public Buy catalogue field contract.
5. Catalogue `Import` has no visible action or destination.
6. Customers, Money, Grow and Storefront incorrectly mark Store current and disable the return action.
7. Procurement highlights Grow and Storefront highlights Today instead of owning correct destination context.
8. Storefront mixes customer-facing status facts with retailer-only controls without explicit Customer Preview framing.
9. Catalogue cards are too large for thousands of SKUs.
10. Stock and Customers duplicate the main Store search owner.
11. Dashboard `Accept` wraps and the order deck wastes operational space.
12. Orders exposes internal commentary, renders `1live`, and clips the Done filter.
13. New Sale and Deliver expose Review actions with zero products/contact; customer fields are not accessibly labelled.
14. Customers says no sale exists while showing an order and uses internal `permitted follow-up` wording.
15. Long-term Store Settings rows are visible but non-actionable.
16. Group Bulk form truncates decision-critical labels and lacks accessible field labels.
17. Grow clips Business support behind the bottom rail.
18. Global Profile truncates the full Store name.
19. Money lacks period context, transaction ledger, settlement history and adjustment drill-down.
20. Store and Wholesale context subtitles/search hints clip on OPPO.

## Defects 21–40 — secondary OPPO and wiring audit

21. Incoming-order `Tap to review` performs no action.
22. Reject confirmation is oversized, visually plain and unpremium.
23. Change Workspace loops back to the same verified dashboard instead of opening a selector.
24. Settings silently discard unsaved drafts on Back.
25. Dashboard status bubbles need compact visible names without enlarging the approved dashboard.
26. Packing and Delivery bubbles open generic Orders instead of the corresponding operational stage.
27. Search and Alerts route into old `/app/retailer/...` screens instead of the current Work Store destinations.
28. Customer Chat, Repeat basket and all period filters are no-op placeholders.
29. New Sale and Deliver barcode scanning is a no-op placeholder.
30. Availability, orders, catalogue and settlement mutations are local-only; catalogue also lacks delete/retire.
31. Store state can represent only one mutable order; beginning another clears the prior order.
32. Order countdown, packing time and packing progress are hardcoded.
33. Delivery captain, vehicle, ETA and progress are fabricated static content.
34. Delivery Chat is a no-op.
35. Handover completes with one tap without QR/OTP confirmation.
36. A missing customer address is presented as confirmed.
37. Order lifecycle does not reserve, decrement or release SKU inventory.
38. Settlement adds gross order value without fee/tax/refund reconciliation, persistence or idempotency.
39. Group Bulk validates then discards entered values and creates no payment-backed request.
40. Group Bulk continues to old `/app/retailer/wholesale`, exiting the Store instead of using the in-Store purchase flow.

## Founder decisions retained

- Keep the approved dashboard footprint; add compact visible names to the right status bubbles.
- Use Wholesale/Bulk inline search as the interaction reference across the complete Store.
- Keep one search owner; remove destination-level duplicate search boxes.
- `+ Add` must create a comprehensive product record matching the public Buy catalogue contract.
- Storefront customer facts must be explicitly framed as Customer Preview; retailer controls remain visibly separate.
- Group Bulk and Wholesale purchases remain inside Store context.
- Implement all defects atomically, validate local screens first, then build and test one combined OPPO APK.

## OPPO review after defects 1–40 — collecting founder corrections

Review candidate: `1.0.0-r62.48-runtime` on OPPO `2b3e0f71`.

1. Store Search is still not the same native inline interaction used by Buy. Replace the rounded field treatment with the Buy-style inline search band across Store.
2. Reject Order still needs stronger visual polish: a more compact decision surface, purposeful colour treatment, clear selected state and balanced actions.
3. Choose your Workspace exceeds the usable OPPO viewport. `Add another Workspace` is hidden behind Android navigation and has native bounds `[0,0][0,0]`.
4. Additional business/work Workspaces must be permission- and approval-based. Content creation is not a separate approval-gated Workspace; it remains available to every signed-in person, including Store owners.
5. Store Settings `Staff and counters` opens GST/tax/bookkeeping assistance instead of staff roles, access, permissions and counter management.
6. `Review assistance` exits Work Store into the legacy Retailer Business Services screen and its separate navigation rail.
7. Store Settings `Delivery area and charges` opens live Orders instead of serviceability, delivery-area, fee and pickup configuration.
8. Add Product truncates field labels at the OPPO text size and provides no persistent Save or visible Cancel/Close action across the long form.
9. The barcode camera does not state that scanning is automatic, shows no active scanning status/motion and provides no capture affordance for users who expect one.
10. Group Bulk Buying truncates decision-critical quantity labels on OPPO.
11. Group Bulk Buying uses a non-searchable selector limited to current Store catalogue products, preventing discovery of Wholesale/Bulk commodities not already stocked.
12. Group Bulk Buying exposes technical wording: `payment service confirms your amount`.
13. Group Bulk closing deadline and door-delivery date are unvalidated free-text fields with no date/time picker, timezone or locked-deadline confirmation.
14. Buy Stock presents a blank white destination for several seconds before Wholesale renders, with no loader, skeleton, retry or status.
15. Wholesale recommendation cards overlap/crop beneath the controls at the OPPO effective text size.
16. The full Store rail remains above the keyboard during in-Store Wholesale search, severely reducing the results viewport.
17. `Complete this order` is non-scrollable and its primary confirmation action is hidden behind Android navigation with bounds `[0,0][0,0]`; the sale cannot be completed.
18. Customer Relationships says there is no customer sale while a live App order for Rakesh is visible on the Store dashboard; Chat and Repeat Basket remain disabled.
19. Customer Relationships lacks the required customer statement/history ledger. Period chips do not filter real purchase rows and Custom opens no date range.
20. Money shows aggregate values but no sale-level or settlement-level ledger with order references, dates, payout status or period-filtered history.
21. `Review and request settlement` immediately requests the full balance without showing amount, bank destination, deductions, expected date or final confirmation.
22. Grow > Offers exits Work Store into legacy Retailer Offers & Campaigns with a separate navigation system.
23. Legacy Offers is not OPPO-responsive: subtitle/filter text truncates and campaign actions collide with the bottom rail.
24. Legacy Offers exposes internal wording such as `MoolSocial + permitted WhatsApp`.
25. Back from legacy Offers does not restore Work Store Grow; it returns into unrelated legacy Retailer operations.
26. `Publish paid work` opens the Earn Today candidate browsing feed instead of a funded requirement/job creation flow.
27. Counter/offline sales cannot generate and send a customer invoice through MoolSocial Chat or WhatsApp.
28. The offline-invoice journey does not acquire/retain that customer in the Store pipeline for repeat purchases and MoolSocial adoption; this action is also absent from the high-visibility dashboard.
29. Promote does not visibly carry or confirm the active Store identity, creating campaign-scope ambiguity for owners with multiple Workspaces.
30. Promote uses an old non-brand visual/navigation system and requires a full premium Store-aligned redesign.
31. Customer Storefront Preview is not an exact Buy/public preview; its product card is not actionable and omits the complete public product detail structure.
32. Customer Storefront Preview falsely highlights `Today` because the contextual rail has no Storefront state.
33. Storefront visibility is ambiguous: the hero says `CUSTOMER VIEW · VISIBLE` while the retailer action says `Private`, which appears to be the current state rather than `Make private`.
34. The approved public trust layer is absent: follow action, trust/reliability signal, ratings, repeat-customer proof, offers and direct Buy entry are missing.
35. Global Workspace Chat clips the `Business` filter on OPPO.
36. Global Chat's `New conversation` banner is oversized and displaces search, filters and conversation content; it should become a compact person-plus action.
37. Packing has no per-item packed controls/evidence; progress is a fixed presentation rather than operational completion.
38. A Pickup order incorrectly changes to `DELIVERY LIVE`, requests a delivery partner and demands a delivery address after `Mark ready`; no customer-pickup completion state exists.
39. The unsaved-settings confirmation is oversized, with stacked full-width actions and the destructive action styled as the primary brand action.
40. Group Bulk and New Sale editable controls expose empty accessible names in the native OPPO hierarchy despite visible labels.
41. A live Store's `Business details and documents` action opens the pre-approval onboarding review state showing `0 of 4` documents and `Decision Pending`, contradicting the active approved Store and replacing Store context.

Collection status: open. Consolidate all founder points before authorizing the next implementation and APK round.
