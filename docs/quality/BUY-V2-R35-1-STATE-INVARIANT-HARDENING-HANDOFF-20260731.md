# Buy V2 R35.1 state-invariant hardening handoff

Date: 31 July 2026

State: `COMPLETE_NONVISUAL_PRODUCTION_HARDENING`

Ticket `BUY-FV2-108` strengthens the founder-approved R35.1 native Buy
candidate with deterministic regression and misuse-boundary tests. It changes
no application runtime, approved HTML, protected media, Social source,
backend contract or business rule.

## Protected identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- Starting HEAD:
  `456b482f7ea97c69f53a8bd639ceb2a7075e7d6d`
- Founder-approved Buy baseline commit:
  `34045d33869e13ac17b03d59c2625f2d91a1fb92`
- Protected Buy runtime files: `28`
- Protected Buy runtime tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- New invariant-test SHA-256:
  `56D92A4F36815785F998196D351948A0A36AB7C9400B97959DA42D20D0FBB052`

## Added coverage

The new `buy_v2_state_invariant_test.dart` contains five deterministic tests:

1. Every unrestricted Shop, Wholesale and Medicine offer preserves its
   established minimum-order quantity and total floors through add,
   increment, decrement, repeated decrement and removal.
2. Every prescription offer remains outside the cart when add or increment is
   attempted before a matched prescription approval.
3. Unknown product, order and address identifiers, unsupported payment input
   and invalid review/report input fail closed without mutating valid cart,
   Saved, review, report, address or payment state.
4. Checkout lines, checkout destinations, fulfilment-group lines, confirmed
   orders and confirmed destinations are read-only, and a second confirmation
   cannot duplicate orders after the scoped cart is consumed.
5. Twelve deterministic traversal cycles prove Shop, Wholesale and Medicine
   retain independent category ownership while transient query and filter
   state resets at each destination boundary.

The coverage asserts only behavior already established by the current
in-process session and approved tests. It does not invent transport,
authentication, authorization, inventory, pricing, prescription, payment or
backend behavior.

## Verification

- Focused state-invariant suite: `5/5` passed.
- Full Flutter analysis: passed with no issues.
- Complete Buy regression 1: `111/111` passed; four opt-in capture generators
  skipped.
- Complete Buy regression 2: `111/111` passed; four opt-in capture generators
  skipped.
- Protected Buy baseline: passed.
- Protected Social baseline: passed.
- Approved Screens 01–03 and reference locks: passed.
- Founder-FINAL Buy HTML reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contract: `154` unique routes passed.
- Temporary HTML server exited and port 8765 was verified free.

## OPPO identity

The connected OPPO `2b3e0f71` still has the exact approved candidate:

- package: `com.moolsocial.app`;
- version: `1.0.0-r35.1`;
- version code: `2026073045`;
- on-device base APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.

Because the protected runtime tree did not change, rebuilding or reinstalling
an APK would not add evidence for this test-only ticket.

## Evidence

`artifacts/quality/buy-r35-1-state-invariant-hardening-20260731-29`

The additive local evidence contains focused/full verification output, two
regressions, all gate logs, the test/source fingerprint, HTML server lifecycle
record and the read-only OPPO installed identity.

## Remaining boundaries

- Motion and subjective UI/UX work requires founder review.
- Buy runtime, routing or protected-media changes require founder approval and
  a new additive protected baseline.
- Backend implementation remains deferred until transport, identity,
  authorization, idempotency and failure contracts are approved.
- Push, deploy, publication and production release remain unauthorized.
