# REG-20260820-3046 frozen dirty digest compressed foreach whitespace parser

## Observed failure

The final non-emitting dirty-digest wrapper was compressed to
`foreach($v in$b)`. PowerShell rejected the missing separator before Git
started.

## Root cause

Mechanical command compression removed required PowerShell token whitespace.

## Impact

- Git status did not start and no dirty output was produced;
- no repository, source, provider, build, Play, OPPO or device state changed;
- no digest result was accepted.

## Prevention and authorized retry

Reuse the previously proven expanded wrapper verbatim, retaining ordinary
PowerShell whitespace and line breaks. Do not compress parser-sensitive loops.
