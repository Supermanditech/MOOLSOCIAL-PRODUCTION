# Buy V2 R38 Saved and Offers refinement handoff

Date: 31 July 2026

Status: founder approved and promoted to the protected R38 native Buy
baseline; future motion additions require a new candidate and founder review.

## Repository identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate source fingerprint:
  `57AC2C12E1D5870EE19EBBCAAFA3936BD5A74C1F9D1373C685C57B88F86E8EB0`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- The earlier protected R35.1 Buy baseline remains preserved unchanged.
- The active protected R38 baseline owns 31 runtime files with portable tree
  SHA-256
  `363ebe4c7342ba0118f9a7108e83fa8c2b0b3ded23332c7dd42a32849f9a5cd7`.
- No commit, push, deploy or publication was performed.

## Candidate identity

- Candidate ID: `BUY-R38-SAVED-OFFERS-REFINEMENT-DEVICE`
- Version: `1.0.0-r38`
- Version code: `2026073151`
- APK bytes: `200232680`
- APK SHA-256:
  `79F62DB262954BAE3334C3C77DF1F66562829225D24208970C03B8B6E787E45F`
- Connected OPPO: serial `2b3e0f71`, model `CPH2375`
- Pulled installed `base.apk`: exact byte and SHA-256 match
- Runtime marker: exact candidate ID and ready authenticated device-review
  state passed

The candidate and additive qualification evidence are under:

`artifacts/quality/buy-flutter-r38-saved-offers-founder-reference-oppo-20260731-41/r38-saved-offers-refinement-device`

The founder reference screenshots pulled unchanged from OPPO Gallery are
under the sibling `founder-reference-oppo-gallery` directory.

## Completed tickets

### `BUY-FV2-132` — subtle Saved removal

1. Every Saved product retains a visible word-and-icon `Remove` action.
2. The control changed from an image-dominating 80×44 filled treatment to a
   compact 62×44 semantic/touch owner with a smaller inner treatment.
3. At least two product decisions remain visible together at OPPO width.
4. Removing one Saved product leaves every other Saved product and Cart line
   unchanged.

### `BUY-FV2-133` — Saved clear decision sheet

1. The generic `AlertDialog` was replaced by a compact native bottom decision
   sheet.
2. The sheet names the active Saved vertical and exact number/type of saved
   decisions, and states that existing Cart lines remain.
3. `Keep saved`, close and outside dismissal make no change; `Clear list` is
   visually and semantically destructive.
4. The sheet passed 320×700 at 140% text without overflow.

### `BUY-FV2-134` — dense Coupons and Offers

1. Destination ownership is shown in one 44-pixel compact row containing the
   exact vertical Cart total; the separate oversized context introduction was
   removed.
2. Coupons and payment offers remain distinct 44-pixel accessible tabs.
3. Dense repeatable cards begin immediately below the tabs, with concise
   detail, one selection action and an explicit selected/remove state.
4. The review-only adapter now returns three editable typed records for each
   of the six Shop/Wholesale/Medicine coupon/payment states. The first stable
   IDs remain unchanged and additional records have stable IDs and source
   ownership.
5. The records contain no code, bank, monetary value, percentage, threshold,
   unlocked, redeemed or entitlement claim.
6. Selection and replacement use the same validated `BuyV2CartBenefit` and
   `BuyV2CartBenefitsAdapter` boundary intended for a real provider adapter.
   A production adapter can replace the seeded records without replacing the
   screen/session contract. Normal builds continue to use the fail-closed
   disabled adapter; the seed set is compiled only for device review.

## Qualification results

- Focused Cart/Saved/offer analysis: passed with no issues.
- Focused Cart/Saved/offer suites: 19/19 passed.
- Full Flutter analysis: passed with no issues.
- Complete Buy regression 1: 167/167 passed; four opt-in capture generators
  skipped.
- Complete Buy regression 2: 167/167 passed; four opt-in capture generators
  skipped.
- Source drift across regressions, guarded build and device replay: zero.
- Approved UI locks: passed before build and after device replay.
- Brand integrity: passed before build and after device replay.
- Founder FINAL Buy reference: 25 immutable files passed before build and
  after device replay.
- Interaction contracts: 154 unique routes passed.
- User-facing copy: passed before build and after device replay.
- HTML customer copy: nine read-only screenbook states passed; temporary
  local server was stopped and port 8765 released.
- Buy backend-contract boundary and adversarial self-test: passed.
- Buy data-egress boundary and adversarial self-test: passed.
- Protected Social baseline: 119 files and exact tree hash passed before build
  and after device replay.
- OPPO replay log scan: zero fatal, unhandled Flutter, Flutter error or
  RenderFlex-overflow matches.

The first streamed `adb install -r` returned a blank failure string even
though package metadata advanced to R38. That ambiguous transcript is
preserved as `30-adb-install.log` and was not accepted. A clean
`--no-streaming` reinstall returned `Success`; the resulting installed APK was
then pulled and checksum matched.

## Device evidence

- Founder baseline Saved defect: sibling Gallery capture
  `Screenshot_2026-07-31-19-22-20-52_5f4356efd97aa738c62fbb50c227b3a3.jpg`
- Founder Coupons/Offers hierarchy references: sibling Gallery captures at
  `19-25-24`, `19-25-43` and `19-25-53`.
- Two-product Saved lane with subtle Remove:
  `40-oppo-saved-subtle-remove.png`
- Saved clear decision sheet: `41-oppo-saved-clear-decision-sheet.png`
- Individual removal and list clear results:
  `42-oppo-saved-product-removed.png` and
  `43-oppo-saved-list-cleared.png`
- Shop coupon list and selected state:
  `48-oppo-shop-coupons-dense.png` and
  `49-oppo-shop-coupon-selected.png`
- Shop payment offers: `50-oppo-shop-payment-offers-dense.png`
- Wholesale payment and coupon lists:
  `51-oppo-wholesale-payment-offers-dense.png` and
  `52-oppo-wholesale-coupons-dense.png`
- Medicine coupon and payment lists:
  `53-oppo-medicine-coupons-dense.png` and
  `54-oppo-medicine-payment-offers-dense.png`
- Medicine selected payment offer: `55-oppo-medicine-payment-selected.png`
- Mixed Cart return with selected states and unchanged `₹1,225` total:
  `56-oppo-cart-return-selected-benefits-total-retained.png`

Every material captured state has a same-prefix accessibility hierarchy where
the XML file is present.

## R38 incremental source scope

- `apps/mobile/lib/features/buy/buy_v2_cart_contracts.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_widget_test.dart`
- `docs/delivery/BUY-FLUTTER-V2-PRODUCTION-TICKETS-20260729.md`
- this handoff

All inherited R37.3 modified/untracked source and evidence remain preserved.
The approved HTML screenbook, Screens 01–03 and Social source were not
modified.

## Remaining production gaps and future-change gate

1. A real benefits provider, eligibility quote, redemption and monetary
   contract still do not exist. Normal builds therefore remain honestly empty.
2. Review seeds prove the real frontend model/session/adapter path, but are
   not customer offers or entitlements and cannot be shipped as such.
3. Saved choices remain active-session owned. Cross-relaunch retention is
   blocked on approved account ownership, classification, consent, retention,
   deletion, sign-out and migration behavior plus a real store adapter.
4. R38 is the founder-approved protected native Buy baseline. This approval
   does not convert review seeds into production offers or authorize backend,
   deployment or publication.
5. Later motion, theme or other presentation additions must produce a new
   checksum-matched candidate and receive founder review. Commit and push
   remain separately unauthorized.
