# C28A PowerShell reconciliation command rejection

- Date: 2026-08-10
- Phase: pre-ticket read-only reconciliation
- Mutation before failure: none
- Device effect: none; installed r60.26 remained unchanged
- Rejection: a PowerShell `foreach` statement was piped directly to `Format-Table` without wrapping the statement, producing `ParserError: An empty pipe element is not allowed.`
- Root cause: the inventory query coupled file-size reporting and repository identity into an unnecessarily complex one-liner.
- Prevention: use simple independent read-only commands for branch, HEAD, dirty counts, and file inventories; avoid piping a bare `foreach` language statement.
