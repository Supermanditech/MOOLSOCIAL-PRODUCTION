# REG2845 — C34L capture FIX2 parser diagnostic colon

Date: 17 August 2026
State: registered parser-wrapper failure before owner parsing

## Mistake

The first capture FIX2 parser wrapper used `"$file:$($error.Message)"` in its
diagnostic. PowerShell treated the colon immediately after `$file` as invalid
variable syntax and rejected the wrapper before any of the four mutated owners
were parsed. No mutation resulted from the failed command; existing owner edits
remain untested.

## Prevention

Build diagnostic rows with the format operator, for example
`'{0}:{1}' -f $file,$error.Message`, or use `${file}`. Parse each owner
independently and never place punctuation immediately after an unbraced
interpolated variable.
