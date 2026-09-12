# Work Store post-approval premium UI/UX audit — 2026-09-03

> Planning disposition: findings 59–92 remain valid evidence, but their earlier implementation grouping is superseded by `work-store-live-master-ticket-register-20260903.md`, which combines them with the Store master plan and the latest MoolSocial Store Live architecture.

## Scope and status

- Read-only founder audit of the approved Store Workspace from the live dashboard onward.
- Time boundary reviewed: work produced between 01:00 and 22:36 IST on 2026-09-03.
- Current reviewed source head: `ef8c8aea45a6eb572ff0b2552b862cc5405d2a2d`.
- Latest OPPO candidate already installed: `1.0.0-r62.56-runtime` (`2026090312`).
- Coverage: 31 primary screens/destinations, 13 operational sheets/live states and 14 connected journeys.
- Evidence: current 412 x 915 captures at 1.4x text scale, existing OPPO flow captures, current route/wiring declarations and current Work session state.
- No source, route, session, APK, device or backend change is part of this audit.

## Product verdict

The Store now has broad functional coverage and the important routes are connected. It is not yet a final premium busy-retailer experience. The main issue is operational hierarchy: the dashboard exposes several simultaneous navigation systems, while some frequent destinations still use oversized cards, large empty areas or explanatory copy. A retailer should be able to see what needs action, act with one tap or swipe, and immediately understand money, stock, delivery and customer consequences.

The next implementation should retain the accepted search/header placement and bottom Store rail, but make the centre of the screen a denser, state-driven operating surface. Configuration should remain in Settings. Daily actions should be visible only when relevant.

## Screen and journey inventory reviewed

### Store shell and live work

1. Store dashboard — quiet/idle.
2. New app order.
3. Packing in progress.
4. Ready for customer pickup.
5. Delivery assignment/progress.
6. Customer invoice ready.
7. Store-wide search, results, keyboard and completion.
8. Needs your attention.
9. Business action drawer.
10. Store state, visibility and settings.

### Orders, sales and delivery

11. Orders — Live, New, Packing, Ready and Done.
12. Compact order ticket.
13. Reject order decision.
14. New Sale.
15. Deliver Order.
16. Complete this order.
17. Delivery desk and delivery request.
18. Handover OTP/completion.
19. Invoice delivery by MoolSocial Chat or WhatsApp.

### Products and sourcing

20. Store catalogue and low-stock state.
21. Add/Edit complete public product record.
22. Import products.
23. Barcode scanner handoff.
24. Wholesale and Bulk in-Store host.
25. Group Bulk Buying create flow.
26. Active paid Group Bulk Buying lead.

### Customers, money and growth

27. Customer records and purchase statement.
28. Repeat basket.
29. Custom date range.
30. Customer-specific Chat handoff.
31. Sales and settlements.
32. Settlement review.
33. Grow.
34. Store offers.
35. Publish funded Store work.
36. Promote Store handoff.

### Store identity and connected global surfaces

37. Customer storefront preview.
38. Store product detail.
39. Exact public Buy product handoff and return.
40. Delivery area and charges.
41. Staff and counters.
42. Approved business record.
43. Workspace switcher.
44. Global Profile and global Chat return.

## Registered findings — continue after closed defect 58

### P0 — correct before the next founder APK

#### 59. The Store shell has four competing navigation layers

The header actions, right-side live bubbles, bottom floating commands, business drawer and persistent bottom rail all compete for attention. Several destinations are reachable from more than one of these layers. Keep the accepted bottom Store rail and top search. Use one compact live-status strip in the centre; show a contextual first-tap action only when that action is due.

#### 60. The quiet dashboard gives the largest area to an empty explanation

`Ready for customer activity`, `will rise here automatically` and `Completed activity moves to history` occupy most of the first viewport without helping the retailer run the day. Replace this empty deck with a compact operating pulse: orders needing action, packing due, delivery due, low stock, available settlement and customer follow-ups. When every value is zero, use a short one-line ready state, not a full card.

#### 61. The dashboard does not retain a compact daily business pulse while live work is shown

