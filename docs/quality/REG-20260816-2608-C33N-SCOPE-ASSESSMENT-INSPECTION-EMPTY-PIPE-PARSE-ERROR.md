# REG-20260816-2608 — C33N scope-assessment inspection had an empty-pipe parse error

Date: 2026-08-16 IST

A bounded read-only PowerShell inspection placed a pipeline immediately after
a `foreach` statement without grouping the statement's output. PowerShell
rejected the command at parse time as an empty pipe element, so it read no
scope assessment and produced no usable result. The failed command is not
counted.

The correction is to collect the `foreach` output in an explicit array first
and pipe only that array to formatting. This changes no repository product
source, candidate count, authority or external state.
