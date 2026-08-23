# C20B rg wildcard Windows path and masked exit rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

A diagnostic sent `scripts/check-personal-*.ps1` to `rg` as a required path
argument. Windows rejected that wildcard path with OS error 123. A subsequent
successful `Select-String` in the same compound command made the shell wrapper
exit zero, even though the `rg` component had failed.

No mutation followed. Future script searches enumerate literal paths with
`rg --files scripts`, filter the returned filenames, and assert each component
exit status independently before performing exact literal reads.
