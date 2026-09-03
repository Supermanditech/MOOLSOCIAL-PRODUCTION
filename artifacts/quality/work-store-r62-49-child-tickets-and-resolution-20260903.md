# Work Store r62.49 — child tickets and defect-equivalence review

Candidate source: `work/codex-ui/work-core-controls-v1-20260902`

## Child tickets

- `STORE-OPPO-1-8,10-28,31-34,37-41` — Codex Work owner. Implemented in Work models, session, gateway, widgets, dashboard and focused tests.
- `CHAT-OPPO-35-36` — global Chat owner. Implemented and verified with 69 Chat/contextual regressions.
- `PROMOTE-OPPO-29-30` — Promote owner. Implemented and verified with 35 Promote/Social regressions.
- `SCANNER-OPPO-9` — blocked by exact active Buy owner `/root/cursor_shop_mvp_go_live_v1_20260829`; no overlapping mutation was made. The Buy owner must add automatic-scan wording/motion and its focused regression.
- `STORE-LIVE-ADAPTERS` — production endpoint implementation for paid requirements, operational snapshots/invoices, trust/follow data and settlement/delivery responses. Frontend contracts fail closed and do not fabricate remote success.

## Equivalent-fix verification

- 1–3: native inline Store search, compact reject decision and Android-safe Workspace switcher are implemented with layout/hit-test coverage.
- 4: the switcher now explains that content creation remains in Social; another business/professional Workspace remains an approval request.
- 5–7 and 41: settings now open exact Store-owned delivery, staff and approved-business-record destinations. They no longer reuse live Orders, tax services or pre-approval proof screens.
- 8: product editor uses responsive single-column fields at compact/large text, visible close, and pinned Cancel/Save actions above the keyboard.
- 9: intentionally not claimed; exact Buy owner conflict retained.
- 10–13: Group Bulk uses responsive fields, searchable master/Store product discovery, customer wording and typed date/time selection.
- 14–16: Store host supplies a loading state, clamps embedded dense Wholesale fit, and removes the Store rail during keyboard search while preserving it afterward. Buy source remains untouched.
- 17: order completion uses a bounded scrollable sheet with bottom view-padding; primary action is hit-tested above Android navigation.
- 18–21: scalar/live orders are normalized into typed visible records; customer and money statements use order rows and real periods; settlement requires amount/destination/deduction/date confirmation.
- 22–25: Store no longer routes to legacy Retailer Offers/Services, so legacy clipping, wording and Back-context failures are removed from this journey rather than cosmetically restyled.
- 26: Store-funded work has its own validated creation surface and authenticated gateway contract before Earn Today publication.
- 27–28: completed counter/pickup sales create invoices, update stock/money/customer history and expose high-visibility MoolSocial Chat/WhatsApp handoff.
- 29–30: Promote is Store-aware and premium navy/saffron; shared logic and routes remain intact.
- 31–34: Storefront uses the public Buy product contract, complete detail sheet/direct Buy entry, explicit Storefront context, unambiguous visibility action and truthful trust/follow placeholders without invented ratings.
- 35–36: Chat Business filter wraps on compact layouts and New conversation is a compact person-plus action.
- 37–38: packing is per-product and gated; pickup has a separate ready/handover/invoice lifecycle and never requests delivery.
- 39–40: compact destructive settings dialog and merged input semantics have focused regressions.

## Local gates

- Focused analyzer: clean for all changed Work, Chat and Promote owners.
- Combined active regressions: 169 passed; evidence-only captures skipped in normal runs.
- Local 412×915 capture set: generated under `artifacts/quality/work-store-atomic-r62-49-local-review-20260903`.
