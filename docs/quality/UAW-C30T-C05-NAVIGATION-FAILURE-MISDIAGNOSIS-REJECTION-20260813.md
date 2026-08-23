# C30T C05 navigation-failure misdiagnosis rejection — 2026-08-13

The first combined-suite failure was attributed to concurrent Flutter test files before the beginning of the log and the C05 helper were inspected. A serial rerun disproved that explanation. The actual cause is the C05 helper passing the retired `mool-root-selected` key while current compact navigation uses `mool-compact-launcher`.

Prevention: inspect the first failing case and its helper before assigning a harness-level root cause; use a serial rerun only as evidence, not as an assumed diagnosis.
