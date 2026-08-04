# Buy FV2 R58.7 Orders and purchased-item continuity handoff

Date: 4 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

Candidate `BUY-R58-ORDERS-PURCHASED-ITEM-CONTINUITY-FIX1`, profile
`1.0.0-r58.7` (`2026080403`), is fully host/device qualified on exact 2,429-file
app/test source SHA-256
`BF7CAE2F2225C833AFB72824F9BB32AA463E3E20BC192A799688D4C8E5A9F1AA`.
The wrapper APK and OPPO-pulled install are identical at 134,115,809 bytes and
SHA-256
`D38C0BBEDB6245584F630D6A096E1FD8034495688B0F4C79A97914F7F9C8B71E`.

The fix makes every order card a non-mutating exact inspection owner, keeps
Delivered `View order` separate from in-order `Reorder`, restores exact
Orders tab/query/depth, and removes the previous fabricated fallback from an
older order to unrelated catalogue products. Items/Reorder accept only a
complete, real order-owned identity set and fail closed before Cart mutation.

Host qualification passed focused 5/5, related 137/137, responsive large-text
and reduced-motion captures, format/analysis, two complete 322-active +
16-established-skip Buy regressions, all mandatory positive/HTML/protected
classifications and the one-candidate machine gate.

Checksum-matched OPPO replay passed Active/Delivered exact selection, older
order fail-closed Items/Reorder, Delivered query/Back restoration, real
current-session order -> exact item -> R58.1 continuation -> Items -> Tracking
-> Orders, keyboard/focus/semantics, hot resume, truthful process recreation,
visible reduced motion with final scales `1/1/1`, and runtime failure scan.
The ten-cycle performance trace passed p95 16.948 ms, max 17.037 ms and zero
intervals over 25/33.333/50/100 ms.

Exact implementation files:

- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_orders_purchased_item_continuity_test.dart`

Immutable evidence:
`artifacts/quality/buy-orders-purchased-item-continuity-r58-7-fix1-20260804-139`.

Founder observation points:
`artifacts/quality/buy-orders-purchased-item-continuity-r58-7-fix1-20260804-139/135-founder-review-observation-points.md`.

Technical/device qualification is not founder approval. No protected baseline,
backend state, payment, live order fact, stock or recommendation claim changed.
