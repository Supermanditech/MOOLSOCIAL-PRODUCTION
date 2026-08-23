# REG3183 - MVP selected-ticket hash parent guessed again

## Classification

Registered read-only validation-projection recurrence with zero build, APK,
install or device action.

## Evidence

After the failed r60.81 action journal was written, a validation command guessed
`preTicketSelectionCheckpoint.selectedTicket.manifestSha256`. That nonexistent
parent returned null even though the exact manifest-hash field at the live MVP
owner had been patched. This repeats the failure class already prohibited by
REG3166.

## Prevention

Never reconstruct the selected-ticket parent path from memory. Project the
bounded live JSON lines around the unique FIX8 ticket manifest path, identify
its actual parent, and compare the exact field to the independently computed
ticket SHA-256. Treat null as a failed projection, never as state evidence.