An incoming order replaces almost all daily context. Keep live orders dominant, but retain one slim row for `Orders`, `Sales today`, `Low stock` and `Available to settle`. This gives the screen the live-market quality requested by the founder without adding a new destination.

#### 62. Current 1.4x layouts still clip or split actionable labels

The current captures clip `Buy stock` and `Group bulk`; the delivery state splits `Assigned`, `Delivered` and `Confirm handover`. These are functional reading defects. The command dock and delivery controls need text-scale-safe labels, minimum widths and single-line fallbacks.

#### 63. Store status is repeated without a single clear control owner

`Open / Public`, `STORE LIVE` and additional state bubbles repeat the same condition. Show store name plus one compact state control in the header. Keep public visibility in Settings/Storefront and show it in the header only as a small state, not as a competing command.

#### 64. Incoming-order decisions expose duplicate action paths

The same card presents `Review now`, Reject, Accept and swipe instructions. Keep swipe actions for speed and one `View order` tap for detail. Remove the explanatory swipe sentence after the first guided use. Add the promised fulfilment time/countdown and a direct customer call/chat action before acceptance.

#### 65. Packing language and progress do not match the actual units

The card says `3 products reserved for packing` while two product lines are visible because the number represents units. Use `0 of 3 units packed`, show item-level quantity, and provide `Unavailable / Replace item / Contact customer` when a line cannot be packed. The card height must adapt to line count instead of leaving a fixed empty area.

#### 66. Pickup and delivery cards are visually large but operationally incomplete

Pickup uses a large empty card around one action. Delivery repeats assignment state and uses a tiny multi-step row, yet does not keep customer call, address/map, payment/COD, ETA and delivery exception actions visible. Use a compact order header plus an action strip. Make the primary action one line at 1.4x.

#### 67. Status and success messages displace live work

Full-width banners such as `Order is now preparing` and `Order is now ready for pickup` consume the top of the operating surface. They should acknowledge the action briefly, then collapse into the live state within about two seconds. Errors that need action may remain, but should be attached to the affected card rather than carried to another Store destination.

#### 68. Settings contains false affordances

`Today's hours`, `Maximum active orders` and `Order alerts` display chevrons but have no tap handlers in the current source. Either make each row editable or remove the chevron and present it as read-only. A busy retailer must never tap a control that does nothing.

#### 69. Staff access promises functionality the screen does not provide

The screen says permissions are granted individually, but only provides one Store-wide staff toggle and a counter count. Add named staff, role, assigned counter and explicit permissions, or narrow the promise to the functionality actually available in the MVP.

#### 70. Store product capture still lacks a fast complete-product path

The editor is comprehensive but long. Identity consumes the first viewport, while selling price, MRP, stock, visibility and customer media are below it. A retailer adding many SKUs needs scan/match first, then a compact editable commercial block with photo, selling price, MRP, stock and Publish. Advanced product facts can expand only when needed.

#### 71. The shared scanner remains an incomplete acquisition action

The camera handoff still has no visible capture action or unmistakable automatic-scanning state. This is retained as a shared Buy-owner item and must not be implemented in the Work-owned file. Store can consume the corrected scanner after the Buy owner supplies it.

### P1 — daily retailer speed and scale

#### 72. Orders will not scale visually beyond a few simultaneous orders

One large ticket and a wrapped five-chip filter consume most of the viewport. Use compact rows with amount, customer, due time, payment and the next required action. Keep segmented counts such as `New 4`, `Packing 2`, `Ready 1`; move Done into history/filter so the primary strip remains one line.

#### 73. The same action uses inconsistent names across the Store

`New sale`, `Record store order`, `Create customer order` and `Confirm customer order` describe overlapping stages. Standardize the journey as `New sale` for counter billing, `Create delivery order` for phone/Chat delivery, `Review order`, then `Complete sale`. Use the same terms on dashboard, Orders and confirmation sheets.

#### 74. New Sale and Deliver Order duplicate almost the same full screen

Both screens repeat customer, source, product and total controls. Use one fast order composer. `Counter`, `Phone` and `Chat` select how the order arrived; `Pickup`, `Own delivery` and `Mool delivery` select how it reaches the customer. The Deliver shortcut can open the same composer with delivery preselected.

