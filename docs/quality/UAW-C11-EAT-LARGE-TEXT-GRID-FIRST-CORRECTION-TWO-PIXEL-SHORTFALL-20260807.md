# C11 Eat large-text grid first-correction shortfall

Date: 2026-08-07

Regression ID:
`REG-20260807-248-C11-EAT-LARGE-TEXT-GRID-FIRST-CORRECTION-SHORTFALL`

The first text-scaled Eat grid correction reduced the compact overflow from up
to 32 pixels to two pixels, but still under-allocated the effective action
content height at 140% text. The retry therefore remained correctly rejected.

Permanent prevention: fitment corrections are measured from the rendered
post-padding constraint with a small deterministic allowance, not merely from
the reported overflow delta. The unchanged 320x568/140% matrix must reach zero
exceptions before the regression status can close.
