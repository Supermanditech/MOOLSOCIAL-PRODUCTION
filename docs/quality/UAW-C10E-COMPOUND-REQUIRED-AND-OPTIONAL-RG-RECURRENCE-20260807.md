# C10E compound required/optional search recurrence

Date: 2026-08-07

Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`

During root-route inspection, one PowerShell command ran a required fixed-string
search and then an optional source-symbol search without handling the second
search's valid zero-match exit. The command therefore exited 1 and its combined
output was rejected. It made no source or runtime change.

The retry separates required and optional searches. Every optional `rg` probe
maps exit 1 to an explicit zero-result outcome and rejects only exit codes above
1. This evidence permanently records the recurrence so a partial command output
cannot be accepted as navigation-contract evidence.
