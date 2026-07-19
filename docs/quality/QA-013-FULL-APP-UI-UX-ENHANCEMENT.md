# QA-013 — Full-app UI/UX enhancement and navigation regression

Date: 19 July 2026

## Scope

- Independent UI/UX enhancement cycle after the completed Business Book audit
- Apple-inspired product rules from
  `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
- Universal, Buy, Eat, Ride, Book, Pay, Work, Chat and retailer surfaces
- Stable Mool and Chat placement with a separate focused task rail
- One content-surface hierarchy across every product vertical
- Direct pressed feedback, restrained borders and layered elevation
- Calm form controls, buttons, segmented controls, sheets and app bars
- 44 logical-pixel minimum navigation targets
- 320 px compact layout, larger text and reduced-motion behavior
- Visual baselines at 360 × 800 and 412 × 915

## Enhancement findings and fixes

| Finding | User impact | Enhancement | Evidence replay |
|---|---|---|---|
| Product rails used four or five equal visual buttons | Mool, the current task and Chat competed for attention; longer labels became cramped | Added one full-app `MoolOutcomeDock`: stable Mool, separate focused middle rail and stable Chat | Physical OPPO replay rendered Buy, Eat, Ride, Book, Pay, Work and retailer rails; every target measured at least 44 px |
| Card borders, shadows and tap behavior differed by vertical | The product felt assembled from separate prototypes | Added one `MoolCardSurface` and adopted it across Buy, Eat, Ride, Book, Pay, Work, Chat and retailer components | Full application regression and updated visual baselines passed |
| Tappable cards had no restrained direct-manipulation response | A tap could feel static until navigation completed | Added a short accessible pressed scale, ink response and reduced-motion support | Design-system pressed-state test passed at normal and disabled animation settings |
| Inputs and secondary buttons used heavy navy outlines | Operational screens looked form-heavy rather than calm and content-first | Rebalanced enabled, focused, error and disabled states with light neutral outlines and brand focus | Business Book, Stock Statement and Money control goldens updated and passed |
| Business Book had no visual regression baseline | Layout regressions could pass functional tests | Added stable 412 × 915 baselines for screens 91, 92 and 106 | Three new golden tests passed twice with the full application |

## Surface and interaction coverage

| Product vertical | Stable actions | Focused task actions | Physical replay |
|---|---|---|---|
| Buy | Mool, Chat | Shop, Basket, Order | Passed |
| Eat | Mool, Chat | Order, Table, Tiffin | Passed |
| Ride | Mool, Chat | Book, Trip, Help | Passed |
| Book | Mool, Chat | Book, Activity, Help | Passed |
| Pay | Mool, Chat | Pay, Receipts, Requests | Passed |
| Work | Mool, Chat | Earn, My Work | Passed |
| Retailer | Mool, Chat | Orders, Stock, Wholesale | Passed |
| Universal Social | Mool, Chat | Shorts, Videos, Feed, Create | Existing Apple-inspired dock and updated golden passed |

## Test results

- Design-system token, glass, outcome-dock and pressed-surface tests: 4/4
  passed.
- Existing dedicated vertical and nested-intent suites: passed.
- Full application regression cycle 1 after enhancement: 150/150 passed.
- Full application regression cycle 2 after enhancement: 150/150 passed.
- Flutter analyzer after all enhancements: no issues.
- Physical OPPO CPH2375 cross-vertical design replay: 1/1 passed.
- Physical OPPO Business Book exact functional replay after enhancement: 1/1
  passed.
- Visual baselines: Universal 412 × 915, Universal 360 × 800, Mool palette,
  Buy entry, Business Book, Stock Statement and Money control passed.

## Current gate

The shared client design system, product rails and current implemented
verticals are **GO** for continued full-scale implementation. This is not a
public-launch GO for unfinished approved screens or external services. Every
new screen must use `MoolCardSurface`, `MoolOutcomeDock` where a product rail
is needed, the shared theme, the production wording rules and the same
black-box plus two-regression gate.
