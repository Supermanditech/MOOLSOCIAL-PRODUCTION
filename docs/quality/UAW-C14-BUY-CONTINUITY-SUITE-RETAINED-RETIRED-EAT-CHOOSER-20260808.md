# C14 Buy continuity suite retained retired Eat chooser

Date: 2026-08-08

Regression:
`REG-20260808-290-C14-BUY-CONTINUITY-SUITE-RETAINED-RETIRED-EAT-CHOOSER`

## Failure

The first complete Buy cycle passed 426 tests and failed only the continuity
case that opened Eat from Mool. The app correctly landed on Order Food, while
the test still expected the retired Eat chooser.

## Root cause and prevention

The retired-root inventory initially covered the universal test directory but
missed a cross-destination assertion in the Buy suite. Buy continuity now
proves Eat Home with Order Food selected and no chooser, then proves exact
Back to Mool, Buy opening, and Back to Mool. Future chooser-retirement audits
must search all affected destination suites, not only universal navigation.
