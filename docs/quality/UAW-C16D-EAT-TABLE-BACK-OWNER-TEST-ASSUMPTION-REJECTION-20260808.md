# C16D Eat table Back-owner test rejection

The first focused C16D test incorrectly searched for `eat-back` after entering
Book Table. The existing `EatTableScreen` deliberately configures
`showBack: false`, so that optional app-bar control is not part of this route.

Production navigation remains unchanged. The corrected proof invokes the
platform Back route, verifies return to the exact Eat home screen and rechecks
the home content hit target. This matches the real OPPO Back journey without
inventing a control or changing the established screen contract.
