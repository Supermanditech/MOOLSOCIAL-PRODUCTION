# C13 FIX1 Mool action tests expected retired chooser owners

Date: 2026-08-07

Regression:
`REG-20260807-276-C13-FIX1-MOOL-ACTION-TESTS-EXPECTED-RETIRED-CHOOSER-OWNERS`

## Failure

The independent FIX1 navigation file exposed four of the six remaining batch
failures. Mool actions for Eat, Ride, Book and Work still expected
`mvp-action-root-*`, while C13 correctly opened the default destination owner.
Social, Buy and all downstream exact-return cases passed.

## Prevention

Mool and global main-action acceptance shares the C13 direct-landing contract.
The four expected owners are Eat Home, Ride Booking, Book Doctor and Work Earn;
the existing Back assertion continues to require the stable Mool home. No
retired chooser key may be restored to make an old test pass.
