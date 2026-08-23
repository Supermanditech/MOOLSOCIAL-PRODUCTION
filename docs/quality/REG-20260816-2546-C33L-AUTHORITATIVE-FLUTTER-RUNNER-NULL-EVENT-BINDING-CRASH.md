# REG-20260816-2546 — authoritative Flutter runner null-event crash

Cycle 2 used the same 71-file manifest and exact expected counts as clean cycle
1. The Flutter process returned to the summarizer, but a raw line produced a
null `ConvertFrom-Json` result. The runner then passed null to the mandatory
`Event` parameter and terminated before emitting its bounded count summary.

The candidate is not qualified. Cycle 1 remains preserved evidence but cannot
be paired. Analyzer, backend and Hosting stages for cycle 2 did not run. No AAB,
Play action, OPPO mutation, provider write, email, SMS, secret access, or
readiness claim occurred.

FIX3 must classify blank lines before conversion and JSON null before event
helpers, preserve all fail-closed counts, never output JSON values, pass
behavioral checks on both PowerShell hosts, and force a new source seal plus two
fresh complete cycles.
