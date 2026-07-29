# Buy Flutter V2 candidate evidence — 29 July 2026

## Approval and source boundary

- Founder-final HTML authority:
  `approved-references/screens/09-buy-complete/v1`
- HTML lock commit:
  `ffcb4fee23f8136a6f08bd53900ab40f2bb2d6c2`
- Native V2 source commit:
  `c557a25164a3b4e4dd87c4f1a852c888a609c157`
- Final reviewed source commit:
  `f1d13569c96c6a3e4ce1069bb2fa394d5192d971`
- Branch:
  `remediation/prototype-conformance-2026-07-20`

The founder-final HTML was not edited while producing this native Flutter
candidate. The legacy Buy presentation remains available only through its
test-only compatibility flag.

## Candidate identity

- File: `moolsocial-buy-v2-review-release-r6.apk`
- Version name: `1.0.0`
- Version code: `2026072906`
- SHA-256:
  `0D9CD9CA1D38F41B6D4CD9CB58FFEA32F4D7F8063556E5C0A6A9BAF80D1651FD`
- OPPO-pulled file: `oppo-installed-release-r6-base.apk`
- OPPO-pulled SHA-256:
  `0D9CD9CA1D38F41B6D4CD9CB58FFEA32F4D7F8063556E5C0A6A9BAF80D1651FD`
- Byte identity: pass

The APK is a release-mode founder-review harness built from the same native Buy
V2 package mounted by the production `/app/buy` route. It is not a public
release or live-commerce activation.

## Physical device

- Serial: `2b3e0f71`
- Model: `CPH2375`
- Android: `13`
- Physical display: `720×1612`
- Density: `320`
- Font scale: `1.0`
- Final cold start: `2591 ms`

## Final OPPO evidence

- `38-oppo-release-r6-cold-start.png` — Shop catalogue and persistent dock.
- `39-oppo-release-r6-orders-currency.png` — Orders, named fulfilment,
  promises and locked Indian currency grouping.
- `40-oppo-release-r6-cart-final.png` — unified Cart and correct singular
  product count.
- Matching `.xml` files provide semantic labels and interactive bounds.

Earlier numbered captures in this directory preserve Shop, Wholesale,
Medicine, product detail, quantity, Cart and Checkout defect discovery and
correction evidence. They are not the promoted candidate identity.

## Automated gates

The final committed source passed:

- approved UI locks;
- founder-final Buy reference lock: 25 immutable files;
- protected Social baseline: 119 files;
- App brand integrity;
- user-facing copy;
- interaction contracts: 154 unique routes and no static no-op controls;
- scoped `flutter analyze --fatal-infos`;
- 15 responsive viewports from `320×568` through tablet sizes, including
  `844×390` and `932×430` landscape;
- 140% text navigation fitment; and
- two independent affected regression runs, 47 tests each.

Final-run logs:

- `apps/mobile/tmp/buy-v2-final-f1d1356-regression-1.log`
- `apps/mobile/tmp/buy-v2-final-f1d1356-regression-2.log`

## Defects found and fixed before r6

- duplicate added-product notice;
- stale shared scroll offset opening Orders away from its top;
- unbounded Mool Assist width;
- compact-landscape overflow;
- visible static no-op controls;
- incorrect `1 products` Cart copy; and
- ungrouped large rupee values such as `₹4839` instead of locked `₹4,839`.

## Open promotion gates

This evidence does not claim founder acceptance of Flutter, live backend
readiness or public Production release.

Still open:

- automated HTML-to-Flutter pixel parity registry/tolerances;
- complete process-death, network, permission and interruption journeys;
- repository-wide stale legacy visual-golden debt unrelated to this Buy V2
  candidate;
- live catalogue, payment, pharmacy, fulfilment and address-request backend
  activation; and
- founder Flutter review and acceptance.
