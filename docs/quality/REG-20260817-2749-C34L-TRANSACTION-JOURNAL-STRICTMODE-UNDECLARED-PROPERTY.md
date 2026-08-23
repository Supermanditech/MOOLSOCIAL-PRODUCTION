# REG-20260817-2749: C34L journal undeclared property under strict mode

## Truthful event

After REG2748 was registered, the literal source-anchor check matched exactly
once, the planned atomic-write coverage assertion was added, and the
implementation regression-memory gate passed at 2719 entries and 1727
applicable lessons. The next PowerShell 7 lifecycle fixture then stopped while
committing its fixture journal. Under strict mode, direct assignment to
`$journal.committedUtc` failed because the prepared PSCustomObject did not
declare that property. The same schema class can affect later reconciliation
and observation fields. The transaction sub-agent stopped without retry.

The unique fixture was cleaned up. No real C34L state, aggregate, source seal,
cycle, AAB, Google Play, device, credential, secret, deployment, or external
state changed.

## Root cause

The journal implementation treated a deserialized PSCustomObject like an open
dictionary and assigned lifecycle properties that were absent from the
prepared journal schema while `Set-StrictMode -Version Latest` was active.

## Prevention

- Declare every prepared, reconciled, observed, and committed journal field in
  the initial immutable schema, or add fields through one explicit checked
  property helper.
- Make the journal checker assert the exact allowed property set for every
  status and reject missing, duplicate, or unexpected fields.
- Resume under a new fixture root only after registration and a passing updated
  regression-memory gate.

## Candidate consequence

C34L remains selection-only. The failure is zero lifecycle qualification
evidence and authorizes no real state creation.
