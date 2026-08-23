# C30T sequential rg optional no-match exit

Date: 2026-08-13

A fixed-string Creator test search chained required-presence and optional-absence queries. Required `/app/creator` evidence printed, but a later optional no-match made the overall command exit 1.

Permanent prevention: run required and optional queries separately; assert required results and treat exit 1 as absence only for a bounded optional query that emitted no diagnostics.
