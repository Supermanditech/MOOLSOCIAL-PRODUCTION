# C24H candidate-specific APK gate without authority rejection

Date: 2026-08-09
Regression: `REG-20260809-753-C24H-INCLUDED-CANDIDATE-SPECIFIC-APK-GATE-WITHOUT-BUILD-AUTHORITY`

`check-apk-regression-gate-state.ps1` requires a candidate identity, build
name/number, build mode, source fingerprint and runtime define. C24H is
explicitly build-closed and therefore has none of these. The gate is reserved
for the single C24I candidate. C24H instead validates the exact installed
r60.22 version/code/checksum and false successor authorities in its aggregate
gate.

The candidate-specific APK gate is removed from C24H's gate inventory and
remains unchanged for C24I.
