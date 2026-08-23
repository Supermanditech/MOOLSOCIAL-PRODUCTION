# C30N PowerShell foreach direct-pipe parser rejection

A read-only final evidence-summary command attempted to pipe directly from a
statement-form `foreach` block. PowerShell rejected the command at parse time
with `An empty pipe element is not allowed`, so no child command ran and no
state changed.

Permanent prevention: materialize statement-form loop output in an explicit
`@(...)` collection (or use pipeline-form `ForEach-Object`) before piping to a
formatter. A parser-rejected command is never treated as evidence.
