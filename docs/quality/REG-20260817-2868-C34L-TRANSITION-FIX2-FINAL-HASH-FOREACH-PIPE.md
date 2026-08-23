# REG2868 — C34L transition FIX2 final-hash foreach-pipe recurrence

- Status: registered after all semantic suites had already passed.
- Scope: read-only final evidence collection.
- Mistake: the transition agent piped directly from a statement-level PowerShell `foreach` into `ConvertTo-Json`, causing `An empty pipe element is not allowed` before file identities were collected.
- Root cause: the known unsupported statement-to-pipeline construction was reused in a handoff projection.
- Prevention: collect loop output in a variable before serialization, or emit one exact file identity per independent command.
- Repository/external impact: no owner mutation, test rerun, or external action followed.
