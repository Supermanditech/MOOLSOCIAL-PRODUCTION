# UAW C33J ripgrep Windows wildcard positional-path regression

- Regression: `REG-20260815-2488-C33J-RG-WINDOWS-WILDCARD-POSITIONAL-PATH`
- Scope: read-only native-successor inventory for Screen 03 v5.
- Failure: a bounded command supplied `scripts/check-mvp-scope*.ps1` as a positional `rg` path on Windows. `rg` rejected that path syntax after returning unrelated exact-path matches.
- Impact: no repository, reference, provider, email, build, Play or device state changed. The rejected lookup supplies zero gate evidence.
- Prevention: resolve candidate script names with `rg --files` and a bounded filename filter, then search only the verified exact paths.
