# Autonomous Buy audit foreach metrics-pipe parser recurrence

Date: 2026-08-14
Registry ID: `REG-20260814-2111-AUTONOMOUS-BUY-AUDIT-FOREACH-METRICS-PIPE-PARSER-RECURRENCE`

A read-only metrics command piped directly from a statement-form `foreach` block into `ConvertTo-Json`. PowerShell rejected the pipeline before any inventory was produced. This repeated the prevention already recorded for C30W reviewer-package metrics.

The recurrence was registered before retry. The corrected form assigns the loop output to a task-specific array and pipes only that completed array to formatting. No product or backend source was changed.
