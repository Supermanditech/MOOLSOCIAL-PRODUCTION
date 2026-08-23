# C30V Windows path-normalization regex recurrence

Date: 2026-08-14
Successor: r60.47 recovery

## Incident

A bounded `rg --files` inventory attempted to normalize Windows paths with PowerShell `-replace '\','/'`. The first operand was interpreted as an invalid regular expression, producing repeated error records and zero admissible inventory rows.

No repository, Google Play or OPPO mutation occurred.

## Escalated prevention

For repository-relative path normalization, use the literal string method `.Replace([char]92, [char]47)` or avoid normalization when only a case-insensitive filename token is needed. The corrected command must capture native `rg` output and its immediate exit before filtering, cap the result, and reject any diagnostic stream.
