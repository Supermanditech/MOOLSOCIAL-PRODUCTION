# REG3167 - MVP current-ticket optional projection repeated path guess

## Classification

Registered null optional projection rejected; selected manifest remains independently proven.

## Evidence

The final seal correctly projected `preTicketSelectionCheckpoint.selectedTicketAssessment`, and its FIX8 manifest hash matched the independently computed ticket hash. An unnecessary additional projection guessed `currentTicket.ticketId` and returned null. The null is discarded and does not weaken the selected-ticket proof.

## Prevention

Stop projecting the optional current-ticket field. Use only the exact selected-ticket assessment plus the passing execution-authorized MVP gate.
