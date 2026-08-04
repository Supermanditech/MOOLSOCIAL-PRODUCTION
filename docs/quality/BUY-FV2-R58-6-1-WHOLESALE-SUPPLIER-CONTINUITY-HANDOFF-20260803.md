# Buy FV2 R58.6.1 Wholesale supplier continuity handoff

Date: 3 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

Candidate: `BUY-R58-WHOLESALE-SUPPLIER-CONTINUITY-FIX1`

Profile: `1.0.0-r58.6` (`2026080319`)

## Exact identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,422 files, SHA-256
  `1D85096A578FC1B2E5C87E6A07E745D8DD3A4902CB5DEA92735C6D172E30A8BC`
- Wrapper-produced and pulled-installed APK: 134,115,809 bytes, SHA-256
  `D24497C67F18DE4A1ED4CD7972DE3C676A63FF86DABF5628EA4491A311CBCBA0`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Immutable evidence:
  `artifacts/quality/buy-wholesale-continuation-r58-6-audit-20260803-129`

## Confirmed defect and bounded fix

Wholesale -> Refined sunflower oil exposed the established supplier
`Surya Oils India` in a non-clickable decision panel. The generic R58.1 lane
remained available, but there was no intentional exact same-supplier owner.

The qualified fix adds a fail-closed, Wholesale-only same-seller selector and
one native semantic supplier action/sheet. It excludes the current product,
shows only three other exact products already present in the current catalogue
and renders only established pack, MOQ, price and unit-price facts. Selection
waits for the route-owned reverse controller before replacing the existing
product owner. Android Back continues to restore the original Wholesale root
and exact horizontal position.

Exact runtime/test files:

- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_supplier_sheet_motion.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_wholesale_supplier_continuity_test.dart`

No supplier profile, verification, recommendation, stock, serviceability,
negotiated term, credit, tax, payment or fulfilment fact was introduced.

## Qualification result

Host qualification passed final focused 4/4, clean formatting and analysis,
three responsive/reduced-motion captures, two complete Buy regressions at 312
active passes plus 15 established skips each, every mandatory positive gate and
the exact preserved splash/Social/Buy protected-boundary fail-closed
classification. The one-candidate negative wrong-source machine-gate test
failed closed and the positive gate passed before the single wrapper build.

On the checksum-matched OPPO install:

- the supplier action is a native clickable/focusable semantic Button;
- the sheet exposes exactly Cold-pressed mustard oil, Filtered groundnut oil
  and Pure cow ghee from the exact current supplier;
- product selection waits for reverse and opens the exact existing detail;
- Android Back, sheet Back, Close and scrim dismissal preserve their correct
  owners and do not mutate the current product;
- hot resume retains the sheet; process recreation fails closed and invents no
  supplier state;
- keyboard focus and accessibility semantics pass with no keyboard request;
- visible system `Remove animations` produced immediate/static, pixel-identical
  50 ms and 900 ms states and was restored to its original Off value;
- the extended six-cycle warmed trace has p95/max 17.042 ms, one 0.375 ms
  deadline miss, zero frames over 33.333 ms or 100 ms and zero shader/compile
  events;
- post-performance runtime scan contains no AndroidRuntime/Flutter error and no
  crash, native-crash, ANR or low-memory exit;
- post-device app/test source remains exact at 2,422 files and the same SHA.

All exploratory harness failures are preserved. The early timer-based reverse
implementation was rejected by the backend-boundary gate and replaced before
the final source seal by the real route controller. No rejected evidence was
deleted or relabelled.

## Founder review points

1. Open Wholesale -> Refined sunflower oil and scroll to `Pack, delivery and
   seller`. Confirm the supplier action says it will show three exact current-
   catalogue products from Surya Oils India.
2. Open the sheet. Confirm the three rows and their pack/MOQ/price/unit facts
   are clear, compact and do not claim stock, recommendation or verification.
3. Select Filtered groundnut oil. Confirm the sheet reverses cleanly before the
   product changes, without a flash or geometry jump.
4. Press Android Back. Confirm the original Wholesale catalogue and prior
   horizontal oil-family position return.
5. Reopen the sheet and test Android Back, Close and scrim. Confirm each only
   dismisses the sheet and retains the source product.
6. With `Remove animations` enabled, confirm the sheet is immediate/static and
   the actions remain readable and stable.

Technical/device qualification is not founder approval. The founder-requested
compact product-detail Add/quantity control is a separate successor ticket and
is not mixed into this sealed candidate. R58.7 remains queued behind that new
bounded density correction unless the founder changes priority.
