# REG-20260817-2756: C34L final-summary foreach pipeline recurrence

## Truthful event

After the REG2754 correction, the transaction lifecycle and journal suites
passed on PowerShell 7 and Windows PowerShell 5.1, and branch/HEAD were
reverified exact. A final read-only handoff command then placed a statement-form
`foreach` block directly before `Format-Table`. PowerShell rejected the pipe as
an empty pipeline element. The transaction sub-agent stopped without retry or
follow-up evidence command. A separate full status output also truncated and is
not admitted as bounded status evidence.

No assigned file changed after qualification, and no real C34L state,
aggregate, source seal, cycle, AAB, Google Play, device, credential, secret,
deployment, or external state changed.

## Root cause

The final evidence command repeated the registered statement-form foreach
pipeline parser shape instead of materializing rows before formatting.

## Prevention

- Assign the loop output to a ticket-specific array and only then format or
  serialize it.
- Collect each authoritative file hash/line/byte summary in bounded output and
  keep branch, HEAD, and scoped status in independent commands.
- Reject the failed parser call and truncated status output in full.

## Candidate consequence

The successful dual-host fixture results remain test evidence, but final file
inventory must be recollected after registration. C34L remains selection-only.
