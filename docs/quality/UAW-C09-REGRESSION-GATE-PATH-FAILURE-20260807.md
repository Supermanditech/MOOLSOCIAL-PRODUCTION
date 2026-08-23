# C09 regression-gate path failure

Date: 7 August 2026

REG-20260807-134 initially placed the command label `flutter test` in its
`gates` array. The registry checker treats every value in that array as a
repository-relative gate file and correctly rejected the missing path before
the test retry. No runtime, build or device action occurred.

REG-20260807-135 registers the machine-state mistake. Command names remain in
prevention prose; the `gates` field contains existing repository files only.
