# C21G incomplete predecessor-test token migration rejection — 2026-08-08

The first C21G focused run correctly removed all test calls to the retired flat `glassFill` API and passed static analysis, but two historical expectations remained: pressed scale `0.985` and two-action cluster width `212`. The C21 contract requires `0.975` and `200` respectively. The focused run failed and is not host-cycle evidence.

REG-20260808-487 requires the complete predecessor-token inventory to be reconciled before retry. No runtime, build, install or OPPO state changed; the installed r60.19 checksum identity remains preserved.
