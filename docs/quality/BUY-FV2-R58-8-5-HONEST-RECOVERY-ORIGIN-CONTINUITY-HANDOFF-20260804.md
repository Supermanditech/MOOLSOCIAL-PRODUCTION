# Buy FV2 R58.8.5 honest recovery origin continuity handoff

State: **founder approved/protected after technical/device qualification**.

Founder authority: explicit 4 August 2026 approval preserved in
`artifacts/quality/buy-r58-8-5-founder-approval-20260804-154`. The approval is
exact to the source, profile, APK/install checksum and evidence below; it does
not update a protected baseline or approve any future candidate.

Candidate `BUY-R58-HONEST-RECOVERY-ORIGIN-CONTINUITY-FIX1`, profile
`1.0.0-r58.14` (`2026080410`), retains and validates the first real origin for
the six existing Buy recovery states. Visible primary and Android Back restore
the same destination/view, scope, query/filter, selected product or selected
order. Explicit bottom navigation replaces and clears the old origin.

Exact changed app/test files:

- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_session_coverage_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_honest_recovery_origin_continuity_test.dart`

The six cards now state only session-owned truth. Delivery Help exists only
from a valid exact Tracking/Items order and opens Assist for that same order.
No recovery action mutates Cart, address, order, payment, prescription,
entitlement, provider or backend state.

Final source: 2,454 files, SHA-256
`DF7A4817AB6848056A0F148EC0E6BC291F5DF0410BD31890F845206D33F571EB`.
APK/install: 134,214,109 bytes, SHA-256
`4A6640DDEFEF3B50E76D7A4EFB73973814D0D237905B92DD75AEACDCC2E2F03D`.

Host: focused 7/7, related suites passed, two complete 347+20 Buy regressions,
all release/protected/machine gates passed. OPPO: all six states, exact
primary/Back, unrelated-Cart isolation, exact `PO-240783` Help, query/IME,
replacement, lifecycle/recreation, visible 0/0/0 reduced motion and final p95
19.795 ms passed; crash/ANR scan is zero. Evidence:
`artifacts/quality/buy-honest-recovery-origin-continuity-r58-8-5-fix1-20260804-151`.

Founder review points are `151/173-founder-review-observation-points.md`.
Technical/device qualification is not founder approval. Provider/payment/
stock/serviceability/order/delivery/backend outcomes remain dependency-held.
