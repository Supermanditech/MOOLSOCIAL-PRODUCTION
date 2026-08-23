# REG-20260812-1393 — C30I historical Social count non-reproducible rejection

- Phase: C30I complete-suite reconstruction
- Failure: The nine test paths recoverable from the historical C30G log plus the two new C30I tests passed 87 tests, not the asserted 166 derived from the historical `164` count.
- Rejection: `uaw-c30i-complete-social-suite-cycle-1-20260812-01` is a passed recovered-path matrix, but not a qualifying complete cycle.
- Permanent prevention: A full-cycle contract must store an explicit current test inventory as well as a count and log hash. Build the inventory from repository-owned Social, Screen04 and global-edge tests, seal it before execution, and require both cycles to use the identical inventory and final count.
- Protected state: No build, install or deployment occurred.
