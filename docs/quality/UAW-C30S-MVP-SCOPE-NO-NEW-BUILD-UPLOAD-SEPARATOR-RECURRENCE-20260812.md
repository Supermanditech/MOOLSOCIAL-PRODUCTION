# C30S MVP scope no-new-build-upload separator recurrence

Date: 2026-08-12

The next bounded C30S transition stopped because the expected value used a
space after `no_new_build`; the literal state contains
`no_new_build_upload`. No later line, gate, build or external action ran.

All continuation values must be copied directly from a fresh literal `rg`
line with contiguous underscore-delimited tokens preserved exactly.
