# Buy V2 adversarial reiteration — 29 July 2026

## Result

The native Flutter Buy V2 candidate was audited from the Screen 04 handoff
through Shop, Wholesale, Medicine, cart, checkout, confirmation, Orders,
tracking, assistance, reorder and recovery.

Screens 01–03 and the founder-FINAL Buy HTML reference were not modified.
The candidate is installed on the connected OPPO for continued founder review.
It has not been committed, pushed, promoted or deployed.

## Source identity

- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Branch: `remediation/prototype-conformance-2026-07-20`
- Starting HEAD: `0aaa32bfd383b77a392b3426a49e6ef3744493dd`
- Approved Buy reference:
  `approved-references/screens/09-buy-complete/v1`
- Approved HTML screenbook remained read-only:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook`

## Production changes audited

- Screen 04 Mool `Buy` selection routes directly to native `/app/buy`.
- Historical Buy routes resolve to Buy V2 instead of the legacy shell.
- Shop, Wholesale, Medicine and Orders remain permanently visible in the Buy
  dock.
- Mool opens a native, scrollable capability palette and keeps Buy immediately
  available.
- Shop, Wholesale and Medicine have definitive categories, destination-specific
  filters and real matching product results.
- Product decision information precedes the final purchase action.
- Medicine prescription approval unlocks only matched medicine lines and
  enforces the approved quantity.
- Shop, Wholesale and Medicine can be combined in one cart or checked out by
  family.
- Cart quantities, MOQ, family totals and Indian currency grouping are
  deterministic.
- Empty-cart removal returns directly to the relevant catalogue.
- Checkout uses the selected saved or newly added address, selected payment
  method, real cart families, partners and fulfilment promises.
- Confirmation creates traceable order records; reorder restores exact saved
  product identifiers into an editable cart.
- Active and delivered Orders, tracking, assistance and recovery states are
  native and reachable.
- Cart content padding and the sticky total were tightened to remove the
  unnecessary empty band above the dock.
- The compact cart indicator is limited to catalogue and product-detail
  surfaces so it never covers tracking or support actions.
- Customer-facing `fulfilment` spelling was standardised.

## Automated verification

- `flutter analyze`: PASS, no issues.
- Final focused Buy V2 suite: PASS, 37/37.
- Final affected regression suite: PASS, 66/66.
- Representative viewport matrix: PASS, including small phones, current phones,
  larger phones, tablets and landscape.
- Every primary Buy state at 320 px width and 140% text: PASS.
- Scrollable destination filter sheets at 320 × 568 and 140% text: PASS.
- Purchase and navigation actions meet the 44 px target: PASS.
- Approved UI locks: PASS.
- Founder-FINAL Buy reference lock: PASS, 25 immutable files.
- App brand integrity: PASS.
- User-facing copy gate: PASS.
- `git diff --check`: PASS.

A diagnostic full-repository test run during the audit recorded 511 passing,
4 skipped and 76 failing tests. The failures are legacy visual-golden
differences, including older medicine, captain and shared-screen baselines.
Those unrelated goldens were not rewritten or silently accepted. The current
Buy and affected regression suites are green.

## Physical OPPO verification

- Device: OPPO CPH2375
- Android: 13
- Final Buy review version code: `2026072910`
- Final APK:
  `artifacts/quality/buy-flutter-v2-reiteration-oppo-20260729-02/moolsocial-buy-v2-reiteration-r10-final.apk`
- SHA-256:
  `CF1DFF55927F273C94EC104C2F396210E4D63A3A97330B4B9F2C46D1A27E6C9D`
- APK pulled back from the installed app: exact hash match.
- Final candidate restored on the OPPO after integration diagnostics: exact
  hash match.
- Runtime log check on the Buy review candidate: no matching fatal exception,
  unhandled Flutter exception or RenderFlex overflow.

The physical replay covered:

1. cold Shop start;
2. Shop, Wholesale and Medicine dock switching;
3. native Mool palette;
4. product detail and final action;
5. medicine information and prescription route;
6. compact add confirmation;
7. mixed Shop + Wholesale + Medicine cart;
8. quantity editing and wholesale MOQ;
9. checkout and fulfilment grouping;
10. saved address and payment selection;
11. confirmation and generated order identifiers;
12. active and delivered Orders;
13. tracking;
14. central Mool Assist, chat and in-app call choices;
15. exact reorder into an editable cart;
16. Shop filter sheet, scrolling and a non-empty fast-delivery result;
17. final compact-cart anti-overlap replay.

The evidence directory contains device screenshots, UI hierarchy captures,
candidate APKs and pulled installed APKs.

## Screen 04 integration boundary

The production router test proves that the Screen 04 Mool `Buy` action opens
only native Buy V2.

An ad-hoc normal release build failed closed at startup because protected
production Firebase identifiers were intentionally not supplied. The documented
isolated device-review build reached the locked clean setup flow. Continuing to
Screen 04 would require authenticating Screens 01–03, which was outside this
task. No protected value was invented, exposed or copied.

## Promotion blocker requiring founder decision

`scripts/check-social-protected-baseline.ps1` remains red because the deliberate
Screen 04 Mool-to-Buy route change modifies the protected Social source tree:

- expected:
  `927ba8662457d64640ef3a3a97b2b53120ca53e26e80f761a937ee35bad92851`
- candidate:
  `76d99b043c86e3f6c3ebf757ceb5bd9adbe1432aaa2f457d925a6a42fb0b3196`

The protected Social baseline was not replaced. Founder approval is required
before accepting this route-only baseline change.

## Remaining production dependencies

- Protected CI must supply the environment-specific Firebase identifiers for a
  signed normal production build.
- Live catalogue, inventory, price, payment, pharmacy, prescription,
  fulfilment, address and order services still require their production
  backends and regulated operating controls.
- The current review candidate proves the native UI, state contracts and user
  journeys; it is not evidence that those external production services are
  live.
