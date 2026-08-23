# C11 product-detail fixed drag overshot target

- Regression: `REG-20260807-259-C11-PRODUCT-DETAIL-FIXED-DRAG-OVERSHOT-TARGET`
- Date: 2026-08-07 IST

## Observation

The compact no-results and Assist corrections passed, but the product-detail
test's replacement 520-pixel drag overshot the already built Wholesale terms
panel. This was a test-location error, not missing product content.

## Permanent correction

The test first proves the exact panel exists with offstage elements included,
then uses `tester.ensureVisible` on that owned target. It no longer guesses a
scroll offset that changes when bottom navigation or viewport geometry changes.
