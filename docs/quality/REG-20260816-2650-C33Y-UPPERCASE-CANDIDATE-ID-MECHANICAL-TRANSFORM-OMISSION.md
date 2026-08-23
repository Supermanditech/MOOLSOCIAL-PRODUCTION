# REG2650 — C33Y uppercase candidate-ID transform omission

Date: 2026-08-16 IST

The first C33Y ticket correction patch failed verification before sealing. The
mechanical clone changed lowercase `r60-62` spellings but left uppercase
`R60-62` inside `ticketId` and `candidateId`, while the patch expected the new
identity.

No ticket bytes changed and no gate pass is counted. Before retry, read back
every C33Y identity occurrence, replace uppercase `R60-62` with `R60-63`
explicitly, and verify ticket ID, candidate ID, filenames, version name/code
and absence of current-candidate C33X leakage before computing the ticket hash.
