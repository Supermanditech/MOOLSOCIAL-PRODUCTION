# Post-YouTube backlog PowerShell `foreach` direct-pipe parser failure

Date: 15 August 2026
Registry: `REG-20260815-2244-POST-YOUTUBE-BACKLOG-POWERSHELL-FOREACH-DIRECT-PIPE-PARSER-FAILURE`

The first bounded final status/hash verification placed `| Format-Table`
directly after a statement-form `foreach` loop. PowerShell rejected the script
with `An empty pipe element is not allowed` before status, time or checksum
evidence was produced.

No repository, device, provider, release or external state changed. The retry
is blocked until this entry exists. Future bounded verification collects the
loop output in a task-specific array and formats that array, or uses
`ForEach-Object` explicitly. Parser-rejected output is not evidence.
