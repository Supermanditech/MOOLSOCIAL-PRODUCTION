# REG-20260817-2747: C34L atomic replace null backup path

## Truthful event

After REG2746 was registered and its explicit ordered projections were applied,
the next first PowerShell 7 lifecycle-fixture run stopped during the first
atomic detailed-state replacement. The helper called
`[IO.File]::Replace($temp, $Path, $null, $true)`, and this PowerShell 7/.NET
host rejected the null backup argument as an empty path. The transaction
sub-agent stopped without retry or correction.

The implementation regression-memory gate had passed at 2717 entries and 1725
applicable lessons before the fixture. The unique temporary fixture was cleaned
up. No real C34L state, aggregate, source seal, cycle, AAB, Google Play, device,
credential, secret, deployment, or other external state changed.

## Root cause

The atomic writer assumed the four-argument `System.IO.File.Replace` overload
accepts a null backup filename consistently across the required PowerShell/.NET
hosts.

## Prevention

- Use an explicit repository-local backup path for `File.Replace`, remove that
  backup only after successful replacement, and leave failures fail-closed.
- Exercise both new-file and existing-file atomic writes on PowerShell 7 and
  Windows PowerShell before treating the transition helper as host-compatible.
- Resume from a new unique fixture root only after this event is registered and
  the updated regression-memory gate passes alone.

## Candidate consequence

C34L remains selection-only at zero release actions. The failure is zero
transaction qualification evidence and authorizes no real state creation.
