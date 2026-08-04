# Buy FV2 R58.3.1 Cart-line product continuity handoff

Date: 3 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

Candidate: `BUY-R58-CART-LINE-PRODUCT-CONTINUITY-FIX1`

Profile: `1.0.0-r58.3` (`2026080316`)

## Exact identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,418 files, SHA-256
  `71FA7C84EFC484E87FC866A54158D579998701CDBA105D1A5BB34A7248ED7A71`
- Wrapper-produced and pulled-installed APK: 134,017,505 bytes, SHA-256
  `BC5FAA7990F098E5C3651FB37EFF9A942492748C79E62B238B83A8B8B0DA0D7A`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Immutable evidence:
  `artifacts/quality/buy-cart-line-product-continuity-r58-3-1-20260803-126`

## Defect and bounded fix

The primary non-empty Cart product identity was focusable but not clickable;
only quantity controls acted. The customer therefore could not inspect the
selected item directly from Cart.

The qualified fix makes media/title/variant/pack/delivery/seller one native
semantic product-details action, retains independent Remove/Add actions, and
restores exact live-session Cart scope and scroll after product navigation.
It reuses approved R54 navigation, R58.1 continuation and existing Cart value
motion. Intent depth is finite and reduced motion is immediate/static.

Exact runtime/test files:

- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_cart_line_continuity_test.dart`

## Qualification result

Host qualification passed clean analysis, 3/3 new focused tests, 43/43 related
focused tests, two complete Buy regressions at 301 active passes plus 15
established skips each, all positive release gates, exact protected-boundary
rejections, and Android/iOS-size/320px-140% reduced-motion captures.

On the checksum-matched OPPO install:

- Shop Cart opened exact Fresh tomatoes, continued to Fresh red onions and one
  Back restored the original mixed Cart;
- Wholesale opened the exact 10 kg crate, quantity two, with no Shop-pack
  leakage; Add/Remove remained Cart-local and restored quantity two;
- Medicine opened the exact Pain relief gel 30 g tube, quantity one, with no
  Wholesale-line leakage in the Medicine scope;
- product identity is a native focusable/clickable Button and quantity controls
  remain separate native Buttons in all three verticals;
- a scrolled Cart recommendation anchor and lane returned to exactly the same
  pixel bounds after product entry/Back and after hot resume;
- force-stop restored the approved catalogue destination without inventing
  in-memory Cart persistence;
- the corrected 91-frame warmed trace has p95 18.230 ms, zero frames over 33 or
  100 ms and no shader/compile event;
- classified MoolSocial failures are zero;
- post-device source remains exact.

## Founder review points

1. In a non-empty Shop Cart, tap the product media/title—not Add/Remove—and
   confirm exact product detail opens.
2. Continue to another product through the approved discovery lane, then Back;
   confirm the original Cart scope, quantities and scroll position return.
3. Confirm Remove/Add remain separate 44-pixel actions and do not open detail.
4. Repeat in Wholesale and Medicine; confirm the exact trade/medicine pack and
   no cross-vertical leakage.
5. With reduced motion enabled, confirm the product action is immediate/static
   and the geometry does not jump.

Technical/device qualification is not founder approval. R58.2 remains founder
approved/protected. R58.1 remains founder-review pending. R58.4 is the next
separate registered audit; no R58.4 runtime work is included here.
