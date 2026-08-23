# UAW C30T optional ripgrep no-match grouped diagnostic — 13 August 2026

The first search for the founder-reported Feed Like-to-Play defect placed
optional ripgrep queries in one fail-fast grouped diagnostic. A normal no-match
exit code of 1 rejected the group and discarded otherwise independent output.

The mistake was registered before retry. Optional discovery queries must
classify ripgrep status 1 as an explicit zero-match result and fail only on
statuses above 1.
