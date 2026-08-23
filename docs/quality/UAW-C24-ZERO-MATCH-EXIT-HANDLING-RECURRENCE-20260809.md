# C24 zero-match exit-handling recurrence — 2026-08-09

The exact `/app/book` route-owner search truthfully returned zero matches, but the command again surfaced ripgrep exit code 1 as a tool failure immediately after REG608 established the required zero-safe pattern.

No source or state changed. All further optional C24 ripgrep searches must capture results first and explicitly normalize zero matches before emitting output.

This recurrence is permanently registered as `REG-20260809-609-C24-ZERO-MATCH-EXIT-HANDLING-IMMEDIATE-RECURRENCE`.