#### 75. Customer entry is a manual dead end instead of a retailer shortcut

The large mobile-number field should search known customers as digits are entered and show recent customers, name and preferred contact channel. This reduces typing, prevents duplicate records and supports repeat sales without creating another page.

#### 76. The sale composer wastes space and weakens product decisions

One small product card sits above a large empty area. Show recent/frequently sold products as dense rows, include product image or category icon, full pack, selling price and available stock, and keep scan/search beside `Add products`. The current truncated title and letter-avatar are not premium catalogue cues.

#### 77. The completion sheet lacks the facts needed for a final decision

`Complete this order` leaves a large blank lower area and omits customer, item count and total. Show a compact bill summary first, then `Customer pickup / My delivery / Mool delivery` and payment. Keep confirm sticky above Android navigation and change only its verb for the selected outcome.

#### 78. Catalogue title and shortcut hierarchy are crowded

`Store catalogue` and `Purchases` collide visually, while Scan, Import, Add, Low stock and Group Bulk compete in one row and clip. Keep `Store catalogue` as the title. Use first-tap Scan and Add, a searchable overflow for Import/Low stock, and retain Buy stock/Group Bulk in the Store command layer.

#### 79. Catalogue rows do not yet feel like the source of the public Store

Generic initial avatars and text-only verified matches weaken confidence. Each owned SKU row should show image, complete product/pack, selling price, MRP, stock, public/private and quick stock/price edit. `Verified catalogue matches` should read `Add from MoolSocial catalogue`; `Use verified match` should read `Add this product`.

#### 80. The editor needs a high-volume SKU mode

The current sequential form is suitable for one detailed product but not hundreds or thousands. Use collapsible groups and keep `Save product` sticky. After scan or catalogue match, prefill identity/regulatory data and ask the retailer mainly for store-specific image, selling price, MRP confirmation, stock and availability.

#### 81. Customer records are too large for a real customer book

One customer card consumes most of the first viewport. Replace it with a searchable compact customer list showing last purchase, total orders, balance due and last contact. Tapping a customer can expand the statement in place or open the existing detail state.

#### 82. High-value customer-retention actions are missing from the customer row

Keep first-tap Call, Chat/WhatsApp, Repeat basket, Send invoice and Send offer. These actions directly support the approved objective of converting phone/counter customers into repeat MoolSocial customers. Do not hide all of them behind another generic menu.

#### 83. Customer periods are visually heavy and the native range title truncates

Week, Month, Quarter, Financial year and Custom use two chip rows; the OPPO date picker truncates its range heading at 1.4x. Use a compact period selector with one `Custom dates` action, and ensure the selected range is visible on return.

#### 84. Money looks stronger than other destinations, but its main action is below the fold

Keep the premium dark surface. Put a compact `Request settlement` action beside the available amount, then show ledger and history. `Financial year` should not force a second chip row at large text scale.

#### 85. Money uses settlement language that is not clear to a shop owner

Replace `Pending fulfilment` with `Sales awaiting completion`, `Requested` with `Settlement requested`, and `Platform and fulfilment adjustments` with `MoolSocial fees and delivery adjustments`. Always show gross sales, deductions, holds and net available as an aligned payment table.

#### 86. Settlement review does not identify the receiving account

`Workspace bank account` is not sufficient for a payment decision. Show bank name and masked account ending, settlement amount, deductions, net payout and expected date. Keep Edit/Cancel available before confirmation.

#### 87. Group Bulk Buying is informative but not first-viewport actionable

The gauge and title consume most of the page; confirmed retailer trust and the next action fall below. Compress the gauge, keep `kg secured / target`, closing countdown, delivered unit price, savings and confirmed retailer names visible together, and pin `Secure my quantity` or the current paid status. Rename `Confirmation paid` to `Your amount paid` or `Amount paid to secure stock`.

#### 88. Grow, Offers and Funded Work do not yet feel like live Store tools

Grow is a sparse icon grid; Offers is a mostly empty form; Funded Work is a long form with no final preview. Add live counts to Grow (`Active offers`, `Repeat customers`, `Paid work open`). Offers should choose products/customers, show a compact customer preview and offer reusable suggestions. Funded Work should end with a concise posting/payment preview before funding.

