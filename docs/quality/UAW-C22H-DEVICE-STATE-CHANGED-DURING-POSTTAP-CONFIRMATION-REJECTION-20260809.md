# C22H post-tap device-state interruption rejection

- Date: 2026-08-09
- Candidate: installed checksum-proven r60.21
- Accepted evidence before interruption: Buy Shop only

## Rejection

The helper tapped the uniquely verified `Open Wholesale` control, but the
target never achieved two consecutive confirmations. The immediate diagnostic
hierarchy showed Mool Home, not any Buy state. Therefore no Wholesale evidence
was accepted and later operations in the batch did not run.

## Prevention

Treat a family replacement during the stability window as an interrupted live
journey. Reacquire the current hierarchy, deterministically reopen Buy, verify
Buy Shop, and only then retry the one-tap Wholesale journey.
