# C11 product-detail post-scroll action visibility assumption

- Regression: `REG-20260807-260-C11-PRODUCT-DETAIL-POSTSCROLL-ACTION-VISIBILITY-ASSUMPTION`
- Date: 2026-08-07 IST

## Observation

Exact `ensureVisible` brought Wholesale terms into view, then the test failed
because it still required the earlier inline purchase action to remain visible
in the same compact viewport. The action had already been proven visible and
was retained offscreen above the newly visible panel.

## Permanent correction

The test keeps its pre-scroll visible-action assertion. Post-scroll checks use
offstage-inclusive ownership finders for the action and its icon/label contract,
without requiring two distant product sections to be visible simultaneously.
