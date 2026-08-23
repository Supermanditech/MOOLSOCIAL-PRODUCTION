# C20H PowerShell foreach pipeline parser rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

A read-only geometry summary placed a pipe immediately after a PowerShell
`foreach` statement. Parsing failed before the audit ran, so no geometry claim
was accepted from that command. The correction collects loop output into an
explicit array and validates that array separately.
