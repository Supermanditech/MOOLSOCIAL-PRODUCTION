# Buy V2 R38 protected baseline handoff

Date: 31 July 2026

State: `FOUNDER_APPROVED_PROTECTED_BUY_BASELINE`

The founder approved every current native Flutter Buy screen, visible state,
tap and connected journey through the checksum-matched R38 OPPO candidate.
The approval is subject to later motion additions: motion, theme or other
presentation changes are outside this baseline and require a new candidate
and founder review.

## Protected identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- Repository HEAD at approval:
  `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Runtime files: `31`
- Portable runtime tree SHA-256:
  `363ebe4c7342ba0118f9a7108e83fa8c2b0b3ded23332c7dd42a32849f9a5cd7`
- Candidate: `BUY-R38-SAVED-OFFERS-REFINEMENT-DEVICE`
- Version: `1.0.0-r38`
- Version code: `2026073151`
- Candidate and pulled installed APK SHA-256:
  `79F62DB262954BAE3334C3C77DF1F66562829225D24208970C03B8B6E787E45F`
- OPPO: `CPH2375`, serial `2b3e0f71`
- Source fingerprint:
  `57AC2C12E1D5870EE19EBBCAAFA3936BD5A74C1F9D1373C685C57B88F86E8EB0`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Baseline authority:

`artifacts/quality/buy-protected-baseline-r38-20260731-42/BASELINE.json`

The previous R35.1 baseline remains preserved unchanged. The default Buy
protection gate now resolves to R38; an older baseline can still be verified
explicitly by passing its immutable `BASELINE.json` path.

## Approval scope

The current Shop, Wholesale, Medicine, Orders, Cart, Checkout, address,
tracking, prescription, Account and Buy Chat presentation and wiring are
approved as one native Flutter baseline, including the R38 Saved and
Coupons/Offers refinements.

This approval does not:

- authorize HTML changes;
- change Screens 01–03 or Social;
- convert device-review offer seeds into production customer entitlements;
- establish an offer-redemption, Saved-persistence, payment, payout or Buy
  backend contract;
- authorize commit, push, deployment, publication or Production release; or
- pre-approve later motion/theme changes.

## Qualification inherited from the exact candidate

- Full Flutter analysis: passed.
- Focused Cart/Saved/offer suite: `19/19`.
- Complete Buy regression 1: `167/167`; four opt-in captures skipped.
- Complete Buy regression 2: `167/167`; four opt-in captures skipped.
- Interaction contracts: `154` routes.
- Approved locks, founder-FINAL Buy reference, brand, Flutter customer copy,
  nine-state HTML copy, backend boundary, data-egress boundary and protected
  Social gates: passed.
- Connected OPPO crash/Flutter-error/RenderFlex scan: zero matches.
- Source drift through build and device replay: zero.

Candidate handoff and evidence:

- `docs/quality/BUY-V2-R38-SAVED-OFFERS-REFINEMENT-HANDOFF-20260731.md`
- `artifacts/quality/buy-flutter-r38-saved-offers-founder-reference-oppo-20260731-41/r38-saved-offers-refinement-device`

## Future-work rule

Tests, documentation and read-only analysis may advance while the R38 runtime
tree remains exact. Any Buy runtime, routing, protected-media, visual, theme
or motion change requires an additive checksum-matched candidate and a later
founder-approved baseline replacement. Earlier baselines and evidence must
never be overwritten.
