# REG2713 — C34I generated cycle owner incomplete semantic substitution

## Observation

Readback of the newly generated C34I source-cycle owner found two pre-run
semantic gaps: its summary retained the predecessor's bare registry count
`2674`, and its static phase referenced a mechanically renamed C34I/C34G
replay gate that does not exist and was not selected for the privacy-safe
successor. No cycle or test command had started.

## Root cause

Mechanical text substitution covered named registry strings but not the bare
integer summary field, and it renamed a predecessor-specific replay path
instead of replacing that semantic dependency with C34I's selected shared
device-actor gate.

## Prevention

Audit every generated owner for registry numbers, predecessor names and
referenced file existence before execution. Bind the summary to the exact
current registry generation and call
`check-release-device-acceptance-actor-policy-c34i.ps1 -SelfTest` instead of a
fabricated replay filename. A generated file parsing successfully is not
semantic qualification.
