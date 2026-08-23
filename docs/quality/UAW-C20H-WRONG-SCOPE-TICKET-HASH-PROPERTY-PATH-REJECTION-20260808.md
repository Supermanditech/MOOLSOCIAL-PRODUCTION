# C20H wrong scope ticket-hash property path rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

The first final seal queried nonexistent property
`preTicketSelectionCheckpoint.candidateTicket.manifestSha256` and therefore
compared the real ticket hash with an empty string. Direct schema inspection
showed the authoritative field is
`preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256` and that
both stored and computed values already equal
`E539171E282F9F8E07D81960F33D413BA593ADD7AE4EABC293F9A861FBDA9317`.
No scope hash refresh was required or performed.
