# C30T focused test filename-guess regression

## Observation

A combined focused Flutter command used a guessed C29N creator ergonomics filename. Flutter reported that path as missing; the other 26 tests in the command passed.

## Root cause

The command used a shortened continuation-summary name rather than discovering the exact repository path first.

## Permanent prevention

- Resolve every focused test path with `rg --files` before running a multi-file suite.
- Preserve independently reported sibling passes when a single test path fails to load.
- After registration, run only the exact discovered missing test instead of repeating the passed suite.
