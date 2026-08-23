# REG2655 — C34A combined gate patch ticket-context mismatch

Date: 2026-08-16 IST

The first combined C34A gate correction patch expected the gate to read
`parentTicketIds[0]`. Exact source instead uses a `parentTickets` containment
assertion. `apply_patch` rejected the complete operation at its first hunk and
changed no gate bytes.

No parser or candidate gate result is counted. Before retry, every required
gate region is read back exactly and the ticket, history, source-flag,
launcher-parity and build-flag changes are applied and verified as separate
hunks. Both PowerShell hosts must parse all bounded owners before any source
gate or seal.
