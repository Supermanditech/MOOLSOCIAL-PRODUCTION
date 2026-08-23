# REG-20260817-2757: C34L primary rg attempt-pattern interpolation recurrence

## Truthful event

During primary read-only review after REG2756, a bounded `rg` command used a
double-quoted regex containing `$Attempt`. Outer PowerShell expanded the token
and left backslashes and alternation in an invalid group. `rg` exited 2 with an
unclosed-group parse error. The primary agent stopped without retrying that
search.

No file, candidate, build, Google Play, device, private value, deployment, or
external state changed.

## Root cause

The diagnostic again treated PowerShell source text containing a variable token
as an interpolated runtime string instead of a literal regex.

## Prevention

- Use a single-quoted regex or fixed-string search for source patterns that
  contain `$` variable tokens.
- Prefer separate literal searches over one alternation when the tokens mix
  regex metacharacters and PowerShell variables.
- Assert the intended pattern string still contains the literal `$Attempt`
  before invoking the search.

## Candidate consequence

The failed search is zero review evidence. C34L remains selection-only and the
exact source inventory must be recollected after registration.
