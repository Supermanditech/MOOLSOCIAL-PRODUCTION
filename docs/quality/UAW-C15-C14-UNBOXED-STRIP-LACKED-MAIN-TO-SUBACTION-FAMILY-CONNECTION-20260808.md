# C15 regression: C14 strip lacked main-to-subaction family connection

Date: 2026-08-08

Regression ID:
`REG-20260808-293-C15-C14-UNBOXED-STRIP-LACKED-MAIN-TO-SUBACTION-FAMILY-CONNECTION`

The r60.14 candidate passed the numerical 44px, unboxed and one-tap rules, but
its selected local action still read as a separate flat row rather than a
visually connected child of the selected global main action. The static family
line did not communicate that relationship strongly enough on the real OPPO.

Root cause: C14 tested the absence of boxes and the presence of a static line,
but did not require the connection endpoint to follow the selected local index
or visually terminate at the selected main-action anchor.

Permanent prevention: the shared destination wrapper must have no
side-to-side surface. A noninteractive, semantics-excluded transparent gradient
wave must connect the selected global anchor to the exact selected local index,
move finitely left or right when selection changes, and settle immediately
under reduced motion. Tests and the placement machine gate must cover all six
destinations while retaining 44px targets and the unchanged global rail.

Retained evidence:

- `docs/quality/UAW-C14-R60-14-FAMILY-CONNECTION-OPPO-FEEDBACK-20260808.md`
- `artifacts/quality/uaw-personal-mvp-slim-unboxed-subaction-family-strip-fix1-c14-r60-14-20260808-01/15-05-buy-shop-settled.png`
