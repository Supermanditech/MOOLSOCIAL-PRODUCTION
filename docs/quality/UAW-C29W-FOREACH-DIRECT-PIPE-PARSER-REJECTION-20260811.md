# C29W foreach direct-pipe parser rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Result: rejected before file read or mutation

A read-only PowerShell probe attempted to pipe directly from a `foreach` statement. PowerShell rejected the syntax before either machine-state file was read. Future bounded multi-file probes first collect results in a task-specific variable and only then serialize that variable. No build, install, or provider mutation occurred.
