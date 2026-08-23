# C28D device-rejection bounds-table parser recurrence

- Date: 2026-08-10
- Phase: read-only first-device-gate evidence formatting
- Rejection: the command piped directly after a `foreach` statement and failed
  with `An empty pipe element is not allowed` before producing the table.
- Evidence effect: none; the immutable screenshot and XML were already captured
  successfully and remain unchanged.
- Root cause: the REG939/REG948 PowerShell parser shape recurred instead of
  collecting rows in a named array.
- Prevention: assign all loop output to a named collection and pipe only that
  collection. Do not retry the read until this recurrence is registered.
