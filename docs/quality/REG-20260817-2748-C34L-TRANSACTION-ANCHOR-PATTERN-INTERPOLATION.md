# REG-20260817-2748: C34L transaction anchor-pattern interpolation

## Truthful event

After the REG2747 atomic-helper correction was applied, the transaction
sub-agent ran a read-only `Select-String` source-anchor diagnostic with a
double-quoted pattern containing `$positive`. Outer PowerShell expanded that
fixture variable to an empty value, so the command returned a false no-match.
The command exited zero, but its result is not admitted as source-anchor
evidence. The agent stopped without retry, checker-coverage edit, or test.

No real C34L state, aggregate, source seal, cycle, build, Google Play, device,
private value, deployment, or external state changed.

## Root cause

The diagnostic treated a PowerShell source fragment as an interpolated runtime
string instead of preserving the fragment literally.

## Prevention

- Use a single-quoted literal or a properly escaped regex when searching for
  source text that contains PowerShell variable tokens.
- Assert the intended literal pattern still contains `$positive` before the
  search and require exactly one bounded match.
- Retry the diagnostic only after registration and a passing updated
  regression-memory gate.

## Candidate consequence

C34L remains selection-only. The false no-match is zero qualification evidence
and authorizes no release-state creation or external action.
