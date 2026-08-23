# C30S unused-plugin inventory empty-pipe parser rejection

Date: 2026-08-12

The first unused-plugin source inventory piped an inline `foreach` directly to
`ConvertTo-Json` without grouping. PowerShell rejected the command before it
executed, so no project, device or external state changed.

The retry assigns rows to an explicit result array, treats an expected
`ripgrep` zero match as an empty array and serializes only after the loop.
