# C22D successor machine identity reconciliation — 2026-08-08

Before C22D runtime mutation, the C22 `successorPreselection` record was found to contain three stale fields from the r60.19/C21 transition: the predecessor checksum, an already-performed install boolean and a C21H successor-ticket pointer. REG-20260808-529 records the defect.

The block now truthfully identifies installed founder-rejected r60.20 SHA-256 `FF3932D84794BA8802946CBB04F8A346F34386F4A5C8321F3970AD8E6228EF8A` as the preserved predecessor, records no C22 build or install, and points to the C22 parent ticket. No device operation was performed.
