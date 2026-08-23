# C09 optional route-transition search failure

Date: 7 August 2026

Before C09 runtime implementation, a compound read-only command first proved
`go_router: ^17.3.0`, then searched for an existing `CustomTransitionPage`
owner. No existing owner was a valid possible result, but that optional search
was not mapped explicitly from ripgrep exit 1 to a named zero-result. The
compound command therefore exited 1 even though the dependency evidence was
valid and no repository mutation occurred.

The recurrence is registered as REG-20260807-132. Required dependency searches
and optional duplicate-owner searches are now separate invocations; optional
absence is accepted only for exit 1, while exit codes above 1 remain failures.
