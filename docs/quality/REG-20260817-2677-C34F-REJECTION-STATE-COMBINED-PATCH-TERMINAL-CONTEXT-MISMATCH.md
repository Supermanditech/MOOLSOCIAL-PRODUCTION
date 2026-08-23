# C34F rejection-state combined patch terminal-context mismatch

Date: 2026-08-17 IST

Status: registered post-failure; exact state and aggregate hunks required

The first C34F rejection-state patch combined state and aggregate lifecycle,
authority and rejection changes while assuming `rejection: null` was the final
property. `apply_patch` rejected the operation atomically because the exact
current state context differed. No state or aggregate file changed.

Read each exact rejection-property context, apply state and aggregate changes
as separate bounded hunks and parse each owner. C34F remains rejected at
`0/0/0/0`; sealed source, ticket, runbook and gate owners must not be changed.
