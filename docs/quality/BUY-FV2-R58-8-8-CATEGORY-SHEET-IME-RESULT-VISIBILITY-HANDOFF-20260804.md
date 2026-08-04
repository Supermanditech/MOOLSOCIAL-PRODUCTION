# Buy FV2 R58.8.8 category-sheet IME result visibility handoff — 4 August 2026

> Historical FIX5 handoff. Superseded by the technically/device-qualified FIX7
> handoff dated 5 August 2026. Preserve this record and its evidence unchanged.

## Disposition

`BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX5` is technically qualified
on the exact connected OPPO and is awaiting founder visual/UX review. It is not
founder approved and no protected baseline has been changed.

## Exact candidate

- Source: 2,466 files at
  `4FAC35E85635DCC20C2E983959FB7D6DA1D2E79A4655195C18D488A97D5D300C`
- Profile: `1.0.0-r58.21 (2026080417)`
- APK/install:
  `F55260F23846CB702122EEEA35DA0E81A986C3956759592001823F20CCD0252C`
- OPPO: CPH2375, serial `2b3e0f71`
- Evidence:
  `artifacts/quality/buy-category-sheet-ime-result-visibility-r58-8-8-fix5-20260804-173`

## What was corrected

The existing category sheet now uses full available height only for a genuine
IME inset, keeping the filtered category card and label wholly visible above
the keyboard in Shop, Wholesale and Medicine. The exact no-keyboard `.64`
geometry, opaque surface, whole-sheet repaint boundary, focus/semantics and
protected R56.3 finite arrival/reverse plus static reduced-motion behavior are
retained. The redundant live 18 px backdrop blur was removed because device
tracing proved that it remained coupled to moving catalogue content and
regressed presentation cadence even inside a repaint boundary.

No product/category truth, subcategory taxonomy, stock, nearby,
serviceability, personalization, Cart, order, payment, provider or backend
state was invented or changed.

## Qualification summary

Formatting, analysis, focused/related tests, two full Buy regressions and every
required positive or exact expected-rejection gate passed. The wrapper-built
APK exactly matches the OPPO-pulled APK. Cold/process recreation, cumulative
category ownership, product/Back restoration, keyboard/focus/Close/Back, hot
resume, cross-vertical isolation, visible reduced motion with settings restored,
runtime failure scan and final source identity all passed.

Across sixteen Shop category-sheet arrival/Back cycles, presentation cadence
passed at p95 29.409 ms and maximum 60.218 ms, with zero intervals above 100 ms
and zero shader/compile markers. The rejected FIX1-FIX4 evidence remains
immutable and is linked by the machine gate.

## Founder review

The OPPO is parked on the Shop category sheet at normal `1/1/1` animation
scales. Review the six observation points in
`143-founder-review-observation-points.md`. The live device is primary; three
still captures and accessibility XML are preserved as companion evidence due
to known ColorOS screenshot alternation.

## Held boundaries

Founder disposition remains pending. R43, R45-R48, R50, R52.1, R53-R55 and
the already founder-approved R56/R57/R58 work remain protected. Backend
taxonomy/pagination, stock, nearby/serviceability and personalization remain
dependency-held.
