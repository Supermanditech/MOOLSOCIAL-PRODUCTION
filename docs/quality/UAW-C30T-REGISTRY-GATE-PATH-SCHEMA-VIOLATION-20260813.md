# C30T registry gate path schema violation

Date: 2026-08-13
Scope: permanent regression-memory metadata only

## Observed failure

The regression-memory checker rejected new entries whose `gates` arrays contained human-readable command labels instead of repository-relative paths. Qualification had not started, and no build, upload, install, device mutation or external write occurred.

## Resolution and prevention

The affected entries now reference only the existing C30T qualifier and machine-state files. Analyzer and focused-test results remain recorded in their evidence documents, not in path-only metadata fields.
