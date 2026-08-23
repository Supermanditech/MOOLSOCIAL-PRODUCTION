# C30K-FIX1 PowerShell boolean-literal rejection

- Scope: bounded local dependency residual-risk reporting.
- Result: all deployment and MVP gates passed before the reporting object failed on the JavaScript-style `false` literal.
- Root cause: PowerShell requires `$false`.
- Prevention: use PowerShell-native boolean literals and do not conflate a reporting-format rejection with preceding gate outcomes.
- Cloud/device impact: none.
