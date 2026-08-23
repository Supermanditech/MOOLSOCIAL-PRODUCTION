# C09 internal implementation copy reached OPPO

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## Founder-visible regression

The checksum-matched r60.9 OPPO frame exposed internal engineering language as
customer copy:

- `Mool keeps navigation available without inventing nearby availability.`
- `Social, Buy, Eat, Ride, Book and Work stay ready in the main rail below.`
- `Swipe the main rail to see every action. Mool and Chat stay fixed.`

The phrases explain implementation constraints and component mechanics. They
do not help a customer decide what to do and are not production-grade wording.
r60.9 is rejected and cannot be presented for founder acceptance.

## Root cause

The C09 implementation moved defensive design rationale into visible and
semantic strings. The R15 machine state verified presence, fitment,
accessibility names and tap targets, but did not classify copy as customer
language. The user-facing-copy gate used a finite older phrase list and the
device review concentrated on navigation behavior before copy quality.

## Permanent prevention

Every new visible or semantic string must express a customer goal, action,
benefit or plain-language reassurance. Implementation nouns and rationales such
as `main rail`, `navigation available`, `stay fixed`, `without inventing`,
`route`, `owner` and `state` are prohibited when customer-visible. The copy
gate blocks the exact C09 phrases, C09 tests assert the approved replacement
copy and forbidden-term absence, and OPPO qualification includes a dedicated
untouched-frame wording review before a pass.
