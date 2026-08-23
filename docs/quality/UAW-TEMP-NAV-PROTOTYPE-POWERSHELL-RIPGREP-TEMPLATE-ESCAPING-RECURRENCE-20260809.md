# Temporary prototype PowerShell/ripgrep template escaping recurrence

Date: 2026-08-09

A retired-family-gateway source check embedded escaped HTML quotes and the
JavaScript `${action.id}` template expression inside a PowerShell double-quoted
ripgrep pattern. The resulting native invocation was malformed and ripgrep
reported an unrelated file-type error before inspecting the HTML.

Root cause: the validation repeated the mixed-shell quoting class prohibited
by REG856 instead of separating exact literal assertions from regex discovery.

Correction: use PowerShell raw-string `Contains` or `Select-String` checks for
exact JavaScript/HTML literals. Use ripgrep only with shell-safe patterns.

No product behavior, Flutter source, accepted screenbook, APK or OPPO state was
changed by this false failure.
