# C24G Ride test-path guess rejection

Date: 2026-08-09
Regression: `REG-20260809-739-C24G-RIDE-TEST-PATH-GUESSED-DURING-KEY-INVENTORY`

## Rejection

The first Ride owner-key inventory named an inferred C16F test path that was
not present in the repository. Although ripgrep returned matches from the
other valid inputs, the non-zero command is rejected as an incomplete
inventory.

## Permanent prevention

Resolve optional test owners from `rg --files` before content search. Never
translate a ticket identifier into an assumed filename, and never accept
partial search output when any requested input is missing.
