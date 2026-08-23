# REG-20260815-2530 C33L second PowerShell foreach direct-pipe recurrence

- Date: 2026-08-15
- Predecessors: `REG-20260815-2525-C33K-POWERSHELL-FOREACH-PIPELINE-PARSER-ERROR` and `REG-20260815-2527-REPEATED-POWERSHELL-FOREACH-DIRECT-PIPE-PARSER-ERROR`
- Failure: the C33L read-only file-hash reconciliation command again used the
  prohibited `foreach (...) { ... } | Format-Table` form and PowerShell rejected
  it at parse time.
- Impact: the command body did not execute. No file, Firebase setting, Play
  release, AAB state or OPPO state changed.
- Root cause: the prevention remained narrative and was not applied as a
  command-construction invariant before another loop was written.
- Strengthened prevention: C33L release work prohibits direct
  `foreach`-to-pipeline syntax. Assign the complete loop output to a uniquely
  named collection, then format that collection. Run the implementation
  regression-memory gate before the corrected readback and bind this entry to
  the C33L release-readiness gate.
- Resolution: the implementation memory gate passed with 2,502 entries and
  the corrected collection-first readback succeeded. C33L remains governed by
  the strengthened prohibition.
