# C24H restarted cycle array-splat named-parameter rejection

Date: 2026-08-09
Regression: `REG-20260809-754-C24H-QUALIFIER-ARRAY-SPLAT-CANNOT-BIND-DYNAMIC-NAMED-GATE-PARAMETERS`

The restarted cycle again completed zero-diff formatting, clean complete
analysis and 888 passing tests with 35 retained visual-capture skips. It then
rejected at the first gate because array splatting passed the strings
`-RepositoryRoot` and its value positionally to the target script. This run
has no final gate set, after-fingerprint proof or evidence file and does not
count.

The wrapper must use hashtable splatting for dynamic named parameters. A new
gate-only qualifier preflight must pass before another full cycle is allowed.

The wrapper now accepts a parameter hashtable, splats it into each target
script, and exposes `-GatePreflightOnly` so all 12 wrapper calls can be proven
without counting a cycle.
