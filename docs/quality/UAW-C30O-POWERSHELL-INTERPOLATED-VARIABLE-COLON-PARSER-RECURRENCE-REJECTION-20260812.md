# C30O PowerShell interpolated-variable colon parser recurrence rejection

Date: `2026-08-12`

State: `REJECTED_READ_ONLY_COMMAND_NO_REPOSITORY_OR_EXTERNAL_MUTATION`

A bounded C30O Dart symbol inventory composed the error string
`rg failed for $name: $exit`. PowerShell parsed the colon as part of the
variable reference and rejected the command before any search ran.

This repeats the permanent rule that a colon may never immediately follow an
interpolated PowerShell variable name. The failed command produced no accepted
source evidence and changed no repository, device, provider or browser state.

Permanent prevention: use the PowerShell format operator for diagnostic text,
or delimit every interpolated variable as `${name}` before punctuation. The
corrected symbol inventory may run only after this record exists and the
regression-memory gate passes.
