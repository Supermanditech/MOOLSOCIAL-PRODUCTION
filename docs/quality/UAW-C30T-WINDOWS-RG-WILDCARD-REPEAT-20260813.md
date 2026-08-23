# UAW C30T Windows rg wildcard repeat — 2026-08-13

A repository search again passed Windows wildcard path arguments directly to
`rg`. Windows rejected the wildcard paths before those targets were searched.
The successful retry uses literal directories plus `--glob` filters. This is a
repeat of the permanent Windows path-bounding rule and is retained even though
the command was read-only.