### P2 — premium identity, connected surfaces and wording

#### 89. Customer Storefront Preview still mixes owner and customer perspectives

The title says Customer Preview, but `Store visibility`, `Make private` and a disabled `Follow` appear in the same content. Use a slim owner toolbar above an exact customer rendering. Remove self-Follow; replace it with a preview-only trust/follower state. The product row must show complete name/pack without critical truncation.

#### 90. Connected global surfaces lose the dedicated Store feel

Global Profile repeats `Active` in its header and Store card. Global Chat contains a generic `Workspace Review` thread after approval and uses the technical title `Workspace Chat / MoolSocial messaging`. Promote exits into a different orange-accent navigation system and uses phrases such as `attributable orders` and `eligible enquiries`. Preserve Store return context, but simplify these surfaces to one active-business state, customer/order-specific conversations, and plain retailer language. Shared Chat/Profile/Promote owners must be coordinated rather than duplicated in Work.

#### 91. Consumer-facing wording audit

The following visible copy is explanatory, internal or unnecessarily corporate and should be replaced during the next UI pass:

| Current wording | Retailer-facing replacement |
| --- | --- |
| Daily controls and store configuration | Open, pause and run your store |
| Controls you may change during the trading day | Today's store controls |
| Resolve the most important store actions first | Orders and tasks needing action |
| Ready for customer activity | Your store is ready |
| New orders and time-sensitive store work will rise here automatically | New orders and urgent tasks will appear here |
| Completed activity moves to history | Completed orders are saved in History |
| Record store order | Create customer order |
| Counter, Phone or Chat sale from your live catalogue | Choose how the customer ordered |
| Record the customer order before requesting delivery | Add the customer and items to request delivery |
| Customer receives the order | How will the customer receive it? |
| Fulfilment | Pickup and delivery |
| Customer relationships | Customers |
| Customer serviceability | Areas you deliver to |
| Owner-controlled access to daily Store operations | Give staff access without sharing payments or business documents |
| Approved details currently used for Store operations | Business details approved for this store |
| 1 document references available | 1 document on file |
| Retailer control - not shown to customers | Only you can see this control |
| Choose the business outcome you want to improve | What do you want to grow? |
| Review assistance | Ask for help |
| Workspace bank account | Bank account ending XXXX |
| Drive attributable MoolSocial orders | Get more orders through MoolSocial |
| Receive eligible customer enquiries | Get enquiries from interested customers |
| Workspace Chat / MoolSocial messaging | Messages |

Keep `Workspace` only where it names the approved business container. Do not use it to describe ordinary Store actions. Standardize `store` capitalization in sentences and retain `MoolSocial` capitalization everywhere.

#### 92. Motion does not yet communicate enough live business state

Current transitions and countdowns provide some motion, but most destinations remain static. Use restrained operational motion only: pulse an action when its deadline is near, animate numeric changes, progress packing/delivery steps, briefly confirm a swipe, and reveal newly arrived rows. Respect reduced-motion settings. Decorative looping animation should not compete with orders or money.

## Recommended next implementation boundary

Implement 59–71 first as one shell and truthfulness pass. Then implement 72–88 by destination, preserving the accepted Store routes and session wiring. Finish with 89–92 as the premium-language and connected-surface pass. This sequence improves the first founder-visible dashboard and first-tap destinations without requiring new backend integrations.

## Shared-owner boundary

- Work-owned: Store dashboard, Store destinations, Store session/state, Store-owned sheets and copy.
- Buy-owned: shared barcode scanner implementation and Wholesale/Bulk internal content.
- Shared/global owner: Chat, Profile and Promote source. Work owns the Store entry parameters and exact return contract, not duplicate global implementations.
- Public Buy owns the final public product rendering; Work owns supplying a complete, correct SKU contract and an exact Store return.

## Audit completion state

- Audit registered only; findings 59–92 are not implemented or claimed fixed.
- Existing closed defects 1–58 remain closed unless explicitly identified above as a new premium/scale issue.
- Shared scanner remains open with Cursor/Buy ownership.
- No APK was built or installed for this read-only audit.
